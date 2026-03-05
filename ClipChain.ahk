/*

Plugin            : ClipChain
Purpose           : Cycle through a predefined clipboard history on each paste
Version           : 1.11
CL3 version       : 1.5

History:
- 1.10-11 Added insert special items
- 1.9 Reset ClipChain index correctly to 1 after loading from Clipboard (in plugin and API)
- 1.8 Preview ToolTip on Mouse Hover
- 1.71 fix cancelled Load from Clipboard (Set Delim)
- 1.7 enter (multiple) delimiter(s) to split elements from clipboard;
      define send key(s) after paste (AutoHotkey notation) e.g. {tab};
      define Trim options
- 1.6 Attempt to prevent XMLRoot error - https://github.com/hi5/CL3/issues/15
- 1.5.1 Fix for hotkey, using much more reliable #If
- 1.5 Clipchain: you can now define a hotkey (via settings) to "progress to next item"
- 1.4 Added QEDL() for edit and insert (not public)
- 1.3 Added DoubleClick to paste and progress ClipChain
- 1.2 Fixed LV_Modify empty parameters because of AutoHotkey v1.1.23.03 update
- 1.1 Added minor fix for "non-empty" empty lines?

*/

ClipChainInit() {
	global
	local iniFile := ClipDataFolder "ClipChain\ClipChain.ini"

	ClipChainX          := IniRead(iniFile, "Settings", "ClipChainX", "100")
	ClipChainY          := IniRead(iniFile, "Settings", "ClipChainY", "100")
	ClipChainNoHistory  := IniRead(iniFile, "Settings", "ClipChainNoHistory", "0")
	ClipChainTrans      := IniRead(iniFile, "Settings", "ClipChainTrans", "0")
	ClipChainKey        := IniRead(iniFile, "Settings", "ClipChainKey", "ERROR")
	ClipChainSendAfter  := IniRead(iniFile, "Settings", "ClipChainSend", "ERROR")
	ClipChainPause      := IniRead(iniFile, "Settings", "ClipChainPause", "0")
	ClipChainTrim       := IniRead(iniFile, "Settings", "ClipChainTrim", "0")
	ClipChainTrimSet    := IniRead(iniFile, "Settings", "ClipChainTrimSet", "ERROR")
	ClipChainPreview    := IniRead(iniFile, "Settings", "ClipChainPreview", "1")

	If (ClipChainX = "") or (ClipChainX = "ERROR")
		ClipChainX := 100
	If (ClipChainY = "") or (ClipChainY = "ERROR")
		ClipChainY := 100
	If (ClipChainKey = "") or (ClipChainKey = "ERROR") or (ClipChainKey = 0)
		ClipChainKey := "[press to set]"
	If (ClipChainTrimSet = "") or (ClipChainTrimSet = "ERROR") or (ClipChainTrimSet = 0)
		ClipChainTrimSet := "[press to set]"
	else
		SetTrimChars()

	If !IsObject(ClipChainData)
		{
		 if FileExist(ClipDataFolder "ClipChain\ClipChain.xml")
			{
			 If (XA_Load(ClipDataFolder "ClipChain\ClipChain.xml") = 1)
				{
				 MsgBox("ClipChain.xml seems to be corrupt, starting new empty chain.", "ClipChain", 16)
				 FileDelete(ClipDataFolder "ClipChain\ClipChain.xml")
				 ClipChainData := []
				}
			}
		 else
			{
			 ClipChainData := []
			}
		}

	ClipChainIndex := 1
	LVM_SUBITEMHITTEST := 4096 + 57

	ClipChainInsSpecial := ""

	; Build insert menus
	InsertClipChainMenuSpecial := Menu()
	InsertClipChainMenuSpecial.Add("Clipboard", InsertClipChainMenuHandler)
	Loop 10
		InsertClipChainMenuSpecial.Add("Slot " A_Index, InsertClipChainMenuHandler)

	InsertClipChainMenu := Menu()
	InsertClipChainMenu.Add("Insert new entry", ClipChainInsertHandler)
	InsertClipChainMenu.Add("Insert special", InsertClipChainMenuSpecial)

	; Build ClipChain load/save menu
	ClipChainMenu := Menu()
	ClipChainMenu.Add("Load from Clipboard (Default)", ClipChainLoad)
	ClipChainMenu.Add("Load from Clipboard (Set Delim)", ClipChainLoadDelim)
	ClipChainMenu.Add()
	ClipChainMenu.Add("Load from File", ClipChainLoadFile)
	ClipChainMenu.Add("Save to File", ClipChainSaveFile)
	ClipChainMenu.Add()
	ClipChainMenu.Add("Clear ClipChain", ClipChainClear)

	; Build GUI
	ClipChainGui := Gui(, "CL3ClipChain")
	ClipChainGui.Opt("+Border +ToolWindow +AlwaysOnTop +E0x08000000")
	ClipChainGui.OnEvent("Close", ClipChainGuiCloseHandler)
	ClipChainGui.OnEvent("Escape", ClipChainGuiCloseHandler)
	ClipChainGui.SetFont(dpi("s8"))
	ogcLV := ClipChainGui.Add("ListView", dpi("x0 y0 w185 h350 NoSortHdr grid vLVCGIndex"), ["?", "ClipChain", "IDX"])
	ogcLV.OnEvent("Click", ClipChainClicked)
	HLV := ogcLV.Hwnd
	ogcLV.ModifyCol(1, dpi() * 25)
	ogcLV.ModifyCol(2, dpi() * 160)
	ogcLV.ModifyCol(3, 0)

	ClipChainListviewPopulate()

	ClipChainGui.SetFont(dpi("s8"))
	ClipChainGui.Add("GroupBox", dpi("x2 yp+355 w181 h50 vGbox1"), "Chain(s)")
	ClipChainGui.Add("Button", dpi("xp+8 yp+18 w26 h26"), Chr(0x25B2)).OnEvent("Click", ClipChainMoveUp)
	ClipChainGui.Add("Button", dpi("xp+28 yp w26 h26"), Chr(0x25BC)).OnEvent("Click", ClipChainMoveDown)
	ClipChainGui.Add("Button", dpi("xp+28 yp w26 h26"), "Ins").OnEvent("Click", (*) => InsertClipChainMenu.Show())
	ClipChainGui.SetFont(dpi("s11"))
	ClipChainGui.Add("Button", dpi("xp+28 yp w26 h26"), Chr(0x270E)).OnEvent("Click", ClipChainEditHandler)
	ClipChainGui.SetFont()
	ClipChainGui.SetFont(dpi("s12 bold"))
	ClipChainGui.Add("Button", dpi("xp+28 yp w26 h26"), "X").OnEvent("Click", ClipChainDel)
	ClipChainGui.SetFont()
	ClipChainGui.SetFont(dpi("s11"))
	ClipChainGui.Add("Button", dpi("xp+28 yp w26 h26"), Chr(0x1F4C2)).OnEvent("Click", (*) => ClipChainMenu.Show())
	ClipChainGui.SetFont()
	ClipChainGui.SetFont(dpi("s8"))
	ClipChainGui.Add("GroupBox", dpi("x2 yp+40 w181 h170 vGbox2"), "Options")
	ogcNoHistory := ClipChainGui.Add("Checkbox", dpi("xp+10 yp+18 w75 h24 vClipChainNoHistory"), "No History")
	ogcNoHistory.OnEvent("Click", ClipChainCheckboxHandler)
	ogcNoHistory.Value := ClipChainNoHistory
	ogcTrans := ClipChainGui.Add("Checkbox", dpi("xp+80 yp w85 h24 vClipChainTrans"), "Transparent")
	ogcTrans.OnEvent("Click", ClipChainCheckboxHandler)
	ogcTrans.Value := ClipChainTrans
	ogcSendAfter := ClipChainGui.Add("Checkbox", dpi("xp-80 yp+30 w75 h24 vClipChainSendAfter"), "Send after")
	ogcSendAfter.OnEvent("Click", ClipChainCheckboxHandler)
	ogcSendAfter.Value := ClipChainSendAfter != "ERROR" ? ClipChainSendAfter : 0
	ogcKeyBtn := ClipChainGui.Add("Button", dpi("xp+80 yp w85 h24 vClipChainKeyBtn"), ClipChainKey)
	ogcKeyBtn.OnEvent("Click", ClipChainKeyUpdate)
	ogcTrimCb := ClipChainGui.Add("Checkbox", dpi("xp-80 yp+30 w75 h24 vClipChainTrim"), "Trim")
	ogcTrimCb.OnEvent("Click", ClipChainCheckboxHandler)
	ogcTrimCb.Value := ClipChainTrim
	ogcTrimBtn := ClipChainGui.Add("Button", dpi("xp+80 yp w85 h24 vClipChainTrimBtn"), ClipChainTrimSet)
	ogcTrimBtn.OnEvent("Click", ClipChainTrimUpdate)
	ogcPause := ClipChainGui.Add("Checkbox", dpi("xp-80 yp+30 w75 h24 vClipChainPause"), "Pause")
	ogcPause.OnEvent("Click", ClipChainCheckboxHandler)
	ogcPause.Value := ClipChainPause
	ClipChainGui.Add("Button", dpi("xp+80 yp w85 h24"), "Close ClipChain").OnEvent("Click", ClipChainGuiCloseHandler)
	ogcPreview := ClipChainGui.Add("Checkbox", dpi("xp-80 yp+30 w150 h24 vClipChainPreview"), "Show preview TT on Hover")
	ogcPreview.OnEvent("Click", ClipChainCheckboxHandler)
	ogcPreview.Value := ClipChainPreview

	ClipChainCheckboxHandler()
	ClipChainLvHandle := LV_Rows(HLV)
}

