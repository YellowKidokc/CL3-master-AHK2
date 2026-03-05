/*

Plugin            : Search history
Version           : 1.5

Searchable listbox
Combined with Endless scrolling in a listbox http://www.autohotkey.com/forum/topic31618.html

History:
- 1.5 Fix for first time {down} which jumped to second item (see comment in Down::)
- 1.4 Merge items using F5
- 1.3 Replaced rudimentary editor with QEDlg()
      QEDlg() - pop-up editor by jballi, source via PM at autohotkey.com Feb 28th 2017
      Edit Library by jballi, source: https://autohotkey.com/boards/viewtopic.php?f=6&t=5063
      Add-On Functions (included in Edit library package)
      [QEDlg() not included in public release as code is not (yet) published]
- 1.2 Added option to Edit entry and update history (shortcut: f4)
- 1.1 Added option to yank (delete) entry directly from the listbox using ctrl-del (highlight item first)

*/

hk_search_handler(*) {
	global
	local add, time, linetext, disptime, StartList, GUITitle, ChooseID

	If WinExist("CL3Search ahk_class AutoHotkeyGUI")
		{
		 SearchGui.Destroy()
		 Return
		}

	GUITitle := "CL3Search"

	StartList := []
	for k, v in History
		{
		 add := v["text"]
		 time := v.Has("time") ? v["time"] : ""
		 if ShowLines
			linetext := " - " v["lines"]
		 else
			linetext := ""

		 disptime := ""
		 add := StrReplace(add, "|", "")
		 add := StrReplace(add, "`n", A_Space)
		 If ShowTime
		 	If TimeFormat and time
				{
				 disptime := LTrim(TimeFormatIndicator) FormatTime(time, TimeFormatTime) " "
				}
		 StartList.Push(disptime "[" SubStr("00" A_Index, -2) linetext "] " add)
		}

	SearchGui := Gui(, GUITitle)
	SearchGui.OnEvent("Close", SearchGuiCloseHandler)
	SearchGui.OnEvent("Escape", SearchGuiCloseHandler)
	SearchGui.SetFont(dpi("s8"))
	SearchGui.Add("Text", dpi("x5 y8 w45 h15"), "&Filter:")
	ogcGetText := SearchGui.Add("Edit", dpi("vGetText x50 y5 w300 h20 +Left"))
	ogcGetText.OnEvent("Change", GetText)
	SearchGui.Add("Text", dpi("x355 y8"), "[ctrl+del] = yank (Remove) entry. [F4] = edit entry.")
	ChooseID := ChooseID ?? ""
	ogcListBox := SearchGui.Add("ListBox", dpi("multi x5 y30 w" SearchWindowWidth-10 " h" SearchWindowHeight-30 " vChoice" (ChooseID ? " Choose" ChooseID : "")), StartList)
	SearchGui.Add("Button", dpi("default hidden"), "OK").OnEvent("Click", SearchChoice)
	SearchGui.Show(dpi("h" SearchWindowHeight " w" SearchWindowWidth))
	return

	GetText(ctrl, *) {
		searchText := ctrl.Value
		re := "iUms)" searchText
		if InStr(searchText, A_Space)
			re := "iUms)(?=.*" RegExReplace(searchText, "iUms)(.*)\s", "$1)(?=.*") ")"
		UpdatedList := []
		for idx, item in StartList {
			parts := StrSplit(item, "]",, 2)
			if (parts.Length >= 2) && RegExMatch(parts[2], re)
				UpdatedList.Push(item)
		}
		ogcListBox.Delete()
		ogcListBox.Add(UpdatedList)
	}

	SearchChoice(*) {
		SearchGetIDResult := SearchGetID()
		SearchGui.Submit()
		SearchGui.Destroy()
		Sleep(100)
		ClipboardHandler()
		stats["search"]++
	}

	SearchGetID() {
		local Choice, id
		saved := SearchGui.Submit(false)
		Choice := saved.Choice
		if (Choice = "")
			{
			 Choice := ogcListBox.Text
			}
		if RegExMatch(Choice, "\[0*(\d+)", &idMatch)
			id := idMatch[1]
		else
			id := 1
		ClipText := History[Integer(id)]["text"]
		return id
	}

	SearchGuiCloseHandler(*) {
		SetTimer(UpdateEditSB1, 0)
		SearchGui.Destroy()
	}
}

