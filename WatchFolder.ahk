; WatchFolder() by just me @ https://www.autohotkey.com/boards/viewtopic.php?t=8384
; Converted to AHK v2

WatchFolder(Folder, UserFunc, SubTree := False, Watch := 0x03) {
   Static DummyObject := {Base: {__Delete: WatchFolder.Bind("**END", "")}}
   Static TimerID := "**" . A_TickCount
   Static TimerFunc := WatchFolder.Bind(TimerID, "")
   Static MAXIMUM_WAIT_OBJECTS := 64
   Static MAX_DIR_PATH := 260 - 12 + 1
   Static SizeOfLongPath := MAX_DIR_PATH * 2
   Static SizeOfFNI := 0xFFFF
   Static SizeOfOVL := 32
   Static WatchedFolders := Map()
   Static WatchedIndices := Map()
   Static EventArray := []
   Static WaitObjectsBuf := 0
   Static BytesRead := 0
   Static Paused := False

   If (Folder = "")
      Return False
   SetTimer(TimerFunc, 0)
   RebuildWaitObjects := False

   If (Folder = TimerID) {
      If (ObjCount := EventArray.Length) && !Paused {
         ObjIndex := DllCall("WaitForMultipleObjects", "UInt", ObjCount, "Ptr", WaitObjectsBuf, "Int", 0, "UInt", 0, "UInt")
         While (ObjIndex >= 0) && (ObjIndex < ObjCount) {
            FolderName := WatchedIndices[ObjIndex + 1]
            D := WatchedFolders[FolderName]
            BytesRead := 0
            If DllCall("GetOverlappedResult", "Ptr", D.Handle, "Ptr", D.OVLBuf.Ptr, "UInt*", &BytesRead, "Int", True) {
               Changes := []
               FNIAddr := D.FNIBuf.Ptr
               FNIMax := FNIAddr + BytesRead
               OffSet := 0
               PrevIndex := 0
               PrevAction := 0
               PrevName := ""
               Loop {
                  FNIAddr += Offset
                  OffSet := NumGet(FNIAddr + 0, "UInt")
                  Action := NumGet(FNIAddr + 4, "UInt")
                  Length := NumGet(FNIAddr + 8, "UInt") // 2
                  Name   := FolderName . "\" . StrGet(FNIAddr + 12, Length, "UTF-16")
                  IsDir  := InStr(FileExist(Name), "D") ? 1 : 0
                  If (Name = PrevName) {
                     If (Action = PrevAction)
                        Continue
                     If (Action = 1) && (PrevAction = 2) {
                        PrevAction := Action
                        Changes.RemoveAt(PrevIndex--)
                        Continue
                     }
                  }
                  If (Action = 4)
                     PrevIndex := Changes.Push({Action: Action, OldName: Name, IsDir: 0})
                  Else If (Action = 5) && (PrevAction = 4) {
                     Changes[PrevIndex].Name := Name
                     Changes[PrevIndex].IsDir := IsDir
                  }
                  Else
                     PrevIndex := Changes.Push({Action: Action, Name: Name, IsDir: IsDir})
                  PrevAction := Action
                  PrevName := Name
               } Until (Offset = 0) || ((FNIAddr + Offset) > FNIMax)
               If (Changes.Length > 0)
                  D.Func.Call(FolderName, Changes)
               DllCall("ResetEvent", "Ptr", EventArray[D.Index])
               DllCall("ReadDirectoryChangesW", "Ptr", D.Handle, "Ptr", D.FNIBuf.Ptr, "UInt", SizeOfFNI, "Int", D.SubTree
                                              , "UInt", D.Watch, "UInt", 0, "Ptr", D.OVLBuf.Ptr, "Ptr", 0)
            }
            ObjIndex := DllCall("WaitForMultipleObjects", "UInt", ObjCount, "Ptr", WaitObjectsBuf, "Int", 0, "UInt", 0, "UInt")
            Sleep(0)
         }
      }
   }
   Else If (Folder = "**PAUSE") {
      Paused := !!UserFunc
   }
   Else If (Folder = "**END") {
      For FolderPath, D In WatchedFolders
         DllCall("CloseHandle", "Ptr", D.Handle)
      For Idx, Event In EventArray
         DllCall("CloseHandle", "Ptr", Event)
      WatchedFolders := Map()
      WatchedIndices := Map()
      EventArray := []
      Paused := False
      Return True
   }
   Else {
      Folder := RTrim(Folder, "\")
      LongPathBuf := Buffer(SizeOfLongPath, 0)
      If !DllCall("GetLongPathName", "Str", Folder, "Ptr", LongPathBuf, "UInt", MAX_DIR_PATH)
         Return False
      Folder := StrGet(LongPathBuf)

      If WatchedFolders.Has(Folder) {
         D := WatchedFolders[Folder]
         Handle := D.Handle
         Index := D.Index
         DllCall("CloseHandle", "Ptr", Handle)
         DllCall("CloseHandle", "Ptr", EventArray[Index])
         EventArray.RemoveAt(Index)
         WatchedIndices.Delete(Index)
         WatchedFolders.Delete(Folder)
         RebuildWaitObjects := True
      }

      If InStr(FileExist(Folder), "D") && (UserFunc != "**DEL") && (EventArray.Length < MAXIMUM_WAIT_OBJECTS) {
         UserFuncObj := IsObject(UserFunc) ? UserFunc : %UserFunc%
         Watch &= 0x017F
         If (Watch) {
            Handle := DllCall("CreateFile", "Str", Folder . "\", "UInt", 0x01, "UInt", 0x07, "Ptr", 0, "UInt", 0x03
                                          , "UInt", 0x42000000, "Ptr", 0, "UPtr")
            If (Handle > 0) {
               Event := DllCall("CreateEvent", "Ptr", 0, "Int", 1, "Int", 0, "Ptr", 0)
               Index := EventArray.Push(Event)
               FNIBuf := Buffer(SizeOfFNI, 0)
               OVLBuf := Buffer(SizeOfOVL, 0)
               NumPut("Ptr", Event, OVLBuf, A_PtrSize * 2)
               WatchedIndices[Index] := Folder
               WatchedFolders[Folder] := {Func: UserFuncObj, Handle: Handle, Index: Index, SubTree: !!SubTree, Watch: Watch, FNIBuf: FNIBuf, OVLBuf: OVLBuf}
               DllCall("ReadDirectoryChangesW", "Ptr", Handle, "Ptr", FNIBuf.Ptr, "UInt", SizeOfFNI, "Int", SubTree
                                              , "UInt", Watch, "UInt", 0, "Ptr", OVLBuf.Ptr, "Ptr", 0)
               RebuildWaitObjects := True
            }
         }
      }

      If (RebuildWaitObjects) {
         WaitObjectsBuf := Buffer(MAXIMUM_WAIT_OBJECTS * A_PtrSize, 0)
         OffSet := 0
         For Index, Event In EventArray {
            NumPut("Ptr", Event, WaitObjectsBuf, OffSet)
            OffSet += A_PtrSize
         }
      }
   }

   If (EventArray.Length > 0)
      SetTimer(TimerFunc, -100)
   Return (RebuildWaitObjects)
}
