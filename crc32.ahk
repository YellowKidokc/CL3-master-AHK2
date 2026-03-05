; removed "LC_" - source by jNizM ; https://github.com/ahkscript/libcrypt.ahk/blob/master/src/CRC32.ahk
; Converted to AHK v2

CRC32(string, encoding := "UTF-8") {
	chrlength := (encoding = "CP1200" || encoding = "UTF-16") ? 2 : 1
	length := (StrPut(string, encoding) - 1) * chrlength
	data := Buffer(length, 0)
	StrPut(string, data, Floor(length / chrlength), encoding)
	hMod := DllCall("Kernel32.dll\LoadLibrary", "Str", "Ntdll.dll")
	CRC32val := DllCall("Ntdll.dll\RtlComputeCrc32", "UInt", 0, "Ptr", data, "UInt", length, "UInt")
	CRC := Format("{:08x}", CRC32val)
	DllCall("Kernel32.dll\FreeLibrary", "Ptr", hMod)
	return CRC
}
