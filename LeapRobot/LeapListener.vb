Imports Leap
Imports System.IO.Ports

Public Class LeapListener
    Inherits Listener

    Public Overrides Sub OnInit(cntrlr As Controller)
        Console.WriteLine("Initialized")
        FileSwitch = True
    End Sub

    Public Overrides Sub OnConnect(cntrlr As Controller)
        Console.WriteLine("Connected")
    End Sub

    Public Overrides Sub OnDisconnect(cntrlr As Controller)
        Console.WriteLine("Disconnected")
    End Sub

    Public Overrides Sub OnExit(cntrlr As Controller)
        Console.WriteLine("Exited")
        FileSwitch = False
    End Sub

    Private currentTime As Long
    Private previousTime As Long
    Private timeChange As Long
    Private timeInterval As Long
    Private LeapPos0(0 To 2), LeapPos(0 To 2), RobotPos(0 To 2), RobotGripper As Double
    Private GripperUpperBound, GripperLowerBound As Decimal
    Private LeapCaliSwitch As Boolean = False
    Private FileSwitch, OpenSwitch As Boolean
    Private x, y, z As Double
    Private FileName As String


    Public Overrides Sub OnFrame(cntrlr As Controller)
        ' Get the current frame.
        Dim currentFrame As Frame = cntrlr.Frame

        'get time
        currentTime = currentFrame.Timestamp
        timeChange = currentTime - previousTime
        timeInterval = 0.1 ' second

        ' declare position and attitude variables
        Dim roll, pitch, yaw As Double

        ' file open/close switch
        If FileSwitch = True And OpenSwitch = False Then
            OpenSwitch = True

            ' start to write all stepChange

            FileName = Get_File_Name()
            CurrentFileName = FileName
            FileOpen(1, FileName, OpenMode.Output)

            ' write data title
            WriteDataTitle()

            ' console
            DisplayInConsole("File")
        ElseIf FileSwitch = False And OpenSwitch = True Then
            OpenSwitch = False
            'stop writing all stepChange
            FileClose(1)
        End If


        If (timeChange > timeInterval * 10 ^ 6) Then
            If (Not currentFrame.Hands.IsEmpty) Then

                ' get hand
                Dim hand As Hand = currentFrame.Hands(0)
                Dim PalmPos As Vector = hand.PalmPosition
                Dim grabStrength As Decimal = hand.GrabStrength

                ' get palm's position
                x = PalmPos.x
                y = PalmPos.y
                z = PalmPos.z

                ' get fingers(index and middle)
                Dim Index As Finger = hand.Fingers(1)
                Dim Middle As Finger = hand.Fingers(2)
                Dim IndexPos As Vector = Index.TipPosition
                Dim MiddlePos As Vector = Middle.TipPosition

                ' get relative distance(Euclidean distance) between index and middle
                Dim FingerDistance As Decimal
                FingerDistance = Get_Euclidean_Distance(IndexPos.x, IndexPos.y, IndexPos.z,
                                                        MiddlePos.x, MiddlePos.y, MiddlePos.z)

                ' display tracking information before robot control is on
                If RobotSwitch = False Then
                    DisplayInConsole("LeapMotion", grabStrength)
                End If

                ' remote control robot
                If RobotSwitch = True Then
                    'calibrate the current Leap position as an initial position
                    If LeapCaliSwitch = False Then
                        LeapCaliSwitch = True
                        LeapPos0 = PositionTransfer(PalmPos)

                        ' initialize fingers' relative distance as upper bound of the gripper (mm)
                        GripperUpperBound = FingerDistance - 5
                        GripperLowerBound = 20
                    End If

                    'get the current Leap position
                    LeapPos = PositionTransfer(PalmPos)

                    'update the current robot position
                    Dim MmToInch As Decimal = 0.0393701 ' milimeter to inch
                    RobotPos(0) = pos(0) + (LeapPos(0) - LeapPos0(0)) * MmToInch
                    RobotPos(1) = pos(1) + (LeapPos(1) - LeapPos0(1)) * MmToInch
                    RobotPos(2) = pos(2) + (LeapPos(2) - LeapPos0(2)) * MmToInch

                    ' get gripper step
                    ' put the current finger distance in the designated threshold
                    'FingerDistance = Math.Max(Math.Min(FingerDistance, GripperUpperBound), GripperLowerBound)
                    '' normalize the current finger distance
                    'FingerDistance = (FingerDistance - GripperLowerBound) / (GripperUpperBound - GripperLowerBound)
                    'RobotGripper = FingerDistance * 1000

                    'RobotGripper = FindGripperStep(grabStrength)
                    'DoGrab()

                    'Move to the current position
                    SingleMove()

                    ' Save the current data point
                    Dim CurrentData() As Double = {currentTime,
                                                   stepChange(0), stepChange(1), stepChange(2),
                                                   stepChange(3), stepChange(4), stepChange(5),
                                                   x, y, z}
                    RecordData(CurrentData)
                    WriteData(CurrentData)

                    ' waite the current step is finished
                    DataReceiveWaiter()

                    ' display the current position
                    DisplayInConsole("Robot")

                End If
            End If

            previousTime = currentTime
        End If

    End Sub

    Public Sub SingleMove()

        ' calculate target step (position)
        stepNew = FindStep(RobotPos(0), RobotPos(1), RobotPos(2), 0, 0)

        'calculate target step (gripper) 
        'stepNow(5) = RobotGripper

        ' calculate step change
        Dim i As Integer
        For i = 0 To step0.Length - 1
            stepChange(i) = Math.Round(stepNew(i) - stepNow(i), 0)
        Next

        ' get gripper step change separately
        stepChange(5) = RobotGripper

        ' transform stepChange
        StepTransform(stepChange)

        ' reset current step
        stepNow = stepNew

        ' setup individual gripper command
        'If RobotGripper = 0 Then
        '    ' moving without grabing
        '    stepChange(5) = 0
        'Else
        '    ' grabing only
        '    stepChange(0) = 0
        '    stepChange(1) = 0
        '    stepChange(2) = 0
        'End If

        ' write command
        Get_And_Send_STEP_Command(myPort, SP, stepChange(0), stepChange(1), stepChange(2),
                                              stepChange(3), stepChange(4), stepChange(5))

        ' accumulate step change
        For i = 0 To stepChangeAll.Length - 1
            stepChangeAll(i) = stepChangeAll(i) + stepChange(i)
        Next

    End Sub

    ' write the first row (title)
    Private Sub WriteDataTitle()
        ' write titles
        Dim i As Integer
        For i = 0 To (DataTitle.Length - 2)
            Write(1, DataTitle(i))
        Next
        WriteLine(1, DataTitle(DataTitle.Length - 1))
    End Sub

    ' save current data point into an array
    Private Sub RecordData(ByVal CurrentData() As Double)
        ' store data in an array
        ReDim Preserve Data(0 To 9, 0 To total)
        For i = 0 To CurrentData.Length - 1
            Data(i, total) = CurrentData(i)
        Next
        total += 1
    End Sub

    ' write current data point into csv file
    Private Sub WriteData(ByVal CurrentData() As Double)
        ' write data in the csv file
        Dim i As Integer
        For i = 0 To (CurrentData.Length - 2)
            Write(1, CurrentData(i))
        Next
        WriteLine(1, CurrentData(CurrentData.Length - 1))
    End Sub

    ' transfer position data
    Private Function PositionTransfer(ByVal Position As Vector) As Double()
        ' transfer x,y,z based on Euler coordinate and retrun array
        Dim NewPosition(0 To 2) As Double
        NewPosition(0) = Position.z
        NewPosition(1) = Position.x
        NewPosition(2) = Position.y
        Return NewPosition
    End Function

    ' display current status
    Private Sub DisplayInConsole(ByVal MyRequest As String, Optional ByVal OtherData As Single = 0)
        'display current status in the console
        Select Case MyRequest
            ' display LeapMotion sensor data before control the robot
            Case "LeapMotion"
                Console.WriteLine(Format(currentTime / 10 ^ 6, "00.00s") & " : " &
                                  Format(x, "00.00") & " " &
                                  Format(y, "00.00") & " " &
                                  Format(z, "00.00") & " " &
                                  Format(OtherData, "00.00"))
            Case "Robot"
                ' display current robot data when it is under control
                Console.WriteLine(Format(currentTime / 10 ^ 6, "00.00s") & " : " &
                                  Format(RobotPos(0), "00.00") & " " &
                                  Format(RobotPos(1), "00.00") & " " &
                                  Format(RobotPos(2), "00.00") & " " &
                                  CStr(stepChange(5)))
            Case "File"
                ' notify user start to write data in the file
                Console.WriteLine("start to write Leap Motion data in " + FileName)
        End Select
    End Sub

    Private Function FindGripperStep(grabStrength As Decimal) As Integer
        Dim gripper_value As Integer

        If GripperStatus = "Close" Then
            If grabStrength < 0.1 Then
                gripper_value = 1024
                GripperStatus = "Open"
            End If
        ElseIf GripperStatus = "Open" Then
            If grabStrength > 0.9 Then
                gripper_value = -1024
                GripperStatus = "Close"
            End If
        End If
        Return gripper_value
    End Function

    Private Sub DoGrab()
        ' Grab an object(open/close gripper)
        Get_And_Send_STEP_Command(myPort, SP, 0, 0, 0, 0, 0, RobotGripper)
    End Sub

    Private Function Get_Euclidean_Distance(x1, y1, z1, x2, y2, z2)
        Return Math.Sqrt((x1 - x2) ^ 2 + (y1 - y2) ^ 2 + (z1 - z2) ^ 2)
    End Function

    ' generate new file name(eg: "data1.csv", "data2.csv", etc)
    Private Function Get_File_Name() As String
        Dim i As Integer = 1
        Dim FileName As String = "data" + CStr(i) + ".csv"
        While My.Computer.FileSystem.FileExists(FileName)
            i += 1
            FileName = "data" + CStr(i) + ".csv"
        End While
        Return FileName
    End Function

End Class
