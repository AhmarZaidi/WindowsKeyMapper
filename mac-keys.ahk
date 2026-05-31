#Requires AutoHotkey v2.0
#SingleInstance Force

; Self-elevate to Administrator to allow remapping in elevated Windows Terminals, Cmd, and Task Manager
if not (A_IsAdmin or RegExMatch(DllCall("GetCommandLine", "str"), "i)/restart")) {
    try {
        if A_IsCompiled {
            Run('*RunAs "' A_ScriptFullPath '" /restart')
        } else {
            Run('*RunAs "' A_AhkPath '" /restart "' A_ScriptFullPath '"')
        }
        ExitApp()
    } catch {
        ; User clicked No to UAC, let the script run with standard privileges
    }
}

; ==============================================================================
; KepMapper - Lightweight & Battery-Efficient Key Mapping Utility
; Designed by Antigravity AI
; ==============================================================================

; Define global paths and settings file
global SettingsFile := A_ScriptDir "\settings.ini"

; Global GUI Control References
global MyGui := ""
global ChkCapsLockToTab := ""
global ChkHighPriority := ""
global ChkEnabled := ""
global DDLLineModifier := ""
global DDLWordModifier := ""
global DDLTabLeftMod := ""
global DDLTabLeftKey := ""
global DDLTabRightMod := ""
global DDLTabRightKey := ""
global ChkDeleteLine := ""
global ChkSelectToEndOfLine := ""
global ChkSelectToStartOfLine := ""
global ChkMoveToEndOfLine := ""
global ChkMoveToStartOfLine := ""
global ChkMoveToTop := ""
global ChkMoveToBottom := ""
global ChkSelectToTop := ""
global ChkSelectToBottom := ""
global ChkDeleteWordLeft := ""
global ChkSelectWordRight := ""
global ChkSelectWordLeft := ""
global ChkMoveWordRight := ""
global ChkMoveWordLeft := ""
global ChkBrowserBack := ""
global ChkBrowserForward := ""
global ChkBrowserTabLeft := ""
global ChkBrowserTabRight := ""
global ChkStartup := ""
global SearchEdit := ""
global ShortcutLV := ""

; Global configuration state variables
global Enabled := 1
global CapsLockToTab := 1
global HighPriority := 1
global LineModifier := "Alt"
global WordModifier := "Ctrl"
global TabLeft := "^["
global TabRight := "^]"
global BrowserBackKey := "!["
global BrowserForwardKey := "!]"

; --- INITIALIZATION ---
LoadSettings()
SetupTrayMenu()

if (Enabled) {
    RegisterAllHotkeys()
} else if (CapsLockToTab) {
    ; Keep CapsLock remapped even if master remapping is toggled off
    TryRegister("*CapsLock", DoCapsLockRemap)
}

; Return from auto-execute section
return

; ==============================================================================
; HOTKEY REGISTRATION & CALLBACKS
; ==============================================================================

LoadSettings() {
    global SettingsFile, Enabled, CapsLockToTab, HighPriority
    global LineModifier, WordModifier, TabLeft, TabRight, BrowserBackKey, BrowserForwardKey
    
    ; Create settings.ini with default values if it doesn't exist
    if !FileExist(SettingsFile) {
        IniWrite("1", SettingsFile, "General", "Enabled")
        IniWrite("1", SettingsFile, "General", "CapsLockToTab")
        IniWrite("1", SettingsFile, "General", "HighPriority")
        IniWrite("Alt", SettingsFile, "Modifiers", "LineModifier")
        IniWrite("Ctrl", SettingsFile, "Modifiers", "WordModifier")
        IniWrite("^[", SettingsFile, "TabSwitching", "TabLeft")
        IniWrite("^]", SettingsFile, "TabSwitching", "TabRight")
        IniWrite("![", SettingsFile, "TabSwitching", "BrowserBack")
        IniWrite("!]", SettingsFile, "TabSwitching", "BrowserForward")
        
        ; Hotkeys
        for hk in ["DeleteLine", "SelectToEndOfLine", "SelectToStartOfLine", "MoveToEndOfLine", 
                   "MoveToStartOfLine", "MoveToTop", "MoveToBottom", "SelectToTop", "SelectToBottom", 
                   "DeleteWordLeft", "SelectWordRight", "SelectWordLeft", "MoveWordRight", "MoveWordLeft", 
                   "BrowserBack", "BrowserForward", "BrowserTabLeft", "BrowserTabRight"] {
            IniWrite("1", SettingsFile, "Hotkeys", hk)
        }
    }
    
    Enabled := IniRead(SettingsFile, "General", "Enabled", "1") == "1" ? 1 : 0
    CapsLockToTab := IniRead(SettingsFile, "General", "CapsLockToTab", "1") == "1" ? 1 : 0
    HighPriority := IniRead(SettingsFile, "General", "HighPriority", "1") == "1" ? 1 : 0
    
    LineModifier := IniRead(SettingsFile, "Modifiers", "LineModifier", "Alt")
    WordModifier := IniRead(SettingsFile, "Modifiers", "WordModifier", "Ctrl")
    
    TabLeft := IniRead(SettingsFile, "TabSwitching", "TabLeft", "^[")
    TabRight := IniRead(SettingsFile, "TabSwitching", "TabRight", "^]")
    
    BrowserBackKey := IniRead(SettingsFile, "TabSwitching", "BrowserBack", "![")
    BrowserForwardKey := IniRead(SettingsFile, "TabSwitching", "BrowserForward", "!]")
}

