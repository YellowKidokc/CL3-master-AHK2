/**
 * Lib: JSON.ahk
 *     JSON lib for AutoHotkey v2
 *     Wrapper around Jxon_Load / Jxon_Dump for backward compatibility
 */

class JSON {
	static Load(&text, reviver:="") {
		return Jxon_Load(&text)
	}
	static Dump(value, replacer:="", space:="") {
		return Jxon_Dump(value, space)
	}
}
