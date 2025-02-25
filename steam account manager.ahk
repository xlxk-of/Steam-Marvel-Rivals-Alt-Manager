#Requires AutoHotkey v2.0
#SingleInstance Force

; Configuration
iniFile := "SteamAccounts.ini"
steamExePath := ""
accounts := Map()
mainGui := ""  ; Added global variable for main GUI

; Read existing data
ReadINI()
BuildGUI()
return

; Read INI file
ReadINI() {
    global
    
    ; Read Steam path
    if FileExist(iniFile)
        steamExePath := IniRead(iniFile, "Steam", "Path", "")
    
    ; Read accounts
    if FileExist(iniFile) {
        accountList := IniRead(iniFile, "Accounts", "List", "")
        accountIDs := StrSplit(accountList, ",")
        
        for id in accountIDs {
            if id = ""
                continue
            
            account := Map()
            account["ID"] := id
            account["Username"] := IniRead(iniFile, id, "Username", "")
            account["Email"] := IniRead(iniFile, id, "Email", "")
            account["Password"] := IniRead(iniFile, id, "Password", "")
            account["Note"] := IniRead(iniFile, id, "Note", "")
            account["NoteExpanded"] := IniRead(iniFile, id, "NoteExpanded", 0)
            accounts[id] := account
        }
    }
}

; Save INI file
SaveINI() {
    global
    
    ; Save Steam path
    IniWrite(steamExePath, iniFile, "Steam", "Path")
    
    ; Save accounts
    accountList := ""
    for id, account in accounts
        accountList .= (accountList ? "," : "") . id
    
    IniWrite(accountList, iniFile, "Accounts", "List")
    
    for id, account in accounts {
        IniWrite(account["Username"], iniFile, id, "Username")
        IniWrite(account["Email"], iniFile, id, "Email")
        IniWrite(account["Password"], iniFile, id, "Password")
        IniWrite(account["Note"], iniFile, id, "Note")
        IniWrite(account["NoteExpanded"], iniFile, id, "NoteExpanded")
    }
}

BuildGUI() {
    global mainGui
    
    ; Destroy existing GUI if it exists
    if WinExist("Steam Account Manager")
        mainGui.Destroy()
    
    ; Create new GUI
    mainGui := Gui("+Resize +MinSize300x600", "Steam Account Manager")
    mainGui.BackColor := "1A1A1A"
    mainGui.SetFont("cWhite s10 w1000", "Inter")
    
    ; Header buttons
    mainGui.Add("Text", "x20 y20 w100 h30 c4AA5FF Background1A1A1A", "Add Account").OnEvent("Click", AddAccount)
    mainGui.Add("Text", "x+20 yp w150 h30 c4AA5FF Background1A1A1A", "Set Steam Path").OnEvent("Click", SetSteamPath)
    
    ; Add account controls
    yPos := 80
    for id, account in accounts {
        yPos := AddAccountControls(mainGui, account, yPos)
    }
    
    ; Show GUI
    mainGui.Show("w300 AutoSize")
}


; Add account controls to the GUI
AddAccountControls(myGui, account, yPos) {
    global
    mainGui.SetFont("cWhite s10 w1000", "Inter")
    ; Username
    myGui.SetFont("w600")
    myGui.Add("Text", "x20 y" yPos " w100 h20", "Username:")
    myGui.SetFont("w400")
    myGui.Add("Text", "x120 y" yPos " w200 h20", account["Username"])
    yPos += 25
    
    ; Email (private with tooltip)
    myGui.SetFont("w600")
    myGui.Add("Text", "x20 y" yPos " w100 h20", "Email:")
    myGui.SetFont("w400")
    
    ; Create private email string
    emailLength := StrLen(account["Email"])
    privateEmail := "•••••••••••"  ; 11 dots for consistent look
    
    ; Add email text with hover capability
    emailText := myGui.Add("Text", "x120 y" yPos " w200 h20", privateEmail)
    
    ; Add tooltip functionality
    emailText.OnEvent("Click", (*) => ShowEmailTooltip(account["Email"]))
    emailText.OnEvent("DoubleClick", (*) => ToolTip())  ; Hide tooltip when mouse leaves
    
    yPos += 25
    
    ; Buttons
    btnW := 80
    spacing := 10
    xPos := 20
    mainGui.SetFont("c4AA5FF s10 w1000", "Inter")
    myGui.Add("Text", "x" xPos " y" yPos " w" btnW " h25", "Login").OnEvent("Click", (*) => LoginAccount(account["ID"]))
    xPos += btnW + spacing
    myGui.Add("Text", "x" xPos " y" yPos " w" btnW " h25", "Edit").OnEvent("Click", (*) => EditAccount(account["ID"]))
    xPos += btnW + spacing
    mainGui.SetFont("cff564a s10 w1000", "Inter")
    myGui.Add("Text", "x" xPos " y" yPos " w" btnW " h25", "Delete").OnEvent("Click", (*) => DeleteAccount(account["ID"]))
    xPos += btnW + spacing
    mainGui.SetFont("c4AA5FF s10 w1000", "Inter")
    showNoteText := account["NoteExpanded"] ? "Hide Note" : "Show Note"
    myGui.Add("Text", "x" xPos " y" yPos " w" btnW " h25", showNoteText).OnEvent("Click", (*) => ToggleNote(account["ID"]))
    xPos += btnW + spacing
    mainGui.SetFont("ce8f1be s10 w1000", "Inter")
    myGui.Add("Text", "x" xPos " y" yPos " w" btnW " h25", "Stats").OnEvent("Click", (*) => OpenTrackerProfile(account["Username"]))
    yPos += 30
    mainGui.SetFont("cWhite s10 w1000", "Inter")
    ; Note
    if (account["NoteExpanded"]) {
        myGui.Add("Edit", "x20 y" yPos " w300 h100 ReadOnly -Wrap Background1A1A1A cWhite", account["Note"])
        yPos += 110
    }
    
    ; Separator
    myGui.Add("Text", "x0 y" yPos " w400 h1 0x7")
    yPos += 10
    
    return yPos
}