GetModifierSymbol(name) {
    switch name {
        case "Ctrl": return "^"
        case "Alt": return "!"
        case "Win": return "#"
        default: return "^"
    }
}

RegisterAllHotkeys() {
    global SettingsFile, CapsLockToTab, HighPriority
    global LineModifier, WordModifier, TabLeft, TabRight, BrowserBackKey, BrowserForwardKey
    
    prefix := HighPriority ? "$" : ""
    lineSym := GetModifierSymbol(LineModifier)
    wordSym := GetModifierSymbol(WordModifier)
    
    ; 1. CapsLock remapping (runs globally so Tab works in terminal too)
    if (CapsLockToTab) {
        TryRegister("*CapsLock", DoCapsLockRemap)
    }
    
    ; Exclude command terminal windows from custom text editing shortcuts to prevent key conflicts
    HotIf(IsNotTerminalActive)
    
    ; 2. Line-Level Actions
    if (IniRead(SettingsFile, "Hotkeys", "DeleteLine", "1") == "1") {
        TryRegister(prefix . lineSym . "BS", DoDeleteLine)
    }
    if (IniRead(SettingsFile, "Hotkeys", "SelectToEndOfLine", "1") == "1") {
        TryRegister(prefix . lineSym . "+Right", DoSelectToEndOfLine)
    }
    if (IniRead(SettingsFile, "Hotkeys", "SelectToStartOfLine", "1") == "1") {
        TryRegister(prefix . lineSym . "+Left", DoSelectToStartOfLine)
    }
    
    ; Exclude both command terminals and browsers from caret left/right line-jump remapping
    ; so browsers natively receive Alt + Left/Right for history navigation
    HotIf(IsCaretMovementActive)
    if (IniRead(SettingsFile, "Hotkeys", "MoveToEndOfLine", "1") == "1") {
        TryRegister(prefix . lineSym . "Right", DoMoveToEndOfLine)
    }
    if (IniRead(SettingsFile, "Hotkeys", "MoveToStartOfLine", "1") == "1") {
        TryRegister(prefix . lineSym . "Left", DoMoveToStartOfLine)
    }
    
    ; Restore standard terminal exclusion for remaining editing hotkeys
    HotIf(IsNotTerminalActive)
    if (IniRead(SettingsFile, "Hotkeys", "MoveToTop", "1") == "1") {
        TryRegister(prefix . "^Up", DoMoveToTop)
    }
    if (IniRead(SettingsFile, "Hotkeys", "MoveToBottom", "1") == "1") {
        TryRegister(prefix . "^Down", DoMoveToBottom)
    }
    if (IniRead(SettingsFile, "Hotkeys", "SelectToTop", "1") == "1") {
        TryRegister(prefix . "^+Up", DoSelectToTop)
    }
    if (IniRead(SettingsFile, "Hotkeys", "SelectToBottom", "1") == "1") {
        TryRegister(prefix . "^+Down", DoSelectToBottom)
    }
    
    ; 3. Word-Level Actions
    if (IniRead(SettingsFile, "Hotkeys", "DeleteWordLeft", "1") == "1") {
        TryRegister(prefix . wordSym . "BS", DoDeleteWordLeft)
    }
    if (IniRead(SettingsFile, "Hotkeys", "SelectWordRight", "1") == "1") {
        TryRegister(prefix . wordSym . "+Right", DoSelectWordRight)
    }
    if (IniRead(SettingsFile, "Hotkeys", "SelectWordLeft", "1") == "1") {
        TryRegister(prefix . wordSym . "+Left", DoSelectWordLeft)
    }
    if (IniRead(SettingsFile, "Hotkeys", "MoveWordRight", "1") == "1") {
        TryRegister(prefix . wordSym . "Right", DoMoveWordRight)
    }
    if (IniRead(SettingsFile, "Hotkeys", "MoveWordLeft", "1") == "1") {
        TryRegister(prefix . wordSym . "Left", DoMoveWordLeft)
    }
    
    ; Reset HotIf exclusion for terminals
    HotIf()
    
    ; 4. Browser Specific Actions
    HotIf(IsBrowserActive)
    if (IniRead(SettingsFile, "Hotkeys", "BrowserTabLeft", "1") == "1" and TabLeft != "") {
        TryRegister(prefix . TabLeft, DoBrowserTabLeft)
    }
    if (IniRead(SettingsFile, "Hotkeys", "BrowserTabRight", "1") == "1" and TabRight != "") {
        TryRegister(prefix . TabRight, DoBrowserTabRight)
    }
    if (IniRead(SettingsFile, "Hotkeys", "BrowserBack", "1") == "1") {
        TryRegister(prefix . BrowserBackKey, DoBrowserBack)
    }
    if (IniRead(SettingsFile, "Hotkeys", "BrowserForward", "1") == "1") {
        TryRegister(prefix . BrowserForwardKey, DoBrowserForward)
    }
    HotIf()
}

