# KeyMapper

A lightweight, battery-efficient Windows key remapping utility with a modern Windows 11 system-themed interface (Light/Dark mode) and interactive toggle switches. Built entirely on **AutoHotkey v2**.

<!-- Insert Screenshot Here -->
<img width="800" height="800" alt="image" src="https://github.com/user-attachments/assets/9c268933-a251-4f83-9b73-30c2c98d9478" />

### Features

* **Hardware Fix (CapsLock -> Tab):** Remaps CapsLock directly to Tab with Shift-modifier inheritance (e.g., `Shift + CapsLock` sends `Shift + Tab` for reverse indentation). Works inside elevated Administrator windows like Windows Terminal.
* **Typing Customizations:**
  * **Line-Level Operations (Default: `Alt`):** Mac-like shortcuts for line deletions (`Alt + BS`), line selection, and line jumps.
  * **Word-Level Operations (Default: `Ctrl`):** Quick word jumps and word-by-word selections.
  * **Page-Level Navigation:** Always bound to `Ctrl + Up` and `Ctrl + Down` to quickly jump or select to the top/bottom of documents.
* **Dual Browser Shortcuts (Scoped to Chrome, Firefox, Edge, Brave, Opera):**
  * **Tab Switch (Default: `Ctrl + [` / `Ctrl + ]`):** Jump left/right between open tabs.
  * **History Nav (Default: `Alt + [` / `Alt + ]`):** Go backward/forward in browser history. Native `Alt + Left/Right` remains fully functional.
* **Modern Windows 11 Toggle UI:** Fully custom pill-toggles (ON/OFF buttons) that automatically adapt to your Windows system Light/Dark theme.
* **Shortcuts Conflict Reference:** Searchable real-time directory listing standard Windows/browser hotkeys to prevent overlap.
* **Terminal Bypass:** Custom text editing shortcuts are automatically bypassed inside CLI environments (Windows Terminal, Cmd, PowerShell) to prevent command conflicts, while CapsLock-to-Tab remains globally active.

---

### Setup

1. **Install AutoHotkey v2:** Download and install the latest stable version of **[AutoHotkey v2](https://www.autohotkey.com/)**.
2. **Download KeyMapper:** Place `mac-keys.ahk` and `settings.ini` in the same directory.
3. **Run the Script:** Double-click `mac-keys.ahk`. 
   * *Note: KeyMapper automatically requests UAC Administrator elevation on launch to ensure keyboard hooks function correctly inside elevated programs like Windows Terminal.*
4. **Configure:** Right-click the green tray icon and select **Configure Settings** or double-click it to customize modifiers and toggle specific hotkeys.
5. **Set Startup (Optional):** Check the **Windows Auto-Startup** toggle under the *About* tab in the settings panel to run KeyMapper automatically when logging in.
