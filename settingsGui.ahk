
Settings_menu(*) {
	global
	local SetMenuCheck, ogc

	SetupMenu := Menu()
	SetupMenu.Add("Show Special", SetupMenuHandler)
	SetupMenu.Add("Show Templates", SetupMenuHandler)
	SetupMenu.Add("Show Yank", SetupMenuHandler)
	SetupMenu.Add("Show More history", SetupMenuHandler)
	SetupMenu.Add("Show Exit", SetupMenuHandler)

	menuChecks := Map(
		"Show Special", ShowSpecial,
		"Show Templates", ShowTemplates,
		"Show Yank", ShowYank,
		"Show More history", ShowMorehistory,
		"Show Exit", ShowExit
	)
	for itemName, val in menuChecks {
		if (val = 1)
			SetupMenu.Check(itemName)
	}

	SettingsGui := Gui(, "CL3 Settings - " version)
	SettingsGui.OnEvent("Escape", SettingsGuiClose)
	SettingsGui.OnEvent("Close", SettingsGuiClose)

	SettingsGui.SetFont(, "MS Shell Dlg")
	SettingsGui.Add("GroupBox", "x5 y20 w170 h320", "General hotkeys")
	SettingsGui.SetFont("cRed")
	SettingsGui.Add("Text", "xp+140 yp w25", A_Space " [?] " A_Space).OnEvent("Click", HelpHotkeys)
	SettingsGui.SetFont("cBlack")

	SettingsGui.SetFont(, "MS Shell Dlg")
	SettingsGui.Add("Text", "xp-132 yp+25", "Show Menu (History*):")
	SettingsGui.Add("Edit", "xp+110 yp-3 w40 h20 vhk_menu", hk_menu)
	SettingsGui.Add("Text", "xp-110 yp+25", "Show Menu 2 (History):")
	SettingsGui.Add("Edit", "xp+110 yp-3 w40 h20 vhk_menu2", hk_menu2)
	SettingsGui.Add("Text", "xp-110 yp+25", "Paste Plain text:")
	SettingsGui.Add("Edit", "xp+110 yp-3 w40 h20 vhk_plaintext", hk_plaintext)
	SettingsGui.Add("Text", "xp-110 yp+20", "__________________________")
	SettingsGui.Add("Text", "xp yp+25", "Search:")
	SettingsGui.Add("Edit", "xp+110 yp-3 w40 h20 vhk_search", hk_search)
	SettingsGui.Add("Text", "xp-110 yp+25", "FiFo:")
	SettingsGui.Add("Edit", "xp+110 yp-3 w40 h20 vhk_fifo", hk_fifo)
	SettingsGui.Add("Text", "xp-110 yp+25", "ClipChain:")
	SettingsGui.Add("Edit", "xp+110 yp-3 w40 h20 vhk_clipchain", hk_clipchain)
	SettingsGui.Add("Text", "xp-110 yp+20", "__________________________")

	SettingsGui.SetFont("cRed")
	SettingsGui.Add("Text", "xp yp+20 w150", "Do not add modifiers below! [?]").OnEvent("Click", ModHelp)
	SettingsGui.SetFont("cBlack")

	SettingsGui.SetFont(, "MS Shell Dlg")
	SettingsGui.Add("Text", "xp yp+23", "Cycle forward:")
	SettingsGui.Add("Edit", "xp+110 yp-3 w40 h20 vhk_cycleforward", hk_cycleforward)
	SettingsGui.Add("Text", "xp-110 yp+30", "Cycle backward:")
	SettingsGui.Add("Edit", "xp+110 yp-3 w40 h20 vhk_cyclebackward", hk_cyclebackward)
	SettingsGui.Add("Text", "xp-110 yp+30", "Cycle cancel:")
	SettingsGui.Add("Edit", "xp+110 yp-3 w40 h20 vhk_cyclecancel", hk_cyclecancel)
	SettingsGui.Add("Text", "xp-110 yp+30", "Cycle plugin:")
	SettingsGui.Add("Edit", "xp+110 yp-3 w40 h20 vhk_cycleplugins", hk_cycleplugins)

	SettingsGui.Add("GroupBox", "xp+60 y20 w100 h320", "Slots")
	SettingsGui.SetFont("cRed")
	SettingsGui.Add("Text", "xp+70 yp w25", A_Space " [?] " A_Space).OnEvent("Click", HelpHotkeys)
	SettingsGui.SetFont("cBlack")

	SettingsGui.SetFont(, "MS Shell Dlg")
	SettingsGui.Add("Text", "xp-62 yp+24", "Show:")
	SettingsGui.Add("Edit", "xp+40 yp-3 w40 h20 vhk_slots", hk_slots)

	Loop 9
	{
		slotVal := hk_slot.Has(A_Index) ? hk_slot[A_Index] : ""
		SettingsGui.Add("Text", "xp-40 yp+27", "Slot " A_Index ":")
		SettingsGui.Add("Edit", "xp+40 yp-3 w40 h20 vhk_slot" A_Index, slotVal)
	}

	SettingsGui.Add("Text", "xp-40 yp+27", "Slot 10:")
	SettingsGui.Add("Edit", "xp+40 yp-3 w40 h20 vhk_slot0", hk_slot.Has(0) ? hk_slot[0] : "")

	SettingsGui.Add("Text", "xp-40 yp+27", "Menu:")
	SettingsGui.Add("Edit", "xp+40 yp-3 w40 h20 vhk_slotsmenu", hk_slotsmenu)

	SettingsGui.Add("GroupBox", "xp+60 y20 w130 h320", "Other")
	SettingsGui.Add("Text", "xp+8 yp+24", "Max History:")
	SettingsGui.Add("Edit", "xp+70 yp-3 w40 h20 vMaxHistory Number", MaxHistory)
	SettingsGui.Add("Text", "xp-70 yp+25", "Menu width:")
	SettingsGui.Add("Edit", "xp+70 yp-3 w40 h20")
	SettingsGui.Add("UpDown", "Range20-100 vMenuWidth", MenuWidth)
	SettingsGui.Add("Text", "xp-70 yp+25", "More History:")
	SettingsGui.Add("Edit", "xp+70 yp-3 w40 h20")
	SettingsGui.Add("UpDown", "Range-100-300 vMoreHistory", MoreHistory)
	ogc := SettingsGui.Add("Checkbox", "xp-70 yp+24 vAllowDupes", "Allow Duplicates")
	if AllowDupes
		ogc.Value := 1
	SettingsGui.Add("Button", "xp yp+24 h22 w110", "Setup Menu").OnEvent("Click", (*) => SetupMenu.Show())
	SettingsGui.Add("Text", "xp yp+22", "___________________")
	SettingsGui.Add("Text", "xp yp+25", "Search width:")
	SettingsGui.Add("Edit", "xp+70 yp-3 w40 h20 vSearchWindowWidth Number", SearchWindowWidth)
	SettingsGui.Add("Text", "xp-70 yp+30", "Search height:")
	SettingsGui.Add("Edit", "xp+70 yp-3 w40 h20 vSearchWindowHeight Number", SearchWindowHeight)
	SettingsGui.Add("Text", "xp-70 yp+20", "___________________")
	SettingsGui.Add("Text", "xp yp+20", "CyclePlugins:")

	; Build EditCyclePlugins text
	EditCyclePlugins := ""
	for k, v in CyclePlugins
		if (v = "<none>")
			continue
		else
			EditCyclePlugins .= v "`n"

	SettingsGui.Add("Edit", "xp-5 yp+15 w125 R5 vEditCyclePlugins", EditCyclePlugins)

	SettingsGui.Add("GroupBox", "x5 yp+88 w278 h55", "Exclude programs (CSV: program1.exe,prg2.exe)")
	SettingsGui.Add("Edit", "xp+8 yp+20 w260 h20 vExclude", Exclude)

	SettingsGui.Add("GroupBox", "xp+278 yp-20 w130 h55", "Folders (Dir1;Dir2)")
	SettingsGui.SetFont("cRed")
	SettingsGui.Add("Text", "xp+100 yp w25", A_Space " [?] " A_Space).OnEvent("Click", FoldersHelp)
	SettingsGui.SetFont("cBlack")

	SettingsGui.SetFont(, "MS Shell Dlg")
	ogcFldrs := SettingsGui.Add("Edit", "xp-90 yp+20 w110 h20 vSettingsFolders", SettingsFolders)
	SetEditCueBanner(ogcFldrs.Hwnd, "Default CL3 Folders")

	SettingsGui.Add("Button", "x5 yp+40 w100 h25", "&Save").OnEvent("Click", SettingsSave)
	SettingsGui.Add("Button", "xp+158 yp w100 h25", "&Default").OnEvent("Click", SettingsDefault)
	SettingsGui.Add("Button", "xp+159 yp w100 h25", "&Cancel").OnEvent("Click", (*) => SettingsGui.Destroy())

	SettingsGui.Add("GroupBox", "xp+110 y20 w100 h412", "Special")
	ogc := SettingsGui.Add("Checkbox", "xp+8 yp+24 vActivateApi", "Activate API")
	if ActivateApi
		ogc.Value := 1

	ogc := SettingsGui.Add("Checkbox", "xp yp+25 vActivateCmdr", "ccmdr plugin")
	if ActivateCmdr
		ogc.Value := 1
	SettingsGui.Add("Edit", "xp+20 yp+15 w60 h20 vhk_cmdr", hk_cmdr)

	ogc := SettingsGui.Add("Checkbox", "xp-20 yp+25 vActivateBackup", "Auto Backup")
	if ActivateBackup
		ogc.Value := 1
	SettingsGui.Add("Edit", "xp+20 yp+15 w60 h20 vBackupTimer Number", BackupTimer)

	ogc := SettingsGui.Add("Checkbox", "xp-20 yp+25 vShowLines", "Show lines")
	if ShowLines
		ogc.Value := 1
	LineFormatDisplay := StrReplace(LineFormat, A_Tab, "\t")
	SettingsGui.Add("Edit", "xp+20 yp+15 w60 h20 vLineFormat", LineFormatDisplay)

	ogc := SettingsGui.Add("Checkbox", "xp-20 yp+25 vShowTime", "Show time")
	if ShowTime
		ogc.Value := 1
	SettingsGui.Add("Edit", "xp+20 yp+15 w60 h20 vTimeFormat", TimeFormat)

	ogc := SettingsGui.Add("Checkbox", "xp-20 yp+24 vAutoReplaceTrayTip", "AutoRepl. TT")
	if AutoReplaceTrayTip
		ogc.Value := 1
	SettingsGui.Add("Text", "xp yp+25", "Clipchain HK:")
	SettingsGui.Add("Edit", "xp yp+15 w80 vhk_ClipChainPaste", hk_ClipChainPaste)
	SettingsGui.Add("Text", "xp yp+30", "Bypass AutoRepl.`npaste [1st entry]:")
	SettingsGui.Add("Edit", "xp yp+30 w80 vhk_BypassAutoReplace", hk_BypassAutoReplace)
	SettingsGui.Add("Text", "xp yp+30", "Clipb. delay (ms)")
	SettingsGui.SetFont("cRed")
	SettingsGui.Add("Text", "xp+80 yp", "?").OnEvent("Click", ModHelp2)
	SettingsGui.SetFont("cBlack")
	SettingsGui.SetFont(, "MS Shell Dlg")
	SettingsGui.Add("Edit", "xp-80 yp+18 w35 Number vCopyDelay", CopyDelay)
	SettingsGui.Add("Edit", "xp+45 yp w35 Number vPasteDelay", PasteDelay)

	SettingsGui.Show("w545 h440")
	return

	; --- Nested functions ---

	SetupMenuHandler(ItemName, ItemPos, MyMenu) {
		menuCheckVars := Map(
			"Show Special", "ShowSpecial",
			"Show Templates", "ShowTemplates",
			"Show Yank", "ShowYank",
			"Show More history", "ShowMorehistory",
			"Show Exit", "ShowExit"
		)
		if menuCheckVars.Has(ItemName) {
			varName := menuCheckVars[ItemName]
			%varName% := !%varName%
			MyMenu.ToggleCheck(ItemName)
		}
	}

	SettingsGuiClose(*) {
		SettingsGui.Destroy()
	}

	SettingsDefault(*) {
		Settings_Default()
		for k, v in Settings_Hotkeys
			SettingsGui[k].Value := v
		for k, v in Settings_Settings
			try SettingsGui[k].Value := v

		hk_cyclemodkey := Settings_Hotkeys["hk_cyclemodkey"]

		EditCyclePluginsText := Trim(StrReplace(Settings_Plugins["Plugins"], ",", "`n"), " `n")
		SettingsGui["EditCyclePlugins"].Value := EditCyclePluginsText
	}

	SettingsSave(*) {
		saved := SettingsGui.Submit()

		CyclePluginsVal := Trim(StrReplace(saved.EditCyclePlugins, "`n", ","), ", ")
		IniWrite(CyclePluginsVal, ini, "Plugins", "CyclePlugins")

		IniWrite(saved.hk_menu, ini, "Hotkeys", "hk_menu")
		IniWrite(saved.hk_menu2, ini, "Hotkeys", "hk_menu2")
		IniWrite(saved.hk_plaintext, ini, "Hotkeys", "hk_plaintext")
		IniWrite(saved.hk_slots, ini, "Hotkeys", "hk_slots")
		IniWrite(saved.hk_clipchain, ini, "Hotkeys", "hk_clipchain")
		IniWrite(saved.hk_clipchainpaste, ini, "Hotkeys", "hk_clipchainpaste")
		IniWrite(saved.hk_fifo, ini, "Hotkeys", "hk_fifo")
		IniWrite(saved.hk_search, ini, "Hotkeys", "hk_search")
		IniWrite(hk_cyclemodkey, ini, "Hotkeys", "hk_cyclemodkey")
		IniWrite(saved.hk_cyclebackward, ini, "Hotkeys", "hk_cyclebackward")
		IniWrite(saved.hk_cycleforward, ini, "Hotkeys", "hk_cycleforward")
		IniWrite(saved.hk_cycleplugins, ini, "Hotkeys", "hk_cycleplugins")
		IniWrite(saved.hk_cyclecancel, ini, "Hotkeys", "hk_cyclecancel")
		IniWrite(saved.hk_cmdr, ini, "Hotkeys", "hk_cmdr")
		IniWrite(saved.hk_BypassAutoReplace, ini, "Hotkeys", "hk_BypassAutoReplace")

		Loop 9
			IniWrite(saved.%"hk_slot" A_Index%, ini, "Hotkeys", "hk_slot" A_Index)
		IniWrite(saved.hk_slot0, ini, "Hotkeys", "hk_slot0")

		IniWrite(saved.hk_slotsmenu, ini, "Hotkeys", "hk_slotsmenu")

		IniWrite(saved.MenuWidth, ini, "Settings", "MenuWidth")
		IniWrite(saved.MaxHistory, ini, "Settings", "MaxHistory")
		IniWrite(saved.MoreHistory, ini, "Settings", "MoreHistory")
		IniWrite(saved.AllowDupes, ini, "Settings", "AllowDupes")
		IniWrite(saved.SearchWindowWidth, ini, "Settings", "SearchWindowWidth")
		IniWrite(saved.SearchWindowHeight, ini, "Settings", "SearchWindowHeight")
		IniWrite(saved.ActivateApi, ini, "Settings", "ActivateApi")
		IniWrite(saved.ActivateBackup, ini, "settings", "ActivateBackup")
		IniWrite(saved.BackupTimer, ini, "settings", "BackupTimer")
		IniWrite(saved.ShowLines, ini, "Settings", "ShowLines")
		IniWrite(saved.ShowTime, ini, "Settings", "ShowTime")
		IniWrite(saved.AutoReplaceTrayTip, ini, "Settings", "AutoReplaceTrayTip")
		IniWrite(saved.CopyDelay, ini, "Settings", "CopyDelay")
		IniWrite(saved.PasteDelay, ini, "Settings", "PasteDelay")
		IniWrite(saved.Exclude, ini, "Settings", "Exclude")
		IniWrite(saved.SettingsFolders, ini, "Settings", "SettingsFolders")
		IniWrite(ShowSpecial, ini, "Settings", "ShowSpecial")
		IniWrite(ShowTemplates, ini, "Settings", "ShowTemplates")
		IniWrite(ShowYank, ini, "Settings", "ShowYank")
		IniWrite(ShowMorehistory, ini, "Settings", "ShowMorehistory")
		IniWrite(ShowExit, ini, "Settings", "ShowExit")

		LineFormatVal := StrReplace(saved.LineFormat, A_Tab, "\t")
		IniWrite(LineFormatVal, ini, "settings", "LineFormat")
		IniWrite(saved.TimeFormat, ini, "settings", "TimeFormat")

		IniWrite(saved.ActivateCmdr, ini, "Plugins", "ActivateCmdr")

		Sleep(100)
		Reload
	}
}

