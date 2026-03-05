Settings()
	{
	 global
	 local SettingsOutputVar, folders, tmpfolder

	 CyclePlugins := []
	 ini := A_ScriptDir "\settings.ini"
	 ; CyclePlugins
	 SettingsOutputVar := IniRead(ini, "plugins", "CyclePlugins", "ERROR")
	 If (SettingsOutputVar = "ERROR")
		{
		 IniWrite("Title,Lower,Upper,LowerReplaceSpace", ini, "plugins", "CyclePlugins")
		 SettingsOutputVar := "Title,Lower,Upper,LowerReplaceSpace"
		}
	 Loop Parse, SettingsOutputVar, ","
		CyclePlugins.push(A_LoopField)
	 CyclePlugins.InsertAt(1, "<none>") ; v2: arrays are 1-based, use index 1 for the "<none>" marker
	 Stats_Create()
	 MaxHistory          := IniRead(ini, "settings", "MaxHistory", "150")
	 MenuWidth           := IniRead(ini, "settings", "MenuWidth", "40")
	 MoreHistory         := IniRead(ini, "settings", "MoreHistory", "18")
	 AllowDupes          := IniRead(ini, "settings", "AllowDupes", "0")
	 SearchWindowWidth   := IniRead(ini, "settings", "SearchWindowWidth", "595")
	 SearchWindowHeight  := IniRead(ini, "settings", "SearchWindowHeight", "300")
	 ShowLines           := IniRead(ini, "settings", "ShowLines", "0")
	 ShowTime            := IniRead(ini, "settings", "ShowTime", "0")
	 AutoReplaceTrayTip  := IniRead(ini, "settings", "AutoReplaceTrayTip", "0")
	 CopyDelay           := IniRead(ini, "settings", "CopyDelay", "0")
	 PasteDelay          := IniRead(ini, "settings", "PasteDelay", "50")
	 ActivateApi         := IniRead(ini, "settings", "ActivateApi", "0")
	 ActivateBackup      := IniRead(ini, "settings", "ActivateBackup", "0")
	 BackupTimer         := IniRead(ini, "settings", "BackupTimer", "10")
	 Exclude             := IniRead(ini, "settings", "Exclude", "0")
	 LineFormat          := IniRead(ini, "settings", "LineFormat", "\t(\l line),\t(\l lines)")
	 TimeFormat          := IniRead(ini, "settings", "TimeFormat", "@|HH:mm")
	 SettingsFolders     := IniRead(ini, "settings", "SettingsFolders", "0")
	 ShowSpecial         := IniRead(ini, "settings", "ShowSpecial", "1")
	 ShowTemplates       := IniRead(ini, "settings", "ShowTemplates", "1")
	 ShowYank            := IniRead(ini, "settings", "ShowYank", "1")
	 ShowMorehistory     := IniRead(ini, "settings", "ShowMorehistory", "1")
	 ShowExit            := IniRead(ini, "settings", "ShowExit", "1")
	 ActivateCmdr        := IniRead(ini, "plugins", "ActivateCmdr", "0")
	 If (Exclude = 0) or (Exclude = "Error")
		Exclude := ""
	 Exclude := StrLower(Exclude)

	 MenuWidth := Integer(MenuWidth)
	 if (MenuWidth < 20) or (MenuWidth > 100)
		MenuWidth := 40

	 If (SettingsFolders = "") or (SettingsFolders = "ERROR") or (SettingsFolders = 0)
		SettingsFolders := ""

	 folders := SettingsFolders

	 ; Replace A_ built-in variable references in folder paths
	 ahk_vars := Map(
		"A_AppData", A_AppData,
		"A_AppDataCommon", A_AppDataCommon,
		"A_Desktop", A_Desktop,
		"A_DesktopCommon", A_DesktopCommon,
		"A_MyDocuments", A_MyDocuments,
		"A_StartMenuCommon", A_StartMenuCommon,
		"A_Programs", A_Programs,
		"A_ProgramsCommon", A_ProgramsCommon,
		"A_ProgramFiles", A_ProgramFiles,
		"A_StartMenu", A_StartMenu,
		"A_Startup", A_Startup,
		"A_StartupCommon", A_StartupCommon,
		"A_ScriptDir", A_ScriptDir,
		"A_UserName", A_UserName,
		"A_WinDir", A_WinDir,
		"A_WorkingDir", A_WorkingDir
	 )
	 ; Also support A_UserProfile via EnvGet
	 ahk_vars["A_UserProfile"] := EnvGet("USERPROFILE")

	 for varName, varValue in ahk_vars
		folders := StrReplace(folders, "%" varName "%", varValue)

	 If InStr(TimeFormat, "|")
		{
		 TimeFormatIndicator := StrSplit(TimeFormat, "|")[1]
		 If IsNumber(TimeFormatIndicator)
		 	TimeFormatIndicator := Chr(Integer(TimeFormatIndicator))
		 TimeFormatIndicator := A_Space TimeFormatIndicator A_Space
		 TimeFormatTime := StrSplit(TimeFormat, "|")[2]
		}
	 Else
		{
		 TimeFormatIndicator := ""
		 TimeFormatTime := TimeFormat
		}

	 ClipDataFolder := StrSplit(folders, ";")[1] "\ClipData\"
	 If (ClipDataFolder = "\ClipData\")
		ClipDataFolder := A_ScriptDir "\ClipData\"
	 TemplateFolder := StrSplit(folders, ";")[2] "\Templates\"
	 If (TemplateFolder = "\Templates\")
		TemplateFolder := A_ScriptDir "\Templates\"

	 If !FileExist(ClipDataFolder)
		DirCreate(ClipDataFolder)
	 Loop Parse, "History,ClipChain,AutoReplace,Slots,", ","
		{
		 If (A_LoopField = "")
			continue
		 If !FileExist(ClipDataFolder A_LoopField)
			DirCreate(ClipDataFolder A_LoopField)
		}

	 If !FileExist(TemplateFolder)
		DirCreate(TemplateFolder)

	 LineTextFormat := StrSplit(StrReplace(LineFormat, "\t", A_Tab), ",")

	 SettingsObj := Map("MaxHistory", MaxHistory, "ActivateCmdr", ActivateCmdr)
	 If (XA_Load(A_ScriptDir "\stats.xml") = 1)
		{
		 MsgBox("Stats.xml seems to be corrupt, starting new empty Stats.", "Stats", 16)
		 FileDelete(A_ScriptDir "\Stats.xml")
		 Stats_Create()
		}
	 Settings_Default()
	}

Settings_Default()
	{
	 global
	 Settings_Plugins := Map("Plugins", "Title,Lower,Upper,LowerReplaceSpace")
	 Settings_Hotkeys := Map(
		"hk_menu", "^!v",
		"hk_menu2", "",
		"hk_plaintext", "^+v",
		"hk_slots", "^#F12",
		"hk_clipchain", "^#F11",
		"hk_clipchainpaste", "^v",
		"hk_fifo", "^#F10",
		"hk_search", "^#h",
		"hk_cyclemodkey", "LWin",
		"hk_cyclebackward", "v",
		"hk_cycleforward", "c",
		"hk_cycleplugins", "f",
		"hk_cyclecancel", "x",
		"hk_slot1", ">^1",
		"hk_slot2", ">^2",
		"hk_slot3", ">^3",
		"hk_slot4", ">^4",
		"hk_slot5", ">^5",
		"hk_slot6", ">^6",
		"hk_slot7", ">^7",
		"hk_slot8", ">^8",
		"hk_slot9", ">^9",
		"hk_slot0", ">^0",
		"hk_slotsmenu", "",
		"hk_BypassAutoReplace", "",
		"hk_cmdr", "#j"
	 )
	 Settings_Settings := Map(
		"MaxHistory", "150",
		"MenuWidth", 40,
		"MoreHistory", 26,
		"AllowDupes", 0,
		"SearchWindowWidth", 595,
		"SearchWindowHeight", 300,
		"ActivateApi", 0,
		"ShowLines", 1,
		"ShowTime", 0,
		"AutoReplaceTrayTip", 0,
		"CopyDelay", 0,
		"PasteDelay", 50,
		"ShowSpecial", 1,
		"ShowYank", 1,
		"ShowTemplates", 1,
		"ShowMorehistory", 1,
		"ShowExit", 1,
		"Exclude", "",
		"TimeFormat", "@|HH:mm",
		"LineFormat", "\t(\l line),\t(\l lines)"
	 )
	}

Stats_Create()
	{
	 global stats
	 if !FileExist(A_ScriptDir "\stats.xml")
		{
		 stats := Map()
		 stats["cyclepaste"] := 0
		 stats["cycleplugins"] := 0
		 stats["menu"] := 0
		 stats["templates"] := 0
		 stats["slots"] := 0
		 stats["clipchain"] := 0
		 stats["search"] := 0
		 stats["edit"] := 0
		 stats["fifo"] := 0
		 stats["templates"] := 0
		 stats["copieditems"] := 0
		 XA_Save("stats", A_ScriptDir "\stats.xml")
		}
	}

Settings_Hotkeys()
	{
	 global
	 local ini, index
	 ini := A_ScriptDir "\settings.ini"

	 hk_menu           := IniRead(ini, "Hotkeys", "hk_menu", "^!v")
	 hk_menu2          := IniRead(ini, "Hotkeys", "hk_menu2", "ERROR")
	 hk_plaintext      := IniRead(ini, "Hotkeys", "hk_plaintext", "^+v")
	 hk_slots          := IniRead(ini, "Hotkeys", "hk_slots", "^#F12")
	 hk_clipchain      := IniRead(ini, "Hotkeys", "hk_clipchain", "^#F11")
	 hk_clipchainpaste := IniRead(ini, "Hotkeys", "hk_clipchainpaste", "^v")
	 hk_fifo           := IniRead(ini, "Hotkeys", "hk_fifo", "^#F10")
	 hk_search         := IniRead(ini, "Hotkeys", "hk_search", "^#h")
	 hk_cyclemodkey    := IniRead(ini, "Hotkeys", "hk_cyclemodkey", "LWin")
	 hk_cyclebackward  := IniRead(ini, "Hotkeys", "hk_cyclebackward", "v")
	 hk_cycleforward   := IniRead(ini, "Hotkeys", "hk_cycleforward", "c")
	 hk_cycleplugins   := IniRead(ini, "Hotkeys", "hk_cycleplugins", "f")
	 hk_cyclecancel    := IniRead(ini, "Hotkeys", "hk_cyclecancel", "x")
	 hk_cmdr           := IniRead(ini, "Hotkeys", "hk_cmdr", "#j")
	 hk_BypassAutoReplace := IniRead(ini, "Hotkeys", "hk_BypassAutoReplace", "ERROR")
	 If (hk_BypassAutoReplace = "ERROR")
	 	hk_BypassAutoReplace := ""
	 If (hk_menu2 = "ERROR")
	 	hk_menu2 := ""

	 ; Slot hotkeys stored in a Map
	 hk_slot := Map()
	 Loop 10
		{
		 index := A_Index - 1
		 hk_slot[index] := IniRead(ini, "Hotkeys", "hk_slot" index, ">^" index)
		 If (hk_slot[index] != "")
			Try
				Hotkey(hk_slot[index], hk_slotpaste)
		}
	 ; Also set individual globals for GUI compatibility
	 hk_slot0 := hk_slot[0], hk_slot1 := hk_slot[1], hk_slot2 := hk_slot[2]
	 hk_slot3 := hk_slot[3], hk_slot4 := hk_slot[4], hk_slot5 := hk_slot[5]
	 hk_slot6 := hk_slot[6], hk_slot7 := hk_slot[7], hk_slot8 := hk_slot[8]
	 hk_slot9 := hk_slot[9]

	 hk_slotsmenu := IniRead(ini, "Hotkeys", "hk_slotsmenu", "ERROR")
	 If (hk_slotsmenu = "ERROR")
		hk_slotsmenu := ""
	 If (hk_slotsmenu != "")
		{
		 fn := ShowMenu.Bind("QuickSlotsMenu")
		 Try
			Hotkey(hk_slotsmenu, fn)
		}

	 If !hk_menu
		hk_menu := "^+v"
	 Try
		Hotkey(hk_menu, hk_menu_handler)
	 If hk_menu2
		Try
			Hotkey(hk_menu2, hk_menu2_handler)
	 If hk_plaintext
		Try
			Hotkey(hk_plaintext, hk_plaintext_handler)
	 Hotkey(hk_clipchain, hk_clipchain_handler)
	 If hk_BypassAutoReplace
		Try
			Hotkey(hk_BypassAutoReplace, hk_BypassAutoReplace_handler)

	 if (hk_clipchainpaste = "^v")
		Hotkey("$" hk_clipchainpaste, hk_clipchainpaste_defaultpaste)

	 HotIf((*) => ClipChainActive())
	 Hotkey("$" hk_clipchainpaste, ClipChainPasteDoubleClick)
	 HotIf()
	 If hk_fifo
		Try
			Hotkey(hk_fifo, hk_fifo_handler)
	 If hk_slots
		Try
			Hotkey(hk_slots, hk_slots_handler)
	 If hk_search
		Try
			Hotkey(hk_search, hk_search_handler)
	 If hk_cyclemodkey
		{
		 If hk_cyclebackward
			{
			 Try
				Hotkey(hk_cyclemodkey " & " hk_cyclebackward, hk_cyclebackward_handler)
			 Try
				Hotkey(hk_cyclemodkey " & " hk_cyclebackward " up", hk_cyclebackward_up_handler)
			}
		 If hk_cycleforward
			{
			 Try
				Hotkey(hk_cyclemodkey " & " hk_cycleforward, hk_cycleforward_handler)
			 Try
				Hotkey(hk_cyclemodkey " & " hk_cycleforward " up", hk_cycleforward_up_handler)
			}
		 If hk_cycleplugins
			{
			 Try
				Hotkey(hk_cyclemodkey " & " hk_cycleplugins, hk_cycleplugins_handler)
			 Try
				Hotkey(hk_cyclemodkey " & " hk_cycleplugins " up", hk_cycleplugins_up_handler)
			}
		 If hk_cyclebackward
			Try
				Hotkey(hk_cyclemodkey " & " hk_cyclecancel, hk_cyclecancel_handler)
		}
	 If hk_cmdr
		Try
			Hotkey(hk_cmdr, hk_cmdr_handler)
	 if !ActivateCmdr
		Try
			Hotkey(hk_cmdr, "Off")
	}

Settings_PasteShortCuts()
	{
	 global PasteShortCuts := Map()
	 i := A_ScriptDir "\PasteShortCuts.ini"
	 If !FileExist(i)
		Return
	 OutputVarSectionNames := IniRead(i)
	 Loop Parse, OutputVarSectionNames, "`n", "`r"
	 	{
		 section := A_LoopField
		 OutputVarPrograms := IniRead(i, section, "Programs", "0")
		 OutputVarKey := IniRead(i, section, "Key", "0")
		 OutputVarPrograms := StrLower(OutputVarPrograms)
		 OutputVarPrograms := Trim(RegExReplace(OutputVarPrograms, "ms)\s*,\s*", ","), ",")
		 If !(OutputVarPrograms ~= "i)^(0|error)$")
			{
			 if !PasteShortCuts.Has(section)
				PasteShortCuts[section] := Map()
		 	 PasteShortCuts[section]["programs"] := OutputVarPrograms
			}
		 If !(OutputVarKey ~= "i)^(0|error)$")
			{
			 if !PasteShortCuts.Has(section)
				PasteShortCuts[section] := Map()
		 	 PasteShortCuts[section]["key"] := Trim(OutputVarKey, Chr(34))
			}
		 OutputVarPrograms := "", OutputVarKey := ""
	 	}
	}
