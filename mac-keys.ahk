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
; KeyMapper - Lightweight & Battery-Efficient Key Mapping Utility
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

; Global Theme Colors (dynamically populated based on Windows Personalizations)
global ThemeBg := "121214"
global ThemeFg := "DCDCDC"
global ThemeControlBg := "1A1A1E"
global ToggleOnBg := "Background00FF88 c121214"
global ToggleOffBg := "Background2D2D30 cA0A0A0"
global EditBg := "Background242428 cFFFFFF"
global GroupBorderColor := "DCDCDC"

; --- INITIALIZATION ---
LoadSettings()
LoadTheme()
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

; ==============================================================================
; SYSTEM THEME DETECTION & MODERN DYNAMIC TOGGLE SWITCH CONTROLS
; ==============================================================================

IsSystemLightTheme() {
    try {
        return RegRead("HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize", "AppsUseLightTheme") == 1
    } catch {
        return 0
    }
}

LoadTheme() {
    global ThemeBg, ThemeFg, ThemeControlBg, ToggleOnBg, ToggleOffBg, EditBg, GroupBorderColor
    if IsSystemLightTheme() {
        ThemeBg := "F3F3F3"
        ThemeFg := "1A1A1A"
        ThemeControlBg := "FFFFFF"
        ToggleOnBg := "Background4CAF50 cWhite"
        ToggleOffBg := "BackgroundD0D0D0 c555555"
        EditBg := "BackgroundFFFFFF c000000"
        GroupBorderColor := "808080"
    } else {
        ThemeBg := "121214"
        ThemeFg := "DCDCDC"
        ThemeControlBg := "1A1A1E"
        ToggleOnBg := "Background00FF88 c121214"
        ToggleOffBg := "Background2D2D30 cA0A0A0"
        EditBg := "Background242428 cFFFFFF"
        GroupBorderColor := "DCDCDC"
    }
}

AddToggleSwitch(GuiObj, x, y, defaultVal, textLabel) {
    global ToggleOnBg, ToggleOffBg, ThemeFg
    
    ; Add descriptive text label (styled with current theme text color)
    GuiObj.Add("Text", "x" . x . " y" . y . " w160 r1 c" . ThemeFg, textLabel)
    
    btnText := defaultVal ? "ON" : "OFF"
    btnBg := defaultVal ? ToggleOnBg : ToggleOffBg
    
    ; Add toggle button
    toggleBtn := GuiObj.Add("Text", "x" . (x + 165) . " y" . (y - 2) . " w45 h20 Center +Border +0x200 " . btnBg, btnText)
    toggleBtn.OnEvent("Click", OnToggleClick)
    
    return toggleBtn
}

OnToggleClick(Ctrl, *) {
    global ToggleOnBg, ToggleOffBg
    if (Ctrl.Text == "ON") {
        Ctrl.Text := "OFF"
        Ctrl.Opt(ToggleOffBg)
    } else {
        Ctrl.Text := "ON"
        Ctrl.Opt(ToggleOnBg)
    }
}

SetToggleState(toggleCtrl, val) {
    global ToggleOnBg, ToggleOffBg
    if (val) {
        toggleCtrl.Text := "ON"
        toggleCtrl.Opt(ToggleOnBg)
    } else {
        toggleCtrl.Text := "OFF"
        toggleCtrl.Opt(ToggleOffBg)
    }
}

