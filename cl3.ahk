/*

Script      : CL3 ( = CLCL CLone ) - AutoHotkey v2
Version     : 2.0
Author      : hi5
Purpose     : CL3 started as a lightweight clone of the CLCL clipboard caching utility
              which can be found at http://www.nakka.com/soft/clcl/index_eng.html.
              But some unique features have been added making it more versatile
              "text only" Clipboard manager.
Source      : https://github.com/hi5/CL3

*/

; General script settings
#Requires AutoHotkey v2.0
#SingleInstance Force
#KeyHistory 0
SetTitleMatchMode(2)
SendMode("Input")
SetWorkingDir(A_ScriptDir)
StringCaseSense(true)
name := "CL3 "
version := "v2.0"
CycleFormat := 0
Templates := Map()
Global CyclePlugins, History, SettingsObj, Slots, ClipChainData, SlotKey
Error_Flag := 0
CoordMode("Menu", "Screen")
ListLines(false)
PasteTime := A_TickCount
CyclePluginsToolTipLine := "`n" StrReplace(Format("{:020}", ""), "0", Chr(0x2014)) "`n"
ClipboardHistoryToggle := 0
TemplateClip := 0
History_Save := 0
ClipboardPrivate := 0
ClipboardByPass := ""
ActiveWindowID := ""
oldttext := ""
ttext := ""
ClipText := ""
IconExe := ""
MousePos := 0
MenuItemPos := 0
ClipChainPause := 0
FIFOACTIVE := 0
SlotKey := ""
ClipboardOwnerProcessName := ""

iconA := "icon-a.ico"
iconC := "icon-c.ico"
iconS := "icon-s.ico"
iconT := "icon-t.ico"
iconX := "icon-x.ico"
iconY := "icon-y.ico"
iconZ := "icon-z.ico"

; <for compiled scripts>
;@Ahk2Exe-SetFileVersion 2.0
;@Ahk2Exe-SetDescription CL3 Clipboard Manager
;@Ahk2Exe-SetProductName CL3
;@Ahk2Exe-SetCopyright MIT License - (c) https://github.com/hi5
; </for compiled scripts>

; <for compiled scripts>
if !FileExist(A_ScriptDir "\res")
	DirCreate(A_ScriptDir "\res")
; </for compiled scripts>

Settings()
Settings_Hotkeys()
Settings_PasteShortCuts()
HistoryRules()

ahk_icons_path := A_AhkPath
If A_IsCompiled
	ahk_icons_path := A_ScriptFullPath

; tray menu
Try
	TraySetIcon("res\cl3.ico",, true)
A_IconTip := name version

A_TrayMenu.Delete()
A_TrayMenu.Add(name version, DoubleTrayClick)
Try
	A_TrayMenu.SetIcon(name version, "res\cl3.ico")
A_TrayMenu.Default := name version
A_TrayMenu.ClickCount := 1
A_TrayMenu.Add()
A_TrayMenu.Add("&AutoReplace Active", TrayMenuHandler)
A_TrayMenu.Add("&FIFO Active", TrayMenuHandler)
A_TrayMenu.Add()
A_TrayMenu.Add("&Usage statistics", TrayMenuHandler)
Try
	A_TrayMenu.SetIcon("&Usage statistics", "shell32.dll", 278)
A_TrayMenu.Add()
A_TrayMenu.Add("&Settings", TrayMenuHandler)
Try
	A_TrayMenu.SetIcon("&Settings", "dsuiext.dll", 36)
If A_IsCompiled
	A_TrayMenu.Add("&Check for updates", TrayMenuHandler)
A_TrayMenu.Add()
A_TrayMenu.Add("&Reload CL3", TrayMenuHandler)
Try
	A_TrayMenu.SetIcon("&Reload CL3", "shell32.dll", 239)
If !A_IsCompiled
	{
	 A_TrayMenu.Add("&Edit this script", TrayMenuHandler)
	 Try
		A_TrayMenu.SetIcon("&Edit this script", "comres.dll", 7)
	}
A_TrayMenu.Add()
A_TrayMenu.Add("&Suspend Hotkeys", TrayMenuHandler)
Try
	A_TrayMenu.SetIcon("&Suspend Hotkeys", ahk_icons_path, 3)
A_TrayMenu.Add("&Pause Script", TrayMenuHandler)
Try
	A_TrayMenu.SetIcon("&Pause Script", ahk_icons_path, 4)
A_TrayMenu.Add()
A_TrayMenu.Add("&Pause clipboard history", TrayMenuHandler)
A_TrayMenu.Add()
A_TrayMenu.Add("Exit", SaveSettings)
Try
	A_TrayMenu.SetIcon("Exit", "shell32.dll", 132)

