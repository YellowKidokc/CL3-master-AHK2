/*

Plugin            : AutoReplace()
Version           : 1.7
CL3 version       : 1.4

History:
- 1.7 Don't use clipboard in String Replacement but text variable
- 1.6 Attempt to prevent XMLRoot error - https://github.com/hi5/CL3/issues/15
- 1.5 Optional tray menu "replace actions" indicator (reverted change, code commented, see "TrayTip" code near the end)
- 1.4 Added fixed setting for Bypass (excell.exe) to avoid problems pasting content in Excel, default setting inactive
- 1.3 Added A_Space/A_Tab/%A_Space%/%A_Tab% for space/tab Replacement
- 1.2 Added 'Try' as a fix for rare issue

*/

AutoReplaceInit() {
	global AutoReplace, ClipDataFolder, AutoReplaceGui

	If !IsObject(AutoReplace)
		{
		 if FileExist(ClipDataFolder "AutoReplace\AutoReplace.xml")
			{
			 If (XA_Load(ClipDataFolder "AutoReplace\AutoReplace.xml") = 1)
				{
				 MsgBox("AutoReplace.xml seems to be corrupt, starting a new empty AutoReplace.xml.", "AutoReplace", 16)
				 FileDelete(ClipDataFolder "AutoReplace\AutoReplace.xml")
				 AutoReplace := []
				}
			}
		 else
			{
			 AutoReplace := []
			}
		}

	if !(AutoReplace is Map)
		{
		 ; Ensure Settings sub-map exists
		 if !IsObject(AutoReplace) || !(AutoReplace is Array)
			AutoReplace := []
		}

	; Ensure Settings exists as a Map
	if !AutoReplace.HasProp("Settings")
		AutoReplace.DefineProp("Settings", {Value: Map()})
	if !AutoReplace.Settings.Has("Active")
		AutoReplace.Settings["Active"] := 0
	if !AutoReplace.Settings.Has("Bypass")
		AutoReplace.Settings["Bypass"] := "excel.exe"

	AutoReplaceMenuUpdate()

	; Build AutoReplace GUI
	AutoReplaceGui := Gui(, "AutoReplace")
	AutoReplaceGui.OnEvent("Close", (*) => AutoReplaceGui.Hide())
	AutoReplaceGui.OnEvent("Escape", (*) => AutoReplaceGui.Hide())

	ogcRules := AutoReplaceGui.Add("ListBox", "w200 h170 vRules AltSubmit")
	ogcRules.OnEvent("Change", AutoReplaceList)
	AutoReplaceGui.Add("Text", "xp+220 yp+5 w30", "Name:")
	AutoReplaceGui.Add("Edit", "xp+50 yp-3 w250 vName")
	AutoReplaceGui.Add("Checkbox", "xp yp+30 w80 vType", "RegEx?")
	AutoReplaceGui.Add("Text", "xp-50 yp+30 w50", "Find:")
	AutoReplaceGui.Add("Edit", "xp+50 yp-3 w250 vFind")
	AutoReplaceGui.Add("Text", "xp-50 yp+30 w50", "Replace:")
	AutoReplaceGui.Add("Edit", "xp+50 yp-3 w250 vReplace")
	AutoReplaceGui.Add("Button", "xp yp+40 w60", "New Rule").OnEvent("Click", AutoReplaceAdd)
	AutoReplaceGui.Add("Button", "xp+65 yp w55", "*Delete*").OnEvent("Click", AutoReplaceDelete)
	AutoReplaceGui.Add("Button", "xp+65 yp w55", "Cancel").OnEvent("Click", (*) => AutoReplaceGui.Hide())
	AutoReplaceGui.Add("Button", "xp+65 yp w55", "Save").OnEvent("Click", AutoReplaceSave)
	AutoReplaceGui.Add("GroupBox", "x10 yp+50 w520 h50", "General setting(s)")
	AutoReplaceGui.Add("Text", "xp+10 yp+25", "Bypass (a CSV list of Exe)")
	AutoReplaceGui.Add("Edit", "xp+130 yp-3 w365 vBypass")

	AutoReplaceUpdateListbox()
}

AutoReplaceUpdateListbox() {
	global AutoReplace, AutoReplaceGui
	RulesList := []
	for k, v in AutoReplace {
		if (v is Map) && v.Has("name")
			RulesList.Push(v["name"])
		else if IsObject(v) && v.HasProp("name")
			RulesList.Push(v.name)
	}
	if (RulesList.Length = 0)
		RulesList.Push("First rule")
	AutoReplaceGui["Rules"].Delete()
	AutoReplaceGui["Rules"].Add(RulesList)
	AutoReplaceUpdate(1)
}

ShowAutoReplace(*) {
	global AutoReplaceGui
	AutoReplaceGui.Show("AutoSize Center")
}