TryRegister(hkName, callback) {
    try {
        Hotkey(hkName, callback, "On")
    } catch as err {
        ; Silent fail to prevent execution block
    }
}

IsBrowserActive(*) {
    return WinActive("ahk_exe chrome.exe") 
        or WinActive("ahk_exe firefox.exe") 
        or WinActive("ahk_exe msedge.exe") 
        or WinActive("ahk_exe brave.exe") 
        or WinActive("ahk_exe opera.exe")
}

IsNotTerminalActive(*) {
    return not (WinActive("ahk_exe WindowsTerminal.exe") 
        or WinActive("ahk_class ConsoleWindowClass") 
        or WinActive("ahk_exe powershell.exe") 
        or WinActive("ahk_exe cmd.exe"))
}

IsCaretMovementActive(*) {
    return IsNotTerminalActive() and not IsBrowserActive()
}

; Action Functions
DoCapsLockRemap(*) {
    Send("{Blind}{Tab}")
}

DoDeleteLine(*) {
    Send("+{Home}")
    Sleep(50)
    Send("{Delete}")
}

DoSelectToEndOfLine(*) {
    Send("+{End}")
}

DoSelectToStartOfLine(*) {
    Send("+{Home}")
}

DoMoveToEndOfLine(*) {
    Send("{End}")
}

DoMoveToStartOfLine(*) {
    Send("{Home}")
}

DoMoveToTop(*) {
    Send("^{Home}")
}

DoMoveToBottom(*) {
    Send("^{End}")
}

DoSelectToTop(*) {
    Send("^+{Home}")
}

DoSelectToBottom(*) {
    Send("^+{End}")
}

DoDeleteWordLeft(*) {
    Send("^+{Left}")
    Sleep(20)
    Send("{Delete}")
}

DoSelectWordRight(*) {
    Send("^+{Right}")
}

DoSelectWordLeft(*) {
    Send("^+{Left}")
}

DoMoveWordRight(*) {
    Send("^{Right}")
}

DoMoveWordLeft(*) {
    Send("^{Left}")
}

DoBrowserBack(*) {
    Send("!{Left}")
}

DoBrowserForward(*) {
    Send("!{Right}")
}

DoBrowserTabLeft(*) {
    Send("^+{Tab}")
}

DoBrowserTabRight(*) {
    Send("^{Tab}")
}

; ==============================================================================
; SYSTEM TRAY MANAGEMENT
; ==============================================================================

SetupTrayMenu() {
    A_IconTip := "KepMapper - Active"
    Tray := A_TrayMenu
    Tray.Delete()
    Tray.Add("Configure Settings", (*) => ShowGui())
    Tray.Add("Toggle Enabled", (*) => ToggleMaster())
    Tray.Add()
    Tray.Add("Reload Script", (*) => Reload())
    Tray.Add("Exit", (*) => ExitApp())
    Tray.Default := "Configure Settings"
}

ToggleMaster() {
    global SettingsFile, Enabled
    newVal := Enabled ? 0 : 1
    IniWrite(newVal, SettingsFile, "General", "Enabled")
    TrayTip("KepMapper", newVal ? "Keyboard remappings enabled" : "Keyboard remappings disabled", 1)
    Sleep(500)
    Reload()
}

; ==============================================================================
; MODERN CONFIGURATION GUI (DARK THEME)
; ==============================================================================

ShowGui(*) {
    global MyGui
    if (MyGui) {
        MyGui.Show()
    } else {
        CreateGui()
    }
}