; load clipboard history and templates
if !FileExist(ClipDataFolder "History\History.xml")
	Error_Flag := 1

if (XA_Load(ClipDataFolder "History\History.xml") = 1)
	Error_Flag := 1

If (Error_Flag = 1)
	{
	 FileCopy("res\history.bak.txt", ClipDataFolder "History\History.xml", true)
	 History := []
	 XA_Load(ClipDataFolder "History\History.xml")
	}

OnExit(SaveSettings)

If !FileExist(TemplateFolder "*.txt")
	FileCopy("res\01_Example.txt", TemplateFolder "01_Example.txt", false)

; get templates in root folder first
templatefilelist := ""
Loop Files, TemplateFolder "*.txt"
	templatefilelist .= A_LoopFileName "|"
templatefilelist := Trim(templatefilelist, "|")
templatefilelist := Sort(templatefilelist, "D|")

Loop Parse, templatefilelist, "|"
	{
	 a := FileRead(TemplateFolder A_LoopField)
	 if !Templates.Has("submenu2")
		Templates["submenu2"] := Map()
	 Templates["submenu2"][A_Index] := a
	 a := ""
	}

; now check for folders for possible sub-submenus
templatesfolderlist := ""
Loop Files, TemplateFolder "*.*", "D"
	templatesfolderlist .= A_LoopFileName "|"
templatesfolderlist := Trim(templatesfolderlist, "|")
templatesfolderlist := Sort(templatesfolderlist, "D|")
templatesfolderlist := StrUpper(templatesfolderlist)

Template_Hotkeys()
OnClipboardChange(FuncOnClipboardChange)

If ActivateBackup
	SetTimer(Backup, BackupTimer * 60000)

WatchFolder(TemplateFolder, UpdateTemplate, true, 27)

If ActivateApi
	ObjRegisterActive(CL3API, "{01DA04FA-790F-40B6-9FB7-CE6C1D53DC38}")

#Include %A_ScriptDir%\plugins\plugins.ahk

UpdateTemplate(folder, Changes) {
	Reload
	Sleep(1000)
	ExitApp()
}

~^x::
~^c::
{
	global IconExe, ClipText
	IconExe := WinGetProcessPath("A")
	Sleep(100)
	ClipText := A_Clipboard
}

hk_BypassAutoReplace_handler(*) {
	global ClipboardByPass, History
	OnClipboardChange(FuncOnClipboardChange, 0)
	A_Clipboard := ClipboardByPass
	Sleep(100)
	Send("^v")
	Sleep(100)
	A_Clipboard := ""
	A_Clipboard := History[1]["text"]
	OnClipboardChange(FuncOnClipboardChange, 1)
}

; show clipboard history menu
hk_menu2_handler(*) {
	global MousePos
	MousePos := 1
	hk_menu_handler()
}

hk_menu_handler(*) {
	global MousePos, FIFOACTIVE
	FifoInit()
	BuildMenuFromFifo()
	ClipMenu := BuildMenuHistory()
	BuildMenuPluginTemplate(ClipMenu)

	WinGetPos(&MenuX, &MenuY,,, "A")
	MenuX += A_CaretX ?? 0
	MenuX += 20
	MenuY += A_CaretY ?? 0
	MenuY += 10
	If !MousePos
		{
		 If (A_CaretX != "")
			ClipMenu.Show(MenuX, MenuY)
		 Else
			ClipMenu.Show()
		}
	else
		{
		 MouseGetPos(&MenuX, &MenuY)
		 ClipMenu.Show(MenuX, MenuY)
		}
	MousePos := 0
}

BuildMenuFromFifo() {
	; Placeholder - actual FIFO menu building handled elsewhere
}

; 1x paste as plain text
hk_plaintext_handler(*) {
	global History
	If (A_Clipboard = "")
		A_Clipboard := History[1]["text"]
	A_Clipboard := Trim(A_Clipboard, "`n`r`t ")
	PasteIt()
}

hk_clipchainpaste_defaultpaste(*) {
	global ClipChainPause
	If !WinExist("CL3ClipChain ahk_class AutoHotkeyGUI") or ClipChainPause
		{
		 PasteIt("normal")
		 Return
		}
	If WinExist("CL3ClipChain ahk_class AutoHotkeyGUI")
		{
		 If (hk_clipchainpaste != "^v") or ClipChainPause
			PasteIt()
		 else
			ClipChainPasteDoubleClick()
		}
	else
		ClipChainPasteDoubleClick()
}

