AboutBox(ItemName,ItemPos,MyMenu){
DllCall("delphian32\DisplayAboutBoxA","UInt",0)
}
DonateClick(ItemName, ItemPos, MyMenu) {
if InStr(ItemName,"PayPal")
{
DonError:=DllCall("delphian32.dll\Donate","Int",1,"UInt",0,"Int")
if not(DonError=1)
MsgBox "Donation failed to open(" DonError ")"
return
}
if InStr(ItemName,"CashApp")
{
DonError:=DllCall("delphian32.dll\Donate","Int",2,"UInt",0,"Int")
if not(DonError=1)
MsgBox "Donation failed to open(" DonError ")"
return
}
MsgBox "Unknown donation error"
}
A_TrayMenu.Add("About FCCClicker",AboutBox)
A_TrayMenu.Add("Donate PayPal",DonateClick)
A_TrayMenu.Add("Donate CashApp",DonateClick)
Max_Time := RegRead("HKEY_CURRENT_USER\SOFTWARE\Justin\FCCClicker","MaxTime",21600000)
FCC_MODES := RegRead("HKEY_CURRENT_USER\SOFTWARE\Justin\FCCClicker","Modes","")
lastpid := RegRead("HKEY_CURRENT_USER\SOFTWARE\Justin\FCCClicker","ClickerPID",0)
if ProcessExist(lastpid)
{
choice:="."
if InStr(FCC_MODES,"K")
choice:="Yes"
if (choice=".")
{
choice:=MsgBox("FCClicker is running, kill it?","delphijustin FCCClicker","YesNo")
}
if not (choice="Yes")
ExitApp 2
RegDelete "HKEY_CURRENT_USER\SOFTWARE\Justin\FCCClicker","ClickerPID"
ProcessClose lastpid 
}
thispid:=ProcessExist()
RegWrite thispid,"REG_DWORD","HKEY_CURRENT_USER\SOFTWARE\Justin\FCCClicker","ClickerPID"
loop:
fcc_dir := RegRead("HKEY_CURRENT_USER\SOFTWARE\FreeConferenceCall","InstallLocation")
;find the install path in the registry
fcc_pid := ProcessExist("freeconferencecall.exe")
if (fcc_pid > 0)
ProcessClose fcc_pid
Run "FreeConferenceCall.exe",fcc_dir
;execute fcc
;wait for the program to load
fcc_pid := ProcessExist("freeconferencecall.exe")
RegWrite fcc_pid,"REG_DWORD","HKEY_CURRENT_USER\SOFTWARE\Justin\FCCClicker","FCC_PID"
WinWait "FreeConferenceCall"
WinRestore "FreeConferenceCall"
WinActivate "FreeConferenceCall"
;activate the main window
Sleep 4096
MouseMove 788,541
Sleep 4096
MouseClick
Sleep 10240
MouseMove 521,508
MouseClick
Sleep 4096
MouseMove 446,474
MouseClick
Sleep 4096
MouseMove 524,547
MouseClick
Sleep 4096
if InStr(FCC_MODES,"N")
{
;disable noise reduction
MouseMove 975,732
MouseClick
WinWait "Test"
Sleep 1024
MouseMove 79,184
MouseClick
Sleep 1024
MouseMove 865,275
Sleep 1024
MouseClick
Sleep 1024
MouseMove 875,23
MouseClick
Sleep 4096
}
if InStr(FCC_MODES,"H")
{
WinMinimize "FreeConferenceCall"
;minimizes FCC
}
Sleep Max_Time
goto loop