CreateGui() {
    global MyGui, ChkCapsLockToTab, ChkHighPriority, ChkEnabled
    global DDLLineModifier, DDLWordModifier
    global DDLTabLeftMod, DDLTabLeftKey, DDLTabRightMod, DDLTabRightKey
    global ChkDeleteLine, ChkSelectToEndOfLine, ChkSelectToStartOfLine
    global ChkMoveToEndOfLine, ChkMoveToStartOfLine, ChkMoveToTop, ChkMoveToBottom
    global ChkSelectToTop, ChkSelectToBottom, ChkDeleteWordLeft, ChkSelectWordRight
    global ChkSelectWordLeft, ChkMoveWordRight, ChkMoveWordLeft
    global ChkBrowserBack, ChkBrowserForward, ChkBrowserTabLeft, ChkBrowserTabRight
    global ChkStartup, SearchEdit, ShortcutLV
    global Enabled, CapsLockToTab, HighPriority, LineModifier, WordModifier, TabLeft, TabRight

    MyGui := Gui("-MinimizeBox -MaximizeBox", "KepMapper Settings Panel")
    MyGui.BackColor := "121214"
    MyGui.SetFont("s10 cDCDCDC", "Segoe UI")
    
    TabCtrl := MyGui.Add("Tab3", "w550 h460 cDCDCDC", ["Core Mappings", "Hotkeys Checklist", "Conflict Reference", "About"])
    
    ; --- TAB 1: Core Mappings ---
    TabCtrl.UseTab(1)
    
    MyGui.Add("GroupBox", "w510 h95 cDCDCDC x20 y50", "General Hardware & Engine Options")
    ChkCapsLockToTab := MyGui.Add("Checkbox", "x40 y75 w460", "Remap CapsLock to Tab (perfect for broken physical Tab keys)")
    ChkHighPriority := MyGui.Add("Checkbox", "x40 y108 w460", "High Priority Mode (runs hotkeys using physical hook, overrides other apps)")
    
    MyGui.Add("GroupBox", "w510 h110 cDCDCDC x20 y155", "Typing Modifier Assignments")
    MyGui.Add("Text", "x40 y180", "Line-level modifier:")
    DDLLineModifier := MyGui.Add("DropDownList", "x200 y175 w100", ["Ctrl", "Alt", "Win"])
    MyGui.Add("Text", "x315 y180 c888888", "(Mac Cmd-like line tasks)")
    
    MyGui.Add("Text", "x40 y220", "Word-level modifier:")
    DDLWordModifier := MyGui.Add("DropDownList", "x200 y215 w100", ["Ctrl", "Alt", "Win"])
    MyGui.Add("Text", "x315 y220 c888888", "(Mac Option-like word tasks)")
    
    MyGui.Add("GroupBox", "w510 h150 cDCDCDC x20 y275", "Browser Navigation Shortcuts")
    MyGui.Add("Text", "x40 y300", "Tab Navigation:")
    DDLTabLeftMod := MyGui.Add("DropDownList", "x160 y295 w100", ["Ctrl", "Alt", "Ctrl + Shift", "Win", "None"])
    MyGui.Add("Text", "x270 y300", "+")
    DDLTabLeftKey := MyGui.Add("DropDownList", "x290 y295 w80", ["[", "]", "Left", "Right", "PageUp", "PageDown", "Tab"])
    
    MyGui.Add("Text", "x40 y345", "History Navigation:")
    DDLTabRightMod := MyGui.Add("DropDownList", "x160 y340 w100", ["Ctrl", "Alt", "Ctrl + Shift", "Win", "None"])
    MyGui.Add("Text", "x270 y345", "+")
    DDLTabRightKey := MyGui.Add("DropDownList", "x290 y340 w80", ["[", "]", "Left", "Right", "PageUp", "PageDown", "Tab"])
    
    MyGui.Add("Text", "x40 y390 c888888", "Configuring the base key automatically maps the opposite side key.")

    ; --- TAB 2: Hotkeys Checklist ---
    TabCtrl.UseTab(2)
    MyGui.Add("GroupBox", "w510 h380 cDCDCDC x20 y50", "Toggle Specific Actions & Shortcuts")
    
    MyGui.SetFont("Bold s9.5")
    MyGui.Add("Text", "x40 y75 cFFFFFF", "Line-Level Operations")
    MyGui.SetFont("norm s10")
    ChkDeleteLine := MyGui.Add("Checkbox", "x40 y105 w220", "Delete whole line (Mod+BS)")
    ChkSelectToEndOfLine := MyGui.Add("Checkbox", "x40 y135 w220", "Select to end (Mod+Sh+Rt)")
    ChkSelectToStartOfLine := MyGui.Add("Checkbox", "x40 y165 w220", "Select to start (Mod+Sh+Lf)")
    ChkMoveToEndOfLine := MyGui.Add("Checkbox", "x40 y195 w220", "Move to end (Mod+Rt)")
    ChkMoveToStartOfLine := MyGui.Add("Checkbox", "x40 y225 w220", "Move to start (Mod+Lf)")
    ChkMoveToTop := MyGui.Add("Checkbox", "x40 y255 w220", "Move to top (Ctrl+Up)")
    ChkMoveToBottom := MyGui.Add("Checkbox", "x40 y285 w220", "Move to bottom (Ctrl+Dn)")
    ChkSelectToTop := MyGui.Add("Checkbox", "x40 y315 w220", "Select to top (Ctrl+Sh+Up)")
    ChkSelectToBottom := MyGui.Add("Checkbox", "x40 y345 w220", "Select to bottom (Ctrl+Sh+Dn)")

    MyGui.SetFont("Bold s9.5")
    MyGui.Add("Text", "x280 y75 cFFFFFF", "Word-Level & Navigation")
    MyGui.SetFont("norm s10")
    ChkDeleteWordLeft := MyGui.Add("Checkbox", "x280 y105 w220", "Delete word left (Mod+BS)")
    ChkSelectWordRight := MyGui.Add("Checkbox", "x280 y135 w220", "Select word right (Mod+Sh+Rt)")
    ChkSelectWordLeft := MyGui.Add("Checkbox", "x280 y165 w220", "Select word left (Mod+Sh+Lf)")
    ChkMoveWordRight := MyGui.Add("Checkbox", "x280 y195 w220", "Move word right (Mod+Rt)")
    ChkMoveWordLeft := MyGui.Add("Checkbox", "x280 y225 w220", "Move word left (Mod+Lf)")
    
    MyGui.SetFont("Bold s9.5")
    MyGui.Add("Text", "x280 y255 cFFFFFF", "Browser Navigation")
    MyGui.SetFont("norm s10")
    ChkBrowserBack := MyGui.Add("Checkbox", "x280 y285 w220", "Back history (Ctrl+[)")
    ChkBrowserForward := MyGui.Add("Checkbox", "x280 y315 w220", "Forward history (Ctrl+])")
    ChkBrowserTabLeft := MyGui.Add("Checkbox", "x280 y345 w220", "Tab switch left")
    ChkBrowserTabRight := MyGui.Add("Checkbox", "x280 y375 w220", "Tab switch right")

    ; --- TAB 3: Conflict Reference ---
    TabCtrl.UseTab(3)
    MyGui.Add("Text", "x20 y55", "Search standard Windows & Application hotkeys to avoid overlaps:")
    SearchEdit := MyGui.Add("Edit", "x20 y80 w510 h24 cFFFFFF Background242428 -E0x200")
    SearchEdit.OnEvent("Change", OnSearchEditChange)
    
    ShortcutLV := MyGui.Add("ListView", "x20 y115 w510 h310 cFFFFFF Background1A1A1E Grid", ["Shortcut", "Description", "Target Scope", "Conflict Risk"])
    ShortcutLV.ModifyCol(1, 120)
    ShortcutLV.ModifyCol(2, 180)
    ShortcutLV.ModifyCol(3, 110)
    ShortcutLV.ModifyCol(4, 80)
    
    PopulateConflictDatabase("")

    ; --- TAB 4: About ---
    TabCtrl.UseTab(4)
    MyGui.SetFont("Bold s14 c00FF88")
    MyGui.Add("Text", "x20 y60", "KepMapper Utility")
    MyGui.SetFont("norm s10 cDCDCDC")
    MyGui.Add("Text", "x20 y95 w510", "Designed for maximum battery efficiency and zero-latency keyboard remapping on Windows.")
    MyGui.Add("Text", "x20 y130 w510", "Utility Features:")
    MyGui.Add("Text", "x40 y155 w480", "• CapsLock remapped to Tab with Shift/Ctrl modifier inheritance.")
    MyGui.Add("Text", "x40 y180 w480", "• Custom modifiers (Ctrl/Alt/Win) for typing shortcuts.")
    MyGui.Add("Text", "x40 y205 w480", "• Custom combos for browser tab switching to unlock brackets [ and ].")
    MyGui.Add("Text", "x40 y230 w480", "• Fully searchable system shortcut conflict reference database.")
    MyGui.Add("Text", "x40 y255 w480", "• Low-priority (fallback) or High-priority (override) system hook mode.")
    
    MyGui.Add("Text", "x20 y295 w510 c888888", "Status: Running (Uses 0% CPU when not processing keystrokes)")
    ChkStartup := MyGui.Add("Checkbox", "x20 y325 w480", "Launch KepMapper automatically when logging in to Windows")
    
    MyGui.SetFont("norm s10")
    
    ; --- Bottom Controls ---
    TabCtrl.UseTab()
    ChkEnabled := MyGui.Add("Checkbox", "x25 y478 w260 cFFFFFF", "Enable Typing Customizations (Master)")
    
    SaveBtn := MyGui.Add("Button", "x300 y472 w110 h30 Default", "Save & Apply")
    SaveBtn.OnEvent("Click", OnSaveClick)
    
    CloseBtn := MyGui.Add("Button", "x420 y472 w110 h30", "Close to Tray")
    CloseBtn.OnEvent("Click", (*) => MyGui.Hide())
    
    SetGuiValues()
    
    MyGui.OnEvent("Close", (*) => MyGui.Hide())
    MyGui.Show()
}

