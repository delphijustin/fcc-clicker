@echo off
::This batch file contains scheduled recordings for the fcc clicker
::Example to start a 3-hour recording at 07:00 pm
::
::time /T | find /I "07:00 PM"
::if "%ERRORLEVEL%"=="0" fccclick32.exe recordfor 03:00
::
::Any lines that begins with "::" are comments
::All recordings and if commands must come before the goto on each section
:start
date /T | find /I "sun" > nul
if "%ERRORLEVEL%"=="0" goto sun
date /T | find /I "mon" > nul
if "%ERRORLEVEL%"=="0" goto mon
date /T | find /I "tue" > nul
if "%ERRORLEVEL%"=="0" goto tue
date /T | find /I "wed" > nul
if "%ERRORLEVEL%"=="0" goto wed
date /T | find /I "thu" > nul
if "%ERRORLEVEL%"=="0" goto thu
date /T | find /I "fri" > nul
if "%ERRORLEVEL%"=="0" goto fri
date /T | find /I "sat" > nul
if "%ERRORLEVEL%"=="0" goto sat
echo Command Extension needed but looks like they are disabled.
exit /B 1
::Recording sections start
:sun
goto weekend
:mon
goto weekday
:tue
goto weekday
:wed
goto weekday
:thu
goto weekday
:fri
goto weekday
:sat
:weekend
goto clockdone
:weekday
goto clockdone
::Recording sections end
:clockdone
timeout /T 60 /NOBREAK > nul
goto start
