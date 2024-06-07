#Requires AutoHotkey v2.0

SetWorkingDir StrReplace(A_ScriptDir, "\Scripts")
Global Path_Conf := "Conf.ini"
Global Path_ConfDefault := "Scripts\ConfDefault.ini"
Global Path_Presets := "Presets"
Global Path_Macros := "Macros"
Global Path_Readme := "README.md"

;
;UIA library https://github.com/Descolada/UIA-v2
;
#Include ..\Scripts\Lib\UIA.ahk

;
;Input buffer
;
#Include ..\Scripts\Lib\InputBuffer.ahk

;
;Ini map tweaks list
;
#Include ..\Scripts\IniTweaks.ahk

;
;Configuration and presets
;
#Include ..\Scripts\Conf.ahk

;
;Tray menu
;
#Include ..\Scripts\Menu.ahk

;
;Hotkey
;
#Include ..\Scripts\Hotkey.ahk

;
;Text modification logic
;
#Include ..\Scripts\Logic.ahk

;
;Macros
;
#Include ..\Scripts\Macros.ahk

;
;Debug functions
;
#Include ..\Scripts\Debug.ahk