GetIndexForModifier(name) {
    if (name == "Ctrl") {
        return 1
    }
    if (name == "Alt") {
        return 2
    }
    if (name == "Win") {
        return 3
    }
    return 1
}

GetMatchingOppositeKey(key) {
    if (key == "[") {
        return "]"
    }
    if (key == "Left") {
        return "Right"
    }
    if (key == "PageUp") {
        return "PageDown"
    }
    return "]"
}

DecodeTabNav(hotkeyStr, &modChoice, &keyChoice) {
    modChoice := "Ctrl + Shift"
    keyChoice := "["
    
    if (hotkeyStr == "") {
        modChoice := "None"
        keyChoice := "["
        return
    }
    
    remStr := hotkeyStr
    
    if (SubStr(remStr, 1, 2) == "^+") {
        modChoice := "Ctrl + Shift"
        remStr := SubStr(remStr, 3)
    } else if (SubStr(remStr, 1, 1) == "^") {
        modChoice := "Ctrl"
        remStr := SubStr(remStr, 2)
    } else if (SubStr(remStr, 1, 1) == "!") {
        modChoice := "Alt"
        remStr := SubStr(remStr, 2)
    } else if (SubStr(remStr, 1, 1) == "#") {
        modChoice := "Win"
        remStr := SubStr(remStr, 2)
    } else {
        modChoice := "None"
    }
    
    keyChoice := remStr
    if (keyChoice == "") {
        keyChoice := "["
    }
}