SetTrimChars() {
	global ClipChainTrimSet, TrimSet
	TrimSet := ClipChainTrimSet
	TrimSet := StrReplace(TrimSet, "\n", "`n")
	TrimSet := StrReplace(TrimSet, "\r", "`r")
	TrimSet := StrReplace(TrimSet, "\t", "`t")
	TrimSet := StrReplace(TrimSet, "\s", " ")
}

ClipChainTrimUpdate(*) {
	global ClipChainTrimSet, ClipChainGui
	ib := InputBox("Set Trim characters Delimiter(s) (\n,\r,\t,\s)`nTrims Left and Right", "ClipChain Trim characters", "w300 h140", ClipChainTrimSet)
	If (ib.Result = "Cancel")
		Return
	ClipChainTrimSet := ib.Value
	If (ClipChainTrimSet = "")
		{
		 ClipChainTrimSet := "[press to set]"
		 ClipChainGui["ClipChainTrimBtn"].Text := ClipChainTrimSet
		 Return
		}
	ClipChainGui["ClipChainTrimBtn"].Text := ClipChainTrimSet
	SetTrimChars()
}

ClipChainKeyUpdate(*) {
	global ClipChainKey, ClipChainGui
	ib := InputBox("Send key(s) after paste (AutoHotkey notation)", "ClipChain Send after Paste", "w300 h130", ClipChainKey)
	If (ib.Result = "Cancel")
		Return
	ClipChainKey := ib.Value
	If (ClipChainKey = "")
		{
		 ClipChainKey := "[press to set]"
		 ClipChainGui["ClipChainKeyBtn"].Text := ClipChainKey
		 Return
		}
	ClipChainGui["ClipChainKeyBtn"].Text := ClipChainKey
}