SearchEditEntry(id) {
	global History, SearchWindowWidth, SearchWindowHeight, ClipText, stats

	ClipText := History[id]["text"]
	SearchEditGui := Gui(, "CL3 Edit Entry ID: [ " id " ]")
	SearchEditGui.SetFont(dpi("s8"))
	SearchEditGui.Add("Text", dpi("x5 y8 w100 h15"), "Edit this entry:")
	SearchEditGui.SetFont(, "Courier")
	ogcEditCtrl := SearchEditGui.Add("Edit", dpi("vClipText x5 y25 w" SearchWindowWidth-10 " h" SearchWindowHeight-80), ClipText)
	SearchEditGui.Add("Button", dpi("w100"), "OK").OnEvent("Click", SearchEditOK)
	SearchEditGui.Add("Button", dpi("xp+110 yp w100"), "Cancel").OnEvent("Click", SearchEditCancel)
	SearchEditGui.Add("StatusBar",, "...")
	SearchEditGui.GetClientPos(,,, &sbW)
	SB := SearchEditGui.Add("StatusBar")
	SearchEditGui.Show(dpi("w" SearchWindowWidth " h" SearchWindowHeight))
	SetTimer(UpdateEditSB1, 100)
	return

	SearchEditOK(*) {
		saved := SearchEditGui.Submit()
		History[id]["text"] := saved.ClipText
		OnClipboardChange(FuncOnClipboardChange, 0)
		If (id = 1)
			A_Clipboard := saved.ClipText
		OnClipboardChange(FuncOnClipboardChange, 1)
		lineCount := 0
		StrReplace(saved.ClipText, "`n", "`n",, &lineCount)
		History[id]["lines"] := lineCount + 1
		History[id]["crc"] := crc32(saved.ClipText)
		History[id]["time"] := A_Now
		ClipText := ""
		SetTimer(UpdateEditSB1, 0)
		stats["edit"]++
		CheckHistory()
		hk_search_handler()
	}

	SearchEditCancel(*) {
		SearchEditGui.Destroy()
		SetTimer(UpdateEditSB1, 0)
		hk_search_handler()
	}

	UpdateEditSB1() {
		if !WinActive("CL3 Edit Entry")
			Return
		; Update status bar info if available
	}
}

#HotIf WinActive("CL3Search")

F5:: ; merge items
{
	global History, ClipText, SearchGui, iconA
	saved := SearchGui.Submit()
	ClipText := "", Removeids := ""
	Loop Parse, saved.Choice, "|"
		{
		 if (A_LoopField = "")
			continue
		 id := LTrim(SubStr(A_LoopField, 2, InStr(A_LoopField, "]") - 2), "0")
		 if (id = "")
			id := 1
		 ClipText .= History[Integer(id)]["text"] "`n"
		 Removeids := id "," Removeids
		}
	Loop Parse, Removeids, ","
		{
		 if (A_LoopField = "")
			continue
		 History.RemoveAt(Integer(A_LoopField))
		}
	lineCount := 0
	StrReplace(ClipText, "`n", "`n",, &lineCount)
	History.InsertAt(1, Map("text", ClipText, "icon", "res\" iconA, "lines", lineCount + 1, "time", A_Now))
	CheckHistory()
	ClipText := "", Removeids := ""
}

F4::
{
	global
	local id
	id := SearchGetID()
	SearchGui.Destroy()
	SearchEditEntry(Integer(id))
}

^Del::
{
	global
	local id
	id := SearchGetID()
	SearchGui.Destroy()
	History.RemoveAt(Integer(id))
	SetTimer(UpdateEditSB1, 0)
	hk_search_handler()
}

Up::
{
	global SearchGui
	hwnd := SearchGui.Hwnd
	ControlSend("{Up}", "ListBox1", "ahk_id " hwnd)
}

Down::
{
	global SearchGui
	hwnd := SearchGui.Hwnd
	ControlSend("{Down}", "ListBox1", "ahk_id " hwnd)
}

#HotIf

; not public
;@Ahk2Exe-IgnoreBegin
#include *i %A_ScriptDir%\plugins\MyQEDLG.ahk
;@Ahk2Exe-IgnoreEnd
