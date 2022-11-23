Module TeachMover_Control
    Public AllPort As Array
    Public StringCommand As String
    Public SP As Integer
    Public myPort As System.IO.Ports.SerialPort
    Public WaitMarker As Boolean = True
    Public DataTitle() As String
    Public Data(,) As Double

    Public Function Init_Control(CurrentPort As System.IO.Ports.SerialPort) As System.IO.Ports.SerialPort
        'Initialize SerialPort
        AllPort = IO.Ports.SerialPort.GetPortNames()
        CurrentPort.PortName = AllPort(0)
        CurrentPort.BaudRate = 9600

        'Initialize Parameters
        StringCommand = ""  'serial string command 
        SP = 240            'Default Speed of Motion

        'Initialize Data Titles
        DataTitle = {"Time", "Step_Base", "Step_Elbow", "Step_Shoulder",
                    "Step_WristLeft", "Step_WristRight", "Step_Gripper",
                    "Palm_x", "Palm_y", "Palm_z"}

        Return CurrentPort
    End Function

    Public Sub Get_And_Send_STEP_Command(myPort, SP, a, b, c, d, e, f)
        '<input>
        'myPort:            Concurrent serial port - (System.IO.Ports.SerialPort)
        'SP:                robot moving speed (step/s) - (integer)
        'a, b, c, d, e, f:  moving step of each joint - (integer)
        '<output>
        'StringCommand:     integrated serial command for the robot - (string)

        ' integrate and send serial command
        StringCommand = Get_STEP_Command(SP, a, b, c, d, e, f)

        ' Send string command to the robot arm
        Write_Command(StringCommand, myPort)
    End Sub

    Public Function Get_STEP_Command(SP, a, b, c, d, e, f) As String
        ' integrate command type and step as string command
        Dim command, command1, command2 As String
        command = "@STEP" & CStr(SP) & "," & CStr(a) & "," + CStr(b) & "," + CStr(c) & "," &
                            CStr(d) & "," + CStr(e) & "," & CStr(f)

        command1 = "@STEP" + CStr(SP) + "," + CStr(a) + "," + CStr(b) + "," + CStr(c) + "," +
                             CStr(d) + "," + CStr(e) + "," + CStr(f) + ","

        command2 = "@STEP" & CStr(SP) & "," & CStr(a) & "," & CStr(b) & "," & CStr(c) & "," &
                             CStr(d) & "," & CStr(e) & "," & CStr(f)
        Return command2
    End Function

    Public Sub Write_Command(ByVal StringCommand As String, myPort As System.IO.Ports.SerialPort)
        ' Send string command to the robot arm
        myPort.Write(StringCommand + vbCr)
    End Sub

    Public Sub SerialPort_Read(CurrentPort As System.IO.Ports.SerialPort, CurrentTextbox As TextBox)
        ' read data from the current serial port
        ' and display to the related textbox
        Dim RawData As String

        'Threading.Thread.Sleep(100)
        CurrentPort.ReadByte()                                  ' skip the first byte "1"
        CurrentPort.ReadByte()                                  ' skip the first carriage return (vbCr)
        CurrentPort.ReadByte()
        RawData = CurrentPort.ReadExisting.ToString             ' read raw string data

        ' process the raw data under "READ" command
        If RawData <> "" Then
            CurrentTextbox.Text &= vbNewLine & RawData ' display the raw data
            GetStepByRead(RawData)
        End If

        ' clear everthing in the serial buffer
        CurrentPort.DiscardInBuffer()
    End Sub

    Public Sub GetStepByRead(RawData)
        ' process raw data from read command
        Dim stepString() As String
        Dim i As Integer

        ' split all steps by ','
        stepString = RawData.Split(",")

        ' pick up first 6 steps as number
        'For i = 0 To stepChangeAll.Length - 1
        ' stepChangeAll(i) = CDbl(stepChangeAll(i))
        'Next
    End Sub

    ' find absolute maximum value in an array
    Public Function ArrayFindAbsMax(CurrentArray() As Double) As Integer
        Return Math.Max(CurrentArray.Max, Math.Abs(CurrentArray.Min))
    End Function

    Public Sub DataReceiveWaiter()
        ' wait until current command is finished 
        'Dim CurrentDateTime As DateTime
        'Dim timeInterval As Integer

        While WaitMarker = True
            ' when SerialPort1_DataReceived executes,
            ' WaitMarker -> True and terminate the While Loop
        End While
        WaitMarker = True

        'timeInterval = (DateTime.Now.Millisecond - CurrentDateTime.Millisecond)
        'Console.WriteLine(" time -> " & Format(timeInterval, "0.00 us"))
    End Sub
End Module