ClipChainPasteDoubleClick(*) {
	global ClipChainData, ClipChainIndex, ClipChainNoHistory, ClipChainTrim, TrimSet
	global ClipChainSendAfter, ClipChainKey, ClipChainPause, History, stats, Slots, ClipChainGui, ogcLV

	saved := ClipChainGui.Submit(false)
	If saved.ClipChainPause
		Return
	If (ClipChainIndex > ClipChainData.Length)
		ClipChainIndex := 1

	If saved.ClipChainNoHistory
		OnClipboardChange(FuncOnClipboardChange, 0)

	If InStr(ClipChainData[ClipChainIndex], "{CL3.ClipChain=")
		{
		 If (ClipChainData[ClipChainIndex] = "{CL3.ClipChain=Clipboard}")
			A_Clipboard := A_Clipboard
		 else
			{
			 SlotIDChainInsert := SubStr(ClipChainData[ClipChainIndex], 20, 1)
			 A_Clipboard := Slots.Length >= Integer(SlotIDChainInsert) ? Slots[Integer(SlotIDChainInsert) + 1] : ""
			}
		}
	else
		A_Clipboard := ClipChainData[ClipChainIndex]

	If saved.ClipChainTrim
		A_Clipboard := Trim(A_Clipboard, TrimSet)

	PasteIt()
	Sleep(100)
	A_Clipboard := History[1]["text"]
	If saved.ClipChainNoHistory
		OnClipboardChange(FuncOnClipboardChange, 1)
	stats["clipchain"]++
	ClipChainIndex++
	If saved.ClipChainSendAfter and (ClipChainKey != "[press to set]")
		Send(ClipChainKey)
	ClipChainUpdateIndicator()
}