GetToggleValue(toggleCtrl) {
    return (toggleCtrl.Text == "ON") ? 1 : 0
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
    A_IconTip := "KeyMapper - Active"
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
    TrayTip("KeyMapper", newVal ? "Keyboard remappings enabled" : "Keyboard remappings disabled", 1)
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

    MyGui := Gui("-MinimizeBox -MaximizeBox", "KeyMapper Settings Panel")
    MyGui.BackColor := ThemeBg
    MyGui.SetFont("s10 c" . ThemeFg, "Segoe UI")
    
    TabCtrl := MyGui.Add("Tab3", "w550 h460 c" . ThemeFg, ["Core Mappings", "Hotkeys Checklist", "Conflict Reference", "About"])
    
    ; --- TAB 1: Core Mappings ---
    TabCtrl.UseTab(1)
    
    MyGui.Add("GroupBox", "w510 h105 c" . GroupBorderColor . " x20 y50", "General Hardware & Engine Options")
    ChkCapsLockToTab := AddToggleSwitch(MyGui, 40, 75, CapsLockToTab, "Remap CapsLock to Tab")
    ChkHighPriority := AddToggleSwitch(MyGui, 40, 110, HighPriority, "High Priority Hook Mode")
    
    MyGui.Add("GroupBox", "w510 h110 c" . GroupBorderColor . " x20 y165", "Typing Modifier Assignments")
    MyGui.Add("Text", "x40 y190 c" . ThemeFg, "Line-level modifier:")
    DDLLineModifier := MyGui.Add("DropDownList", "x200 y185 w100", ["Ctrl", "Alt", "Win"])
    MyGui.Add("Text", "x315 y190 c888888", "(Mac Cmd-like line tasks)")
    
    MyGui.Add("Text", "x40 y230 c" . ThemeFg, "Word-level modifier:")
    DDLWordModifier := MyGui.Add("DropDownList", "x200 y225 w100", ["Ctrl", "Alt", "Win"])
    MyGui.Add("Text", "x315 y230 c888888", "(Mac Option-like word tasks)")
    
    MyGui.Add("GroupBox", "w510 h150 c" . GroupBorderColor . " x20 y285", "Browser Navigation Shortcuts")
    MyGui.Add("Text", "x40 y310 c" . ThemeFg, "Tab Navigation:")
    DDLTabLeftMod := MyGui.Add("DropDownList", "x160 y305 w100", ["Ctrl", "Alt", "Ctrl + Shift", "Win", "None"])
    MyGui.Add("Text", "x270 y310 c" . ThemeFg, "+")
    DDLTabLeftKey := MyGui.Add("DropDownList", "x290 y305 w80", ["[", "]", "Left", "Right", "PageUp", "PageDown", "Tab"])
    
    MyGui.Add("Text", "x40 y355 c" . ThemeFg, "History Navigation:")
    DDLTabRightMod := MyGui.Add("DropDownList", "x160 y350 w100", ["Ctrl", "Alt", "Ctrl + Shift", "Win", "None"])
    MyGui.Add("Text", "x270 y355 c" . ThemeFg, "+")
    DDLTabRightKey := MyGui.Add("DropDownList", "x290 y350 w80", ["[", "]", "Left", "Right", "PageUp", "PageDown", "Tab"])
    
    MyGui.Add("Text", "x40 y400 c888888", "Configuring the base key automatically maps the opposite side key.")

    ; --- TAB 2: Hotkeys Checklist ---
    TabCtrl.UseTab(2)
    MyGui.Add("GroupBox", "w510 h380 c" . GroupBorderColor . " x20 y50", "Toggle Specific Actions & Shortcuts")
    
    MyGui.SetFont("Bold s9.5")
    MyGui.Add("Text", "x40 y75 c" . (IsSystemLightTheme() ? "0066CC" : "00FF88"), "Line-Level Operations")
    MyGui.SetFont("norm s10")
    ChkDeleteLine := AddToggleSwitch(MyGui, 40, 105, 1, "Delete whole line")
    ChkSelectToEndOfLine := AddToggleSwitch(MyGui, 40, 135, 1, "Select to end")
    ChkSelectToStartOfLine := AddToggleSwitch(MyGui, 40, 165, 1, "Select to start")
    ChkMoveToEndOfLine := AddToggleSwitch(MyGui, 40, 195, 1, "Move to end")
    ChkMoveToStartOfLine := AddToggleSwitch(MyGui, 40, 225, 1, "Move to start")
    ChkMoveToTop := AddToggleSwitch(MyGui, 40, 255, 1, "Move to top")
    ChkMoveToBottom := AddToggleSwitch(MyGui, 40, 285, 1, "Move to bottom")
    ChkSelectToTop := AddToggleSwitch(MyGui, 40, 315, 1, "Select to top")
    ChkSelectToBottom := AddToggleSwitch(MyGui, 40, 345, 1, "Select to bottom")

    MyGui.SetFont("Bold s9.5")
    MyGui.Add("Text", "x280 y75 c" . (IsSystemLightTheme() ? "0066CC" : "00FF88"), "Word-Level & Navigation")
    MyGui.SetFont("norm s10")
    ChkDeleteWordLeft := AddToggleSwitch(MyGui, 280, 105, 1, "Delete word left")
    ChkSelectWordRight := AddToggleSwitch(MyGui, 280, 135, 1, "Select word right")
    ChkSelectWordLeft := AddToggleSwitch(MyGui, 280, 165, 1, "Select word left")
    ChkMoveWordRight := AddToggleSwitch(MyGui, 280, 195, 1, "Move word right")
    ChkMoveWordLeft := AddToggleSwitch(MyGui, 280, 225, 1, "Move word left")
    
    MyGui.SetFont("Bold s9.5")
    MyGui.Add("Text", "x280 y255 c" . (IsSystemLightTheme() ? "0066CC" : "00FF88"), "Browser Navigation")
    MyGui.SetFont("norm s10")
    ChkBrowserBack := AddToggleSwitch(MyGui, 280, 285, 1, "Back history")
    ChkBrowserForward := AddToggleSwitch(MyGui, 280, 315, 1, "Forward history")
    ChkBrowserTabLeft := AddToggleSwitch(MyGui, 280, 345, 1, "Tab switch left")
    ChkBrowserTabRight := AddToggleSwitch(MyGui, 280, 375, 1, "Tab switch right")

    ; --- TAB 3: Conflict Reference ---
    TabCtrl.UseTab(3)
    MyGui.Add("Text", "x20 y55 c" . ThemeFg, "Search standard Windows & Application hotkeys to avoid overlaps:")
    SearchEdit := MyGui.Add("Edit", "x20 y80 w510 h24 " . EditBg . " -E0x200")
    SearchEdit.OnEvent("Change", OnSearchEditChange)
    
    ShortcutLV := MyGui.Add("ListView", "x20 y115 w510 h310 c" . ThemeFg . " Background" . ThemeControlBg . " Grid", ["Shortcut", "Description", "Target Scope", "Conflict Risk"])
    ShortcutLV.ModifyCol(1, 120)
    ShortcutLV.ModifyCol(2, 180)
    ShortcutLV.ModifyCol(3, 110)
    ShortcutLV.ModifyCol(4, 80)
    
    PopulateConflictDatabase("")
 
    ; --- TAB 4: About ---
    TabCtrl.UseTab(4)
    MyGui.SetFont("Bold s14 c" . (IsSystemLightTheme() ? "0066CC" : "00FF88"))
    MyGui.Add("Text", "x20 y60", "KeyMapper Utility")
    MyGui.SetFont("norm s10 c" . ThemeFg)
    MyGui.Add("Text", "x20 y95 w510", "Designed for maximum battery efficiency and zero-latency keyboard remapping on Windows.")
    MyGui.Add("Text", "x20 y130 w510", "Utility Features:")
    MyGui.Add("Text", "x40 y155 w480", "• CapsLock remapped to Tab with Shift/Ctrl modifier inheritance.")
    MyGui.Add("Text", "x40 y180 w480", "• Custom modifiers (Ctrl/Alt/Win) for typing shortcuts.")
    MyGui.Add("Text", "x40 y205 w480", "• Custom combos for browser tab switching to unlock brackets [ and ].")
    MyGui.Add("Text", "x40 y230 w480", "• Fully searchable system shortcut conflict reference database.")
    MyGui.Add("Text", "x40 y255 w480", "• Low-priority (fallback) or High-priority (override) system hook mode.")
    
    MyGui.Add("Text", "x20 y295 w510 c" . (IsSystemLightTheme() ? "555555" : "888888"), "Status: Running (Uses 0% CPU when not processing keystrokes)")
    ChkStartup := AddToggleSwitch(MyGui, 20, 325, 0, "Windows Auto-Startup")
    
    MyGui.SetFont("norm s10")
    
    ; --- Bottom Controls ---
    TabCtrl.UseTab()
    ChkEnabled := AddToggleSwitch(MyGui, 20, 478, Enabled, "Enable Typing Remaps")
    
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

    SetToggleState(ChkCapsLockToTab, CapsLockToTab)
    SetToggleState(ChkHighPriority, HighPriority)
    SetToggleState(ChkEnabled, Enabled)
    
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
    
    SetToggleState(ChkDeleteLine, IniRead(SettingsFile, "Hotkeys", "DeleteLine", "1") == "1")
    SetToggleState(ChkSelectToEndOfLine, IniRead(SettingsFile, "Hotkeys", "SelectToEndOfLine", "1") == "1")
    SetToggleState(ChkSelectToStartOfLine, IniRead(SettingsFile, "Hotkeys", "SelectToStartOfLine", "1") == "1")
    SetToggleState(ChkMoveToEndOfLine, IniRead(SettingsFile, "Hotkeys", "MoveToEndOfLine", "1") == "1")
    SetToggleState(ChkMoveToStartOfLine, IniRead(SettingsFile, "Hotkeys", "MoveToStartOfLine", "1") == "1")
    SetToggleState(ChkMoveToTop, IniRead(SettingsFile, "Hotkeys", "MoveToTop", "1") == "1")
    SetToggleState(ChkMoveToBottom, IniRead(SettingsFile, "Hotkeys", "MoveToBottom", "1") == "1")
    SetToggleState(ChkSelectToTop, IniRead(SettingsFile, "Hotkeys", "SelectToTop", "1") == "1")
    SetToggleState(ChkSelectToBottom, IniRead(SettingsFile, "Hotkeys", "SelectToBottom", "1") == "1")
    
    SetToggleState(ChkDeleteWordLeft, IniRead(SettingsFile, "Hotkeys", "DeleteWordLeft", "1") == "1")
    SetToggleState(ChkSelectWordRight, IniRead(SettingsFile, "Hotkeys", "SelectWordRight", "1") == "1")
    SetToggleState(ChkSelectWordLeft, IniRead(SettingsFile, "Hotkeys", "SelectWordLeft", "1") == "1")
    SetToggleState(ChkMoveWordRight, IniRead(SettingsFile, "Hotkeys", "MoveWordRight", "1") == "1")
    SetToggleState(ChkMoveWordLeft, IniRead(SettingsFile, "Hotkeys", "MoveWordLeft", "1") == "1")
    
    SetToggleState(ChkBrowserBack, IniRead(SettingsFile, "Hotkeys", "BrowserBack", "1") == "1")
    SetToggleState(ChkBrowserForward, IniRead(SettingsFile, "Hotkeys", "BrowserForward", "1") == "1")
    SetToggleState(ChkBrowserTabLeft, IniRead(SettingsFile, "Hotkeys", "BrowserTabLeft", "1") == "1")
    SetToggleState(ChkBrowserTabRight, IniRead(SettingsFile, "Hotkeys", "BrowserTabRight", "1") == "1")
    
    SetToggleState(ChkStartup, FileExist(A_Startup "\KeyMapper.lnk") ? 1 : 0)
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
    IniWrite(GetToggleValue(ChkEnabled), SettingsFile, "General", "Enabled")
    IniWrite(GetToggleValue(ChkCapsLockToTab), SettingsFile, "General", "CapsLockToTab")
    IniWrite(GetToggleValue(ChkHighPriority), SettingsFile, "General", "HighPriority")
    
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
    IniWrite(GetToggleValue(ChkDeleteLine), SettingsFile, "Hotkeys", "DeleteLine")
    IniWrite(GetToggleValue(ChkSelectToEndOfLine), SettingsFile, "Hotkeys", "SelectToEndOfLine")
    IniWrite(GetToggleValue(ChkSelectToStartOfLine), SettingsFile, "Hotkeys", "SelectToStartOfLine")
    IniWrite(GetToggleValue(ChkMoveToEndOfLine), SettingsFile, "Hotkeys", "MoveToEndOfLine")
    IniWrite(GetToggleValue(ChkMoveToStartOfLine), SettingsFile, "Hotkeys", "MoveToStartOfLine")
    IniWrite(GetToggleValue(ChkMoveToTop), SettingsFile, "Hotkeys", "MoveToTop")
    IniWrite(GetToggleValue(ChkMoveToBottom), SettingsFile, "Hotkeys", "MoveToBottom")
    IniWrite(GetToggleValue(ChkSelectToTop), SettingsFile, "Hotkeys", "SelectToTop")
    IniWrite(GetToggleValue(ChkSelectToBottom), SettingsFile, "Hotkeys", "SelectToBottom")
    
    IniWrite(GetToggleValue(ChkDeleteWordLeft), SettingsFile, "Hotkeys", "DeleteWordLeft")
    IniWrite(GetToggleValue(ChkSelectWordRight), SettingsFile, "Hotkeys", "SelectWordRight")
    IniWrite(GetToggleValue(ChkSelectWordLeft), SettingsFile, "Hotkeys", "SelectWordLeft")
    IniWrite(GetToggleValue(ChkMoveWordRight), SettingsFile, "Hotkeys", "MoveWordRight")
    IniWrite(GetToggleValue(ChkMoveWordLeft), SettingsFile, "Hotkeys", "MoveWordLeft")
    
    IniWrite(GetToggleValue(ChkBrowserBack), SettingsFile, "Hotkeys", "BrowserBack")
    IniWrite(GetToggleValue(ChkBrowserForward), SettingsFile, "Hotkeys", "BrowserForward")
    IniWrite(GetToggleValue(ChkBrowserTabLeft), SettingsFile, "Hotkeys", "BrowserTabLeft")
    IniWrite(GetToggleValue(ChkBrowserTabRight), SettingsFile, "Hotkeys", "BrowserTabRight")
    
    ; Startup Setting
    SetStartup(GetToggleValue(ChkStartup))
    
    MyGui.Hide()
    TrayTip("KeyMapper", "Settings saved successfully! Restarting engine...", 1)
    Sleep(600)
    Reload()
}

SetStartup(enable) {
    StartupLnk := A_Startup "\KeyMapper.lnk"
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