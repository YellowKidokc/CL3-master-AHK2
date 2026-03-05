/*
Name             : DPI
Purpose          : Return scaling factor or calculate position/values for AHK controls (font size, position (x y), width, height)
Version          : 2.0
Source           : https://github.com/hi5/dpi
License          : see license.txt (GPL 2.0)
Documentation    : See readme.md @ https://github.com/hi5/dpi
*/

DPI(in:="", setdpi:=1)
	{
	 static dpi := 1
	 if (setdpi != 1)
		dpi := setdpi
	 try
		AppliedDPI := RegRead("HKEY_CURRENT_USER\Control Panel\Desktop\WindowMetrics", "AppliedDPI")
	 catch
		AppliedDPI := 96
	 if (AppliedDPI = 96)
		AppliedDPI := 96
	 if (dpi != 1)
		AppliedDPI := dpi
	 factor := AppliedDPI / 96
	 if !in
		Return factor

	 out := ""
	 Loop Parse, in, A_Space . A_Tab
		{
		 option := A_LoopField
		 if RegExMatch(option, "i)(w0|h0|h-1|xp|yp|xs|ys|xm|ym)$") or RegExMatch(option, "i)(icon|hwnd)") ; these need to be bypassed
			out .= option A_Space
		 else if RegExMatch(option, "i)^\*{0,1}(x|xp|y|yp|w|h|s)[-+]{0,1}\K(\d+)", &number) ; should be processed
			out .= StrReplace(option, number[0], Round(Integer(number[0]) * factor)) A_Space
		 else ; the rest can be bypassed as well (variable names etc)
			out .= option A_Space
		}
	 Return Trim(out)
	}
