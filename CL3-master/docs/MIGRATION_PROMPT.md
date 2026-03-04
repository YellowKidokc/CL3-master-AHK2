# Prompt for AI migration run (ZIP input)

Assume this project contains legacy v1 code written between 2008–2022. Prioritize compatibility fixes over stylistic refactoring.

You are a senior AutoHotkey engineer performing a **full project migration from AutoHotkey v1 to AutoHotkey v2**.

I will provide a **ZIP archive containing a large AutoHotkey v1 codebase**. Your job is to migrate the entire project to **AutoHotkey v2.0+**.

### Phase 1 — Project Analysis
1. Extract the ZIP archive.
2. Scan all directories and `.ahk` files.
3. Detect main entry scripts, `#Include` libraries, GUI files, utility scripts, and shared functions.
4. Build a dependency map showing which scripts call which libraries.

### Phase 2 — Automatic Syntax Conversion
Convert all scripts from v1 syntax to v2 syntax and handle major breaking changes:
- Commands → Functions (`MsgBox`, `Run`, `WinActivate`, etc.)
- `%var%` dereferencing to expression syntax
- Legacy `if` and loop forms to v2 forms
- Function call and parameter updates
- Object/array modernization
- GUI migration (`Gui, Add/Show`, `GuiControl` → v2 GUI objects)
- Timer migration (`SetTimer, Label, 1000` → `SetTimer(Func, 1000)`)
- File/Ini/String command migration (`FileAppend`, `IniRead`, `StringSplit`, `StringReplace`, etc.)

### Phase 3 — Structural Refactoring
Where direct translation is unsafe:
- replace labels with functions as needed
- refactor deprecated constructs into v2-safe functions
- keep behavior compatibility first.

### Phase 4 — Runtime Validation
Validate converted scripts for syntax, deprecated commands, parameter order, broken includes, and GUI callback issues. Fix automatically.

### Phase 5 — Output
Return:
1. Fully converted AHK v2 project
2. Same folder structure
3. Migration report (files converted, major changes, manual follow-ups)
