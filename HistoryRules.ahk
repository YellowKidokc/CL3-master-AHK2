/*

HistoryRules() to read rules from \HistoryRules.ini to allow CL3 to filter
clipboard content before adding it to history, allowing or skipping text

Version           : 2.0
CL3 version       : 2.0

*/

HistoryRules()
	{
	 global HistoryRules := Map()
	 local GlobalSetting, Active, Copy, Filter, SectionNames
	 try
		SectionNames := IniRead(A_ScriptDir "\HistoryRules.ini")
	 catch
		Return
	 If (SectionNames = "")
		Return

	 Loop Parse, SectionNames, "`n", "`r"
		{
		 If (A_LoopField = "Setting")
			{
			 GlobalSetting := IniRead(A_ScriptDir "\HistoryRules.ini", A_LoopField, "Global", "0")
			 If !Integer(GlobalSetting)
				break
			 Copy := IniRead(A_ScriptDir "\HistoryRules.ini", A_LoopField, "Copy", "0")
			 HistoryRules["Copy"] := Copy
			}
		 try
			Active := IniRead(A_ScriptDir "\HistoryRules.ini", A_LoopField, "Active", "")
		 catch
			Active := ""
		 If (Active = "") or (Active = "ERROR")
			continue
		 try
			Filter := IniRead(A_ScriptDir "\HistoryRules.ini", A_LoopField, "filter", "")
		 catch
			Filter := ""
		 If (Filter = "") or (Filter = "ERROR")
			continue
		 HistoryRules[A_LoopField] := Map("Active", Active, "Filter", Filter)
		}
	}
