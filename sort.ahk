/*

Plugin            : Sort()
Purpose           : Sort current clipboard
Version           : 1.0
CL3 version       : 1.9.4

History:
- 1.0 initial version

*/

SortText(Text, options := "") {
	 text := Sort(text, options)
	 return text
	}

SortMenuSetup() {
	global SortMenu, SortHelpText, SortMenuObj
	SortMenu := Map(
		"a", "Standard (new line)|",
		"b", "R - Reverse (new line)|R",
		"c", "N - Numerical (new line)|N",
		"d", "NR - Numerical, reverse (new line)|NR",
		"e", "U - Unique, remove duplicates (new line)|U",
		"f", "Set Delimeter and other options|"
	)

	SortHelpText := "C: Case sensitive`tCL: Case insensitive`tDx: delimiter character`n"
		. "N: Numeric sort`tPn: Character position n`tR: Reverse order`n"
		. "Random: random `tU: Unique`t`t\: Substring last backslash"

	SortMenuObj := Menu()
	For k, v in SortMenu
		SortMenuObj.Add("&" k ". " StrSplit(v, "|")[1], SortMenuHandler)
}

SortMenuHandler(ItemName, ItemPos, MyMenu) {
	global SortMenu, SortHelpText, History, ClipText
	for k, v in SortMenu
		If (ItemName = "&" k ". " StrSplit(v, "|")[1])
			If !InStr(v, "Set Delimiter and other options")
				ClipText := SortText(History[1]["text"], StrSplit(v, "|")[2])
			else
				{
				 ib := InputBox("Enter sort options:`n" SortHelpText, "Sort options", "w500 h170")
				 if (ib.Result = "Cancel")
					Return
				 ClipText := SortText(History[1]["text"], ib.Value)
				}
	ClipboardHandler()
}
