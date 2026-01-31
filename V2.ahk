#Requires AutoHotkey v2.0
#SingleInstance Force

; ==============================================================================
; 1. YOUR DATA (ORGANISED BY COLUMNS)
; ==============================================================================
; The layout has 3 Columns. Each Column has a list of "Sections".
ShortcutData := [
    ; ---------------- COLUMN 1 (LEFT) ----------------
    [
        {Title: "My AHK Scripts", Items: [
            {Key: "Ctrl + /",        Desc: "Cheatsheet"},
        ]},
        ; Second Section in Middle Column
        {Title: "Single", Items: [
            {Key: "Ctrl + Nump+",     Desc: "New Todoist note"},
            {Key: "Alt + Space",         Desc: "ChatGPT chat"}
        ]}
    ],

    ; ---------------- COLUMN 2 (MIDDLE) ----------------
    [
       {Title: "General", Items: [
            {Key: "Win + E",                  Desc: "File Explorer"},
            {Key: "Ctrl + Shift + N",         Desc: "New Folder"},
            {Key: "Win + .",                  Desc: "Emoji / Symbol Menu"},
            {Key: "Win + Shift + S",          Desc: "Screenshot"}
        ]}
    ],

    ; ---------------- COLUMN 3 (RIGHT) ----------------
    [
        ; Second Section in Right Column
        {Title: "OBSIDIAN", Items: [
            {Key: "Ctrl + O",        Desc: "Open File"},
            {Key: "Ctrl + G",        Desc: "Graph View"},
            {Key: "Ctrl + E",        Desc: "Read/Edit"}
        ]}
    ]
]

; ==============================================================================
; 2. VISUAL SETTINGS
; ==============================================================================
GuiWidth    := 900           ; Wider to fit 3 columns
ColWidth    := 280           ; Width of one column
ColGap      := 20            ; Gap between columns
HeaderH     := 80            ; Top padding for "Cheatsheet" title
FooterH     := 40            ; Bottom padding
SectionGap  := 25            ; Space between "Notion" and "Listary" groups
ItemHeight  := 25            ; Height of one shortcut line

; Colors & Fonts
BorderColor := "8a8a8a"
BorderWidth := 0
FontColor   := "FFFFFF"
KeyColor    := "8a8a8a"      ; Cyan for keys
SectionColor:= "b5b5b5"      ; Gold/Yellow for Section Titles (Windows, Notion...)

; FONTS (Family Name Only)
TitleFont   := "Faustina"
TextFont    := "Faustina"

WindowTitle := "CheatSheetUI"
global MyGui := unset

; ==============================================================================
; HOTKEY: CTRL + /
; ==============================================================================
^/::
{
    global MyGui
    if IsSet(MyGui) && MyGui
        CloseGui()
    else
        CreateGui()
}

#HotIf WinActive(WindowTitle)
Esc::CloseGui()
#HotIf

CloseGui()
{
    global MyGui
    if IsSet(MyGui) && MyGui
    {
        try MyGui.Destroy()
        MyGui := unset
    }
}

