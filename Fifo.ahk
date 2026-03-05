/*

Plugin            : FIFO (Reverse paste)
Purpose           : Paste back in the order in which the entries were added to the clipboard history
Version           : 1.2
CL3 version       : 1.7

History:
- 1.2 Fix FIFO activation via Hotkey trigger
- 1.1 Added FifoApi() to be able to trigger FIFO from cl3api.fifo(data)
- 1.0 Initial version

*/

FifoApi(data)
	{
	 Global FIFOID, FIFOIDCOUNTER, FIFOACTIVE
	 FIFOID := Data
	 FIFOIDCOUNTER := 0
	 FIFOACTIVE := 1
	 if (data = 0)
	 	FIFOACTIVE := 0
	}

FifoInit()
	{
	 global FIFOID, FIFOIDCOUNTER, FIFOACTIVE
	 FIFOID := 0
	 FIFOIDCOUNTER := 0
	 FIFOACTIVE := 0
	}

hk_fifo_handler(*)
	{
	 global
	 FifoInit()
	 FIFOACTIVE := 1
	 FifoActiveMenu()
	 BuildMenuFromFifo()
	}

#HotIf FIFOACTIVE

; Paste FIFO MODE
^v::
{
	global FIFOID, FIFOIDCOUNTER, FIFOACTIVE, History, stats
	If (FIFOID = 0)
		{
		 OnClipboardChange(FuncOnClipboardChange, 0)
		 A_Clipboard := History[1]["text"]
		 OnClipboardChange(FuncOnClipboardChange, 1)
		 PasteIt()
		 Sleep(100)
		 FifoInit()
		}
	A_Clipboard := History[FIFOID]["text"]
	PasteIt()
	stats["fifo"]++
	FIFOIDCOUNTER++
	If (FIFOID = FIFOIDCOUNTER)
		{
		 FifoInit()
		 FifoActiveMenu()
		}
}

; stop FIFO
^+#F10::
{
	FifoInit()
	FifoActiveMenu()
}

#HotIf

FifoActiveMenu()
	{
	 global FIFOACTIVE
	 If FIFOACTIVE
		{
		 A_TrayMenu.Check("&FIFO Active")
		}
	 Else
		{
		 A_TrayMenu.Uncheck("&FIFO Active")
		 TrayTip("FIFO Paste Mode Deactivated", "FIFO", 1)
		 FifoInit()
		}
	}
