/*

Plugin            : DumpHistory()
Purpose           : Export history to plain text file
Version           : 1.0
CL3 version       : 1.32
*/

DumpHistory() {
	global History

	DumpGui := Gui(, "Export CL3 Clipboard History")
	DumpGui.Opt("+AlwaysOnTop")
	DumpGui.Add("Checkbox", "vCBText checked", "Export Text")
	DumpGui.Add("Checkbox", "vCBProgram", "Export Source (program)")
	DumpGui.Add("Edit", "vDumpFileName w200", "history" A_Now ".txt")
	DumpGui.Add("Button", "Default", "Export").OnEvent("Click", DoDumpHistory)
	DumpGui.Show("Center")

	DoDumpHistory(*) {
		saved := DumpGui.Submit()
		DumpHistoryOutput := ""
		for k, v in History
			{
			 If saved.CBProgram
			 	DumpHistoryOutput .= v["icon"] "`n"
			 If saved.CBText
			 	DumpHistoryOutput .= v["text"] "`n`n-------------------------------------`n`n"
			}
		if FileExist(saved.DumpFileName)
			FileDelete(saved.DumpFileName)
		FileAppend(DumpHistoryOutput, saved.DumpFileName)
	}
}
