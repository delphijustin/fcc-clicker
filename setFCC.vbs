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
Dim wshshell
set wshshell=WScript.CreateObject("WScript.Shell")
Dim argCount
Dim modes
argCount = WScript.Arguments.Count
If argCount = 0 Then
WScript.Echo "Usage: setFCC.vbs [/modes:Modes] [/cdelay:seconds]" & vbCrLf & "Modes:" & vbCrLf & "H     Minimizes the FCC window when done starting the conference" & vbCrLf & "N     Disables noise reduction" & vbCrLf & "K     Autokill FCC if is running without asking" & vbCrLf & "!     Remove the current modes from the registry" & vbCrLf  & vbCrLf & "/cdelay     Enables fcc restart warning console window to disable it set seconds to 0"
WScript.Quit 0
end if
if WScript.Arguments.Named.Exists("modes")then
modes=WScript.Arguments.Named("modes")
badchr=AreAllCharsInString(modes,"nhNHkK!")
if badchr<256 then
WScript.echo "'"&Chr(badchr)&"' charactor is not a valid mode."
WScript.Quit 1
end if
if InStr(modes,"!")>0 then
wshshell.RegWrite "HKEY_CURRENT_USER\Software\Justin\FCCClicker\Modes","","REG_SZ"
else
wshshell.RegWrite "HKEY_CURRENT_USER\Software\Justin\FCCClicker\Modes",modes,"REG_SZ"
end if
end if
if WScript.Arguments.Named.Exists("cdelay")then
cdelay=CInt(WScript.Arguments.Named("cdelay"))
wshshell.RegWrite "HKEY_CURRENT_USER\Software\Justin\FCCClicker\ConsoleDelay",cdelay,"REG_DWORD"
end if
