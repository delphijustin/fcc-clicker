Max_Time := RegRead("HKEY_CURRENT_USER\SOFTWARE\Justin\FCCClicker","MaxTime",21600000)
FCC_MODES := RegRead("HKEY_CURRENT_USER\SOFTWARE\Justin\FCCClicker","Modes","")
lastpid := RegRead("HKEY_CURRENT_USER\SOFTWARE\Justin\FCCClicker","ClickerPID",0)
ConsoleDelay := RegRead("HKEY_CURRENT_USER\SOFTWARE\Justin\FCCClicker","ConsoleDelay",0)
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
DllCall("AllocConsole") ; Allocate a console window
ConsoleOut := FileOpen("CONOUT$", "w")
ConsoleHandle := DllCall("GetConsoleWindow", "UInt")
DllCall("SetConsoleTitle","Str","FCC is about to restart")
loop:
try
{
DllCall("User32\ShowWindow", "UInt", ConsoleHandle, "Int", 0) ; 0 = SW_HIDE
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
;wait 6 hours. The usual limit for time on a meeting
}
catch as e
{
DllCall("User32\ShowWindow", "UInt", ConsoleHandle, "Int", 5) ; 5 = SW_SHOW
ConsoleOut.WriteLine("[" FormatTime() "] Exception: " e.message)
Sleep 15000
}
if (ConsoleDelay=0)
goto loop
DllCall("User32\ShowWindow", "UInt", ConsoleHandle, "Int", 5) ; 5 = SW_SHOW
ConsoleOut.WriteLine("[" FormatTime() "] In " ConsoleDelay " seconds FCC will restart...")
Sleep ConsoleDelay*1000
goto loop