hk_clipchain_handler(*) {
	global ClipChainGui, ClipChainX, ClipChainY, Mouse_Hwnd
	If !WinExist("CL3ClipChain ahk_class AutoHotkeyGUI")
		{
		 OnMessage(0x200, WM_MOUSEMOVE)
		 ClipChainGui.Show(dpi("w185 NA x") ClipChainX " y" ClipChainY)
		}
	else
		{
		 ClipChainSaveWindowPosition()
		 ClipChainGui.Hide()
		}
	ClipChainCheckboxHandler()
}

hk_clipchainpaste_defaultpaste(*) {
	; Default paste when clipchain is not active
	Send("^v")
}

ClipChainCheckboxHandler(*) {
	global ClipChainGui, ClipChainTrans
	try {
		saved := ClipChainGui.Submit(false)
		ClipChainTrans := saved.ClipChainTrans
		If ClipChainTrans
			WinSetTransparent(200, "CL3ClipChain ahk_class AutoHotkeyGUI")
		else
			WinSetTransparent(255, "CL3ClipChain ahk_class AutoHotkeyGUI")
	}
}

ClipChainClicked(ctrl, info) {
	global ClipChainIndex, ogcLV
	ClipChainIndex := info
	ClipChainUpdateIndicator()
}

ClipChainListviewPopulate() {
	global ClipChainData, ClipChainIndex, ogcLV
	ClipChainIndex := 1
	ogcLV.Delete()
	for k, v in ClipChainData
		ogcLV.Add("", "", ClipChainHelper(v), A_Index)
	ogcLV.Modify(1, "Col1", "||")
	XMLSave("ClipChainData")
}

ClipChainHelper(in) {
	in := StrReplace(in, "`r`n", "\n")
	in := StrReplace(in, "`n", "\n")
	in := StrReplace(in, "`r", "\n")
	return in
}

ClipChainUpdateIndicator() {
	global ClipChainData, ClipChainIndex, ogcLV
	Loop ClipChainData.Length
		ogcLV.Modify(A_Index, "Col1", " ")

	If (ClipChainIndex > ClipChainData.Length) or (ClipChainIndex <= 1)
		{
		 if (ClipChainData.Length > 0) {
			ogcLV.Modify(1, "Col1", "||")
			ogcLV.Modify(1, "Vis")
		 }
		 return
		}

	ogcLV.Modify(ClipChainIndex, "Col1", ">>")
	ogcLV.Modify(ClipChainIndex, "Vis")
}

ClipChainSet() {
	global ClipChainData, ogcLV
	ClipChainNewOrder := ""
	ClipChainDataNew := []
	Loop ogcLV.GetCount()
		{
		 ClipChainDataIndex := ogcLV.GetText(A_Index, 3)
		 ClipChainNewOrder .= ClipChainDataIndex ","
		}
	ClipChainNewOrder := RTrim(ClipChainNewOrder, ",")
	Loop Parse, ClipChainNewOrder, ","
		ClipChainDataNew.Push(ClipChainData[Integer(A_LoopField)])
	ClipChainData := ClipChainDataNew

	; Update IDX column
	Loop ogcLV.GetCount()
		ogcLV.Modify(A_Index, "Col3", A_Index)
	ClipChainUpdateIndicator()
}

