/*

Plugin            : ccmdr (optional via settings.ini)
Purpose           : Allow for (batch) operations on clipboard history vs the
                    usual one by one operations via standard CL3 options.
                    see docs\ccmdr.md
Version           : 1.3
CL3 version       : v1.94

History:
- 1.3 fix for AutoHotkey v1.1.37.02 suddenly stuck in loop calling gCmdr + missing global var for ClipDataFolder
- 1.2 burst, added \s for space
- 1.1 added named slots
- 1.0 initial version

*/

ccmdersetup() {
	global HelpCommands, HelpEntryText, CmdrGui, CmdHwnd

	HelpCommands := Map(
		"b", "Burst seperator (\n, \t, \s, \\, char or word)",
		"i", "Insert IDx",
		"f", "FIFO IDx, e=enter, t=tab",
		"l", "Lower case IDx or range (IDx-IDy)",
		"p", "Paste IDx (repeat) or range (IDx-IDy), e=enter, t=tab",
		"r", "Reverse",
		"s", "Store in Slot (1-10) or name",
		"t", "Title case IDx or range (IDx-IDy)",
		"u", "Upper case IDx or range (IDx-IDy)",
		"y", "Yank IDx or range (IDx-IDy)"
	)

	HelpEntryText := ""
	for k, v in HelpCommands
		HelpEntryText .= k ","
	HelpEntryText := Trim(HelpEntryText, ",")
	HelpEntryText := Sort(HelpEntryText, "D,")
	HelpEntryText := StrReplace(HelpEntryText, ",", ", ")

	CmdrGui := Gui(, "CL3:cmdr")
	CmdrGui.Opt("-Caption +Border")
	CmdrGui.OnEvent("Close", (*) => CmdrGuiHide())
	CmdrGui.OnEvent("Escape", (*) => CmdrGuiHide())
	CmdrGui.SetFont(dpi("s10"))
	CmdrGui.Add("Text",, "Action: [ hint: " HelpEntryText " ]")
	ogcCmd := CmdrGui.Add("Edit", dpi("vCmd w350"))
	ogcCmd.OnEvent("Change", CmdrInputChange)
	CmdrGui.Add("Text", dpi("vCmdrFeedback w350"), "enter command")
	CmdrGui.Add("Button", "Hidden Default", "OK").OnEvent("Click", CmdExec)
}

CmdrGuiHide() {
	global CmdrGui
	CmdrGui.Hide()
	CmdrGui["Cmd"].Value := ""
}

hk_cmdr_handler(*) {
	global CmdrGui
	If !WinExist("CL3:cmdr ahk_class AutoHotkeyGUI")
		{
		 CmdrGui["Cmd"].Value := ""
		 CmdrGui.Show("AutoSize center")
		}
	else
		{
		 CmdrGuiHide()
		}
}

CmdrInputChange(ctrl, *) {
	global HelpCommands, CmdrGui
	cmd := ctrl.Value
	Help := SubStr(cmd, 1, 1)
	Reverse := 0
	If (Help = "") or (cmd = "")
		Return
	If (Help = "r")
		{
		 Reverse := 1
		 Help := SubStr(cmd, 2, 1)
		 If (Help = "")
			Help := "r"
		}
	if !HelpCommands.Has(Help)
		{
		 CmdrGui["Cmd"].Value := ""
		 CmdrGui["CmdrFeedback"].Value := "enter command"
		 Return
		}
	If Reverse and (Help = "b")
		CmdrGui["CmdrFeedback"].Value := "Reverse " HelpCommands[Help]
	else
		CmdrGui["CmdrFeedback"].Value := HelpCommands[Help]
}

CmdExec(*) {
	global CmdrGui
	saved := CmdrGui.Submit()
	Command(saved.Cmd)
}