HelpHotkeys(*) {
	MsgBox("To disable a feature/plugin, simple delete the associated hotkey(s).`n`n"
		. "Example: to disable ClipChain or Slots, remove (all) hotkey(s).`n`n"
		. "* Show menu hotkey is mandatory.`n`n"
		. "Modifiers:`n`n"
		. "#`tWindows-key`n"
		. "^`tCtrl`n"
		. "+`tShift`n"
		. "!`tAlt`n"
		. "< >`tuse RIGHT or LEFT modifier (>^ = RIGHT Control)`n`n"
		. "F1-F12`tFunction keys`n`n"
		. "See AutoHotkey help for further details."
	, "CL3 Hotkeys Help", 32)
}

ModHelp(*) {
	MsgBox("If you want to change the default modifier from LWin to say RAlt:`n"
		. "Close CL3 and edit the hk_cyclemodkey key in settings.ini`n"
		. "(see [Hotkeys] section)`n`n"
		. "Examples:`n`n"
		. "hk_cyclemodkey=RAlt`n"
		. "hk_cyclemodkey=LCtrl`n`n"
		. 'Using "Default" to restore the default settings will also reset hk_cyclemodkey.'
	, "CL3 CyclePlugins Help", 32)
}

ModHelp2(*) {
	MsgBox("Time in milliseconds to wait before adding a Copy of a new clipboard entry to the CL3 history. (left edit control)`n"
		. "This may resolve some conflicts when other programs or scripts access the clipboard.`n"
		. "Increasing this value may work around this issue.`n`n"
		. "A value for a Paste Delay (right edit control) can also be set."
	, "CL3 Clipboard delay Help", 32)
}