ClipChainEditHandler(*) {
	global ClipChainData, ClipChainGui, ogcLV, ClipChainPause
	ClipChainInsEdit := 1
	ClipChainPauseStore := ClipChainGui.Submit(false).ClipChainPause
	ClipChainPause := 1
	ClipChainGui["ClipChainPause"].Value := 1

	LVCGIndex := ogcLV.GetNext()
	If (LVCGIndex = 0)
		LVCGIndex := 1
	ClipChainDataIndex := ogcLV.GetText(LVCGIndex, 3)
	If (ClipChainDataIndex = "")
		ClipChainDataIndex := 1

	editText := ClipChainData[Integer(ClipChainDataIndex)]
	ClipChainInsertGuiShow("CL3ClipChain Edit text", editText, ClipChainDataIndex, true)
}

ClipChainInsertHandler(*) {
	global ClipChainData, ClipChainGui, ogcLV, ClipChainPause, ClipChainInsSpecial
	ClipChainPauseStore := ClipChainGui.Submit(false).ClipChainPause
	ClipChainPause := 1
	ClipChainGui["ClipChainPause"].Value := 1

	LVCGIndex := ogcLV.GetNext()
	If (LVCGIndex = 0)
		LVCGIndex := 1
	ClipChainDataIndex := ogcLV.GetText(LVCGIndex, 3)
	If (ClipChainDataIndex = "")
		ClipChainDataIndex := 1

	insertText := ClipChainInsSpecial ? ClipChainInsSpecial : ""
	ClipChainInsSpecial := ""

	if (insertText = "")
		ClipChainInsertGuiShow("CL3ClipChain Insert text", "", ClipChainDataIndex, false)
	else {
		; Direct insert for special items
		ClipChainData.InsertAt(Integer(ClipChainDataIndex) + 1, insertText)
		ogcLV.Insert(Integer(ClipChainDataIndex) + 1, "", "", ClipChainHelper(insertText))
		; Update IDX
		Loop ogcLV.GetCount()
			ogcLV.Modify(A_Index, "Col3", A_Index)
		ClipChainPause := ClipChainPauseStore
		ClipChainGui["ClipChainPause"].Value := ClipChainPause
		ClipChainSet()
		XMLSave("ClipChainData")
	}
}

ClipChainInsertGuiShow(title, text, dataIndex, isEdit) {
	global ClipChainData, ClipChainGui, ogcLV, ClipChainPause

	InsGui := Gui(, title)
	InsGui.Add("Text", "x5 y5", "Insert text into chain after " dataIndex " item:")
	InsGui.Add("Edit", "xp yp+20 w500 h300 vClipChainIns", text)
	InsGui.Add("Button", "w100", "OK").OnEvent("Click", InsOK)
	InsGui.Add("Button", "xp+120 w100", "Cancel").OnEvent("Click", InsCancel)
	InsGui.Show()
	return

	InsOK(*) {
		saved := InsGui.Submit()
		if (saved.ClipChainIns = "") {
			ClipChainPause := 0
			ClipChainGui["ClipChainPause"].Value := 0
			return
		}
		if isEdit {
			ClipChainData[Integer(dataIndex)] := saved.ClipChainIns
			ogcLV.Modify(Integer(dataIndex), "Col2", ClipChainHelper(saved.ClipChainIns))
		} else {
			ClipChainData.InsertAt(Integer(dataIndex) + 1, saved.ClipChainIns)
			ogcLV.Insert(Integer(dataIndex) + 1, "", "", ClipChainHelper(saved.ClipChainIns))
		}
		; Update IDX
		Loop ogcLV.GetCount()
			ogcLV.Modify(A_Index, "Col3", A_Index)
		ClipChainPause := 0
		ClipChainGui["ClipChainPause"].Value := 0
		ClipChainSet()
		XMLSave("ClipChainData")
	}

	InsCancel(*) {
		InsGui.Destroy()
		ClipChainPause := 0
		ClipChainGui["ClipChainPause"].Value := 0
	}
}

ClipChainDel(*) {
	global ClipChainData, ClipChainGui, ogcLV
	XMLSave("ClipChainData", "-" A_Now)
	LVCGIndex := ogcLV.GetNext()
	If (LVCGIndex = 0)
		LVCGIndex := 1
	ClipChainDataIndex := Integer(ogcLV.GetText(LVCGIndex, 3))
	ogcLV.Delete(LVCGIndex)
	If (ClipChainData.Length != 0)
		ClipChainData.RemoveAt(ClipChainDataIndex)
	; Update IDX
	Loop ogcLV.GetCount()
		ogcLV.Modify(A_Index, "Col3", A_Index)
	ClipChainSet()
	XMLSave("ClipChainData")
}

