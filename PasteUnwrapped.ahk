/*

Plugin            : PasteUnwrapped()
Purpose           : Paste current clipboard (top most in menu) unwrapped (one single line)
Version           : 2.0

History:
- first version 14 June 2017

*/

PasteUnwrapped(Text)	{
	 text := Trim(RegExReplace(text, "ims)\s+", " "), "`n`r`t ")
	 return text
	}