; Cycle through clipboard history
hk_cyclebackward_handler(*) {
	global ActiveWindowID, History, hk_cyclemodkey, hk_cyclebackward, ClipboardPrivate
	global MaxHistory, ClipText, stats, oldttext, ttext
	If !ActiveWindowID
		ActiveWindowID := WinGetID("A")
	ClipCycleCounter := 1
	ClipCycleFirst := 1
	While GetKeyState(hk_cyclemodkey, "D")
		{
		 Indicator := ""
		 If (ClipCycleCounter = 1) and (ClipboardPrivate = 1)
			Indicator := "*"
		 If (ClipCycleCounter != 0)
		 	{
		 	 If (ClipCycleCounter < 27)
				ClipCycleCounterIndicator := Chr(96 + ClipCycleCounter)
		 	 Else
				ClipCycleCounterIndicator := ClipCycleCounter
			 ttext := ClipCycleCounterIndicator Indicator " : " DispToolTipText(History[ClipCycleCounter]["text"],, History[ClipCycleCounter].Has("time") ? History[ClipCycleCounter]["time"] : "")
		 	}
		 else
			ttext := "[cancelled]"
		 If (oldttext != ttext)
			{
			 ToolTip(ttext, A_CaretX ?? unset, A_CaretY ?? unset)
			 oldttext := ttext
			}
		 Sleep(100)
		 KeyWait(hk_cyclebackward)
		}
	ToolTip()
	If (ClipCycleCounter > 0)
		{
		 ClipText := History[ClipCycleCounter]["text"]
		 ClipboardHandler()
		 stats["cyclepaste"]++
		}
}

hk_cyclebackward_up_handler(*) {
	; Handled within the while loop above
}

hk_cycleforward_handler(*) {
	; Forward cycle - simplified placeholder
}

hk_cycleforward_up_handler(*) {
}

hk_cyclecancel_handler(*) {
	global oldttext, ttext, ActiveWindowID
	ToolTip()
	oldttext := "", ttext := "", ActiveWindowID := ""
}

hk_cycleplugins_handler(*) {
	; Plugin cycle - simplified placeholder
}

hk_cycleplugins_up_handler(*) {
	global CycleFormat, CyclePlugins
	if (CycleFormat > CyclePlugins.Length)
		CycleFormat := 0
	CycleFormat++
	Sleep(100)
}

