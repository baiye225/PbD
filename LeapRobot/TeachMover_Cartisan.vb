Module TeachMover_Cartisan
    ' Cartisan to Step
    Public C, B_C, S_C, E_C, W_C, G_C, RR As Decimal

    ' TeachMover2 Geometrical Paramaters
    Public H, L, LL As Decimal

    ' Parameters in Cartisan Coordinate System
    Public X, Y, Z, Roll, Pitch, Yaw As Decimal

    ' Initialize position data (robot arm faces vertical up)
    Public pos(0 To 2), step0(0 To 5), stepNow(0 To 5), stepNew(),
           stepChange(0 To 5), stepChangeAll(0 To 5),
           stepAngle(0 To 5) As Double

    ' Initialize gripper status
    Public GripperStatus As String = "Close"


    ' initialize all constants
    Public Sub Init_Cartisan()
        ' Cartisan to Step
        C = 2 * Math.PI     ' Radians of a circle
        B_C = 7072 / C      ' Base motor:             7072 steps in 1 rotation
        S_C = 7072 / C      ' Shoulder motor:         7072 steps in 1 rotation
        E_C = 4158 / C      ' Elbow motor:            4158 steps in 1 rotation
        W_C = 1536 / C      ' Right/Left Wrist motor: 1536 steps in 1 rotation
        G_C = 2330 / C      ' Gripper motor:          2330 steps in 1 rotation

        ' TeachMover2 Geometrical Paramaters (inches)
        H = 7.625   ' The length of Base to Shoulder
        L = 7.0     ' The length of Shoulder to Elbow and Elbow to Wrist
        LL = 3.8    ' The length of Wrist

        pos(0) = L          'x0
        pos(1) = 0          'y0
        pos(2) = H + L      'z0

        step0(3) = 0        'p0
        step0(4) = 0        'r0
        step0(5) = 1000        'r0
        step0 = FindStep(pos(0), pos(1), pos(2), step0(3), step0(4))
        stepNow = step0
    End Sub

    ' b,s,e stand for current position of base, shoulder and elbow in steps
    ' Step to Cartisan (X, Y, Z, Roll,Pitch)
    ' Assume no roll rotation
    Private Function FindX(b As Decimal, s As Decimal, e As Decimal, p As Decimal) As Decimal
        ' <Input>
        ' b, s, e - step value of base, shoulder, elbow
        ' p - pitch
        ' <Output>
        ' FindX - current X position
        RR = L * Math.Cos(-s / S_C) + L * Math.Cos(-e / E_C)
        RR += LL * Math.Cos(p)

        Return RR * Math.Cos(b / B_C)
    End Function

    Private Function FindY(b As Decimal, s As Decimal, e As Decimal, p As Decimal) As Decimal
        ' <Input>
        ' b, s, e - step value of base, shoulder, elbow
        ' p - pitch
        ' <Output>
        ' FindY - current Y position

        RR = L * Math.Cos(-s / S_C) + L * Math.Cos(-e / E_C)
        RR += LL * Math.Cos(p)

        Return RR * Math.Sin(b / B_C)
    End Function

    Private Function FindZ(s As Decimal, e As Decimal, p As Decimal) As Decimal
        ' <Input>
        ' b, s, e - step value of base, shoulder, elbow
        ' p - pitch
        ' <Output>
        ' FindZ - current Z position

        Return H + (L * Math.Sin(-s / S_C)) + (L * Math.Sin(-e / E_C)) _
                + (LL * Math.Sin(p))

    End Function

    Private Function FindRoll(wr As Decimal, wl As Decimal) As Decimal
        ' <Input>
        ' wr, wl - right wrist and left wrist
        ' <Output>
        ' FindRoll - current roll angle

        Return 0.5 * (-wr + wl) / W_C
    End Function

    Private Function FindPitch(wr As Decimal, wl As Decimal) As Decimal
        ' <Input>
        ' wr, wl - right wrist and left wrist
        ' <Output>
        ' FindPitch - current pitch angle

        Return -0.5 * (wr + wl) / W_C
    End Function

    ' Cartisan to Step (b, s, e, wr, wl)
    Public Function FindStep(x As Double, y As Double, z As Double,
                              r As Double, p As Double) As Double()
        ' <Input>
        ' x, y, z - location
        ' r, p - roll and pitch
        ' <Output>
        ' FindStep - integrated step data converted by location and rotation

        ' Get local location of gripper base
        Dim r0, z0 As Double
        RR = Math.Sqrt(x * x + y * y) 'intermediate value
        r0 = RR
        z0 = z - H

        ' Get intermediate angles (radian)
        Dim alpha, beta As Double
        alpha = Math.Acos(Math.Sqrt((r0 * r0 + z0 * z0) / (4 * L * L)))
        beta = Math.Atan2(z0, r0)

        ' Get and convert each angle into STEP (step)
        Dim b, s, e, wr, wl As Double
        Dim b_angle, s_angle, e_angle, wr_angle, wl_angle As Double

        ' integrate each angle
        b_angle = Math.Atan2(CDbl(y), CDbl(x))
        s_angle = (alpha + beta)
        e_angle = (beta - alpha)
        wr_angle = (p - r)
        wl_angle = (p + r)

        ' integrate each angle
        stepAngle = {Rad2Deg(b_angle), Rad2Deg(s_angle), Rad2Deg(e_angle), Rad2Deg(wr_angle), Rad2Deg(wl_angle)}

        ' convert angle to step
        b = b_angle * B_C
        s = s_angle * S_C
        e = e_angle * E_C
        wr = wr_angle * W_C
        wl = wl_angle * W_C


        ' Return all step
        Return {b, s, e, wr, wl, 0}
    End Function

    Private Function Rad2Deg(ByVal RadData As Double) As Double
        ' convert radian to degree
        Return RadData * 180 / Math.PI
    End Function


    Private Sub MoveTo()
        ' x0, y0, z0 - current location
        ' x1, y1, z1 - desired location

        ' Test x0, y0, z0 and x1, y1, z1
        Dim x0, y0, z0 As Decimal
        Dim x1, y1, z1 As Decimal

        ' Read STEP from TeachMover2
        ' b, s, e, wr, wl, g
        Dim b, s, e, wr, wl, g, r, p As Decimal

        'x0 = FindX(b, s, e, p)
        'y0 = FindY(b, s, e, p)
        'z0 = FindZ(b, s, e, p)

        ' Find current roll and pitch
        r = FindPitch(wr, wl)
        p = FindRoll(wr, wl)

        ' Get desired step from desired location(x1, y1, z1)
        Dim step1(), r1, p1 As Double
        step1 = FindStep(x1, y1, z1, r1, p1)

        ' Get and write command to the robot
        Dim data As String

        ' to be done!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        'data = GetCmd(step1, CInt(SP_Text.Text))
        'Call Write_Command(data, SerialPort1)
    End Sub
    Private Function GetCmd(ByVal StepData() As Decimal, ByVal SP As Integer) As String
        ' <Input> 
        ' StepData() - an array of all step data
        ' SP - speed of motion
        ' <Output>
        ' data - integrated string command
        Dim Data As String

        Data = "@STEP " + CStr(SP) + "," + CStr(StepData(0)) + "," + CStr(StepData(1)) _
                + "," + CStr(StepData(2)) + "," + CStr(StepData(3)) _
                + "," + CStr(StepData(4)) + "," + CStr(0) + ","

        Return Data
    End Function

    Public Function StepTransform(CurrentStep() As Double) As Double()
        Dim step0, step1, step2 As Integer
        'get x, y, z
        step0 = CurrentStep(0)
        step1 = CurrentStep(1)
        step2 = CurrentStep(2)

        'transform x, y, z
        CurrentStep(0) = step0
        CurrentStep(1) = -step1
        CurrentStep(2) = -step2

        Return CurrentStep
    End Function

End Module