FoldersHelp(*) {
	MsgBox("[expert setting]`n`n"
		. "By default CL3 uses two folders to store History/Plugin and Templates data.`n`n"
		. "ClipData:`n`n"
		. "%A_ScriptDir%\ClipData\`n`n"
		. "* AutoReplace`n"
		. "* ClipChain`n"
		. "* History`n"
		. "* Slots`n`n"
		. "Templates:`n`n"
		. "%A_ScriptDir%\Templates\`n`n"
		. "You can change the path for one or both of these, separate them with a semi-colon (;).`n"
		. "To only set the Templates folder start with semi-colon ;My_Preferred_Path_to_Templates_folder\`n`n"
		. 'Omit "ClipData\" and "Templates\" as those are automatically appended by CL3`n`n'
		. "Tip: if you use %A_AppData% - do add \CL3 as in %A_AppData%CL3"
	, "CL3 Clipboard folders Help", 32)
}

; https://autohotkey.com/board/topic/76540-function-seteditcuebanner-ahk-l/
SetEditCueBanner(HWND, Cue) {
   Static EM_SETCUEBANNER := (0x1500 + 1)
   Return DllCall("User32.dll\SendMessageW", "Ptr", HWND, "Uint", EM_SETCUEBANNER, "Ptr", True, "WStr", Cue)
}
