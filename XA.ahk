/*

Save/Load Arrays - trueski
- original source  : http://www.autohotkey.com/board/topic/85461-ahk-l-saveload-arrays/
- Updated source   : https://github.com/hi5/XA (see notes)
  AutoHotkey forum : https://autohotkey.com/boards/viewtopic.php?f=6&t=34849

Converted to AHK v2

Examples:

XA_Save("Array", Path) ; put variable name in quotes
XA_Load(Path)          ; the name of the variable containing the array is returned

*/

XA_Save(ArrayName, Path) {
	 global
	 local content
	 try FileDelete(Path)
	 catch {
	 }
	 content := '<?xml version="1.0" encoding="UTF-8"?>`n<' . ArrayName . '>`n' . XA_ArrayToXML(%ArrayName%) . '`n</' . ArrayName . '>'
	 try {
		FileAppend(content, Path, "UTF-8")
		Return 0
	 } catch {
		Return 1
	 }
	}

XA_Load(Path) {
	 global
	 local XMLText, XMLObj, XMLRoot

	 If (!FileExist(Path))
		Return 1

	 XMLText := FileRead(Path)

	 If !InStr(XMLText, "<?xml")
		Return 1

	 XMLText := StrReplace(XMLText, " & ", " &amp; ")

	 Try
		{
		 XMLObj := XA_LoadXML(XMLText)
		 XMLObj := XMLObj.selectSingleNode("/*")
		 XMLRoot := XMLObj.nodeName
		 %XMLRoot% := XA_XMLToArray(XMLObj.childNodes)
		}
	 Catch
		{
		 Return 1
		}

	 Return XMLRoot
	}

XA_XMLToArray(nodes, NodeName:="") {
	 Obj := Map()

	 for node in nodes
		{
		 if (node.nodeName != "#text")
			{
			 If (node.nodeName == "Invalid_Name" && node.getAttribute("ahk") == "True")
				NodeName := node.getAttribute("id")
			 Else
				NodeName := node.nodeName
			}

		 else
			Obj := node.nodeValue

		 if node.hasChildNodes
			{
			 If ((node.nextSibling.nodeName = node.nodeName || node.nodeName = node.previousSibling.nodeName) && node.nodeName != "Invalid_Name" && node.getAttribute("ahk") != "True")
				{
				 If (!node.previousSibling.nodeName)
					{
					 if !IsObject(Obj)
						Obj := Map()
					 Obj[NodeName] := Map()
					 ItemCount := 0
					}
				 ItemCount++

				 If (node.getAttribute("id") != "")
					Obj[NodeName][node.getAttribute("id")] := XA_XMLToArray(node.childNodes, node.getAttribute("id"))

				 Else
					Obj[NodeName][ItemCount] := XA_XMLToArray(node.childNodes, ItemCount)
					}

			 Else {
				if !IsObject(Obj)
					Obj := Map()
				Obj[NodeName] := XA_XMLToArray(node.childNodes, NodeName)
			 }
			}
		}
	 Return Obj
	}

XA_LoadXML(&data) {
	 o := ComObject("MSXML2.DOMdocument.6.0")
	 o.async := false
	 o.LoadXML(data)
	 return o
	}

XA_ArrayToXML(theArray, tabCount:=1, NodeName:="") {
	 local tabSpace, extraTabSpace, tag, val, theXML, root
	 tabCount++
	 tabSpace := ""
	 extraTabSpace := ""
	 theXML := ""

	 if (!IsObject(theArray))
		{
		 root := theArray
		 global
		 theArray := %root%
		}

	 tc := 0
	 While (++tc < tabCount)
		{
		 tabSpace .= "`t"
		 extraTabSpace := tabSpace . "`t"
		}

	 for tag, val in theArray
		{
		 If (!IsObject(val))
			{
			 If (XA_InvalidTag(tag))
				theXML .= "`n" . tabSpace . '<Invalid_Name id="' . XA_XMLEncode(String(tag)) . '" ahk="True">' . XA_XMLEncode(String(val)) . '</Invalid_Name>'
			 Else
				theXML .= "`n" . tabSpace . "<" . tag . ">" . XA_XMLEncode(String(val)) . "</" . tag . ">"
			}

		 Else
			{
			 If (XA_InvalidTag(tag))
				theXML .= "`n" . tabSpace . '<Invalid_Name id="' . XA_XMLEncode(String(tag)) . '" ahk="True">' . "`n" . XA_ArrayToXML(val, tabCount, "") . "`n" . tabSpace . '</Invalid_Name>'
			 Else
				theXML .= "`n" . tabSpace . "<" . tag . ">" . "`n" . XA_ArrayToXML(val, tabCount, "") . "`n" . tabSpace . "</" . tag . ">"
			}
		}

	 theXML := SubStr(theXML, 2)
	 Return theXML
	}

XA_InvalidTag(Tag) {
	 Char1   := SubStr(String(Tag), 1, 1)
	 Chars3  := SubStr(String(Tag), 1, 3)
	 StartChars := "~``!@#$%^&*()_-+={[}]|\:;`"'<,>.?/1234567890 `t`n`r"
	 Chars := "`"'<>=/ `t`n`r"

	 Loop Parse, StartChars
		{
		 If (Char1 = A_LoopField)
			Return 1
		}

	 Loop Parse, Chars
		{
		 If (InStr(String(Tag), A_LoopField))
			Return 1
		}

	 If (Chars3 = "xml")
		Return 1

	 Return 0
	}

XA_XMLEncode(Text) {
	 Text := StrReplace(Text, "&", "&amp;")
	 Text := StrReplace(Text, "<", "&lt;")
	 Text := StrReplace(Text, ">", "&gt;")
	 Text := StrReplace(Text, '"', "&quot;")
	 Text := StrReplace(Text, "'", "&apos;")
	 Return XA_CleanInvalidChars(Text)
	}

XA_CleanInvalidChars(text, replace:="") {
		re := "[^\x09\x0A\x0D\x20-\x{D7FF}\x{E000}-\x{FFFD}\x{10000}-\x{10FFFF}]"
		Return RegExReplace(text, re, replace)
	}
