#Requires AutoHotkey v2.0
#SingleInstance Force

; Self-elevate to Administrator to allow remapping in elevated Windows Terminals, Cmd, and Task Manager
if not (A_IsAdmin or RegExMatch(DllCall("GetCommandLine", "str"), "i)/restart")) {
    try {
        ; Forward arguments if any
        argsStr := ""
        for arg in A_Args {
            argsStr .= ' "' arg '"'
        }
        
        if A_IsCompiled {
            Run('*RunAs "' A_ScriptFullPath '" /restart' . argsStr)
        } else {
            Run('*RunAs "' A_AhkPath '" /restart "' A_ScriptFullPath '"' . argsStr)
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
global ChkRemapWinK := ""
global DDLTheme := ""
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

; Global App Exclusion GUI Controls
global ExclusionLV := ""
global SearchExclusionEdit := ""
global ChkExclCapsLock := ""
global ChkExclTyping := ""
global ChkExclBrowser := ""

; Global configuration state variables
global Enabled := 1
global CapsLockToTab := 1
global HighPriority := 1
global RemapWinK := 1
global AppTheme := "System"
global LineModifier := "Alt"
global WordModifier := "Ctrl"
global TabLeft := "^["
global TabRight := "^]"
global BrowserBackKey := "!["
global BrowserForwardKey := "!]"
global ExclusionAppsList := []

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
    ; Keep CapsLock remapped globally unless excluded for active application
    HotIf(IsCapsLockEnabled)
    TryRegister("*CapsLock", DoCapsLockRemap)
    HotIf()
}

; Check if we need to show the GUI on startup (e.g., after reload saving)
if (A_Args.Length > 0 and A_Args[1] == "/showgui") {
    startTab := (A_Args.Length > 1) ? A_Args[2] : 1
    ShowGui(startTab)
}

; Return from auto-execute section
return

; ==============================================================================
; HOTKEY REGISTRATION & CALLBACKS
; ==============================================================================

LoadSettings() {
    global SettingsFile, Enabled, CapsLockToTab, HighPriority, RemapWinK, AppTheme
    global LineModifier, WordModifier, TabLeft, TabRight, BrowserBackKey, BrowserForwardKey
    global ExclusionAppsList
    
    ; Create settings.ini with default values if it doesn't exist
    if !FileExist(SettingsFile) {
        IniWrite("1", SettingsFile, "General", "Enabled")
        IniWrite("1", SettingsFile, "General", "CapsLockToTab")
        IniWrite("1", SettingsFile, "General", "HighPriority")
        IniWrite("1", SettingsFile, "General", "RemapWinK")
        IniWrite("System", SettingsFile, "General", "Theme")
        
        IniWrite("Alt", SettingsFile, "Modifiers", "LineModifier")
        IniWrite("Ctrl", SettingsFile, "Modifiers", "WordModifier")
        IniWrite("^[", SettingsFile, "TabSwitching", "TabLeft")
        IniWrite("^]", SettingsFile, "TabSwitching", "TabRight")
        IniWrite("![", SettingsFile, "TabSwitching", "BrowserBack")
        IniWrite("!]", SettingsFile, "TabSwitching", "BrowserForward")
        
        ; Exclusions default list
        IniWrite("cmd.exe,powershell.exe,windowsterminal.exe", SettingsFile, "Exclusions", "Apps")
        IniWrite("0", SettingsFile, "Exclusion_cmd.exe", "DisableCapsLock")
        IniWrite("1", SettingsFile, "Exclusion_cmd.exe", "DisableTyping")
        IniWrite("1", SettingsFile, "Exclusion_cmd.exe", "DisableBrowser")
        IniWrite("0", SettingsFile, "Exclusion_powershell.exe", "DisableCapsLock")
        IniWrite("1", SettingsFile, "Exclusion_powershell.exe", "DisableTyping")
        IniWrite("1", SettingsFile, "Exclusion_powershell.exe", "DisableBrowser")
        IniWrite("0", SettingsFile, "Exclusion_windowsterminal.exe", "DisableCapsLock")
        IniWrite("1", SettingsFile, "Exclusion_windowsterminal.exe", "DisableTyping")
        IniWrite("1", SettingsFile, "Exclusion_windowsterminal.exe", "DisableBrowser")
        
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
    RemapWinK := IniRead(SettingsFile, "General", "RemapWinK", "1") == "1" ? 1 : 0
    AppTheme := IniRead(SettingsFile, "General", "Theme", "System")
    
    LineModifier := IniRead(SettingsFile, "Modifiers", "LineModifier", "Alt")
    WordModifier := IniRead(SettingsFile, "Modifiers", "WordModifier", "Ctrl")
    
    TabLeft := IniRead(SettingsFile, "TabSwitching", "TabLeft", "^[")
    TabRight := IniRead(SettingsFile, "TabSwitching", "TabRight", "^]")
    BrowserBackKey := IniRead(SettingsFile, "TabSwitching", "BrowserBack", "![")
    BrowserForwardKey := IniRead(SettingsFile, "TabSwitching", "BrowserForward", "!]")
    
    exclusionStr := IniRead(SettingsFile, "Exclusions", "Apps", "cmd.exe,powershell.exe,windowsterminal.exe")
    ExclusionAppsList := StrSplit(exclusionStr, ",")
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
    global SettingsFile, CapsLockToTab, HighPriority, RemapWinK
    global LineModifier, WordModifier, TabLeft, TabRight, BrowserBackKey, BrowserForwardKey
    
    prefix := HighPriority ? "$" : ""
    lineSym := GetModifierSymbol(LineModifier)
    wordSym := GetModifierSymbol(WordModifier)
    
    ; 1. CapsLock remapping
    HotIf(IsCapsLockEnabled)
    if (CapsLockToTab) {
        TryRegister("*CapsLock", DoCapsLockRemap)
    }
    HotIf()
    
    ; Windows Default Shortcut Overrides (Remap Win+K to Bluetooth Settings)
    if (RemapWinK) {
        TryRegister("#k", DoBluetoothRemap)
    }
    
    ; Exclude command terminals and specifically blocked apps from custom shortcuts
    HotIf(IsTypingActive)
    
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
    
    ; Restore standard terminal/exclusion check for remaining editing hotkeys
    HotIf(IsTypingActive)
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
    HotIf()
    
    ; 4. Browser Specific Actions
    HotIf(IsBrowserShortcutActive)
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

; Dynamic Action Restrictions
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

IsCapsLockEnabled(*) {
    try {
        activeProcess := WinGetProcessName("A")
        if (activeProcess == "") {
            return true
        }
        return IniRead(SettingsFile, "Exclusion_" . StrLower(activeProcess), "DisableCapsLock", "0") != "1"
    } catch {
        return true
    }
}

IsTypingEnabled(*) {
    try {
        activeProcess := WinGetProcessName("A")
        if (activeProcess == "") {
            return true
        }
        return IniRead(SettingsFile, "Exclusion_" . StrLower(activeProcess), "DisableTyping", "0") != "1"
    } catch {
        return true
    }
}

IsBrowserEnabled(*) {
    try {
        activeProcess := WinGetProcessName("A")
        if (activeProcess == "") {
            return true
        }
        return IniRead(SettingsFile, "Exclusion_" . StrLower(activeProcess), "DisableBrowser", "0") != "1"
    } catch {
        return true
    }
}

IsTypingActive(*) {
    return IsNotTerminalActive() and IsTypingEnabled()
}

IsCaretMovementActive(*) {
    return IsNotTerminalActive() and not IsBrowserActive() and IsTypingEnabled()
}

IsBrowserShortcutActive(*) {
    return IsBrowserActive() and IsBrowserEnabled()
}

; Action Functions
DoCapsLockRemap(*) {
    Send("{Blind}{Tab}")
}

DoBluetoothRemap(*) {
    Run("explorer.exe ms-settings:bluetooth")
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
    global ThemeBg, ThemeFg, ThemeControlBg, ToggleOnBg, ToggleOffBg, EditBg, GroupBorderColor, AppTheme
    
    themeStyle := AppTheme
    if (themeStyle == "System") {
        themeStyle := IsSystemLightTheme() ? "Light" : "Dark"
    }
    
    if (themeStyle == "Light") {
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
    
    ; Add descriptive text label (styled with current theme text color and rounded layout spacing)
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

; ==============================================================================
; MODERN CONFIGURATION GUI (SYSTEM THEMED, PILL TOGGLES)
; ==============================================================================

ShowGui(startTab := 1) {
    global MyGui, TabCtrl
    if (MyGui) {
        TabCtrl.Value := startTab
        MyGui.Show()
    } else {
        CreateGui(startTab)
    }
}

CreateGui(startTab := 1) {
    global MyGui, TabCtrl, ChkCapsLockToTab, ChkHighPriority, ChkRemapWinK, DDLTheme, ChkEnabled
    global DDLLineModifier, DDLWordModifier
    global DDLTabLeftMod, DDLTabLeftKey, DDLTabRightMod, DDLTabRightKey
    global ChkDeleteLine, ChkSelectToEndOfLine, ChkSelectToStartOfLine
    global ChkMoveToEndOfLine, ChkMoveToStartOfLine, ChkMoveToTop, ChkMoveToBottom
    global ChkSelectToTop, ChkSelectToBottom, ChkDeleteWordLeft, ChkSelectWordRight
    global ChkSelectWordLeft, ChkMoveWordRight, ChkMoveWordLeft
    global ChkBrowserBack, ChkBrowserForward, ChkBrowserTabLeft, ChkBrowserTabRight
    global ChkStartup, SearchEdit, ShortcutLV
    global ExclusionLV, SearchExclusionEdit, ChkExclCapsLock, ChkExclTyping, ChkExclBrowser
    global Enabled, CapsLockToTab, HighPriority, RemapWinK, AppTheme, LineModifier, WordModifier, TabLeft, TabRight

    MyGui := Gui("-MinimizeBox -MaximizeBox", "KeyMapper Settings Panel")
    MyGui.BackColor := ThemeBg
    MyGui.SetFont("s10 c" . ThemeFg, "Segoe UI")
    
    ; Expanded dimensions to provide standard Windows 11 rounded layouts breathing room
    TabCtrl := MyGui.Add("Tab3", "w550 h480 c" . ThemeFg, ["Core Mappings", "Hotkeys Checklist", "App Exclusions", "Conflict Reference", "About"])
    
    ; --- TAB 1: Core Mappings ---
    TabCtrl.UseTab(1)
    
    MyGui.Add("GroupBox", "w510 h165 c" . GroupBorderColor . " x20 y50", "General Hardware & Engine Options")
    ChkCapsLockToTab := AddToggleSwitch(MyGui, 40, 75, CapsLockToTab, "Remap CapsLock to Tab")
    ChkHighPriority := AddToggleSwitch(MyGui, 40, 105, HighPriority, "High Priority Hook Mode")
    ChkRemapWinK := AddToggleSwitch(MyGui, 40, 135, RemapWinK, "Remap Win+K to Bluetooth")
    
    MyGui.Add("Text", "x40 y182 c" . ThemeFg, "Interface theme color:")
    DDLTheme := MyGui.Add("DropDownList", "x200 y178 w100", ["System", "Dark", "Light"])
    
    MyGui.Add("GroupBox", "w510 h110 c" . GroupBorderColor . " x20 y225", "Typing Modifier Assignments")
    MyGui.Add("Text", "x40 y250 c" . ThemeFg, "Line-level modifier:")
    DDLLineModifier := MyGui.Add("DropDownList", "x200 y245 w100", ["Ctrl", "Alt", "Win"])
    MyGui.Add("Text", "x315 y250 c888888", "(Mac Cmd-like line tasks)")
    
    MyGui.Add("Text", "x40 y290 c" . ThemeFg, "Word-level modifier:")
    DDLWordModifier := MyGui.Add("DropDownList", "x200 y285 w100", ["Ctrl", "Alt", "Win"])
    MyGui.Add("Text", "x315 y290 c888888", "(Mac Option-like word tasks)")
    
    MyGui.Add("GroupBox", "w510 h110 c" . GroupBorderColor . " x20 y345", "Browser Navigation Shortcuts")
    MyGui.Add("Text", "x40 y370 c" . ThemeFg, "Tab Navigation:")
    DDLTabLeftMod := MyGui.Add("DropDownList", "x160 y365 w100", ["Ctrl", "Alt", "Ctrl + Shift", "Win", "None"])
    MyGui.Add("Text", "x270 y370 c" . ThemeFg, "+")
    DDLTabLeftKey := MyGui.Add("DropDownList", "x290 y365 w80", ["[", "]", "Left", "Right", "PageUp", "PageDown", "Tab"])
    
    MyGui.Add("Text", "x40 y410 c" . ThemeFg, "History Navigation:")
    DDLTabRightMod := MyGui.Add("DropDownList", "x160 y405 w100", ["Ctrl", "Alt", "Ctrl + Shift", "Win", "None"])
    MyGui.Add("Text", "x270 y410 c" . ThemeFg, "+")
    DDLTabRightKey := MyGui.Add("DropDownList", "x290 y405 w80", ["[", "]", "Left", "Right", "PageUp", "PageDown", "Tab"])

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

    ; --- TAB 3: App Exclusions ---
    TabCtrl.UseTab(3)
    MyGui.Add("GroupBox", "w510 h380 c" . GroupBorderColor . " x20 y50", "App-Specific Bypass Settings")
    MyGui.Add("Text", "x40 y75 c" . ThemeFg, "Search app:")
    SearchExclusionEdit := MyGui.Add("Edit", "x120 y72 w220 h24 " . EditBg . " -E0x200")
    SearchExclusionEdit.OnEvent("Change", OnSearchExclusionChange)
    
    ExclusionLV := MyGui.Add("ListView", "x40 y105 w300 h220 c" . ThemeFg . " Background" . ThemeControlBg . " Grid -Multi", ["Executable Name"])
    ExclusionLV.ModifyCol(1, 275)
    ExclusionLV.OnEvent("Click", OnExclusionLVClick)
    
    AddBtn := MyGui.Add("Button", "x40 y335 w140 h30", "Add Custom App")
    AddBtn.OnEvent("Click", OnAddExclusionClick)
    
    RemoveBtn := MyGui.Add("Button", "x200 y335 w140 h30", "Remove App")
    RemoveBtn.OnEvent("Click", OnRemoveExclusionClick)
    
    ; Specific App Exclusion settings (displayed on selection)
    MyGui.Add("GroupBox", "w150 h250 c" . GroupBorderColor . " x360 y105", "Selection Actions")
    ChkExclCapsLock := AddToggleSwitch(MyGui, 370, 135, 0, "Bypass CapsLock")
    ChkExclTyping := AddToggleSwitch(MyGui, 370, 195, 0, "Bypass Modifiers")
    ChkExclBrowser := AddToggleSwitch(MyGui, 370, 255, 0, "Bypass Browser")
    
    ; Bind events on toggles to save immediately in INI
    ChkExclCapsLock.OnEvent("Click", OnToggleExclusionClick)
    ChkExclTyping.OnEvent("Click", OnToggleExclusionClick)
    ChkExclBrowser.OnEvent("Click", OnToggleExclusionClick)
    
    PopulateExclusionLV()

    ; --- TAB 4: Conflict Reference ---
    TabCtrl.UseTab(4)
    MyGui.Add("Text", "x20 y55 c" . ThemeFg, "Search standard Windows & Application hotkeys to avoid overlaps:")
    SearchEdit := MyGui.Add("Edit", "x20 y80 w510 h24 " . EditBg . " -E0x200")
    SearchEdit.OnEvent("Change", OnSearchEditChange)
    
    ShortcutLV := MyGui.Add("ListView", "x20 y115 w510 h310 c" . ThemeFg . " Background" . ThemeControlBg . " Grid", ["Shortcut", "Description", "Target Scope", "Conflict Risk"])
    ShortcutLV.ModifyCol(1, 120)
    ShortcutLV.ModifyCol(2, 180)
    ShortcutLV.ModifyCol(3, 110)
    ShortcutLV.ModifyCol(4, 80)
    
    PopulateConflictDatabase("")
 
    ; --- TAB 5: About ---
    TabCtrl.UseTab(5)
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
    ChkEnabled := AddToggleSwitch(MyGui, 20, 498, Enabled, "Enable Typing Remaps")
    
    SaveBtn := MyGui.Add("Button", "x300 y492 w110 h30 Default", "Save & Apply")
    SaveBtn.OnEvent("Click", OnSaveClick)
    
    CloseBtn := MyGui.Add("Button", "x420 y492 w110 h30", "Close to Tray")
    CloseBtn.OnEvent("Click", (*) => MyGui.Hide())
    
    SetGuiValues()
    
    MyGui.OnEvent("Close", (*) => MyGui.Hide())
    
    ; Select initial start tab index
    TabCtrl.Value := startTab
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
    global ChkCapsLockToTab, ChkHighPriority, ChkRemapWinK, DDLTheme, ChkEnabled
    global DDLLineModifier, DDLWordModifier
    global DDLTabLeftMod, DDLTabLeftKey, DDLTabRightMod, DDLTabRightKey
    global ChkDeleteLine, ChkSelectToEndOfLine, ChkSelectToStartOfLine
    global ChkMoveToEndOfLine, ChkMoveToStartOfLine, ChkMoveToTop, ChkMoveToBottom
    global ChkSelectToTop, ChkSelectToBottom, ChkDeleteWordLeft, ChkSelectWordRight
    global ChkSelectWordLeft, ChkMoveWordRight, ChkMoveWordLeft
    global ChkBrowserBack, ChkBrowserForward, ChkBrowserTabLeft, ChkBrowserTabRight
    global ChkStartup
    global Enabled, CapsLockToTab, HighPriority, RemapWinK, AppTheme, LineModifier, WordModifier, TabLeft, TabRight, BrowserBackKey, BrowserForwardKey

    SetToggleState(ChkCapsLockToTab, CapsLockToTab)
    SetToggleState(ChkHighPriority, HighPriority)
    SetToggleState(ChkRemapWinK, RemapWinK)
    SetToggleState(ChkEnabled, Enabled)
    
    ; App Theme dropdown choice
    themeIdx := 1
    for i, t in ["System", "Dark", "Light"] {
        if (t == AppTheme) {
            themeIdx := i
            break
        }
    }
    DDLTheme.Choose(themeIdx)
    
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
    global SettingsFile, MyGui, TabCtrl
    global ChkCapsLockToTab, ChkHighPriority, ChkRemapWinK, DDLTheme, ChkEnabled
    global DDLLineModifier, DDLWordModifier
    global DDLTabLeftMod, DDLTabLeftKey, DDLTabRightMod, DDLTabRightKey
    global ChkDeleteLine, ChkSelectToEndOfLine, ChkSelectToStartOfLine
    global ChkMoveToEndOfLine, ChkMoveToStartOfLine, ChkMoveToTop, ChkMoveToBottom
    global ChkSelectToTop, ChkSelectToBottom, ChkDeleteWordLeft, ChkSelectWordRight
    global ChkSelectWordLeft, ChkMoveWordRight, ChkMoveWordLeft
    global ChkBrowserBack, ChkBrowserForward, ChkBrowserTabLeft, ChkBrowserTabRight
    global ChkStartup

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
    IniWrite(GetToggleValue(ChkRemapWinK), SettingsFile, "General", "RemapWinK")
    IniWrite(DDLTheme.Text, SettingsFile, "General", "Theme")
    
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
    IniWrite(GetToggleValue(GetToggleValue(ChkMoveToTop)), SettingsFile, "Hotkeys", "MoveToTop") ; safety check
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
    
    ; Preserve currently active tab index to reload right back to it!
    activeTab := TabCtrl.Value
    
    TrayTip("KeyMapper", "Settings saved successfully! Restarting engine...", 1)
    Sleep(500)
    
    ; Restart engine while keeping current settings window open in foreground!
    if A_IsCompiled {
        Run('"' A_ScriptFullPath '" /restart /showgui ' . activeTab)
    } else {
        Run('*RunAs "' A_AhkPath '" /restart "' A_ScriptFullPath '" /showgui ' . activeTab)
    }
    ExitApp()
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
; EXCLUSIONS MANAGEMENT SYSTEM
; ==============================================================================

OnSearchExclusionChange(*) {
    global SearchExclusionEdit
    PopulateExclusionLV(SearchExclusionEdit.Text)
}

PopulateExclusionLV(query := "") {
    global ExclusionLV, ExclusionAppsList
    ExclusionLV.Delete()
    
    query := StrLower(query)
    for appName in ExclusionAppsList {
        if (appName == "") {
            continue
        }
        if (query == "" or InStr(StrLower(appName), query)) {
            ExclusionLV.Add(, appName)
        }
    }
}

OnExclusionLVClick(LV, RowNumber) {
    global SettingsFile
    global ChkExclCapsLock, ChkExclTyping, ChkExclBrowser
    
    if (RowNumber == 0) {
        return
    }
    
    appName := LV.GetText(RowNumber, 1)
    if (appName == "") {
        return
    }
    
    caps := IniRead(SettingsFile, "Exclusion_" . appName, "DisableCapsLock", "0") == "1" ? 1 : 0
    type := IniRead(SettingsFile, "Exclusion_" . appName, "DisableTyping", "0") == "1" ? 1 : 0
    brow := IniRead(SettingsFile, "Exclusion_" . appName, "DisableBrowser", "0") == "1" ? 1 : 0
    
    SetToggleState(ChkExclCapsLock, caps)
    SetToggleState(ChkExclTyping, type)
    SetToggleState(ChkExclBrowser, brow)
}

OnToggleExclusionClick(Ctrl, *) {
    global ExclusionLV, SettingsFile
    global ChkExclCapsLock, ChkExclTyping, ChkExclBrowser
    
    row := ExclusionLV.GetNext(0)
    if (row == 0) {
        MsgBox("Please select an application from the exclusions list first.")
        return
    }
    
    appName := ExclusionLV.GetText(row, 1)
    if (appName == "") {
        return
    }
    
    ; Flip toggle button state
    OnToggleClick(Ctrl)
    val := GetToggleValue(Ctrl)
    
    ; Save exclusion choice to ini immediately to preserve states during list clicks
    if (Ctrl == ChkExclCapsLock) {
        IniWrite(val, SettingsFile, "Exclusion_" . appName, "DisableCapsLock")
    } else if (Ctrl == ChkExclTyping) {
        IniWrite(val, SettingsFile, "Exclusion_" . appName, "DisableTyping")
    } else if (Ctrl == ChkExclBrowser) {
        IniWrite(val, SettingsFile, "Exclusion_" . appName, "DisableBrowser")
    }
}

OnAddExclusionClick(*) {
    global ExclusionAppsList, SettingsFile
    
    ib := InputBox("Enter the application process executable name to exclude:`n(e.g., discord.exe or photoshop.exe)", "Add Application Exclusion", "w300 h150")
    if (ib.Result == "OK" and ib.Value != "") {
        appName := Trim(ib.Value)
        if not InStr(appName, ".exe") {
            appName .= ".exe"
        }
        appName := StrLower(appName)
        
        ; Verify duplicate
        exists := false
        for app in ExclusionAppsList {
            if (app == appName) {
                exists := true
                break
            }
        }
        
        if (!exists) {
            ExclusionAppsList.Push(appName)
            SaveExclusionAppsList()
            
            ; Set safe defaults (disable typing modifiers and browser features)
            IniWrite("0", SettingsFile, "Exclusion_" . appName, "DisableCapsLock")
            IniWrite("1", SettingsFile, "Exclusion_" . appName, "DisableTyping")
            IniWrite("1", SettingsFile, "Exclusion_" . appName, "DisableBrowser")
            
            PopulateExclusionLV()
        }
    }
}

OnRemoveExclusionClick(*) {
    global ExclusionLV, ExclusionAppsList, SettingsFile
    
    row := ExclusionLV.GetNext(0)
    if (row == 0) {
        MsgBox("Please select an application to remove.")
        return
    }
    
    appName := ExclusionLV.GetText(row, 1)
    if (MsgBox("Are you sure you want to remove " . appName . " from exclusions?", "Confirm Exclusion Removal", "YesNo Icon!") == "Yes") {
        newArray := []
        for app in ExclusionAppsList {
            if (app != appName) {
                newArray.Push(app)
            }
        }
        ExclusionAppsList := newArray
        SaveExclusionAppsList()
        
        try {
            IniDelete(SettingsFile, "Exclusion_" . appName)
        }
        
        PopulateExclusionLV()
    }
}

SaveExclusionAppsList() {
    global ExclusionAppsList, SettingsFile
    appStr := ""
    for app in ExclusionAppsList {
        if (app == "") {
            continue
        }
        if (appStr != "") {
            appStr .= ","
        }
        appStr .= app
    }
    IniWrite(appStr, SettingsFile, "Exclusions", "Apps")
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
        {key: "Win + K", action: "Open Cast Dialog (Default)", scope: "Windows OS", conflict: "Medium (Customizable)"},
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