@echo off

git pull

echo.
echo Updating done.
echo.
echo Starting AutoAccent...

reg query "HKLM\Hardware\Description\System\CentralProcessor\0" | find /i "x86" > nul && set OS=32BIT || set OS=64BIT
if %OS%==64BIT (
	start "" "%~dp0\AhkPortable\AutoHotkey64.exe" "%~dp0\Scripts\Main.ahk"
) else (
	start "" "%~dp0\AhkPortable\AutoHotkey32.exe" "%~dp0\Scripts\Main.ahk"
)

echo AutoAccent is launched.

echo.
@pause