ShowEmailTooltip(email) {
    ToolTip(email)
}

OpenTrackerProfile(username) {
    trackerUrl := "https://tracker.gg/marvel-rivals/profile/ign/" username "/overview?mode=competitive"
    Run(trackerUrl)
}

; Login to Steam account
LoginAccount(accountID) {
    global
    
    if (steamExePath = "") {
        MsgBox("Steam path not set!", "Error", "OK IconX")
        return
    }
    
    account := accounts[accountID]
    Run(steamExePath ' -login ' account["Email"] ' ' account["Password"], , "Hide")
}

; Edit account details
EditAccount(accountID) {
    global mainGui
    
    account := accounts[accountID]
    editGui := Gui("Owner" . mainGui.Hwnd, "Edit Account")
    editGui.BackColor := "1A1A1A"
    editGui.SetFont("cWhite s9", "Segoe UI")
    
    editGui.Add("Text", "x20 y20 w100 h20", "Username:")
    editGui.Add("Edit", "x120 y20 w200 h20 vEditUsername Background1A1A1A cWhite", account["Username"])
    editGui.Add("Text", "x20 y60 w100 h20", "Email:")
    editGui.Add("Edit", "x120 y60 w200 h20 vEditEmail Background1A1A1A cWhite", account["Email"])
    editGui.Add("Text", "x20 y100 w100 h20", "Password:")
    editGui.Add("Edit", "x120 y100 w200 h20 Password vEditPassword Background1A1A1A cWhite", account["Password"])
    editGui.Add("Text", "x20 y140 w100 h20", "Note:")
    editGui.Add("Edit", "x120 y140 w200 h100 vEditNote Background1A1A1A cWhite", account["Note"])
    editGui.Add("Button", "x120 y260 w100 h30", "Save").OnEvent("Click", (*) => SaveEdit(accountID, editGui))
    
    editGui.Show()
}

; Save edited account details
SaveEdit(accountID, editGui) {
    global
    
    editGui.Submit()
    account := accounts[accountID]
    account["Username"] := editGui["EditUsername"].Value
    account["Email"] := editGui["EditEmail"].Value
    account["Password"] := editGui["EditPassword"].Value
    account["Note"] := editGui["EditNote"].Value
    SaveINI()
    BuildGUI()
    editGui.Destroy()
}

; Delete an account
DeleteAccount(accountID) {
    global
    
    result := MsgBox("Are you sure you want to delete this account?", "Confirm", "YesNo Icon!")
    if (result = "No")
        return
    
    accounts.Delete(accountID)
    SaveINI()
    BuildGUI()
}

; Toggle note visibility
ToggleNote(accountID) {
    global
    
    account := accounts[accountID]
    account["NoteExpanded"] := !account["NoteExpanded"]
    SaveINI()
    BuildGUI()
}

; Add a new account
AddAccount(*) {
    global mainGui
    
    addGui := Gui("Owner" . mainGui.Hwnd, "Add Account")
    addGui.BackColor := "1A1A1A"
    addGui.SetFont("cWhite s9", "Segoe UI")
    
    addGui.Add("Text", "x20 y20 w100 h20", "Username:")
    addGui.Add("Edit", "x120 y20 w200 h20 vNewUsername Background1A1A1A cWhite")
    addGui.Add("Text", "x20 y60 w100 h20", "Email:")
    addGui.Add("Edit", "x120 y60 w200 h20 vNewEmail Background1A1A1A cWhite")
    addGui.Add("Text", "x20 y100 w100 h20", "Password:")
    addGui.Add("Edit", "x120 y100 w200 h20 Password vNewPassword Background1A1A1A cWhite")
    addGui.Add("Text", "x20 y140 w100 h20", "Note:")
    addGui.Add("Edit", "x120 y140 w200 h100 vNewNote Background1A1A1A cWhite")
    addGui.Add("Button", "x120 y260 w100 h30", "Save").OnEvent("Click", (*) => SaveNewAccount(addGui))
    
    addGui.Show()
}

; Save new account
SaveNewAccount(addGui) {
    global
    
    addGui.Submit()
    newAccount := Map(
        "ID", A_Now,
        "Username", addGui["NewUsername"].Value,
        "Email", addGui["NewEmail"].Value,
        "Password", addGui["NewPassword"].Value,
        "Note", addGui["NewNote"].Value,
        "NoteExpanded", 0
    )
    accounts[newAccount["ID"]] := newAccount
    SaveINI()
    BuildGUI()
    addGui.Destroy()
}

; Set Steam path
SetSteamPath(*) {
    global
    
    selectedPath := FileSelect(3, , "Select Steam Executable", "Executable (*.exe)")
    if (selectedPath != "") {
        steamExePath := selectedPath
        SaveINI()
    }
}

; Exit script
GuiClose(*) {
    ExitApp()
}