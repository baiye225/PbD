<Global.Microsoft.VisualBasic.CompilerServices.DesignerGenerated()>
Partial Class Form1
    Inherits System.Windows.Forms.Form

    'Form overrides dispose to clean up the component list.
    <System.Diagnostics.DebuggerNonUserCode()>
    Protected Overrides Sub Dispose(ByVal disposing As Boolean)
        Try
            If disposing AndAlso components IsNot Nothing Then
                components.Dispose()
            End If
        Finally
            MyBase.Dispose(disposing)
        End Try
    End Sub

    'Required by the Windows Form Designer
    Private components As System.ComponentModel.IContainer

    'NOTE: The following procedure is required by the Windows Form Designer
    'It can be modified using the Windows Form Designer.  
    'Do not modify it using the code editor.
    <System.Diagnostics.DebuggerStepThrough()>
    Private Sub InitializeComponent()
        Me.components = New System.ComponentModel.Container()
        Me.Button1 = New System.Windows.Forms.Button()
        Me.Button2 = New System.Windows.Forms.Button()
        Me.Robot_Switch = New System.Windows.Forms.Button()
        Me.Exit_Button = New System.Windows.Forms.Button()
        Me.SerialPort1 = New System.IO.Ports.SerialPort(Me.components)
        Me.Return_Button = New System.Windows.Forms.Button()
        Me.PBD = New System.Windows.Forms.Button()
        Me.Label1 = New System.Windows.Forms.Label()
        Me.KeyControl = New System.Windows.Forms.RadioButton()
        Me.TextBox1 = New System.Windows.Forms.TextBox()
        Me.NumericUpDown1 = New System.Windows.Forms.NumericUpDown()
        Me.Label2 = New System.Windows.Forms.Label()
        CType(Me.NumericUpDown1, System.ComponentModel.ISupportInitialize).BeginInit()
        Me.SuspendLayout()
        '
        'Button1
        '
        Me.Button1.Location = New System.Drawing.Point(62, 46)
        Me.Button1.Margin = New System.Windows.Forms.Padding(2)
        Me.Button1.Name = "Button1"
        Me.Button1.Size = New System.Drawing.Size(83, 33)
        Me.Button1.TabIndex = 6
        Me.Button1.Text = "OpenLeap"
        Me.Button1.UseVisualStyleBackColor = True
        '
        'Button2
        '
        Me.Button2.Location = New System.Drawing.Point(169, 46)
        Me.Button2.Margin = New System.Windows.Forms.Padding(2)
        Me.Button2.Name = "Button2"
        Me.Button2.Size = New System.Drawing.Size(98, 33)
        Me.Button2.TabIndex = 7
        Me.Button2.Text = "CloseLeap"
        Me.Button2.UseVisualStyleBackColor = True
        '
        'Robot_Switch
        '
        Me.Robot_Switch.Location = New System.Drawing.Point(62, 102)
        Me.Robot_Switch.Margin = New System.Windows.Forms.Padding(2)
        Me.Robot_Switch.Name = "Robot_Switch"
        Me.Robot_Switch.Size = New System.Drawing.Size(83, 39)
        Me.Robot_Switch.TabIndex = 8
        Me.Robot_Switch.Text = "Robot on"
        Me.Robot_Switch.UseVisualStyleBackColor = True
        '
        'Exit_Button
        '
        Me.Exit_Button.Location = New System.Drawing.Point(519, 327)
        Me.Exit_Button.Margin = New System.Windows.Forms.Padding(2)
        Me.Exit_Button.Name = "Exit_Button"
        Me.Exit_Button.Size = New System.Drawing.Size(70, 28)
        Me.Exit_Button.TabIndex = 9
        Me.Exit_Button.Text = "Exit"
        Me.Exit_Button.UseVisualStyleBackColor = True
        '
        'SerialPort1
        '
        '
        'Return_Button
        '
        Me.Return_Button.Location = New System.Drawing.Point(169, 102)
        Me.Return_Button.Margin = New System.Windows.Forms.Padding(2)
        Me.Return_Button.Name = "Return_Button"
        Me.Return_Button.Size = New System.Drawing.Size(98, 39)
        Me.Return_Button.TabIndex = 10
        Me.Return_Button.Text = "Return_Button"
        Me.Return_Button.UseVisualStyleBackColor = True
        '
        'PBD
        '
        Me.PBD.Location = New System.Drawing.Point(292, 102)
        Me.PBD.Margin = New System.Windows.Forms.Padding(2)
        Me.PBD.Name = "PBD"
        Me.PBD.Size = New System.Drawing.Size(98, 38)
        Me.PBD.TabIndex = 11
        Me.PBD.Text = "PBD"
        Me.PBD.UseVisualStyleBackColor = True
        '
        'Label1
        '
        Me.Label1.AutoSize = True
        Me.Label1.Font = New System.Drawing.Font("Microsoft Sans Serif", 15.0!, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, CType(0, Byte))
        Me.Label1.Location = New System.Drawing.Point(180, 9)
        Me.Label1.Name = "Label1"
        Me.Label1.Size = New System.Drawing.Size(199, 25)
        Me.Label1.TabIndex = 5
        Me.Label1.Text = "LeapRobot Control UI"
        '
        'KeyControl
        '
        Me.KeyControl.AutoSize = True
        Me.KeyControl.Location = New System.Drawing.Point(292, 54)
        Me.KeyControl.Name = "KeyControl"
        Me.KeyControl.Size = New System.Drawing.Size(76, 17)
        Me.KeyControl.TabIndex = 1
        Me.KeyControl.Text = "KeyControl"
        Me.KeyControl.UseVisualStyleBackColor = True
        '
        'TextBox1
        '
        Me.TextBox1.Location = New System.Drawing.Point(62, 204)
        Me.TextBox1.Multiline = True
        Me.TextBox1.Name = "TextBox1"
        Me.TextBox1.Size = New System.Drawing.Size(328, 99)
        Me.TextBox1.TabIndex = 12
        '
        'NumericUpDown1
        '
        Me.NumericUpDown1.Location = New System.Drawing.Point(151, 178)
        Me.NumericUpDown1.Maximum = New Decimal(New Integer() {1000, 0, 0, 0})
        Me.NumericUpDown1.Name = "NumericUpDown1"
        Me.NumericUpDown1.Size = New System.Drawing.Size(46, 20)
        Me.NumericUpDown1.TabIndex = 13
        '
        'Label2
        '
        Me.Label2.AutoSize = True
        Me.Label2.Location = New System.Drawing.Point(62, 180)
        Me.Label2.Name = "Label2"
        Me.Label2.Size = New System.Drawing.Size(83, 13)
        Me.Label2.TabIndex = 14
        Me.Label2.Text = "DataFileNumber"
        '
        'Form1
        '
        Me.AutoScaleDimensions = New System.Drawing.SizeF(6.0!, 13.0!)
        Me.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font
        Me.ClientSize = New System.Drawing.Size(600, 366)
        Me.Controls.Add(Me.Label2)
        Me.Controls.Add(Me.NumericUpDown1)
        Me.Controls.Add(Me.TextBox1)
        Me.Controls.Add(Me.KeyControl)
        Me.Controls.Add(Me.Label1)
        Me.Controls.Add(Me.PBD)
        Me.Controls.Add(Me.Return_Button)
        Me.Controls.Add(Me.Exit_Button)
        Me.Controls.Add(Me.Robot_Switch)
        Me.Controls.Add(Me.Button2)
        Me.Controls.Add(Me.Button1)
        Me.Margin = New System.Windows.Forms.Padding(2)
        Me.Name = "Form1"
        Me.Text = "Form1"
        CType(Me.NumericUpDown1, System.ComponentModel.ISupportInitialize).EndInit()
        Me.ResumeLayout(False)
        Me.PerformLayout()

    End Sub
    Friend WithEvents Button1 As Button
    Friend WithEvents Button2 As Button
    Friend WithEvents Robot_Switch As Button
    Friend WithEvents Exit_Button As Button
    Friend WithEvents SerialPort1 As IO.Ports.SerialPort
    Friend WithEvents Return_Button As Button
    Friend WithEvents PBD As Button
    Friend WithEvents Label1 As Label
    Friend WithEvents KeyControl As RadioButton
    Friend WithEvents TextBox1 As TextBox
    Friend WithEvents NumericUpDown1 As NumericUpDown
    Friend WithEvents Label2 As Label
End Class
