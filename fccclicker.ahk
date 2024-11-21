#SingleInstance Off
AboutBox(ItemName,ItemPos,MyMenu){
DllCall("delphian32.dll\DisplayAboutBoxA","UInt",0,"Int",1)
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
Quit(ExitReason, ExitCode)
{
RegDelete "HKEY_CURRENT_USER\SOFTWARE\Justin\FCCClicker\Memory","ClickerPID"
}
try
{

OnExit Quit
RegCreateKey "HKEY_CURRENT_USER\SOFTWARE\Justin\FCCClicker"
; Constants for RegCreateKeyEx
HKEY_CURRENT_USER := 0x80000001
REG_OPTION_VOLATILE := 1
KEY_ALL_ACCESS := 0xF003F

; Variables for the key
keyPath := "Software\Justin\FCCClicker\Memory"
phkResult := 0

; Load the function
vkeyError:=DllCall("Advapi32\RegCreateKeyExA", "UInt", HKEY_CURRENT_USER, "Str", keyPath
    , "UInt", 0, "UInt", 0, "UInt", REG_OPTION_VOLATILE
    , "UInt", KEY_ALL_ACCESS, "UInt", 0, "UInt*", phkResult, "UInt*", 0,"Int")
if not (vkeyError=0)
{
MsgBox "Couldn't create volatile key. Aborting... Error#" vkeyError,"FCCClicker","iconx"
ExitApp 1
}
DllCall("Advapi32\RegCloseKey", "UInt", phkResult)

A_TrayMenu.Add("About FCCClicker",AboutBox)
A_TrayMenu.Add("Donate PayPal",DonateClick)
A_TrayMenu.Add("Donate CashApp",DonateClick)
Max_Time := RegRead("HKEY_CURRENT_USER\SOFTWARE\Justin\FCCClicker","MaxTime",21600000)
FCC_MODES := RegRead("HKEY_CURRENT_USER\SOFTWARE\Justin\FCCClicker","Modes","")
lastpid := RegRead("HKEY_CURRENT_USER\SOFTWARE\Justin\FCCClicker\Memory","ClickerPID",0)

if ProcessExist(lastpid)
{
choice:="."
if InStr(FCC_MODES,"K")
choice:="Yes"
if (choice=".")
{
choice:=MsgBox("FCClicker is running, kill it?","delphijustin FCCClicker","YesNo Icon?")
}
if not (choice="Yes")
ExitApp 2
RegDelete "HKEY_CURRENT_USER\SOFTWARE\Justin\FCCClicker\Memory","ClickerPID"
ProcessClose lastpid 
}
thispid:=ProcessExist()
RegWrite thispid,"REG_DWORD","HKEY_CURRENT_USER\SOFTWARE\Justin\FCCClicker\Memory","ClickerPID"
loop:
whr := ComObject("WinHttp.WinHttpRequest.5.1")
whr.Open("GET", "http://delphianserver.com/internetTest.txt?" A_TickCount, true)
whr.Send()
; Using 'true' above and the call below allows the script to remain responsive.
whr.WaitForResponse()
if (InStr(whr.ResponseText,"ERROR_SUCCESS",1)=1)
{
RegWrite "[OK]" A_Now,"REG_SZ","HKEY_CURRENT_USER\SOFTWARE\Justin\FCCClicker\Memory","InternetSuccess"
}
else
{
RegWrite "[ERROR]" A_Now,"REG_SZ","HKEY_CURRENT_USER\SOFTWARE\Justin\FCCClicker\Memory","InternetSuccess"
Sleep 10240
goto loop
}
fcc_dir := RegRead("HKEY_CURRENT_USER\SOFTWARE\FreeConferenceCall","InstallLocation")
;find the install path in the registry
fcc_pid := ProcessExist("freeconferencecall.exe")
if (fcc_pid > 0)
ProcessClose fcc_pid
Run "FreeConferenceCall.exe",fcc_dir
;execute fcc
;wait for the program to load
fcc_pid := ProcessExist("freeconferencecall.exe")
RegWrite fcc_pid,"REG_DWORD","HKEY_CURRENT_USER\SOFTWARE\Justin\FCCClicker\Memory","FCC_PID"
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
}
catch as e
{
RegWrite e.file "(" e.line "):" e.Message,"REG_SZ","HKEY_CURRENT_USER\SOFTWARE\Justin\FCCClicker\Memory","LastException"
Sleep 2048
}
reload