EncodeTabNav(modChoice, keyChoice) {
    modSym := ""
    if (modChoice == "Ctrl + Shift") {
        modSym := "^+"
    } else if (modChoice == "Ctrl") {
        modSym := "^"
    } else if (modChoice == "Alt") {
        modSym := "!"
    } else if (modChoice == "Win") {
        modSym := "#"
    }
    return modSym . keyChoice
}

SetGuiValues() {
    global SettingsFile, MyGui
    global ChkCapsLockToTab, ChkHighPriority, ChkEnabled
    global DDLLineModifier, DDLWordModifier
    global DDLTabLeftMod, DDLTabLeftKey, DDLTabRightMod, DDLTabRightKey
    global ChkDeleteLine, ChkSelectToEndOfLine, ChkSelectToStartOfLine
    global ChkMoveToEndOfLine, ChkMoveToStartOfLine, ChkMoveToTop, ChkMoveToBottom
    global ChkSelectToTop, ChkSelectToBottom, ChkDeleteWordLeft, ChkSelectWordRight
    global ChkSelectWordLeft, ChkMoveWordRight, ChkMoveWordLeft
    global ChkBrowserBack, ChkBrowserForward, ChkBrowserTabLeft, ChkBrowserTabRight
    global ChkStartup
    global Enabled, CapsLockToTab, HighPriority, LineModifier, WordModifier, TabLeft, TabRight

    ChkCapsLockToTab.Value := CapsLockToTab
    ChkHighPriority.Value := HighPriority
    ChkEnabled.Value := Enabled
    
    DDLLineModifier.Choose(GetIndexForModifier(LineModifier))
    DDLWordModifier.Choose(GetIndexForModifier(WordModifier))
    
    DecodeTabNav(TabLeft, &leftMod, &leftKey)
    DecodeTabNav(BrowserBackKey, &rightMod, &rightKey)
    
    ; Find index in dropdown lists
    modList := ["Ctrl", "Alt", "Ctrl + Shift", "Win", "None"]
    keyList := ["[", "]", "Left", "Right", "PageUp", "PageDown", "Tab"]
    
    leftModIdx := 1
    for i, m in modList {
        if (m == leftMod) {
            leftModIdx := i
            break
        }
    }
    
    leftKeyIdx := 1
    for i, k in keyList {
        if (k == leftKey) {
            leftKeyIdx := i
            break
        }
    }
    
    rightModIdx := 1
    for i, m in modList {
        if (m == rightMod) {
            rightModIdx := i
            break
        }
    }
    
    rightKeyIdx := 2
    for i, k in keyList {
        if (k == rightKey) {
            rightKeyIdx := i
            break
        }
    }
    
    DDLTabLeftMod.Choose(leftModIdx)
    DDLTabLeftKey.Choose(leftKeyIdx)
    DDLTabRightMod.Choose(rightModIdx)
    DDLTabRightKey.Choose(rightKeyIdx)
    
    ChkDeleteLine.Value := IniRead(SettingsFile, "Hotkeys", "DeleteLine", "1") == "1" ? 1 : 0
    ChkSelectToEndOfLine.Value := IniRead(SettingsFile, "Hotkeys", "SelectToEndOfLine", "1") == "1" ? 1 : 0
    ChkSelectToStartOfLine.Value := IniRead(SettingsFile, "Hotkeys", "SelectToStartOfLine", "1") == "1" ? 1 : 0
    ChkMoveToEndOfLine.Value := IniRead(SettingsFile, "Hotkeys", "MoveToEndOfLine", "1") == "1" ? 1 : 0
    ChkMoveToStartOfLine.Value := IniRead(SettingsFile, "Hotkeys", "MoveToStartOfLine", "1") == "1" ? 1 : 0
    ChkMoveToTop.Value := IniRead(SettingsFile, "Hotkeys", "MoveToTop", "1") == "1" ? 1 : 0
    ChkMoveToBottom.Value := IniRead(SettingsFile, "Hotkeys", "MoveToBottom", "1") == "1" ? 1 : 0
    ChkSelectToTop.Value := IniRead(SettingsFile, "Hotkeys", "SelectToTop", "1") == "1" ? 1 : 0
    ChkSelectToBottom.Value := IniRead(SettingsFile, "Hotkeys", "SelectToBottom", "1") == "1" ? 1 : 0
    
    ChkDeleteWordLeft.Value := IniRead(SettingsFile, "Hotkeys", "DeleteWordLeft", "1") == "1" ? 1 : 0
    ChkSelectWordRight.Value := IniRead(SettingsFile, "Hotkeys", "SelectWordRight", "1") == "1" ? 1 : 0
    ChkSelectWordLeft.Value := IniRead(SettingsFile, "Hotkeys", "SelectWordLeft", "1") == "1" ? 1 : 0
    ChkMoveWordRight.Value := IniRead(SettingsFile, "Hotkeys", "MoveWordRight", "1") == "1" ? 1 : 0
    ChkMoveWordLeft.Value := IniRead(SettingsFile, "Hotkeys", "MoveWordLeft", "1") == "1" ? 1 : 0
    
    ChkBrowserBack.Value := IniRead(SettingsFile, "Hotkeys", "BrowserBack", "1") == "1" ? 1 : 0
    ChkBrowserForward.Value := IniRead(SettingsFile, "Hotkeys", "BrowserForward", "1") == "1" ? 1 : 0
    ChkBrowserTabLeft.Value := IniRead(SettingsFile, "Hotkeys", "BrowserTabLeft", "1") == "1" ? 1 : 0
    ChkBrowserTabRight.Value := IniRead(SettingsFile, "Hotkeys", "BrowserTabRight", "1") == "1" ? 1 : 0
    
    ChkStartup.Value := FileExist(A_Startup "\KepMapper.lnk") ? 1 : 0
}

