/*

Plugin            : LowerReplaceSpace()
Purpose           : Paste current clipboard (top most in menu) as lower case
Version           : 2.0
CL3 version       : 2.0

*/

LowerReplaceSpace(Text)	{
	 text := StrLower(text)
	 text := StrReplace(text, A_Space, "_")
	 return text
	}
