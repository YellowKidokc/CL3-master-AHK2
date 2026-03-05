# AutoHotkey v1 → v2 Migration Report (Analysis-First)

## Compatibility directive

- Assume this project contains legacy v1 code written between 2008–2022. Prioritize compatibility fixes over stylistic refactoring.

## Project scan summary

- `.ahk` files scanned: **32**

- Main entry candidate(s): cl3.ahk

- Library directory: `lib/`
- Plugin directory: `plugins/`

## Include / dependency map

- `cl3.ahk`
  - line 210: `#Include %A_ScriptDir%\plugins\plugins.ahk`
  - line 746: `#Include *i %A_ScriptDir%\plugins\PastePrivateRules.ahk`
  - line 1316: `#Include %A_ScriptDir%\lib\cl3apiclass.ahk`
  - line 1318: `#Include *i %A_ScriptDir%\plugins\ClipboardPrivateRules.ahk`
- `lib/HistoryRules.ahk`
  - (no direct `#Include`)
- `lib/JSON.ahk`
  - (no direct `#Include`)
- `lib/Jxon.ahk`
  - (no direct `#Include`)
- `lib/ObjRegisterActive.ahk`
  - (no direct `#Include`)
- `lib/WatchFolder.ahk`
  - (no direct `#Include`)
- `lib/XA.ahk`
  - (no direct `#Include`)
- `lib/cl3api.ahk`
  - line 3: `#Include CL3API.ahk`
- `lib/cl3apiclass.ahk`
  - (no direct `#Include`)
- `lib/class_lv_rows.ahk`
  - (no direct `#Include`)
- `lib/crc32.ahk`
  - (no direct `#Include`)
- `lib/dpi.ahk`
  - (no direct `#Include`)
- `lib/settings.ahk`
  - line 321: `#Include %A_ScriptDir%\lib\SettingsGui.ahk`
- `lib/settingsGui.ahk`
  - (no direct `#Include`)
- `lib/update.ahk`
  - (no direct `#Include`)
- `plugins/AutoReplace.ahk`
  - (no direct `#Include`)
- `plugins/ClipChain.ahk`
  - line 389: `#Include *i %A_ScriptDir%\plugins\MyQEDLG-ClipChain.ahk`
  - line 485: `#Include *i %A_ScriptDir%\plugins\ClipChainPrivateRules.ahk`
  - line 679: `#Include %A_ScriptDir%\lib\class_lv_rows.ahk`
- `plugins/Compact.ahk`
  - (no direct `#Include`)
- `plugins/DumpHistory.ahk`
  - (no direct `#Include`)
- `plugins/Fifo.ahk`
  - (no direct `#Include`)
- `plugins/Lower.ahk`
  - (no direct `#Include`)
- `plugins/LowerReplaceSpace.ahk`
  - (no direct `#Include`)
- `plugins/PasteUnwrapped.ahk`
  - (no direct `#Include`)
- `plugins/Send.ahk`
  - (no direct `#Include`)
- `plugins/Title.ahk`
  - (no direct `#Include`)
- `plugins/Upper.ahk`
  - (no direct `#Include`)
- `plugins/ccmdr.ahk`
  - (no direct `#Include`)
- `plugins/notes.ahk`
  - (no direct `#Include`)
- `plugins/plugins.ahk`
  - line 25: `#Include %A_ScriptDir%\plugins\PluginScriptFunction.ahk`
  - line 62: `#Include *i %A_ScriptDir%\plugins\MyPlugins.ahk`
  - line 65: `#Include %A_ScriptDir%\plugins\LowerReplaceSpace.ahk`
  - line 66: `#Include %A_ScriptDir%\plugins\Lower.ahk`
  - line 67: `#Include %A_ScriptDir%\plugins\Title.ahk`
  - line 68: `#Include %A_ScriptDir%\plugins\Upper.ahk`
  - line 69: `#Include %A_ScriptDir%\plugins\Send.ahk`
  - line 70: `#Include %A_ScriptDir%\plugins\AutoReplace.ahk`
  - line 71: `#Include %A_ScriptDir%\plugins\Slots.ahk`
  - line 72: `#Include %A_ScriptDir%\plugins\Sort.ahk`
  - line 73: `#Include %A_ScriptDir%\plugins\Search.ahk`
  - line 74: `#Include %A_ScriptDir%\plugins\DumpHistory.ahk`
  - line 75: `#Include %A_ScriptDir%\plugins\ClipChain.ahk`
  - line 76: `#Include %A_ScriptDir%\plugins\Compact.ahk`
  - line 77: `#Include %A_ScriptDir%\plugins\Fifo.ahk`
  - line 78: `#Include %A_ScriptDir%\plugins\PasteUnwrapped.ahk`
  - line 79: `#Include %A_ScriptDir%\plugins\ccmdr.ahk`
- `plugins/search.ahk`
  - line 161: `#Include *i %A_ScriptDir%\plugins\MyQEDLG-Search.ahk`
  - line 256: `#Include *i %A_ScriptDir%\plugins\MyQEDLG.ahk`
- `plugins/slots.ahk`
  - line 241: `#Include *i %A_ScriptDir%\plugins\MyQEDLG-Slots.ahk`
- `plugins/sort.ahk`
  - (no direct `#Include`)

## High-risk v1 patterns found

- Legacy commands: 328 match(es)
- Gosub / labels: 301 match(es)
- Percent deref: 447 match(es)
- Legacy if syntax: 231 match(es)