AutoReplaceUpdate(index) {
	global AutoReplace, AutoReplaceGui
	if (AutoReplace.Length >= index) && IsObject(AutoReplace[index]) {
		v := AutoReplace[index]
		if (v is Map) {
			AutoReplaceGui["Name"].Value := v.Has("name") ? v["name"] : ""
			AutoReplaceGui["Type"].Value := v.Has("type") ? v["type"] : 0
			AutoReplaceGui["Find"].Value := v.Has("find") ? v["find"] : ""
			AutoReplaceGui["Replace"].Value := v.Has("replace") ? v["replace"] : ""
		}
	}
	AutoReplaceGui["Bypass"].Value := AutoReplace.Settings.Has("Bypass") ? AutoReplace.Settings["Bypass"] : ""
}

AutoReplaceAdd(*) {
	global AutoReplaceGui
	AutoReplaceGui["Name"].Value := ""
	AutoReplaceGui["Type"].Value := 0
	AutoReplaceGui["Find"].Value := ""
	AutoReplaceGui["Replace"].Value := ""
}

AutoReplaceDelete(*) {
	global AutoReplace, AutoReplaceGui
	saved := AutoReplaceGui.Submit(false)
	ruleIdx := saved.Rules
	name := saved.Name
	result := MsgBox("Delete " name "?", "Delete", 52)
	if (result = "No")
		Return
	XMLSave("AutoReplace", "-" A_Now)
	AutoReplace.RemoveAt(ruleIdx)
	XMLSave("AutoReplace")
	AutoReplaceUpdateListbox()
}

AutoReplaceList(ctrl, *) {
	AutoReplaceUpdate(ctrl.Value)
}

AutoReplaceSave(*) {
	global AutoReplace, AutoReplaceGui
	saved := AutoReplaceGui.Submit(false)
	AutoReplaceGui.Hide()
	AutoReplace.Settings["Bypass"] := saved.Bypass
	ruleIdx := saved.Rules
	if (ruleIdx = "" || ruleIdx = 0)
		ruleIdx := 1
	if (saved.Find = "")
		Return
	XMLSave("AutoReplace", "-" A_Now)
	name := saved.Name ? saved.Name : "Unnamed rule"
	if (AutoReplace.Length < ruleIdx)
		AutoReplace.Push(Map())
	if !(AutoReplace[ruleIdx] is Map)
		AutoReplace[ruleIdx] := Map()
	AutoReplace[ruleIdx]["name"] := name
	AutoReplace[ruleIdx]["type"] := saved.Type
	AutoReplace[ruleIdx]["find"] := saved.Find
	AutoReplace[ruleIdx]["replace"] := saved.Replace
	XMLSave("AutoReplace")
}

AutoReplaceProcess() {
	global AutoReplace, IconExe, AutoReplaceTrayTip, ClipboardHistoryToggle
	if !AutoReplace.Settings["Active"]
		Return A_Clipboard
	if ClipboardHistoryToggle
		Return A_Clipboard
	if RegExMatch(IconExe, "im)\\(" StrReplace(AutoReplace.Settings["Bypass"], ",", "|") ")$")
		Return

	ClipStore := ClipboardAll()
	ClipStoreText := A_Clipboard
	ClipStoreTextReplace := ClipStoreText

	OnClipboardChange(FuncOnClipboardChange, 0)
	ChangedClipboard := 0
	OutputVarCount := 0
	for k, v in AutoReplace
		{
		 if !(v is Map)
			continue
		 vtype := v.Has("type") ? v["type"] : ""
		 if (vtype = "0") or (vtype = "")
			{
			 Try
				{
				 ReplaceString := v["replace"]
				 if (ReplaceString = "A_Space") || (ReplaceString = "%A_Space%")
					ReplaceString := " "
				 if (ReplaceString = "A_Tab") || (ReplaceString = "%A_Tab%")
					ReplaceString := "`t"
				 ClipStoreTextReplace := StrReplace(ClipStoreTextReplace, v["find"], ReplaceString,, &OutputVarCount)
				 If OutputVarCount
					ChangedClipboard += OutputVarCount
				}
			}
		 else if (vtype = "1")
			{
			 Try
				{
				 ClipStoreTextReplace := RegExReplace(ClipStoreTextReplace, v["find"], v["replace"],, &OutputVarCount)
				 If OutputVarCount
					ChangedClipboard += OutputVarCount
				}
			}
		}
	if (A_Clipboard = ClipStoreText)
		A_Clipboard := ClipStore
	ClipStore := ""
	If ChangedClipboard
		{
		 A_Clipboard := ClipStoreTextReplace
		 If AutoReplaceTrayTip
			OSDTIP_Pop("CL3 AutoReplace", ChangedClipboard " replacement(s)", -750, "W130 H60 U1")
		}
	ClipStoreTextReplace := ""
	OnClipboardChange(FuncOnClipboardChange, 1)
	Return
}

AutoReplaceMenuUpdate() {
	global AutoReplace
	If AutoReplace.Settings["Active"]
		A_TrayMenu.Check("&AutoReplace Active")
	Else
		A_TrayMenu.Uncheck("&AutoReplace Active")
}

; OSDTIP_Pop - notification popup (simplified v2 version)
OSDTIP_Pop(MainText := "", SubText := "", TimeOut := -3000, Options := "") {
	TrayTip(SubText, MainText)
	if (TimeOut < 0)
		SetTimer((*) => TrayTip(), TimeOut)
}