Command(cmd) {
	global History, History_Save, Slots, SlotsNamed, ClipDataFolder, SlotsGui
	cmd := Trim(cmd, " ")
	CommandChar := SubStr(cmd, 1, 1)
	Reverse := 0
	if (CommandChar = "r")
		{
		 Reverse := 1
		 CommandChar := SubStr(cmd, 2, 1)
		 cmd := SubStr(cmd, 3)
		}
	else
		cmd := SubStr(cmd, 2)

	if (cmd = "")
		cmd := 1

	; u/l/t - uppercase/lowercase/titlecase
	if (CommandChar = "u") || (CommandChar = "l") || (CommandChar = "t")
		{
		 if (CommandChar = "u")
			callfunc := StrUpper
		 if (CommandChar = "l")
			callfunc := StrLower
		 if (CommandChar = "t")
			callfunc := StrTitle
		 if RegExMatch(cmd, "i)^[a-z]$")
			cmd := cmdrAsc2Number(cmd)

		 cmd := cmdrRange(cmd)

		 OnClipboardChange(FuncOnClipboardChange, 0)

		 Loop Parse, cmd, ","
			History[Integer(A_LoopField)]["text"] := callfunc(History[Integer(A_LoopField)]["text"])

		 if RegExMatch(cmd, "\b1\b")
			A_Clipboard := History[1]["text"]

		 History_Save := 1
		 OnClipboardChange(FuncOnClipboardChange, 1)
		 return
		}

	; s - store in slot
	if (CommandChar = "s")
		{
		 if RegExMatch(cmd, "^(\d+)", &SlotIDMatch)
			{
			 SlotID := Integer(SlotIDMatch[1])
			 if IsNumber(SlotID)
				{
				 if (SlotID = 10)
					SlotID := 0
				 if (SlotID >= 0) && (SlotID <= 9)
					{
					 XMLSave("Slots", "-" A_Now)
					 Slots[SlotID + 1] := History[1]["text"]
					 XMLSave("Slots")
					 try SlotsGui["Slot" SlotID].Value := History[1]["text"]
					}
				 else
					TrayTip("Invalid SlotID`n(Command ignored)", "CL3:cmdr", 3)
				 return
				}
			}
		 ; Named Slots
		 If !IsObject(SlotsNamed)
			SlotsNamed := Map()
		 SlotsNamed[cmd] := History[1]["text"]
		 XA_Save("SlotsNamed", ClipDataFolder "Slots\SlotsNamed.xml")
		 BuildQuickSlotsMenu()
		}

	; i - insert
	if (CommandChar = "i")
		{
		 if RegExMatch(cmd, "i)^[a-z]$")
			cmd := cmdrAsc2Number(cmd)
		 cmd := Integer(cmd) + 1
		 if IsNumber(cmd)
			{
			 lineCount := 0
			 StrReplace(A_Clipboard, "`n", "`n",, &lineCount)
			 History.InsertAt(cmd, Map("text", A_Clipboard, "icon", "", "lines", lineCount + 1, "time", A_Now))
			 History.RemoveAt(1)
			 OnClipboardChange(FuncOnClipboardChange, 0)
			 A_Clipboard := History[1]["text"]
			 OnClipboardChange(FuncOnClipboardChange, 1)
			 History_Save := 1
			 CheckHistory()
			}
		}

	; f - fifo
	sendtab := 0, sendenter := 0
	if (CommandChar = "f")
		{
		 if (SubStr(cmd, -1) = "t")
			{
			 sendtab := 1
			 cmd := RTrim(cmd, "t")
			}
		 if (SubStr(cmd, -1) = "e")
			{
			 sendenter := 1
			 cmd := RTrim(cmd, "e")
			}
		 newcmd := ""
		 Loop Integer(cmd)
			newcmd .= (Integer(cmd) - A_Index + 1) ","
		 cmd := RTrim(newcmd, ",")
		 CommandChar := "p"
		}

	; p - paste
	if (CommandChar = "p")
		{
		 if (SubStr(cmd, -1) = "t")
			{
			 sendtab := 1
			 cmd := RTrim(cmd, "t")
			}
		 if (SubStr(cmd, -1) = "e")
			{
			 sendenter := 1
			 cmd := RTrim(cmd, "e")
			}

		 range := InStr(cmd, "-") ? 1 : 0
		 cmd := cmdrRange(cmd)

		 Loop Parse, cmd, ","
			{
			 if range
				{
				 OnClipboardChange(FuncOnClipboardChange, 0)
				 A_Clipboard := History[Integer(A_LoopField)]["text"]
				 OnClipboardChange(FuncOnClipboardChange, 1)
				}
			 Send("^v")
			 Sleep(100)
			 if sendtab
				{
				 Send("{tab}")
				 Sleep(100)
				}
			 if sendenter
				{
				 Send("{enter}")
				 Sleep(100)
				}
			}
		 return
		}

	; y - yank
	if (CommandChar = "y")
		{
		 if RegExMatch(cmd, "i)^[a-z]$")
			cmd := cmdrAsc2Number(cmd)
		 if IsNumber(cmd) && !InStr(cmd, "-")
			{
			 Loop Integer(cmd)
				History.RemoveAt(1)
			 return
			}
		 if InStr(cmd, "-")
			{
			 from := StrSplit(cmd, "-")[1]
			 to := StrSplit(cmd, "-")[2]
			 if RegExMatch(from, "i)^[a-z]$")
				from := cmdrAsc2Number(from)
			 if RegExMatch(to, "i)^[a-z]$")
				to := cmdrAsc2Number(to)
			 to := Integer(to) - Integer(from) + 1
			 History.RemoveAt(Integer(from), to)
			 History_Save := 1
			 return
			}
		}

	; b - burst
	if (CommandChar = "b")
		{
		 Delim := ""
		 fullcmd := CommandChar . cmd
		 if (fullcmd = "b\n")
			Delim := "`n", cmd := ""
		 if (fullcmd = "b\t")
			Delim := A_Tab, cmd := ""
		 if (fullcmd = "b\\")
			Delim := "\", cmd := ""
		 if (fullcmd = "b\s")
			Delim := " ", cmd := ""
		 if (Delim = "") && RegExMatch(cmd, ")^.$")
			Delim := cmd, cmd := ""
		 if (Delim = "") && RegExMatch(cmd, ")^\\.*$")
			Delim := StrReplace(cmd, "\"), cmd := ""

		 If (StrLen(Delim) > 1)
			{
			 OnClipboardChange(FuncOnClipboardChange, 0)
			 A_Clipboard := StrReplace(A_Clipboard, Delim, Chr(7))
			 OnClipboardChange(FuncOnClipboardChange, 1)
			 Delim := Chr(7)
			}
		 burst := StrSplit(A_Clipboard, Delim)

		 Loop burst.Length
			{
			 lineCount := 0
			 If !Reverse
				{
				 StrReplace(burst[A_Index], "`n", "`n",, &lineCount)
				 History.InsertAt(1, Map("text", burst[A_Index], "IconExe", "", "lines", lineCount + 1, "time", A_Now))
				}
			 else
				{
				 StrReplace(burst[A_Index], "`n", "`n",, &lineCount)
				 History.InsertAt(1, Map("text", burst[burst.Length + 1 - A_Index], "IconExe", "", "lines", lineCount + 1, "time", A_Now))
				}
			}
		}
}

cmdrAsc2Number(in) {
	in := StrLower(in)
	return String(Ord(in) - 96)
}

cmdrRange(cmd) {
	if InStr(cmd, "-")
		{
		 from := StrSplit(cmd, "-")[1]
		 to := StrSplit(cmd, "-")[2]
		 cmd := ""
		 Loop Integer(to)
			{
			 if (A_Index >= Integer(from))
				cmd .= A_Index ","
			}
		 cmd := RTrim(cmd, ",")
		}
	if IsNumber(cmd) && !InStr(cmd, ",")
		{
		 newcmd := ""
		 Loop Integer(cmd)
			newcmd .= A_Index ","
		 cmd := RTrim(newcmd, ",")
		}
	return cmd
}