; ==============================================================================
; GUI CREATION LOGIC
; ==============================================================================
CreateGui()
{
    global MyGui, GuiWidth, GuiHeight, TitleFont, TextFont
    
    ; 1. Calculate Total Height
    ; We need to simulate the drawing to find which column is the tallest
    MaxHeight := 0
    for Column in ShortcutData {
        ColH := 0
        for Section in Column {
            ColH += 30 ; Section Title Height
            ColH += (Section.Items.Length * ItemHeight)
            ColH += SectionGap
        }
        if (ColH > MaxHeight)
            MaxHeight := ColH
    }
    GuiHeight := HeaderH + MaxHeight + FooterH

    ; 2. Create Window
    MyGui := Gui("-Caption +ToolWindow +AlwaysOnTop +Owner", WindowTitle)
    MyGui.BackColor := "000000"
    
    ; --- MAIN HEADER ---
    MyGui.SetFont("c" FontColor " s26 w700", TitleFont)
    MyGui.Add("Text", "x0 y25 w" GuiWidth " Center BackgroundTrans", "Cheatsheet")

    ; --- DRAW COLUMNS ---
    CurrentX := (GuiWidth - (3 * ColWidth) - (2 * ColGap)) / 2 ; Center the whole grid
    
    for Column in ShortcutData
    {
        CurrentY := HeaderH
        
        for Section in Column
        {
            ; A. Section Title (e.g., "NOTION")
            MyGui.SetFont("c" SectionColor " s14 w700 ", TitleFont)
            MyGui.Add("Text", "x" CurrentX " y" CurrentY " w" ColWidth " Center BackgroundTrans", Section.Title)
            CurrentY += 35
            
            ; B. Shortcuts
            for Item in Section.Items
            {
                ; Key (Left side of column)
                MyGui.SetFont("c" KeyColor " s11 w600", TextFont)
                MyGui.Add("Text", "x" CurrentX " y" CurrentY " w" (ColWidth/2 - 5) " Right BackgroundTrans", Item.Key)
                
                ; Desc (Right side of column)
                MyGui.SetFont("c" FontColor " s11 w400", TextFont)
                MyGui.Add("Text", "x+10 y" CurrentY " w" (ColWidth/2 - 5) " Left BackgroundTrans", Item.Desc)
                
                CurrentY += ItemHeight
            }
            
            CurrentY += SectionGap ; Add space before next section
        }
        
        CurrentX += ColWidth + ColGap ; Move to next column
    }

    ; 3. Show Window
    MyGui.Show("w" GuiWidth " h" GuiHeight " Center")

    ; 4. Apply Effects
    try {
        hwnd := MyGui.Hwnd
        DllCall("dwmapi\DwmSetWindowAttribute", "ptr", hwnd, "int", 33, "ptr*", 2, "int", 4)
        EnableBlur(hwnd, 0xCC000000) 
    } catch {
        WinSetRegion("0-0 w" GuiWidth " h" GuiHeight " R24-24", MyGui.Hwnd)
    }

    OnMessage(0x000F, DrawBorder) 
    WinRedraw("ahk_id " MyGui.Hwnd)
    SetTimer(CheckFocus, 100)
}

CheckFocus()
{
    global MyGui
    if !IsSet(MyGui) || !MyGui {
        SetTimer(CheckFocus, 0)
        return
    }
    if !WinActive("ahk_id " MyGui.Hwnd) {
        CloseGui()
        SetTimer(CheckFocus, 0)
    }
}

DrawBorder(wParam, lParam, msg, hwnd) 
{
    global MyGui, GuiWidth, GuiHeight, BorderColor, BorderWidth
    if !IsSet(MyGui) || (hwnd != MyGui.Hwnd)
        return

    try {
        PAINTSTRUCT := Buffer(64, 0)
        hDC := DllCall("BeginPaint", "Ptr", hwnd, "Ptr", PAINTSTRUCT)
        hPen := DllCall("CreatePen", "Int", 0, "Int", BorderWidth, "UInt", BorderColor, "Ptr")
        hOldPen := DllCall("SelectObject", "Ptr", hDC, "Ptr", hPen)
        hBrush := DllCall("GetStockObject", "Int", 5) 
        hOldBrush := DllCall("SelectObject", "Ptr", hDC, "Ptr", hBrush)
        DllCall("RoundRect", "Ptr", hDC, "Int", 0, "Int", 0, "Int", GuiWidth-1, "Int", GuiHeight-1, "Int", 24, "Int", 24)
        DllCall("SelectObject", "Ptr", hDC, "Ptr", hOldBrush)
        DllCall("SelectObject", "Ptr", hDC, "Ptr", hOldPen)
        DllCall("DeleteObject", "Ptr", hPen)
        DllCall("EndPaint", "Ptr", hwnd, "Ptr", PAINTSTRUCT)
    }
}

EnableBlur(hwnd, accentColor) 
{
    static WCA_ACCENT_POLICY := 19
    ACCENT_POLICY := Buffer(16, 0)
    NumPut("int", 3, ACCENT_POLICY, 0)
    NumPut("int", 0, ACCENT_POLICY, 4)
    NumPut("int", accentColor, ACCENT_POLICY, 8) 
    WINCOMPATTRDATA := Buffer(24, 0)
    NumPut("int", WCA_ACCENT_POLICY, WINCOMPATTRDATA, 0)
    NumPut("ptr", ACCENT_POLICY.Ptr, WINCOMPATTRDATA, 8)
    NumPut("int", 16, WINCOMPATTRDATA, 16)
    DllCall("user32\SetWindowCompositionAttribute", "ptr", hwnd, "ptr", WINCOMPATTRDATA)
}