/*

#include CL3API.ahk

You can modify CL3's clipboard History, Slots and ClipChain via external scripts by using this API.
See docs\cl3api.md

Version           : 1.6
CL3 version       : 1.113

History:
- see cl3apiclass.ahk
- 1.0 initial version

*/

CL3Api_Init(Warning := true) {
	global cl3api, CL3_MaxHistory
	try
		{
		 cl3api := ComObjActive("{01DA04FA-790F-40B6-9FB7-CE6C1D53DC38}")
		 Return true
		}
	catch
		{
		 If Warning
			MsgBox("Error: Can not connect to CL3.`nCheck if it is actually running.", "CL3 API", 16)
		 Return false
		}
}

CL3Api_Close() {
	global cl3api
	cl3api := ""
}

CL3Api_State(toggle) {
	global cl3api
	cl3api.state(toggle)
}

CL3Api_Paste(Data, key := "") {
	global cl3api
	if !IsObject(Data) {
		src := "[" Data "]"
		Data := Jxon_Load(&src)
	}
	cl3api.paste(Jxon_Dump(Data), key)
	return 1
}

CL3Api_Upper(Data) {
	global cl3api
	if !IsObject(Data) {
		src := "[" Data "]"
		Data := Jxon_Load(&src)
	}
	cl3api.upper(Jxon_Dump(Data))
	return 1
}

CL3Api_Lower(Data) {
	global cl3api
	if !IsObject(Data) {
		src := "[" Data "]"
		Data := Jxon_Load(&src)
	}
	cl3api.lower(Jxon_Dump(Data))
	return 1
}

CL3Api_Title(Data) {
	global cl3api
	if !IsObject(Data) {
		src := "[" Data "]"
		Data := Jxon_Load(&src)
	}
	cl3api.title(Jxon_Dump(Data))
	return 1
}

CL3Api_Chain(Data) {
	global cl3api
	cl3api.chain(Jxon_Dump(Data))
	return 1
}

CL3Api_ChainInsertAt(Idx, Data) {
	global cl3api
	cl3api.ChainInsertAt(Idx, Data)
	return 1
}

CL3Api_ChainRemove(Idx) {
	global cl3api
	if !IsObject(Idx)
		cl3api.ChainRemove(Idx)
	else
		for k, v in Idx
			cl3api.ChainRemove(v)
	return 1
}

CL3Api_ChainClear() {
	global cl3api
	cl3api.ChainClear()
	return 1
}

CL3Api_Slot(Idx, Data) {
	global cl3api
	cl3api.Slot(Idx, Data)
	return 1
}

CL3Api_SlotPaste(Idx) {
	global cl3api
	cl3api.SlotPaste(Idx)
	return
}

CL3Api_SlotGet(Idx) {
	global cl3api
	text := cl3api.SlotGet(Idx)
	return text
}

CL3Api_Burst(Data, reverse := 0) {
	global cl3api
	cl3api.burst(Data, reverse)
	return 1
}

CL3Api_Fifo(Data) {
	global cl3api
	cl3api.Fifo(Data)
	return 1
}

CL3Api_Get(Data) {
	global cl3api, CL3_MaxHistory
	if !IsObject(Data) {
		src := "[" Data "]"
		Data := Jxon_Load(&src)
	}
	result := cl3api.get(Jxon_Dump(Data))
	return Jxon_Load(&result)
}

CL3Api_InsertAt(Idx, Data) {
	global cl3api
	cl3api.InsertAt(Idx, Data)
	return 1
}

CL3Api_Remove(Data) {
	global cl3api
	if !IsObject(Data) {
		src := "[" Data "]"
		Data := Jxon_Load(&src)
	}
	result := cl3api.remove(Jxon_Dump(Data))
	return Jxon_Load(&result)
}

CL3Api_Search(SearchString, Results := "-1") {
	global cl3api
	result := cl3api.search(SearchString, Results)
	return Jxon_Load(&result)
}

CL3Api_SearchIdx(SearchString, Results := "-1") {
	global cl3api
	result := cl3api.searchIdx(SearchString, Results)
	return Jxon_Load(&result)
}

CL3Api_GetSetting(setting) {
	global cl3api
	return cl3api.GetSetting(setting)
}