BuildMenuHistory() {
	global History, ClipboardPrivate, iconA, iconC, iconZ
	ClipMenu := Menu()

	for k, v in History
		{
		 text := v["text"]
		 icon := v.Has("icon") ? v["icon"] : ""
		 lines := v.Has("lines") ? v["lines"] : 1
		 Indicator := ""
		 if (icon = "")
			icon := "res\" iconA
		 If (A_Index = 1) and (ClipboardPrivate = 1)
			Indicator := "*"
		 key := "&" Chr(96 + A_Index) Indicator ". " DispMenuText(SubStr(text, 1, 500), lines, v.Has("time") ? v["time"] : "")
		 boundHandler := MenuHandler.Bind(A_Index)
		 ClipMenu.Add(key, boundHandler)
		 if (k = 1)
			ClipMenu.Default := key
		 If (A_Index = 1)
			Try ClipMenu.SetIcon(key, "res\" iconC,, 16)
		 Else
			Try ClipMenu.SetIcon(key, icon)
			catch
				Try ClipMenu.SetIcon(key, "res\" iconA,, 16)
		 If (A_Index = 18)
			Break
		}
	return ClipMenu
}

BuildMenuPluginTemplate(ClipMenu) {
	global History, ShowSpecial, ShowTemplates, ShowYank, ShowExit, ShowMorehistory
	global pluginlistClip, pluginlistFunc, templatefilelist, templatesfolderlist
	global Templates, TemplateFolder, TemplateClip, ClipText
	global iconS, iconT, iconY, iconZ, iconA, iconX
	global FIFOACTIVE, MoreHistory, MaxHistory, SlotsNamed, SortMenuObj
	global MenuItemPos, stats

	If ShowSpecial or ShowTemplates or ShowYank or ShowExit
		ClipMenu.Add()

	If !FIFOACTIVE
		{
		 Submenu1 := Menu()
		 pluginlist := pluginlistClip "|" pluginlistFunc
		 accIdx := 0
		 Loop Parse, pluginlist, "|"
			{
			 if (A_LoopField = "")
				continue
			 if (SubStr(A_LoopField, 1, 1) = "#")
				{
				 if (StrLen(A_LoopField) > 1) {
					Submenu1.Add()
				 }
				 continue
				}
			 accIdx++
			 key := "&" Chr(96 + accIdx) ". "
			 MenuText := SubStr(A_LoopField, 1, StrLen(A_LoopField) - 4)
			 MenuText := Trim(MenuText, "#")
			 MenuTextClean := MenuText
			 MenuText := key RegExReplace(MenuText, "m)([A-Z]+)", " $1")
			 boundSpecial := SpecialMenuHandler.Bind(MenuTextClean)
			 Submenu1.Add(MenuText, boundSpecial)
			 Try Submenu1.SetIcon(MenuText, "res\" iconS,, 16)

			 ; Check for Sort submenu
			 if (MenuTextClean = "Sort") && IsObject(SortMenuObj)
				{
				 Submenu1.Add(MenuText, SortMenuObj)
				 Try Submenu1.SetIcon(MenuText, "res\" iconS,, 16)
				}
			 if (MenuTextClean = "Slots") && IsObject(SlotsNamed) && (SlotsNamed is Map) && SlotsNamed.Count > 0
				{
				 BuildQuickSlotsMenu()
				 Submenu1.Add(MenuText, QuickSlotsMenu)
				 Try Submenu1.SetIcon(MenuText, "res\" iconS,, 16)
				}
			}
		 If ShowSpecial
			{
			 ClipMenu.Add("&s. Special", Submenu1)
			 Try ClipMenu.SetIcon("&s. Special", "res\" iconS,, 16)
			}
		}

	If ShowTemplates
		{
		 Submenu2 := Menu()
		 if (templatefilelist != "")
			{
			 MenuAccelerator := 0
			 Loop Parse, templatefilelist, "|"
				{
				 If (Mod(MenuAccelerator, 26) = 0)
					MenuAccelerator := 0
				 MenuAccelerator++
				 key := "&" Chr(96 + MenuAccelerator) ". "
				 MenuText := key SubStr(A_LoopField, InStr(A_LoopField, "_") + 1)
				 MenuText := SubStr(MenuText, 1, StrLen(MenuText) - 4)
				 Submenu2.Add(MenuText, TemplateMenuHandler)
				 Try Submenu2.SetIcon(MenuText, "res\" iconT,, 16)
				}
			 Submenu2.Add("&0. Open templates folder", TemplateMenuHandler)
			 Try Submenu2.SetIcon("&0. Open templates folder", "res\" iconT,, 16)

			 if (templatesfolderlist != "")
				{
				 Loop Parse, templatesfolderlist, "|"
					{
					 subtemplatefolder := A_LoopField
					 templatefolderFiles := ""
					 Loop Files, TemplateFolder A_LoopField "\*.txt"
						templatefolderFiles .= A_LoopFileName "|"
					 templatefolderFiles := Sort(Trim(templatefolderFiles, "|"), "D|")
					 subMenu := Menu()
					 subAccel := 0
					 Loop Parse, templatefolderFiles, "|"
						{
						 if (A_LoopField = "")
							continue
						 a := FileRead(TemplateFolder subtemplatefolder "\" A_LoopField, "UTF-8")
						 if !Templates.Has(subtemplatefolder)
							Templates[subtemplatefolder] := Map()
						 Templates[subtemplatefolder][A_Index] := a
						 if (Mod(subAccel, 26) = 0)
							subAccel := 0
						 subAccel++
						 key := "&" Chr(96 + subAccel) ". "
						 mText := key SubStr(A_LoopField, InStr(A_LoopField, "_") + 1)
						 subMenu.Add(mText, TemplateMenuHandler)
						 Try subMenu.SetIcon(mText, "res\" iconT,, 16)
						}
					 Submenu2.Add("&" subtemplatefolder, subMenu)
					 try Submenu2.SetIcon("&" subtemplatefolder, TemplateFolder subtemplatefolder "\favicon.ico",, 16)
					 catch
						try Submenu2.SetIcon("&" subtemplatefolder, "res\" iconT,, 16)
					}
				}
			}
		 Else
			Submenu2.Add("No templates", (*) => 0)
		 ClipMenu.Add("&t. Templates", Submenu2)
		 Try ClipMenu.SetIcon("&t. Templates", "res\" iconT,, 16)
		}

	; Yank submenu
	Submenu3 := Menu()
	Loop 18
		{
		 if (History.Length >= A_Index) && History[A_Index]["text"]
			{
			 idx := A_Index
			 Submenu3.Add("&" Chr(96 + A_Index) ".", ((n, *) => YankEntry(n)).Bind(idx))
			}
		}
	Submenu3.Add()
	Submenu3.Add("Clear History", (*) => (History := []))

	; More history submenu
	Submenu4 := Menu()
	If (History.Length > 20)
		{
		 MenuAccelerator := 0
		 for k, v in History
			{
			 text := v["text"]
			 icon := v.Has("icon") ? v["icon"] : ""
			 lines := v.Has("lines") ? v["lines"] : 1
			 If (A_Index < 19)
				Continue
			 MenuAccelerator++
			 if (MenuAccelerator <= 26)
				key := "&" Chr(96 + MenuAccelerator) ". " DispMenuText(SubStr(text, 1, 500), lines, v.Has("time") ? v["time"] : "")
			 else
				key := "  " DispMenuText(SubStr(text, 1, 500), lines, v.Has("time") ? v["time"] : "")
			 idx := A_Index
			 Submenu4.Add(key, ((n, *) => (MenuHandler(n))).Bind(idx))
			 Try Submenu4.SetIcon(key, icon)
			 catch
				Try Submenu4.SetIcon(key, "res\" iconA,, 16)
			 If (Mod(MenuAccelerator, 26) = 0)
				MenuAccelerator := 0
			 If (A_Index > 17 + Abs(MoreHistory))
				Break
			}
		}
	Else
		{
		 Submenu4.Add("No entries ...", (*) => 0)
		 Try Submenu4.SetIcon("No entries ...", "res\" iconA,, 16)
		}

	If !FIFOACTIVE and ShowYank
		{
		 ClipMenu.Add("&y. Yank entry", Submenu3)
		 Try ClipMenu.SetIcon("&y. Yank entry", "res\" iconY,, 16)
		}
	If ShowMorehistory
		{
		 ClipMenu.Add("&z. More history", Submenu4)
		 Try ClipMenu.SetIcon("&z. More history", "res\" iconZ,, 16)
		}
	If ShowExit
		{
		 ClipMenu.Add()
		 ClipMenu.Add("E&xit (Close menu)", (*) => 0)
		 Try ClipMenu.SetIcon("E&xit (Close menu)", "res\" iconX,, 16)
		}
}

YankEntry(idx, *) {
	global History, FIFOACTIVE
	History.RemoveAt(idx)
	If FIFOACTIVE
		{
		 FifoInit()
		 FifoActiveMenu()
		}
}

DispMenuText(TextIn, lines := "1", time := "") {
	global MenuWidth, ShowLines, LineTextFormat, ShowTime, TimeFormat, TimeFormatIndicator, TimeFormatTime

	If (lines = 1)
		linetext := (LineTextFormat.Length >= 1) ? LineTextFormat[1] : ""
	else
		linetext := (LineTextFormat.Length >= 2) ? LineTextFormat[2] : ""
	If (lines = -1)
		linetext := ""

	TextOut := RegExReplace(TextIn, "m)^\s*")
	TextOut := RegExReplace(TextOut, "\s+", " ")
	TextOut := StrReplace(TextOut, "&amp;amp;", "&")
	TextOut := StrReplace(TextOut, "&", "&&")

	If StrLen(TextOut) > MenuWidth
		TextOut := SubStr(TextOut, 1, MenuWidth) " " Chr(8230) " " SubStr(RTrim(TextOut, ".`n"), -10)
	TextOut .= " " Chr(171)

	If ShowLines
		TextOut .= StrReplace(linetext, "\l", lines)

	If ShowTime
		{
		 disptime := ""
		 If TimeFormat and time
			{
			 disptime := FormatTime(time, TimeFormatTime)
			 TextOut .= TimeFormatIndicator disptime
			}
		}

	Return LTrim(TextOut, " `t")
}

DispToolTipText(TextIn, Format := 0, time := 0) {
	Global ShowTime, TimeFormat, TimeFormatIndicator, TimeFormatTime, CyclePlugins
	TextOut := RegExReplace(TextIn, "^\s*")
	TextOut := SubStr(TextOut, 1, 750)
	if (Format > 0) && (CyclePlugins.Length >= Format)
		{
		 FormatFuncName := StrReplace(CyclePlugins[Format], " ")
		 if IsSet(%FormatFuncName%) && (Type(%FormatFuncName%) = "Func" || HasMethod(%FormatFuncName%))
			TextOut := %FormatFuncName%(TextOut)
		}
	If ShowTime
		{
		 If TimeFormat and time
			{
			 disptime := FormatTime(time, TimeFormatTime)
			 TextOut := LTrim(TimeFormatIndicator) disptime "`n" TextOut
			}
		}
	Return TextOut
}

PasteIt(source := "") {
	global PasteTime, ActiveWindowID, oldttext, ttext, ClipboardOwnerProcessName, ClipboardPrivate, PasteShortCuts, PasteDelay
	PasteKey := "^v"
	StartTime := A_TickCount
	If ((StartTime - PasteTime) < 75)
		Return

	if ActiveWindowID
		WinActivate("ahk_id " ActiveWindowID)
	CurrentProcessName := ""
	try CurrentProcessName := WinGetProcessName("A")
	CurrentProcessName := StrLower(CurrentProcessName)

	for k, v in PasteShortCuts
		{
		 if v.Has("programs") && InStr("," v["programs"] ",", "," CurrentProcessName ",")
		 	PasteKey := v["key"]
		}

	If PasteDelay
		Sleep(PasteDelay)

	If (PasteKey = "") or (PasteKey = "[SEND]")
		SendText(A_Clipboard)
	else
		Send(PasteKey)

	PasteTime := A_TickCount
	oldttext := "", ttext := "", ActiveWindowID := "", ClipboardOwnerProcessName := ""

	If (source != "normal")
		ClipboardPrivate := 0
}

MenuHandler(itemPos, *) {
	global History, ClipText, stats, FIFOACTIVE, FIFOID, MenuItemPos
	MenuItemPos := itemPos

	If FIFOACTIVE
		{
		 FIFOID := MenuItemPos
		 FifoActiveMenu()
		 TrayTip("FIFO Paste Mode Activated", "FIFO", 1)
		 Return
		}

	ClipText := History[MenuItemPos]["text"]
	ClipboardHandler()
	stats["menu"]++
}

SpecialMenuHandler(funcName, *) {
	global History, ClipText
	if (funcName = "AutoReplace")
		{
		 ShowAutoReplace()
		 Return
		}
	if (funcName = "Slots")
		{
		 hk_slots_handler()
		 return
		}
	if (funcName = "Search")
		{
		 hk_search_handler()
		 return
		}
	if (funcName = "ClipChain")
		{
		 hk_clipchain_handler()
		 return
		}
	if (funcName = "DumpHistory")
		{
		 DumpHistory()
		 return
		}
	if (funcName = "Compact")
		{
		 Compact()
		 return
		}
	if (funcName = "Fifo")
		{
		 hk_fifo_handler()
		 return
		}
	; Try calling as function for simple text plugins
	if IsSet(%funcName%) && HasMethod(%funcName%)
		ClipText := %funcName%(History[1]["text"])
	ClipboardHandler()
}

TemplateMenuHandler(ItemName, ItemPos, ThisMenu) {
	global Templates, TemplateFolder, TemplateClip, ClipText, stats

	If (ItemName = "&0. Open templates folder")
		{
		 Run(TemplateFolder)
		 Return
		}

	; Find the menu name to look up template
	menuName := ""
	; Try submenu2 (root templates) or subfolder templates
	for folderName, folderTemplates in Templates
		{
		 if folderTemplates.Has(ItemPos)
			{
			 ClipText := folderTemplates[ItemPos]
			 break
			}
		}
	TemplateClip := 1
	ClipboardHandler()
	stats["templates"]++
	TemplateClip := 0
}

ClipboardHandler(*) {
	global oldttext, ttext, ActiveWindowID, ClipText, History, TemplateClip
	global MenuItemPos, IconExe, iconT, stats
	oldttext := "", ttext := "", ActiveWindowID := ""
	If (ClipText != A_Clipboard)
		{
		 lineCount := 0
		 StrReplace(ClipText, "`n", "`n",, &lineCount)
		 If !TemplateClip
			{
			 if (MenuItemPos > 0) && (History.Length >= MenuItemPos) && History[MenuItemPos].Has("icon")
				IconExe := History[MenuItemPos]["icon"]
			 else
				try IconExe := WinGetProcessPath("A")
			}
		 else
			IconExe := "res\" iconT
		 crc := ""
		 if (MenuItemPos > 0) && (History.Length >= MenuItemPos) && History[MenuItemPos].Has("crc")
			crc := History[MenuItemPos]["crc"]
		 else
			crc := crc32(ClipText)
		 History.InsertAt(1, Map("text", ClipText, "icon", IconExe, "lines", lineCount + 1, "crc", crc, "time", A_Now))
		}
	OnClipboardChange(FuncOnClipboardChange, 0)
	A_Clipboard := ClipText
	OnClipboardChange(FuncOnClipboardChange, 1)
	PasteIt()
	CheckHistory()
	MenuItemPos := 0
}

; check clipboard
FuncOnClipboardChange(DataType) {
	global History, History_Save, IconExe, Exclude, CopyDelay, ClipText
	global ClipboardOwnerProcessName, ClipboardPrivate, ClipboardByPass
	global AllowDupes, MaxHistory, HistoryRules, hk_BypassAutoReplace, stats
	global ClipboardHistoryToggle, iconA
	Critical("On")

	If (DataType != 1)
		Return

	ClipboardOwnerProcessName := ""
	try ClipboardOwnerProcessName := WinGetProcessName("ahk_id " DllCall("GetClipboardOwner", "Ptr"))

	If (ClipboardOwnerProcessName = "")
		try ClipboardOwnerProcessName := WinGetProcessName("A")

	ClipboardOwnerProcessName := StrLower(ClipboardOwnerProcessName)

	if (Exclude != "") && InStr("," Exclude ",", "," ClipboardOwnerProcessName ",")
		{
		 ClipboardOwnerProcessName := "", ClipboardPrivate := 1
		 ClipText := ""
		 Return
		}
	else
		ClipboardOwnerProcessName := "", ClipboardPrivate := 0

	If CopyDelay
		Sleep(CopyDelay)

	try IconExe := WinGetProcessPath("A")
	If (History.Length = 0)
		History.InsertAt(1, Map("text", "Text", "icon", IconExe, "lines", 1, "time", A_Now))

	History_Save := 1

	; Handle bypass for AutoReplace
	If !WinActive("ahk_exe excel.exe")
		{
		 If (hk_BypassAutoReplace != "")
			ClipboardByPass := ClipboardAll()
		}
	else
		If (DllCall("IsClipboardFormatAvailable", "Uint", 3) = 0)
			ClipboardByPass := ClipboardAll()

	If (A_Clipboard = "")
		Return

	AutoReplaceProcess()

	If (A_Clipboard == History[1]["text"])
		{
		 ClipText := ""
		 Return
		}

	ClipText := A_Clipboard

	AddToHistory := 1

	If IsObject(HistoryRules) && (HistoryRules is Array) && HistoryRules.Length > 0
		for k, v in HistoryRules
			{
			 if !(v is Map)
				continue
			 If !v["Active"]
				Continue
			 If !RegExMatch(ClipText, v["filter"])
				AddToHistory := 0
			}

	If !AddToHistory
		{
		 ClipText := ""
		 If (HistoryRules is Map) && HistoryRules.Has("Copy") && (HistoryRules["Copy"] = 1)
			ClipboardPrivate := 1
		 else
			{
			 ClipboardPrivate := 0
			 A_Clipboard := History[1]["text"]
			}
		 Return
		}

	lineCount := 0
	StrReplace(ClipText, "`n", "`n",, &lineCount)
	crc := crc32(ClipText)
	History.InsertAt(1, Map("text", ClipText, "icon", IconExe, "lines", lineCount + 1, "crc", crc, "time", A_Now))

	If !AllowDupes
		CheckHistory()

	stats["copieditems"]++
	ClipText := ""
	Return
}

CheckHistory() {
	global History, MaxHistory
	newhistory := []
	HaveCRCList := "|"

	for k, v in History
		{
		 CurrentCRC := v.Has("crc") ? v["crc"] : ""
		 if !CurrentCRC
			CurrentCRC := crc32(v["text"])
		 if !InStr(HaveCRCList, "|" CurrentCRC "|")
			newhistory.Push(Map("text", v["text"], "icon", v.Has("icon") ? v["icon"] : "", "lines", v.Has("lines") ? v["lines"] : 1, "crc", CurrentCRC, "time", v.Has("time") ? v["time"] : ""))
		 HaveCRCList .= CurrentCRC "|"
		 if (k >= Integer(MaxHistory))
			break
		}

	History := newhistory
}

DoubleTrayClick(*) {
	Send("{RButton}")
}

TrayMenuHandler(ItemName, *) {
	global version, stats, ClipboardHistoryToggle, AutoReplace, ClipDataFolder

	If (ItemName = "&Reload CL3")
		{
		 Reload()
		 Return
		}
	Else If (ItemName = "&Edit this script")
		{
		 Run("Edit " A_ScriptName)
		 Return
		}
	Else If (ItemName = "&Suspend Hotkeys")
		{
		 A_TrayMenu.ToggleCheck("&Suspend Hotkeys")
		 Suspend(-1)
		 Return
		}
	Else If (ItemName = "&Pause Script")
		{
		 A_TrayMenu.ToggleCheck("&Pause Script")
		 Pause(-1)
		 Return
		}
	Else If (ItemName = "&Pause clipboard history")
		{
		 CL3Api_State(ClipboardHistoryToggle)
		 If ClipboardHistoryToggle
			try TraySetIcon("res\cl3.ico")
		 else
			try TraySetIcon("res\cl3_clipboard_history_paused.ico")
		 ClipboardHistoryToggle := !ClipboardHistoryToggle
		}
	Else If (ItemName = "&AutoReplace Active")
		{
		 If AutoReplace.Settings["Active"]
			AutoReplace.Settings["Active"] := 0
		 else
			AutoReplace.Settings["Active"] := 1
		 XA_Save("AutoReplace", ClipDataFolder "AutoReplace\AutoReplace.xml")
		 AutoReplaceMenuUpdate()
		}
	Else If (ItemName = "&FIFO Active")
		FifoActiveMenu()
	Else If (ItemName = "&Settings")
		Settings_menu()
	Else If (ItemName = "&Check for updates")
		{
		 Update(version)
		 Return
		}
	Else If (ItemName = "&Usage statistics")
		{
		 show_stats := "CL3 Usage statistics`n___________________________`n"
		 stats_total := 0
		 for k, v in stats
			{
			 if (k = "copieditems")
				continue
			 show_stats .= Format("{:-20}", k) A_Tab v "`n"
			 stats_total += v
			}
		 show_stats .= "___________________________`n" Format("{:-20}", "Total (pasted)") A_Tab stats_total "`n" Format("{:-20}", "Total (copied)") A_Tab stats["copieditems"] "`n"
		 MsgBox(show_stats, "CL3 Usage statistics - " version, 64)
		}
	Else If (Trim(ItemName) = "Exit")
		ExitApp()
}

SaveSettings(*) {
	global History, MaxHistory, stats, ClipDataFolder, ActivateApi, ActivateBackup, BackupTimer

	SetTimer(Backup, 0)

	While (History.Length > Integer(MaxHistory))
		History.RemoveAt(History.Length)

	XA_Save("History", ClipDataFolder "History\History.xml")
	XA_Save("stats", A_ScriptDir "\stats.xml")

	If ActivateApi
		ObjRegisterActive(CL3API, "")

	Sleep(100)
	ExitApp()
}

XMLSave(savelist, id := "") {
	global ActivateBackup, ClipDataFolder

	If !ActivateBackup and (id != "")
		Return
	ext := id ? ".xml.bak" : ".xml"

	Loop Parse, savelist, ","
		{
		 If (A_LoopField = "stats")
			{
			 XA_Save("stats", A_ScriptDir "\stats.xml")
			 Continue
			}
		 If (A_LoopField = "ClipChainData")
			{
			 objectname := "ClipChainData"
			 objectfile := "ClipChain" id ext
			}
		 else
			{
			 objectname := A_LoopField
			 objectfile := A_LoopField id ext
			}
		 If (objectname = "ClipChainData")
			XA_Save(objectname, ClipDataFolder "ClipChain\" objectfile)
		 else
			XA_Save(objectname, ClipDataFolder objectname "\" objectfile)
		}

	; keep only the 5 most recent backups
	Loop Parse, "History,Slots,ClipChain,AutoReplace", ","
		{
		 keeplist := ""
		 Loop Files, ClipDataFolder A_LoopField "\*.bak"
			keeplist .= A_LoopFileFullPath "`n"
		 keeplist := Sort(keeplist, "RN")
		 Loop Parse, keeplist, "`n", "`r"
			{
			 if (A_LoopField = "")
				continue
			 If (A_Index < 6)
				continue
			 FileDelete(A_LoopField)
			}
		}
}

Backup(*) {
	global History_Save
	If History_Save
		{
		 XMLSave("History", "-" A_Now)
		 History_Save := 0
		}
}

Template_Hotkeys() {
	global TemplateFolder, templatesfolderlist
	Loop Parse, templatesfolderlist, "|"
		{
		 if (A_LoopField = "")
			continue
		 TemplatesShortcut := IniRead(TemplateFolder A_LoopField "\settings.ini", "settings", "shortcut", "ERROR")
		 If (TemplatesShortcut != "ERROR")
			{
			 loopField := A_LoopField
			 fn := ShowMenu.Bind(loopField)
			 Hotkey(TemplatesShortcut, fn)
			}
		}
}

CL3Api_State(toggle) {
	if (toggle)
		{
		 OnClipboardChange(FuncOnClipboardChange, 1)
		 A_TrayMenu.ToggleCheck("&Pause clipboard history")
		 Try TraySetIcon("res\cl3.ico")
		}
	else
		{
		 OnClipboardChange(FuncOnClipboardChange, 0)
		 A_TrayMenu.ToggleCheck("&Pause clipboard history")
		 Try TraySetIcon("res\cl3_clipboard_history_paused.ico")
		}
}

#include %A_ScriptDir%\lib\cl3apiclass.ahk
;@Ahk2Exe-IgnoreBegin
#Include *i %A_ScriptDir%\plugins\ClipboardPrivateRules.ahk
;@Ahk2Exe-IgnoreEnd
