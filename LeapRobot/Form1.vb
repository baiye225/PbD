Imports Leap
Imports System.IO.Ports

Public Class Form1

    Private ReadOnly cntrl As New Controller
    Private ReadOnly listener As New LeapListener

    Private Sub Form1_Load(sender As Object, e As EventArgs) Handles MyBase.Load
        ' Centralize the program to center of screen
        Me.CenterToScreen()

        ' initialize serial port
        If SerialPort1.IsOpen = False Then
            SerialPort1 = Init_Control(SerialPort1)
            SerialPort1.Open()
        End If

        ' setup SerialPort1 pointer to myPort (a pointer)
        myPort = SerialPort1

        'initialize position parameters
        Init_Cartisan()

    End Sub

    Private Sub Button1_Click(sender As Object, e As EventArgs) Handles Button1.Click
        ' open leap motion
        cntrl.AddListener(listener)
        Button1.Enabled = False
        Button2.Enabled = True
    End Sub

    Private Sub Button2_Click(sender As Object, e As EventArgs) Handles Button2.Click
        ' close leap motion
        cntrl.RemoveListener(listener)

        Button1.Enabled = True
        Button2.Enabled = False
    End Sub

    Private Sub Robot_Switch_Click(sender As Object, e As EventArgs) Handles Robot_Switch.Click
        ' open or close the robot arm
        If Robot_Switch.Text = "Robot on" Then
            Robot_Switch.Text = "Robot off"
            RobotSwitch = True
        Else
            Robot_Switch.Text = "Robot on"
            RobotSwitch = False
        End If

    End Sub

    Private Sub Exit_Button_Click(sender As Object, e As EventArgs) Handles Exit_Button.Click
        'exit
        'close serial port
        SerialPort1.Dispose()
        If myPort.IsOpen = True Then myPort.Close()

        'exit the program

        'End
        Environment.Exit(Environment.ExitCode)
    End Sub

    Private Sub Return_Button_Click(sender As Object, e As EventArgs) Handles Return_Button.Click
        'return back to the original position
        Get_And_Send_STEP_Command(myPort, SP, -stepChangeAll(0), -stepChangeAll(1), -stepChangeAll(2),
                                              -stepChangeAll(3), -stepChangeAll(4), -stepChangeAll(5))
        DataReceiveWaiter()
    End Sub

    Private Sub PBD_Click(sender As Object, e As EventArgs) Handles PBD.Click
        ' robot move after learning the demonstration
        Dim TotalStep(0 To 5) As Integer
        Dim TempTitle As String = ""
        Dim i, j As Integer
        Dim FileNumber As Integer = 2

        ' choose designated "data.csv" to read
        If NumericUpDown1.Value <> 0 Then
            Data = Nothing 'reset data
            CurrentFileName = "data" + NumericUpDown1.Value.ToString + ".csv"
        End If

        ' read all data if no demonstration data
        If Data Is Nothing Then
            ' open file
            FileOpen(FileNumber, CurrentFileName, OpenMode.Input)
            total = 0

            ' read all data titles
            For i = 0 To DataTitle.Length - 1
                Input(FileNumber, TempTitle)
            Next

            ' read all data
            Do Until EOF(FileNumber)
                ReDim Preserve Data(0 To DataTitle.Length - 1, 0 To total)
                For i = 0 To DataTitle.Length - 1
                    Input(FileNumber, Data(i, total))
                Next
                total += 1
            Loop

            ' close file
            FileClose(FileNumber)
        End If


        ' excute all waypoints one by one  
        DisplayStatus("Execute", CurrentFileName)
        ReceieveCounter = 0

        For i = 0 To total - 1

            ' move to the current target position
            Get_And_Send_STEP_Command(myPort, SP, Data(1, i), Data(2, i), Data(3, i),
                                                  Data(4, i), Data(5, i), Data(6, i))

            ' wait until the current step is finishied
            DataReceiveWaiter()

            ' accumulate effective step(from 0 to t)
            For j = 0 To TotalStep.Length - 1
                TotalStep(j) += Data(j + 1, i)
            Next
        Next

        ' go back to the original position
        Console.WriteLine("---Return---")
        Get_And_Send_STEP_Command(myPort, SP, -TotalStep(0), -TotalStep(1), -TotalStep(2),
                                              -TotalStep(3), -TotalStep(4), -TotalStep(5))

        DataReceiveWaiter()
        Console.WriteLine("---Finished---")
    End Sub

    ' data receiver event listener
    Private Sub SerialPort1_DataReceived(sender As Object, e As SerialDataReceivedEventArgs) Handles SerialPort1.DataReceived
        'Me.Invoke(New EventHandler(AddressOf SerialPort_Read))

        SerialPort_Read(sender, e)
        WaitMarker = False                     ' time marker when serial command has been finished executing
    End Sub

    ' process received data from the current serial port
    Private Sub SerialPort_Read(ByVal sender As Object, ByVal e As EventArgs)

        Dim msg As String
 
        msg = SerialPort1.ReadByte().ToString                ' skip the first byte "1"
        msg &= "-" & SerialPort1.ReadByte().ToString         ' skip the first carriage return (vbCr)
        msg &= "-" & SerialPort1.ReadExisting().ToString     ' read the rest data

        'Threading.Thread.Sleep(25)

        ReceieveCounter += 1
        Console.WriteLine("Data Receieve -> " & CStr(ReceieveCounter) & " " & msg)

        SerialPort1.DiscardInBuffer()
    End Sub

    ' key event to control the gripper
    Private Sub Form1_KeyControl(ByVal sender As Object, ByVal e As KeyEventArgs) Handles KeyControl.KeyDown
        If e.KeyCode = Keys.W Then
            ' Gripper
            Get_And_Send_STEP_Command(myPort, SP, 0, 0, 0, 0, 0, 1024)
            DataReceiveWaiter()
        ElseIf e.KeyCode = Keys.S Then
            ' Gripper
            Get_And_Send_STEP_Command(myPort, SP, 0, 0, 0, 0, 0, -1024)
            DataReceiveWaiter()
        ElseIf e.KeyCode = Keys.ControlKey Then
            ' Robot control on/off
            Robot_Switch_Click(sender, e)
        ElseIf e.KeyCode = Keys.Delete Then
            ' Clear current data
            Data = Nothing
            DisplayStatus("Clear", CurrentFileName)
        End If

    End Sub

    ' select designated information to display in the form1 textbox
    Private Sub DisplayStatus(ByVal request As String, ByVal FileName As String)
        Dim CurrentInfo As String = "N/A"
        Select Case request
            Case "Execute"
                CurrentInfo = "Excute All Commands From: <" + CurrentFileName + ">."
            Case "Clear"
                CurrentInfo = "Current Data From <" + CurrentFileName + "> Has Been Cleared."
        End Select
        TextBox1.Text = CurrentInfo
    End Sub
End Class