OnSaveClick(*) {
    global SettingsFile, MyGui
    global ChkCapsLockToTab, ChkHighPriority, ChkEnabled
    global DDLLineModifier, DDLWordModifier
    global DDLTabLeftMod, DDLTabLeftKey, DDLTabRightMod, DDLTabRightKey
    global ChkDeleteLine, ChkSelectToEndOfLine, ChkSelectToStartOfLine
    global ChkMoveToEndOfLine, ChkMoveToStartOfLine, ChkMoveToTop, ChkMoveToBottom
    global ChkSelectToTop, ChkSelectToBottom, ChkDeleteWordLeft, ChkSelectWordRight
    global ChkSelectWordLeft, ChkMoveWordRight, ChkMoveWordLeft
    global ChkBrowserBack, ChkBrowserForward, ChkBrowserTabLeft, ChkBrowserTabRight
    global ChkStartup

    ; Check if line and word modifiers are the same
    if (DDLLineModifier.Text == DDLWordModifier.Text) {
        warningMsg := "You have selected the same modifier (" DDLLineModifier.Text ") for both Line-Level and Word-Level shortcuts. This could lead to serious conflicts.`n`nAre you sure you want to save this configuration?"
        if (MsgBox(warningMsg, "Potential Overlap Warning", "YesNo Icon!") == "No") {
            return
        }
    }

    ; Save General
    IniWrite(ChkEnabled.Value, SettingsFile, "General", "Enabled")
    IniWrite(ChkCapsLockToTab.Value, SettingsFile, "General", "CapsLockToTab")
    IniWrite(ChkHighPriority.Value, SettingsFile, "General", "HighPriority")
    
    ; Save Modifiers
    IniWrite(DDLLineModifier.Text, SettingsFile, "Modifiers", "LineModifier")
    IniWrite(DDLWordModifier.Text, SettingsFile, "Modifiers", "WordModifier")
    
    ; Save Tab Navigation
    leftNav := EncodeTabNav(DDLTabLeftMod.Text, DDLTabLeftKey.Text)
    rightNav := EncodeTabNav(DDLTabLeftMod.Text, GetMatchingOppositeKey(DDLTabLeftKey.Text))
    IniWrite(leftNav, SettingsFile, "TabSwitching", "TabLeft")
    IniWrite(rightNav, SettingsFile, "TabSwitching", "TabRight")
    
    backNav := EncodeTabNav(DDLTabRightMod.Text, DDLTabRightKey.Text)
    fwdNav := EncodeTabNav(DDLTabRightMod.Text, GetMatchingOppositeKey(DDLTabRightKey.Text))
    IniWrite(backNav, SettingsFile, "TabSwitching", "BrowserBack")
    IniWrite(fwdNav, SettingsFile, "TabSwitching", "BrowserForward")
    
    ; Save Hotkey Checks
    IniWrite(ChkDeleteLine.Value, SettingsFile, "Hotkeys", "DeleteLine")
    IniWrite(ChkSelectToEndOfLine.Value, SettingsFile, "Hotkeys", "SelectToEndOfLine")
    IniWrite(ChkSelectToStartOfLine.Value, SettingsFile, "Hotkeys", "SelectToStartOfLine")
    IniWrite(ChkMoveToEndOfLine.Value, SettingsFile, "Hotkeys", "MoveToEndOfLine")
    IniWrite(ChkMoveToStartOfLine.Value, SettingsFile, "Hotkeys", "MoveToStartOfLine")
    IniWrite(ChkMoveToTop.Value, SettingsFile, "Hotkeys", "MoveToTop")
    IniWrite(ChkMoveToBottom.Value, SettingsFile, "Hotkeys", "MoveToBottom")
    IniWrite(ChkSelectToTop.Value, SettingsFile, "Hotkeys", "SelectToTop")
    IniWrite(ChkSelectToBottom.Value, SettingsFile, "Hotkeys", "SelectToBottom")
    
    IniWrite(ChkDeleteWordLeft.Value, SettingsFile, "Hotkeys", "DeleteWordLeft")
    IniWrite(ChkSelectWordRight.Value, SettingsFile, "Hotkeys", "SelectWordRight")
    IniWrite(ChkSelectWordLeft.Value, SettingsFile, "Hotkeys", "SelectWordLeft")
    IniWrite(ChkMoveWordRight.Value, SettingsFile, "Hotkeys", "MoveWordRight")
    IniWrite(ChkMoveWordLeft.Value, SettingsFile, "Hotkeys", "MoveWordLeft")
    
    IniWrite(ChkBrowserBack.Value, SettingsFile, "Hotkeys", "BrowserBack")
    IniWrite(ChkBrowserForward.Value, SettingsFile, "Hotkeys", "BrowserForward")
    IniWrite(ChkBrowserTabLeft.Value, SettingsFile, "Hotkeys", "BrowserTabLeft")
    IniWrite(ChkBrowserTabRight.Value, SettingsFile, "Hotkeys", "BrowserTabRight")
    
    ; Startup Setting
    SetStartup(ChkStartup.Value)
    
    MyGui.Hide()
    TrayTip("KepMapper", "Settings saved successfully! Restarting engine...", 1)
    Sleep(600)
    Reload()
}

