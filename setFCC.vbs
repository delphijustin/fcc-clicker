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
dim actionCount
actionCount=0
set wshshell=WScript.CreateObject("WScript.Shell")
Dim argCount
Dim modes
argCount = WScript.Arguments.Count
If argCount = 0 Then
WScript.Echo "Usage: setFCC.vbs [/modes:Modes] [/maxtime:milliseconds]" & vbCrLf & "Modes:" & vbCrLf & "H     Minimizes the FCC window when done starting the conference" & vbCrLf & "N     Disables noise reduction" & vbCrLf & "K     Autokill FCC if is running without asking" & vbCrLf & "!     Remove the current modes from the registry" & vbCrLf  & vbCrLf & "/maxtime     Changes the default reset timeout, the default is 21600000 milliseconds(6 hours)"
WScript.Quit 0
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
