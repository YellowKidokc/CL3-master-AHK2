/*

Plugin            : Compact history
Purpose           : Parse history and remove entries over certain size
Version           : 1.1
CL3 version       : 1.6

History:
- v1.1 adding lines and crc to compacted history as well

*/

Compact(*) {
	global History

	CompactGui := Gui(, "CL3Compact")
	CompactGui.Add("Text", "x5 y8 w220 h15", "Compact should remove all entries over:")
	CompactGui.SetFont("cgray")
	CompactGui.Add("Text", "x5 yp+20 w100 h15", "StrLen (in K=1000)")
	CompactGui.SetFont()
	CompactGui.Add("ComboBox", "xp+110 yp-3 w100 R10 vChoice", ["5K","10K","20K","30K","40K","50K","60K","70K","80K","90K","100K"])
	CompactGui.Add("Text", "x5 yp+30 w220", "and/or Maximum entries in History:")
	CompactGui.SetFont("cgray")
	CompactGui.Add("Text", "x5 yp+20 w110", "Current entries: " History.Length)
	CompactGui.SetFont()
	CompactGui.Add("Edit", "x115 yp-3 w100 number vChoiceMax")
	CompactGui.Add("Button", "w100 x5 yp+30", "Cancel").OnEvent("Click", (*) => CompactGui.Destroy())
	okBtn := CompactGui.Add("Button", "w100 xp+110 yp Default", "OK")
	okBtn.OnEvent("Click", CompactChoice)
	CompactGui.Show("w220")
	return

	CompactChoice(*) {
		saved := CompactGui.Submit()
		ChoiceMax := saved.ChoiceMax
		Choice := saved.Choice

		if (ChoiceMax != "")
			{
			 newhistory := []
			 for k, v in History
				{
				 if (A_Index <= Integer(ChoiceMax))
					newhistory.push(Map("text", v["text"], "icon", v["icon"], "lines", v["lines"], "crc", v["crc"]))
				}
			 History := newhistory
			 newhistory := []
			}
		if (Choice != "")
			{
			 ChoiceVal := 1000 * Integer(RegExReplace(Choice, "\D"))
			 if IsNumber(ChoiceVal)
				{
				 newhistory := []
				 for k, v in History
					{
					 if (StrLen(v["text"]) < ChoiceVal)
						newhistory.push(Map("text", v["text"], "icon", v["icon"], "lines", v["lines"], "crc", v["crc"]))
					}
				 History := newhistory
				 newhistory := []
				}
			}
		TrayTip("History compacted", "CL3", 17)
	}
}