SetStartup(enable) {
    StartupLnk := A_Startup "\KepMapper.lnk"
    if (enable) {
        try {
            FileCreateShortcut(A_ScriptFullPath, StartupLnk, A_ScriptDir)
        }
    } else {
        if FileExist(StartupLnk) {
            try {
                FileDelete(StartupLnk)
            }
        }
    }
}

; ==============================================================================
; CONFLICT DIRECTORY SEARCH SYSTEM
; ==============================================================================

OnSearchEditChange(*) {
    global SearchEdit
    PopulateConflictDatabase(SearchEdit.Text)
}

PopulateConflictDatabase(query) {
    global ShortcutLV
    ShortcutLV.Delete()
    
    conflictList := [
        {key: "Win + E", action: "Open File Explorer", scope: "Windows OS", conflict: "System Reserved"},
        {key: "Win + R", action: "Open Run Dialog", scope: "Windows OS", conflict: "System Reserved"},
        {key: "Win + D", action: "Show/Hide Desktop", scope: "Windows OS", conflict: "System Reserved"},
        {key: "Win + L", action: "Lock Laptop", scope: "Windows OS", conflict: "System Reserved"},
        {key: "Alt + Tab", action: "Quick App Switcher", scope: "Windows OS", conflict: "System Reserved"},
        {key: "Ctrl + Alt + Tab", action: "Sticky App Switcher", scope: "Windows OS", conflict: "System Reserved"},
        {key: "Ctrl + Shift + Esc", action: "Open Task Manager", scope: "Windows OS", conflict: "System Reserved"},
        {key: "Ctrl + C", action: "Copy Text/Assets", scope: "Global / Apps", conflict: "High Risk (Typing)"},
        {key: "Ctrl + V", action: "Paste Text/Assets", scope: "Global / Apps", conflict: "High Risk (Typing)"},
        {key: "Ctrl + X", action: "Cut Text/Assets", scope: "Global / Apps", conflict: "High Risk (Typing)"},
        {key: "Ctrl + Z", action: "Undo Operation", scope: "Global / Apps", conflict: "High Risk (Typing)"},
        {key: "Ctrl + Y", action: "Redo Operation", scope: "Global / Apps", conflict: "High Risk (Typing)"},
        {key: "Ctrl + A", action: "Select All Elements", scope: "Global / Apps", conflict: "High Risk (Typing)"},
        {key: "Ctrl + S", action: "Save Progress", scope: "Global / Apps", conflict: "Medium Risk"},
        {key: "Ctrl + F", action: "Search Document", scope: "Global / Apps", conflict: "Medium Risk"},
        {key: "Ctrl + H", action: "Replace Text", scope: "Global / Apps", conflict: "Medium Risk"},
        {key: "Ctrl + T", action: "New Browser Tab", scope: "Browsers", conflict: "Medium Risk"},
        {key: "Ctrl + W", action: "Close Tab", scope: "Browsers", conflict: "Medium Risk"},
        {key: "Ctrl + Shift + T", action: "Reopen Last Closed Tab", scope: "Browsers", conflict: "Medium Risk"},
        {key: "Ctrl + L", action: "Focus URL bar", scope: "Browsers", conflict: "Medium Risk"},
        {key: "Ctrl + R", action: "Reload Webpage", scope: "Browsers", conflict: "Medium Risk"},
        {key: "Ctrl + Left/Right", action: "Cursor word jump", scope: "Text Editors", conflict: "High Risk (Typing)"},
        {key: "Ctrl + BS", action: "Delete word left", scope: "Text Editors", conflict: "High Risk (Typing)"},
        {key: "Alt + Left/Right", action: "Browser Back/Forward", scope: "Browsers", conflict: "Medium Risk"},
        {key: "Alt + BS", action: "Delete word (Mac-style)", scope: "Text Editors", conflict: "Medium Risk"}
    ]
    
    query := StrLower(query)
    
    for item in conflictList {
        if (query == "" 
            or InStr(StrLower(item.key), query) 
            or InStr(StrLower(item.action), query) 
            or InStr(StrLower(item.scope), query) 
            or InStr(StrLower(item.conflict), query)) {
            ShortcutLV.Add(, item.key, item.action, item.scope, item.conflict)
        }
    }
}