Function AreAllCharsInString(source, target)
    Dim i, char
    For i = 1 To Len(source)
        char = Mid(source, i, 1) ' Get each character from the source
        If InStr(1, target, char, vbTextCompare) = 0 Then
            ' Character not found in the target
            AreAllCharsInString = Asc(char)
            Exit Function
        End If
    Next
    ' All characters were found
    AreAllCharsInString = 256
End Function
function MinuteInt(timeString)
Dim parts, hours, minutes
parts = Split(timeString, ":")
hours = CInt(parts(0)) ' Convert hours to an integer
minutes = CInt(parts(1)) ' Convert minutes to an integer
MinuteInt=(hours * 60) + minutes
end function
Function MillisecondsUntil(targetTime)
    Dim nowTime, secondsLeft
    if InStr(targetTime,"/")+InStr(targetTime,"-")=0 then
    nowTime = Time
    else
    nowTime = Now
    end if
    secondsLeft = DateDiff("s", nowTime, targetTime)
    If secondsLeft < 0 Then
        MillisecondsUntil = 0 ' Return 0 if the time has passed
    Else
        MillisecondsUntil = secondsLeft * 1000
    End If
End Function
function KillProcess(processID)
KillProcess=1
' Create the WMI object
Set objWMIService = GetObject("winmgmts:\\.\root\cimv2")

' Query for the process with the specified PID
Set colProcesses = objWMIService.ExecQuery("SELECT * FROM Win32_Process WHERE ProcessId = " & processID)

' Check if any process matches the PID and terminate it
If colProcesses.Count = 0 Then
    Exit Function
Else
    For Each objProcess In colProcesses
        objProcess.Terminate()
        KillProcess=0
    Next
End If
End Function
Dim wshshell
set wshshell=WScript.CreateObject("WScript.Shell")
Dim argCount
Dim modes,minutes
argCount = WScript.Arguments.Count
If argCount = 0 Then
WScript.Echo "Usage: controlfcc.vbs [/stop:WORD] ["&Chr(34)&"/record[:][hh:mm]]"&Chr(34)&" [/modes:Modes] [/maxtime:milliseconds]" & vbCrLf & "Modes:" & vbCrLf & "H     Minimizes the FCC window when done starting the conference" & vbCrLf & "N     Disables noise reduction" & vbCrLf & "K     Autokill FCC if is running without asking" & vbCrLf & "!     Remove the current modes from the registry" & vbCrLf  & vbCrLf & "/maxtime     Changes the default reset timeout, the default is 21600000 milliseconds(6 hours)" & vbCrLf & "/record    Start recording and keep recording until the time runs out. To end recording at a certain time make sure the time parameter contains AM or PM" & vbCrLf & "/stop    Stops Clicker and or Conference Call if WORD equals all if its ahk it stops the Clicker if its fcc it justs Stops the conference call"
WScript.Quit 0
end if
wshshell.RegRead "HKEY_CURRENT_USER\Software\Justin\FCCClicker\Memory\"
if WScript.Arguments.Named.Exists("stop") then
ykill=0
if InStr(WScript.Arguments.Named("stop"),"ahk")+InStr(WScript.Arguments.Named("stop"),"all")>0 then
yKill=KillProcess(wshshell.RegRead("HKEY_CURRENT_USER\Software\Justin\FCCClicker\Memory\ClickerPID"))
end if
if InStr(WScript.Arguments.Named("stop"),"fcc")+InStr(WScript.Arguments.Named("stop"),"all")>0 then
yKill=yKill+(2*KillProcess(wshshell.RegRead("HKEY_CURRENT_USER\Software\Justin\FCCClicker\Memory\FCC_PID")))
end if
WScript.Quit yKill
end if
if WScript.Arguments.Named.Exists("record") then
if InStr(WScript.Arguments.Named("record"),"M")+InStr(WScript.Arguments.Named("record"),"m")=0 then
if WScript.Arguments.Named("record")="" then
rectime=21600000
else
rectime=MinuteInt(WScript.Arguments.Named("record"))*60000
end if
else
rectime=MillisecondsUntil(WScript.Arguments.Named("record"))
end if
wshshell.RegWrite "HKEY_CURRENT_USER\Software\Justin\FCCClicker\Memory\RecordDuration",rectime,"REG_DWORD"
wshshell.Run "fccrecord.exe"
end if
if WScript.Arguments.Named.Exists("modes")then
modes=WScript.Arguments.Named("modes")
badchr=AreAllCharsInString(modes,"nhNHkK!")
if badchr<256 then
WScript.echo "'"&Chr(badchr)&"' character is not a valid mode."
WScript.Quit 1
end if
if InStr(modes,"!")>0 then
wshshell.RegWrite "HKEY_CURRENT_USER\Software\Justin\FCCClicker\Modes","","REG_SZ"
else
wshshell.RegWrite "HKEY_CURRENT_USER\Software\Justin\FCCClicker\Modes",modes,"REG_SZ"
end if
end if
if WScript.Arguments.Named.Exists("maxtime")then
max_time=CInt(WScript.Arguments.Named("maxtime"))
if max_time=0 then
max_time=21600000
end if
wshshell.RegWrite "HKEY_CURRENT_USER\Software\Justin\FCCClicker\MaxTime",max_time,"REG_DWORD"
end if