ClipChainMoveUp(*) {
	global ClipChainLvHandle
	ClipChainLvHandle.Move(1)
	ClipChainSet()
}

ClipChainMoveDown(*) {
	global ClipChainLvHandle
	ClipChainLvHandle.Move()
	ClipChainSet()
}

ClipChainGuiCloseHandler(*) {
	global ClipChainGui, ClipChainData, ClipDataFolder
	ClipChainSaveWindowPosition()
	ClipChainSet()
	ClipChainGui.Hide()
	XA_Save("ClipChainData", ClipDataFolder "ClipChain\ClipChain.xml")
}

ClipChainSaveWindowPosition() {
	global ClipChainX, ClipChainY, ClipChainNoHistory, ClipChainTrans
	global ClipChainKey, ClipChainSendAfter, ClipChainPause, ClipChainPreview
	global ClipChainTrim, ClipChainTrimSet, ClipDataFolder, ClipChainGui

	try {
		WinGetPos(&ClipChainX, &ClipChainY,,, "CL3ClipChain ahk_class AutoHotkeyGUI")
	}
	saved := ClipChainGui.Submit(false)
	local iniFile := ClipDataFolder "ClipChain\ClipChain.ini"
	IniWrite(ClipChainX, iniFile, "Settings", "ClipChainX")
	IniWrite(ClipChainY, iniFile, "Settings", "ClipChainY")
	IniWrite(saved.ClipChainNoHistory, iniFile, "Settings", "ClipChainNoHistory")
	IniWrite(saved.ClipChainTrans, iniFile, "Settings", "ClipChainTrans")
	keyVal := (ClipChainKey = "[press to set]") ? "" : ClipChainKey
	IniWrite(keyVal, iniFile, "Settings", "ClipChainKey")
	IniWrite(saved.ClipChainSendAfter, iniFile, "Settings", "ClipChainSend")
	IniWrite(saved.ClipChainPause, iniFile, "Settings", "ClipChainPause")
	IniWrite(saved.ClipChainPreview, iniFile, "Settings", "ClipChainPreview")
	IniWrite(saved.ClipChainTrim, iniFile, "Settings", "ClipChainTrim")
	trimVal := (ClipChainTrimSet = "[press to set]") ? "" : ClipChainTrimSet
	IniWrite(trimVal, iniFile, "Settings", "ClipChainTrimSet")
}

ClipChainLoad(*) {
	global ClipChainData, ClipChainIndex, ogcLV
	XMLSave("ClipChainData", "-" A_Now)
	ClipChainIndex := 1
	ClipChainData := RegExReplace(A_Clipboard, "m)^\s+$")
	If (Asc(SubStr(ClipChainData, 1, 1)) = 65279)
		ClipChainData := SubStr(ClipChainData, 2)
	CCDelim := "`r`n`r`n"
	ClipChainData := StrReplace(ClipChainData, CCDelim, Chr(7))
	ClipChainData := StrSplit(ClipChainData, Chr(7))
	ClipChainListviewPopulate()
}

ClipChainLoadDelim(*) {
	global ClipChainData, ClipChainIndex, ogcLV
	ib := InputBox("Set Delimiter(s) CSV (\n,\r,\t,\s,\c)`nUse \c for comma", "ClipChain Delimiter", "w300 h140", "\n")
	If (ib.Result = "Cancel") or (ib.Value = "")
		Return

	CCDelim := ib.Value
	CCDelim := StrReplace(CCDelim, "\n", "`n")
	CCDelim := StrReplace(CCDelim, "\r", "`r")
	CCDelim := StrReplace(CCDelim, "\t", "`t")
	CCDelim := StrReplace(CCDelim, "\s", " ")

	XMLSave("ClipChainData", "-" A_Now)
	ClipChainIndex := 1
	ClipChainData := RegExReplace(A_Clipboard, "m)^\s+$")
	If (Asc(SubStr(ClipChainData, 1, 1)) = 65279)
		ClipChainData := SubStr(ClipChainData, 2)

	Loop Parse, CCDelim, ","
		{
		 If (A_LoopField = "\c")
			{
			 ClipChainData := StrReplace(ClipChainData, ",", Chr(7))
			 continue
			}
		 ClipChainData := StrReplace(ClipChainData, A_LoopField, Chr(7))
		}
	ClipChainData := StrSplit(ClipChainData, Chr(7))
	ClipChainListviewPopulate()
}

