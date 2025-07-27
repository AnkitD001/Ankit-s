Attribute VB_Name = "Module1"
Sub DataFormattingMacro()
Attribute DataFormattingMacro.VB_Description = "This Macro Formats your data beautifully"
Attribute DataFormattingMacro.VB_ProcData.VB_Invoke_Func = " \n14"
'
' DataFormattingMacro Macro
' This Macro Formats your data beautifully
'

'
    Range("A1").Select
    Selection.Style = "Title"
    Range("A3").Select
    Selection.Style = "Heading 3"
    Range("A4:F4").Select
    Selection.Style = "Accent1"
    Range("A5:F16").Select
    With Selection
        .HorizontalAlignment = xlCenter
        .VerticalAlignment = xlBottom
        .WrapText = False
        .Orientation = 0
        .AddIndent = False
        .IndentLevel = 0
        .ShrinkToFit = False
        .ReadingOrder = xlContext
        .MergeCells = False
    End With
    Range("A4:F16").Select
    Selection.Columns.AutoFit
    Range("D5:D16").Select
    Selection.NumberFormat = "$ #,##0.00"
    Range("F5:F16").Select
    Selection.NumberFormat = "$ #,##0.00"
End Sub
