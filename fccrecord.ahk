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
MsgBox "Couldn't create volatile key. Aborting... Error#" vkeyError,"FCCClicker","icon!"
ExitApp 1
}
duration:= RegRead("HKEY_CURRENT_USER\SOFTWARE\Justin\FCCClicker\Memory","RecordDuration",0)
if (duration=0)
{
MsgBox "You must call controlfcc.vbs /record:hh:mm first","FCCClicker","Iconx"
ExitApp 1
}
RegDelete "HKEY_CURRENT_USER\SOFTWARE\Justin\FCCClicker\Memory","RecordDuration"
WinWait "FreeConferenceCall"
WinRestore "FreeConferenceCall"
WinActivate "FreeConferenceCall"
MouseMove 472,733
MouseClick
Sleep duration
WinRestore "FreeConferenceCall"
WinActivate "FreeConferenceCall"
MouseMove 472,733
MouseClick