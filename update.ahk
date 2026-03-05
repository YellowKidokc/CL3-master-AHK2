/*
Basic update routine for compiled script
Converted to AHK v2
*/

update(v)
    {
     whr := ComObject("WinHttp.WinHttpRequest.5.1")
     whr.Open("GET", "https://api.github.com/repos/hi5/cl3/releases/latest", true)
     whr.Send()
     whr.WaitForResponse()
     text := whr.ResponseText
     if RegExMatch(text, 'U)\x22tag_name\x22:\x22\K(.*)\x22', &verMatch)
         version1 := verMatch[1]
     else
         version1 := ""
     If (v != version1) and (version1 != "")
         {
          result := MsgBox("A new version seems to be available.`nVisit website to download it?`n`n(See releases/assets on Github)", "New version of CL3", "YesNo")
          if (result = "No")
             Return
          Run("https://github.com/hi5/CL3/releases")
          Return
         }
     OSDTIP_Pop("CL3: No Updates", "No update available it seems", -1000, "W130 H60 U1")
    }
