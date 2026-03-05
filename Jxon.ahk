; Jxon - JSON for AutoHotkey v2
; Converted from cocobelgica's AutoHotkey-JSON

Jxon_Load(&src, args*) {
	static q := Chr(34)
	key := "", is_key := false
	stack := [tree := []]
	is_arr := Map()
	is_arr.Set(ObjPtr(tree), 1)
	next := q . "{[01234567890-tfn"
	pos := 0
	while ((ch := SubStr(src, ++pos, 1)) != "") {
		if InStr(" `t`n`r", ch)
			continue
		if !InStr(next, ch, true) {
			ln := StrSplit(SubStr(src, 1, pos), "`n").Length
			col := pos - InStr(src, "`n",, -(StrLen(src)-pos+1))
			msg := Format("{}: line {} col {} (char {})"
			,   (next == "")      ? "Extra data"
			  : (next == "'")     ? "Unterminated string starting at"
			  : (next == "\")     ? "Invalid \escape"
			  : (next == ":")     ? "Expecting ':' delimiter"
			  : (next == q)       ? "Expecting object key enclosed in double quotes"
			  : (next == q . "}") ? "Expecting object key enclosed in double quotes or object closing '}'"
			  : (next == ",}")    ? "Expecting ',' delimiter or object closing '}'"
			  : (next == ",]")    ? "Expecting ',' delimiter or array closing ']'"
			  :                     "Expecting JSON value"
			, ln, col, pos)
			throw Error(msg, -1, ch)
		}
		obj := stack[1]
		is_array := is_arr.Has(ObjPtr(obj)) ? is_arr[ObjPtr(obj)] : 0

		if (i := InStr("{[", ch)) {
			val := (ch == "{") ? Map() : []
			is_array ? obj.Push(val) : obj[key] := val
			stack.InsertAt(1, val)
			is_arr[ObjPtr(val)] := !(is_key := ch == "{")
			next := q . (is_key ? "}" : "{[]0123456789-tfn")
		}
		else if InStr("}]", ch) {
			stack.RemoveAt(1)
			next := stack[1] == tree ? "" : (is_arr.Has(ObjPtr(stack[1])) && is_arr[ObjPtr(stack[1])]) ? ",]" : ",}"
		}
		else if InStr(",:", ch) {
			is_key := (!is_array && ch == ",")
			next := is_key ? q : q . "{[0123456789-tfn"
		}
		else {
			if (ch == q) {
				i := pos
				while (i := InStr(src, q,, i+1)) {
					val := StrReplace(SubStr(src, pos+1, i-pos-1), "\\", "\u005C")
					if (SubStr(val, -1) != "\")
						break
				}
				if !i {
					pos--
					next := "'"
					continue
				}
				pos := i
				val := StrReplace(val, "\/", "/")
				val := StrReplace(val, "\" . q, q)
				val := StrReplace(val, "\b", "`b")
				val := StrReplace(val, "\f", "`f")
				val := StrReplace(val, "\n", "`n")
				val := StrReplace(val, "\r", "`r")
				val := StrReplace(val, "\t", "`t")

				i := 0
				while (i := InStr(val, "\",, i+1)) {
					if (SubStr(val, i+1, 1) != "u") {
						pos -= StrLen(SubStr(val, i))
						next := "\"
						continue 2
					}
					xxxx := Abs("0x" . SubStr(val, i+2, 4))
					val := SubStr(val, 1, i-1) . Chr(xxxx) . SubStr(val, i+6)
				}
				if is_key {
					key := val
					next := ":"
					continue
				}
			}
			else {
				val := SubStr(src, pos, (i := RegExMatch(src, "[\]\},\s]|$",, pos)) - pos)
				if IsNumber(val) {
					if IsInteger(val)
						val += 0
				}
				else if (val == "true")
					val := 1
				else if (val == "false")
					val := 0
				else if (val == "null")
					val := ""
				else {
					pos--
					next := "#"
					continue
				}
				pos += i - 1
			}
			is_array ? obj.Push(val) : obj[key] := val
			next := obj == tree ? "" : is_array ? ",]" : ",}"
		}
	}
	return tree[1]
}

Jxon_Dump(obj, indent:="", lvl:=1) {
	static q := Chr(34)

	if IsObject(obj) {
		if (Type(obj) != "Array" && Type(obj) != "Map" && Type(obj) != "Object")
			throw Error("Object type not supported.", -1, Type(obj))

		is_array := (Type(obj) = "Array")

		if IsInteger(indent) {
			if (indent < 0)
				throw Error("Indent parameter must be a positive integer.", -1, indent)
			spaces := indent
			indent := ""
			Loop spaces
				indent .= " "
		}
		indt := ""
		Loop indent ? lvl : 0
			indt .= indent

		lvl += 1
		out := ""
		if is_array {
			for v in obj {
				if (indent)
					out .= indt
				out .= Jxon_Dump(v, indent, lvl)
				out .= indent ? ",`n" : ","
			}
		} else {
			for k, v in (obj is Map ? obj : obj.OwnProps()) {
				if (indent)
					out .= indt
				out .= Jxon_Dump(String(k), indent, lvl)
				out .= indent ? ": " : ":"
				out .= Jxon_Dump(v, indent, lvl)
				out .= indent ? ",`n" : ","
			}
		}

		if (out != "") {
			out := Trim(out, ",`n" . indent)
			if (indent != "")
				out := "`n" . indt . out . "`n" . SubStr(indt, StrLen(indent)+1)
		}
		return is_array ? "[" . out . "]" : "{" . out . "}"
	}

	if IsNumber(obj)
		return obj

	if (obj != "") {
		obj := StrReplace(obj, "\", "\\")
		obj := StrReplace(obj, "/", "\/")
		obj := StrReplace(obj, q, "\" . q)
		obj := StrReplace(obj, "`b", "\b")
		obj := StrReplace(obj, "`f", "\f")
		obj := StrReplace(obj, "`n", "\n")
		obj := StrReplace(obj, "`r", "\r")
		obj := StrReplace(obj, "`t", "\t")

		while RegExMatch(obj, "[^\x20-\x7e]", &m)
			obj := StrReplace(obj, m[0], Format("\u{:04X}", Ord(m[0])))
	}
	return q . obj . q
}