ClipChainSaveFile(*) {
	global ClipChainGui, ClipDataFolder
	ClipChainGui.Hide()
	ib := InputBox("Save Clipchain as", "Name for XML")
	SaveAsName := ib.Value
	If (SaveAsName = "") || (ib.Result = "Cancel")
		{
		 MsgBox("Enter filename!`nChain not saved.")
		 ClipChainGui.Show()
		 Return
		}
	SaveAsName := StrReplace(SaveAsName, ".xml", "")
	XA_Save("ClipChainData", ClipDataFolder "ClipChain\" SaveAsName ".xml")
}

ClipChainClear(*) {
	global ogcLV, ClipChainData
	ogcLV.Delete()
	ClipChainData := []
}

ClipChainLoadFile(*) {
	global ClipDataFolder
	FileMenu := Menu()
	FileMenu.Add("ClipChain.xml", MenuHandlerClipChainLoadFile)
	FileMenu.Add()
	Loop Files, ClipDataFolder "ClipChain\*.xml"
		{
		 If (A_LoopFileName = "ClipChain.xml")
			Continue
		 FileMenu.Add(A_LoopFileName, MenuHandlerClipChainLoadFile)
		}
	FileMenu.Show()
}

MenuHandlerClipChainLoadFile(ItemName, *) {
	global ClipChainData, ClipDataFolder, ogcLV
	If (XA_Load(ClipDataFolder "ClipChain\" ItemName) = 1)
		{
		 MsgBox(ItemName " seems to be corrupt, starting new empty ClipChain.", "ClipChain", 16)
		 FileDelete(ClipDataFolder "ClipChain\" ItemName)
		 ClipChainData := []
		}
	ogcLV.Delete()
	ClipChainListviewPopulate()
}

InsertClipChainMenuHandler(ItemName, *) {
	global ClipChainInsSpecial
	If (ItemName = "Clipboard")
		ClipChainInsSpecial := "{CL3.ClipChain=Clipboard}"
	Else
		ClipChainInsSpecial := "{CL3.ClipChain=Slot" SubStr(ItemName, -1) "}"
	ClipChainInsertHandler()
}

ClipChainActive() {
	global ClipChainPause
	If (WinExist("CL3ClipChain ahk_class AutoHotkeyGUI") and (ClipChainPause != 1))
		Return true
	Else
		Return false
}

; Tooltip on hover
DisplayToolTip(text, Columns := 50) {
	DispText := RegExReplace(text, "(.{1," . Columns . "})", "$1`n")
	ToolTip(DispText)
}

WM_MOUSEMOVE(wparam, lparam, msg, hwnd) {
	global Mouse_X, Mouse_Y, Mouse_Hwnd, HLV, ClipChainPreview, LVM_SUBITEMHITTEST, ogcLV
	Mouse_X := lparam & 0xFFFF
	Mouse_Y := lparam >> 16
	Mouse_Hwnd := hwnd

	If !ClipChainPreview
		Return
	If (Mouse_Hwnd = HLV)
		{
		 LVHITTESTINFO := Buffer(24, 0)
		 NumPut("Int", Mouse_X, LVHITTESTINFO, 0)
		 NumPut("Int", Mouse_Y, LVHITTESTINFO, 4)
		 SendMessage(LVM_SUBITEMHITTEST, 0, LVHITTESTINFO.Ptr,, "ahk_id " HLV)
		 LVHT_Row := 1 + NumGet(LVHITTESTINFO, 12, "Int")
		 if (LVHT_Row > 0) && (LVHT_Row <= ogcLV.GetCount()) {
			Cx := ogcLV.GetText(LVHT_Row, 2)
			text := StrReplace(Cx, "\n", "`n")
			if (text = "ClipChain")
				{
				 ToolTip()
				 Return
				}
			DisplayToolTip(text)
			SetTimer((*) => ToolTip(), -3000)
		 }
		 Return
		}
	ToolTip()
}

#include %A_ScriptDir%\lib\class_lv_rows.ahk
