/*

class CL3API

API Class for CL3 to access and modify Clipboard history from other scripts
using ObjRegisterActive() by Lexikos @ https://www.autohotkey.com/boards/viewtopic.php?t=6148

We use JSON Dump/Load to pass on strings from-to CL3 to client script.
Code by cocobelgica @ https://github.com/cocobelgica/AutoHotkey-JSON

Version           : 1.6
CL3 version       : 1.113

History:
- 1.6 True/False for CL3Api_Init() to determine success/check Cl3 is running
- 1.5 added SlotGet
- 1.4 added SlotPaste, ClearClipChain
- 1.3 added ToggleCheck for tray menu
- 1.2 backup data Slots, ClipChainData, History
- 1.1 added State to turn clipboard history on/off
- 1.0 initial version

*/

class CL3API {

	State(toggle) {
		toggleLower := StrLower(String(toggle))
		if (toggleLower = "on") || (toggleLower = "true") || (toggleLower = "1")
			{
			 OnClipboardChange(FuncOnClipboardChange, 1)
			 A_TrayMenu.ToggleCheck("&Pause clipboard history")
			 Try
				TraySetIcon("res\cl3.ico")
			}
		else if (toggleLower = "off") || (toggleLower = "false") || (toggleLower = "0")
			{
			 OnClipboardChange(FuncOnClipboardChange, 0)
			 A_TrayMenu.ToggleCheck("&Pause clipboard history")
			 Try
				TraySetIcon("res\cl3_clipboard_history_paused.ico")
			}
	}

	Upper(Data) {
		src := Data
		for k, v in Jxon_Load(&src)
			History[v]["text"] := StrUpper(History[v]["text"])
		return 1
	}

	Lower(Data) {
		src := Data
		for k, v in Jxon_Load(&src)
			History[v]["text"] := StrLower(History[v]["text"])
		return 1
	}

	Title(Data) {
		src := Data
		for k, v in Jxon_Load(&src)
			History[v]["text"] := StrTitle(History[v]["text"])
		return 1
	}

	Chain(Data) {
		global ClipChainData
		XMLSave("ClipChainData", "-" A_Now)
		ClipChainData := []
		src := Data
		for k, v in Jxon_Load(&src)
			ClipChainData.Push(v)
		ClipChainListviewPopulate()
		return 1
	}

	ChainInsertAt(Index, Data) {
		global ClipChainData
		XMLSave("ClipChainData", "-" A_Now)
		ClipChainData.InsertAt(Index, Data)
		ClipChainListviewPopulate()
		return 1
	}

	ChainRemove(Index) {
		global ClipChainData
		XMLSave("ClipChainData", "-" A_Now)
		ClipChainData.RemoveAt(Index)
		ClipChainListviewPopulate()
		return 1
	}

	ChainClear() {
		global ClipChainData
		XMLSave("ClipChainData", "-" A_Now)
		ClipChainData := []
		ClipChainListviewPopulate()
		return 1
	}

	Slot(SlotID, Data) {
		global Slots, SlotsGui
		if (SlotID = 10)
			SlotID := 0
		if (SlotID >= 0) && (SlotID <= 9)
			{
			 XMLSave("Slots", "-" A_Now)
			 Slots[SlotID + 1] := Data
			 XMLSave("Slots")
			 try SlotsGui["Slot" SlotID].Value := Data
			}
		return 1
	}

	SlotPaste(SlotID) {
		global Slots, History, stats
		if (SlotID = 10)
			SlotID := 0
		OnClipboardChange(FuncOnClipboardChange, 0)
		A_Clipboard := Slots[SlotID + 1]
		PasteIt()
		Sleep(100)
		A_Clipboard := History[1]["text"]
		OnClipboardChange(FuncOnClipboardChange, 1)
		stats["slots"]++
		return 1
	}

	SlotGet(SlotID) {
		global Slots
		if (SlotID = 10)
			SlotID := 0
		if (SlotID >= 0) && (SlotID <= 9)
			Return Slots[SlotID + 1]
		Return 0
	}

	Burst(Data, reverse := 0) {
		global History
		XMLSave("History", "-" A_Now)
		Loop Data.Length
			{
			 lineCount := 0
			 If !reverse
				{
				 StrReplace(Data[A_Index], "`n", "`n",, &lineCount)
				 History.InsertAt(1, Map("text", Data[A_Index], "IconExe", "", "lines", lineCount + 1, "time", A_Now))
				}
			 else
				{
				 StrReplace(Data[A_Index], "`n", "`n",, &lineCount)
				 History.InsertAt(1, Map("text", Data[Data.Length + 1 - A_Index], "IconExe", "", "lines", lineCount + 1, "time", A_Now))
				}
			}
		return 1
	}

	GetSetting(Data) {
		global SettingsObj
		return SettingsObj[Data]
	}

	Fifo(Data) {
		FifoApi(Data)
		FifoActiveMenu()
		return 1
	}

	Paste(Data, key := "") {
		global History
		src := Data
		for k, v in Jxon_Load(&src)
			{
			 A_Clipboard := History[v]["text"]
			 PasteIt()
			 Sleep(100)
			 if key
				Send(key)
			}
		return
	}

	Get(Data) {
		global History
		tmpoutput := []
		src := Data
		for k, v in Jxon_Load(&src)
			tmpoutput.Push(History[v]["text"])
		return Jxon_Dump(tmpoutput)
	}

	InsertAt(Idx, Data) {
		global History, History_Save
		lineCount := 0
		StrReplace(Data, "`n", "`n",, &lineCount)
		History.InsertAt(Idx, Map("text", Data, "IconExe", "", "lines", lineCount + 1, "time", A_Now))
		History_Save := 1
		return 1
	}

	Remove(Data) {
		global History, History_Save
		XMLSave("History", "-" A_Now)
		src := Data
		for k, v in Jxon_Load(&src)
			{
			 History.RemoveAt(k)
			 History_Save := 1
			}
		return 1
	}

	Search(GetText, results := "-1") {
		global History
		tmpoutput := []
		re := "iUms)" GetText
		if InStr(GetText, A_Space)
			re := "iUms)(?=.*" RegExReplace(GetText, "iUms)(.*)\s", "$1)(?=.*") ")"

		for k, v in History
			{
			 if RegExMatch(v["text"], re)
				tmpoutput.Push(History[k]["text"])
			 if (tmpoutput.Length = Integer(results))
				break
			}
		return Jxon_Dump(tmpoutput)
	}

	SearchIdx(GetText, results := "-1") {
		global History
		tmpoutput := []
		re := "iUms)" GetText
		if InStr(GetText, A_Space)
			re := "iUms)(?=.*" RegExReplace(GetText, "iUms)(.*)\s", "$1)(?=.*") ")"

		for k, v in History
			{
			 if RegExMatch(v["text"], re)
				tmpoutput.Push(k)
			 if (tmpoutput.Length = Integer(results))
				break
			}
		return Jxon_Dump(tmpoutput)
	}
}
