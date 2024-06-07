UpdateMacros(NewMacros, OldMacros := "") {
	If OldMacros != "" {
		For HotkeyName,HotkeyFn in OldMacros["Hotkeys"] {
			Hotkey HotkeyName, "Off"
		}
	}
	For HotkeyName,HotkeyFn in NewMacros["Hotkeys"] {
		Hotkey HotkeyName, MacroFunctions[HotkeyFn]
		Hotkey HotkeyName, "On"
	}
}

MacroFunctions := Map()

MacroFunctions["Breakdown"] := Macro_Breakdown
Macro_Breakdown(ThisHotkey) {
	Static Toggle := false
	If Toggle := !Toggle {
		SoundBeep(700)
		SetTimer(Routine, 1)
	} Else {
		SoundBeep(500)
		SetTimer(Routine, 0)
	}

	Routine() {
		If not WinExist("ahk_exe dreamseeker.exe") or not WinActive("ahk_exe dreamseeker.exe") {
			SoundBeep(300)
			Toggle := false
			SetTimer(Routine, 0)
			Return
		}

		dreamStart := UIA.ElementFromHandle("ahk_exe dreamseeker.exe")
		LastParent := dreamStart
		LastLastParent := ""
		dreamRoot := ""
		Loop {
			Try {
				Parent := LastParent.WalkTree("p")
			} Catch {
				dreamRoot := LastLastParent
				Break
			} Else {
				LastLastParent := LastParent
				LastParent := Parent
			}
		}

		dreamMain := dreamRoot.ElementFromPath({T:20})

		If dreamStart.Name = "say" {
			ib := InputBuffer()
			ib.Start()

			TextField := dreamStart.FindElement({Type:"Edit"})

			OldText := TextField.Value
			TextField.Value := RollEmote()

			OkButton := dreamStart.FindElement({Type:"Button", Name:"OK"})
			OkButton.Invoke()

			dreamMain.SetFocus()
			Send("t")

			WinWaitActive("say")
			Sleep(200)

			dreamStart := UIA.ElementFromHandle("ahk_exe dreamseeker.exe")
			TextField := dreamStart.FindElement({Type:"Edit"})

			TextField.Value := OldText
			TextField.SetFocus()
			Send("^{Right 50}")

			Sleep 100
			ib.Stop()
		} Else If dreamStart.Name = dreamRoot.Name {
			ib := InputBuffer()
			ib.Start()

			dreamMain.SetFocus()
			Send("t")

			WinWaitActive("say")
			Sleep(200)

			dreamStart := UIA.ElementFromHandle("ahk_exe dreamseeker.exe")
			TextField := dreamStart.FindElement({Type:"Edit"})
			TextField.Value := RollEmote()
			OkButton := dreamStart.FindElement({Type:"Button", Name:"OK"})
			OkButton.Invoke()

			dreamMain.SetFocus()

			Sleep 100
			ib.Stop()
		}

		SetTimer(, 3000)
	}

	RollEmote() {
		Roll := GetRandomIndexFromChances([0.6, 0.2, 0.125, 0.075])
		Switch Roll
		{
		Case 1:
			Return "*cry"
		Case 2:
			Return "*whimper"
		Case 3:
			Return "*faint"
		Case 4:
			Return "*collapse"
		}
	}
}

UpdateMacros(GetActiveMacros())