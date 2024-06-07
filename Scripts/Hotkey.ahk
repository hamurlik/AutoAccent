Hotkey Conf["Misc"]["Hotkey"], Start

Start(ThisHotkey) {
	Switch Conf["Misc"]["SelectionMethod"]
	{
	Case "Advanced":
		FocusedElement := UIA.GetFocusedElement()
		If FocusedElement.Value != ""
			FocusedElement.Value := ModifyText(FocusedElement.Value, GetActivePreset())
		Send("^{Right 50}")
		If Conf["Misc"]["HotkeyEnter"]
			Send("{Enter}")
		SoundBeep()
	Case "CtrlA":
		Send("^a")
		A_Clipboard := ""
		Send("^c")
		ClipWait()
		A_Clipboard := ModifyText(A_Clipboard, GetActivePreset())
		Send("^v")
		If Conf["Misc"]["HotkeyEnter"]
			Send("{Enter}")
	Case "ArrowSpam":
		Send("^{Right 50}")
		Send("^+{Left 50}")
		A_Clipboard := ""
		Send("^c")
		ClipWait()
		A_Clipboard := ModifyText(A_Clipboard, GetActivePreset())
		Send("^v")
		If Conf["Misc"]["HotkeyEnter"]
			Send("{Enter}")
	}
}