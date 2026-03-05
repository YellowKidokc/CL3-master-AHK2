/*

Plugin            : Slots
Purpose           : Load & Save 10 quick paste texts
Version           : 1.5

10 Slots
Hotkeys: RCTRL-[1-0]

History:
- 1.5 Adding QuickSlotsMenu, SlotsNamed
- 1.4 Attempt to prevent XMLRoot error - https://github.com/hi5/CL3/issues/15
- 1.3 Restore current clipboard from History
- 1.2 Added hotkey for QEDL() Ctrl+E (not public)
- 1.1 Bug fix for not correctly updating control (Edit0 vs Slot0) and moved XML to ClipData, improved first time init
- 1.0 first version

*/

SlotsInit() {
	global Slots, SlotsNamed, ClipDataFolder, SlotsGui

	If !IsObject(Slots)
		{
		 if FileExist(ClipDataFolder "Slots\Slots.xml")
			{
			 If (XA_Load(ClipDataFolder "Slots\Slots.xml") = 1)
				{
				 MsgBox("Slots.xml seems to be corrupt, starting a new Slots.xml", "Slots", 16)
				 FileDelete(ClipDataFolder "Slots\Slots.xml")
				 Slots := []
				}
			}
		 else
			{
			 Slots := []
			 Loop 10
				Slots.Push("Slot" (A_Index - 1) "a")
			}
		}

	If !IsObject(SlotsNamed)
		if FileExist(ClipDataFolder "Slots\SlotsNamed.xml")
			XA_Load(ClipDataFolder "Slots\SlotsNamed.xml")

	x := 10
	y := 10
	Index := 0

	SlotsGui := Gui(, "CL3Slots")
	SlotsGui.OnEvent("Close", (*) => SlotsGui.Hide())
	SlotsGui.OnEvent("Escape", (*) => SlotsGui.Hide())
	SlotsGui.SetFont(dpi("s8"))
	Loop 10
		{
		 Index++
		 If (Index = 10)
			Index := 0
		 slotVal := (Slots.Length > Index) ? Slots[Index + 1] : ""
		 SlotsGui.Add("Text", dpi("x" x " y" y), "Slot #" Index " [RCtrl + " Index "]")
		 SlotsGui.Add("Edit", dpi("w290 h60 vSlot" Index), slotVal)
		 y += 80
		 if (A_Index = 5)
			y := 10
		 if (A_Index = 5)
			x := 310
		}
	SlotsGui.Add("Button", dpi("x10"), "&Save Slots (slots.xml)").OnEvent("Click", SlotsSave)
	SlotsGui.Add("Button", dpi("xp130"), "Save &As (name.xml)").OnEvent("Click", SlotsSaveAs)
	SlotsGui.Add("Button", dpi("xp130"), "&Load (name.xml)").OnEvent("Click", LoadSlots)
	SlotsGui.Add("Button", dpi("xp253"), "&Close window").OnEvent("Click", (*) => SlotsGui.Hide())
}

hk_slots_handler(*) {
	global SlotsGui
	If !WinExist("CL3Slots ahk_class AutoHotkeyGUI")
		SlotsGui.Show()
	else
		SlotsGui.Hide()
}

hk_slotpaste(thisHotkey := "") {
	global Slots, SlotKey, History, stats
	OnClipboardChange(FuncOnClipboardChange, 0)
	If (SlotKey = "")
		SlotKey := SubStr(thisHotkey, -1)
	slotIdx := Integer(SlotKey)
	A_Clipboard := (Slots.Length > slotIdx) ? Slots[slotIdx + 1] : ""
	PasteIt()
	Sleep(100)
	A_Clipboard := History[1]["text"]
	OnClipboardChange(FuncOnClipboardChange, 1)
	stats["slots"]++
	SlotKey := ""
}

hk_slotpastenamed(*) {
	global SlotsNamed, SlotKey, History, stats
	OnClipboardChange(FuncOnClipboardChange, 0)
	A_Clipboard := SlotsNamed.Has(SlotKey) ? SlotsNamed[SlotKey] : ""
	PasteIt()
	Sleep(100)
	A_Clipboard := History[1]["text"]
	OnClipboardChange(FuncOnClipboardChange, 1)
	stats["slots"]++
	SlotKey := ""
}

SlotsSave(*) {
	global Slots, SlotsGui, ClipDataFolder
	saved := SlotsGui.Submit(false)
	SlotsGui.Hide()
	XMLSave("Slots", "-" A_Now)
	Loop 10
		{
		 idx := A_Index - 1
		 if (idx = 0) && saved.HasProp("Slot0")
			Slots[1] := saved.Slot0
		 else
			Slots[idx + 1] := saved.%"Slot" idx%
		}
	XMLSave("Slots")
}

