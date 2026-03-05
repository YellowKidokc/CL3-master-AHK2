; Source: https://gist.github.com/Pulover/5759637
; Forum : http://www.autohotkey.com/board/topic/94364-class-lv-rows-copy-cut-paste-and-drag-listviews/
; Converted to AHK v2

;=======================================================================================
;
; Class LV_Rows
;
; Author: Pulover [Rodolfo U. Batista]
; rodolfoub@gmail.com
;
; Additional functions for ListView controls
;=======================================================================================

Class LV_Rows
{

__New(Hwnd := "") {
	If (Hwnd)
		this.LVHwnd := Hwnd
	this.Slot := [], this.ActiveSlot := 1
	this.CopyData := []
	this.HasChanged := false
}

;=======================================================================================
; Edit Functions
;=======================================================================================

Copy() {
	this.CopyData := []
	LV_Row := 0
	oLV := GuiCtrlFromHwnd(this.LVHwnd)
	Loop {
		LV_Row := oLV.GetNext(LV_Row)
		If !LV_Row
			break
		RowData := this.RowText(LV_Row)
		this.CopyData.Push(RowData)
		CopiedLines := A_Index
	}
	return CopiedLines
}

Cut() {
	this.CopyData := []
	LV_Row := 0
	oLV := GuiCtrlFromHwnd(this.LVHwnd)
	Loop {
		LV_Row := oLV.GetNext(LV_Row)
		If !LV_Row
			break
		RowData := this.RowText(LV_Row)
		this.CopyData.Push(RowData)
		CopiedLines := A_Index
	}
	this.Delete()
	return CopiedLines
}

Paste(Row := 0) {
	If !this.CopyData.Length
		return False
	oLV := GuiCtrlFromHwnd(this.LVHwnd)
	TargetRow := Row ? Row : oLV.GetNext()
	If !TargetRow {
		For each, RowArr in this.CopyData
			oLV.Add(RowArr*)
	} Else {
		LV_Row := TargetRow - 1
		For each, RowArr in this.CopyData
			oLV.Insert(LV_Row + A_Index, RowArr*)
	}
	this.HasChanged := true
	return True
}

Delete() {
	oLV := GuiCtrlFromHwnd(this.LVHwnd)
	If (oLV.GetCount("Selected") = 0)
		return False
	LV_Row := 0
	DeletedLines := 0
	Loop {
		LV_Row := oLV.GetNext(LV_Row - 1)
		If !LV_Row
			break
		oLV.Delete(LV_Row)
		DeletedLines := A_Index
	}
	this.HasChanged := true
	return DeletedLines
}

Move(Up := False) {
	Selections := []
	LV_Row := 0
	oLV := GuiCtrlFromHwnd(this.LVHwnd)
	Critical
	If Up {
		Loop {
			LV_Row := oLV.GetNext(LV_Row)
			If !LV_Row
				break
			If (LV_Row = 1)
				return
			Selections.Push(LV_Row)
		}
		For each, Row in Selections {
			RowData := this.RowText(Row)
			oLV.Insert(Row - 1, RowData*)
			oLV.Delete(Row + 1)
			oLV.Modify(Row - 1, "Select")
			If (A_Index = 1)
				oLV.Modify(Row - 1, "Focus Vis")
		}
		this.HasChanged := true
		return Selections.Length
	} Else {
		Loop {
			LV_Row := oLV.GetNext(LV_Row)
			If !LV_Row
				break
			If (LV_Row = oLV.GetCount())
				return
			Selections.InsertAt(1, LV_Row)
		}
		For each, Row in Selections {
			RowData := this.RowText(Row + 1)
			oLV.Insert(Row, RowData*)
			oLV.Delete(Row + 2)
			If (A_Index = 1)
				oLV.Modify(Row + 1, "Focus Vis")
		}
		this.HasChanged := true
		return Selections.Length
	}
}

Drag(DragButton := "D", AutoScroll := True, ScrollDelay := 100, LineThick := 2, Color := "Black") {
	Static LVIR_LABEL := 0x0002
	Static LVM_GETITEMCOUNT := 0x1004
	Static LVM_SCROLL := 0x1014
	Static LVM_GETTOPINDEX := 0x1027
	Static LVM_GETCOUNTPERPAGE := 0x1028
	Static LVM_GETSUBITEMRECT := 0x1038
	Static LV_currColHeight := 0

	SM_CXVSCROLL := SysGet(2)

	If InStr(DragButton, "d", true)
		DragButton := "RButton"
	Else
		DragButton := "LButton"

	CoordMode("Mouse", "Window")
	MouseGetPos(,, &LV_Win, &LV_LView, 2)
	WinGetPos(&Win_X, &Win_Y, &Win_W, &Win_H, "ahk_id " LV_Win)
	ControlGetPos(&LV_lx, &LV_ly, &LV_lw, &LV_lh,, "ahk_id " LV_LView)
	LV_XYstruct := Buffer(4 * A_PtrSize, 0)

	LV_currRow := ""

	While GetKeyState(DragButton, "P") {
		MouseGetPos(&LV_mx, &LV_my,, &CurrCtrl, 2)
		LV_mx -= LV_lx, LV_my -= LV_ly

		If (AutoScroll) {
			If (LV_my < 0) {
				SendMessage(LVM_SCROLL, 0, -LV_currColHeight,, "ahk_id " LV_LView)
				Sleep(ScrollDelay)
			}
			If (LV_my > LV_lh) {
				SendMessage(LVM_SCROLL, 0, LV_currColHeight,, "ahk_id " LV_LView)
				Sleep(ScrollDelay)
			}
		}

		If (CurrCtrl != LV_LView) {
			LV_currRow := ""
			continue
		}

		result := SendMessage(LVM_GETITEMCOUNT, 0, 0,, "ahk_id " LV_LView)
		LV_TotalNumOfRows := result
		result := SendMessage(LVM_GETCOUNTPERPAGE, 0, 0,, "ahk_id " LV_LView)
		LV_NumOfRows := result
		result := SendMessage(LVM_GETTOPINDEX, 0, 0,, "ahk_id " LV_LView)
		LV_topIndex := result
		Line_W := (LV_TotalNumOfRows > LV_NumOfRows) ? LV_lw - SM_CXVSCROLL : LV_lw

		Loop LV_NumOfRows + 1 {
			LV_which := LV_topIndex + A_Index - 1
			NumPut("UInt", LVIR_LABEL, LV_XYstruct, 0)
			NumPut("UInt", A_Index - 1, LV_XYstruct, 4)
			SendMessage(LVM_GETSUBITEMRECT, LV_which, LV_XYstruct.Ptr,, "ahk_id " LV_LView)
			LV_RowY := NumGet(LV_XYstruct, 4, "UInt")
			LV_RowY2 := NumGet(LV_XYstruct, 12, "UInt")
			LV_currColHeight := LV_RowY2 - LV_RowY
			If (LV_my <= LV_RowY + LV_currColHeight) {
				LV_currRow := LV_which + 1
				Line_Y := Win_Y + LV_ly + LV_RowY
				Line_X := Win_X + LV_lx
				If (LV_currRow > (LV_TotalNumOfRows + 1)) {
					LV_currRow := ""
				}
				Break
			}
		}

		if LV_currRow {
			; Simple visual feedback - using a temporary GUI as drag indicator
			try {
				MarkLineGui := Gui("+LastFound +AlwaysOnTop +ToolWindow -Caption")
				MarkLineGui.BackColor := Color
				MarkLineGui.Show("W" Line_W " H" LineThick " Y" Line_Y " X" Line_X " NoActivate")
			}
		}
	}
	try MarkLineGui.Destroy()

	If LV_currRow {
		oLV := GuiCtrlFromHwnd(this.LVHwnd)
		DragRows := LV_Rows(this.LVHwnd)
		Lines := DragRows.Copy()
		DragRows.Paste(LV_currRow)
		If (oLV.GetNext() < LV_currRow)
			o := Lines + 1, FocusedRow := LV_currRow - 1
		Else
			o := 1, FocusedRow := LV_currRow
		DragRows.Delete()
		Loop Lines {
			i := A_Index - o
			oLV.Modify(LV_currRow + i, "Select")
		}
		oLV.Modify(FocusedRow, "Focus")
	}
	this.HasChanged := true
	return LV_currRow
}

;=======================================================================================
; History Functions
;=======================================================================================

Add() {
	Row := []
	oLV := GuiCtrlFromHwnd(this.LVHwnd)
	If (this.ActiveSlot < this.Slot.Length)
		this.Slot.RemoveAt(this.ActiveSlot + 1, this.Slot.Length - this.ActiveSlot)
	Loop oLV.GetCount() {
		RowData := this.RowText(A_Index)
		Row.Push(RowData)
	}
	this.Slot.Push(Row)
	this.ActiveSlot := this.Slot.Length
	return this.Slot.Length
}

Undo() {
	If (this.ActiveSlot = 1)
		return this.ActiveSlot
	this.ActiveSlot -= 1
	this.Load(this.ActiveSlot)
	return this.ActiveSlot
}

Redo() {
	If (this.ActiveSlot = this.Slot.Length)
		return this.ActiveSlot
	this.ActiveSlot += 1
	this.Load(this.ActiveSlot)
	return this.ActiveSlot
}

;=======================================================================================
; Internal Functions
;=======================================================================================

Load(Number) {
	If !IsObject(this.Slot[Number])
		return False

	oLV := GuiCtrlFromHwnd(this.LVHwnd)
	oLV.Delete()
	For each, RowArr in this.Slot[Number]
		oLV.Add(RowArr*)
	return True
}

RowText(Index) {
	oLV := GuiCtrlFromHwnd(this.LVHwnd)
	Data := []
	ckd := (oLV.GetNext(Index - 1, "Checked") = Index) ? 1 : 0
	iIcon := this.GetIconIndex(this.LVHwnd, Index)
	Data.Push("Icon" iIcon " Check" ckd)
	Loop oLV.GetCount("Col") {
		Cell := oLV.GetText(Index, A_Index)
		Data.Push(Cell)
	}
	return Data
}

GetIconIndex(Hwnd, Row) {
	Static LVIF_IMAGE := 0x00000002
	Static LVM_GETITEMW := 0x104B

	LVITEM := Buffer(6 * 4 + (A_PtrSize * 2), 0)
	NumPut("UInt", LVIF_IMAGE, LVITEM, 0)
	NumPut("Int", Row - 1, LVITEM, 4)
	SendMessage(LVM_GETITEMW, 0, LVITEM.Ptr,, "ahk_id " Hwnd)
	return NumGet(LVITEM, 5 * 4 + (A_PtrSize * 2), "Int") + 1
}

}