SlotsSaveAs(*) {
	global Slots, SlotsGui, ClipDataFolder
	saved := SlotsGui.Submit(false)
	SlotsGui.Hide()
	ib := InputBox("Save slots as", "Name for XML")
	SaveAsName := ib.Value
	If (SaveAsName = "") || (ib.Result = "Cancel")
		{
		 MsgBox("Enter filename!`nSlots not saved.")
		 SlotsGui.Show()
		 Return
		}
	XMLSave("Slots", "-" A_Now)
	Loop 10
		{
		 idx := A_Index - 1
		 Slots[idx + 1] := saved.%"Slot" idx%
		}
	SaveAsName := StrReplace(SaveAsName, ".xml", "")
	XA_Save("Slots", ClipDataFolder "Slots\" SaveAsName ".xml")
}

LoadSlots(*) {
	global ClipDataFolder
	SlotsLoadMenu := Menu()
	SlotsLoadMenu.Add("Slots.xml", MenuHandlerSlots)
	SlotsLoadMenu.Add()
	Loop Files, ClipDataFolder "Slots\*.xml"
		{
		 If (A_LoopFileName = "slots.xml")
			Continue
		 SlotsLoadMenu.Add(A_LoopFileName, MenuHandlerSlots)
		}
	SlotsLoadMenu.Show()
}

MenuHandlerSlots(ItemName, *) {
	global Slots, SlotsGui, ClipDataFolder
	XMLSave("Slots", "-" A_Now)
	Slots := []
	If (XA_Load(ClipDataFolder "Slots\" ItemName) = 1)
		{
		 MsgBox(ItemName " seems to be corrupt, starting a new Slots file", "Slots", 16)
		 FileDelete(ClipDataFolder "Slots\" ItemName)
		 Slots := []
		 Loop 10
			Slots.Push("Slot" (A_Index - 1) "a")
		}
	Loop 10
		{
		 idx := A_Index - 1
		 slotVal := (Slots.Length > idx) ? Slots[idx + 1] : ""
		 SlotsGui["Slot" idx].Value := slotVal
		}
}

BuildQuickSlotsMenu() {
	global Slots, SlotsNamed, QuickSlotsMenu, SlotKey
	QuickSlotsMenu := Menu()
	Loop 9
		QuickSlotsMenu.Add("&" A_Index ". " DispMenuText(SubStr(Slots.Length >= A_Index ? Slots[A_Index + 1] : "", 1, 500), -1), QuickSlotsMenuHandler)
	QuickSlotsMenu.Add("&0. " DispMenuText(SubStr(Slots.Length >= 1 ? Slots[1] : "", 1, 500), -1), QuickSlotsMenuHandler)
	QuickSlotsMenu.Add()
	QuickSlotsMenu.Add("&Show Slots", QuickSlotsMenuHandler)
	If IsObject(SlotsNamed) && (SlotsNamed is Map) && SlotsNamed.Count > 0
		{
		 QuickSlotsMenu.Add()
		 for k, v in SlotsNamed
			QuickSlotsMenu.Add("&" k ": " DispMenuText(SubStr(v, 1, 500), -1), QuickSlotsMenuHandler)
		 QuickSlotsMenu.Add("&x Remove Named Slot", QuickSlotsMenuHandler)
		}
}

QuickSlotsMenuHandler(ItemName, ItemPos, *) {
	global SlotKey, SlotsNamed, ClipDataFolder
	If (ItemName = "&x Remove Named Slot")
		{
		 DeleteEntry := ""
		 for k, v in SlotsNamed
			DeleteEntry .= k ","
		 ib := InputBox("Enter name of slot(s) to delete (exact and csv)", "Delete Named Slot", "w500 h170", DeleteEntry)
		 If (ib.Result = "Cancel")
			return
		 Loop Parse, ib.Value, ","
			SlotsNamed.Delete(A_LoopField)
		 XA_Save("SlotsNamed", ClipDataFolder "Slots\SlotsNamed.xml")
		 BuildQuickSlotsMenu()
		}
	else If (ItemName = "&Show Slots")
		hk_slots_handler()
	else
		{
		 SlotKey := ItemPos
		 If (SlotKey = 10)
			SlotKey := 0
		 if (SlotKey < 10)
			hk_slotpaste()
		 SlotKey := LTrim(StrSplit(ItemName, ":")[1], "&")
		 hk_slotpastenamed()
		 SlotKey := ""
		}
}

ShowMenu(menuName, *) {
	global
	if (menuName = "QuickSlotsMenu") {
		BuildQuickSlotsMenu()
		QuickSlotsMenu.Show()
	}
}

; not public
;@Ahk2Exe-IgnoreBegin
#include *i %A_ScriptDir%\plugins\MyQEDLG-Slots.ahk
;@Ahk2Exe-IgnoreEnd
