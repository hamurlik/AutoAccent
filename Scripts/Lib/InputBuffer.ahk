#Requires AutoHotkey v2

;InputBuffer.Start()
;Sleep(5000)
;InputBuffer.Stop()

/**
 * InputBuffer can be used to buffer user input for keyboard, mouse, or both at once.
 * The default InputBuffer (via the main class name) is keyboard only, but new instances
 * can be created via InputBuffer().
 *
 * InputBuffer(keybd := true, mouse := false, timeout := 0)
 *      Creates a new InputBuffer instance. If keybd/mouse arguments are numeric then the default
 *      InputHook settings are used, and if they are a string then they are used as the Option
 *      arguments for InputHook and HotKey functions. Timeout can optionally be provided to call
 *      InputBuffer.Stop() automatically after the specified amount of milliseconds (as a failsafe).
 *
 * InputBuffer.Start()               => initiates capturing input
 * InputBuffer.Release()             => releases buffered input and continues capturing input
 * InputBuffer.Stop(release := true) => releases buffered input and then stops capturing input
 * InputBuffer.ActiveCount           => current number of Start() calls
 *                                      Capturing will stop only when this falls to 0 (Stop() decrements it by 1)
 * InputBuffer.SendLevel             => SendLevel of the InputHook
 *                                      InputBuffers default capturing SendLevel is A_SendLevel+2,
 *                                      and key release SendLevel is A_SendLevel+1.
 * InputBuffer.IsReleasing           => whether Release() is currently in action
 * InputBuffer.Buffer                => current buffered input in an array
 *
 * Notes:
 * * Mouse input can't be buffered while AHK is doing something uninterruptible (eg busy with Send)
 */
class InputBuffer {
    Buffer := [], SendLevel := A_SendLevel + 2, ActiveCount := 0, IsReleasing := 0, ModifierKeyStates := Map()
        , MouseButtons := ["LButton", "RButton", "MButton", "XButton1", "XButton2", "WheelUp", "WheelDown"]
        , ModifierKeys := ["LShift", "RShift", "LCtrl", "RCtrl", "LAlt", "RAlt", "LWin", "RWin"]
    static __New() => this.DefineProp("Default", {value:InputBuffer()})
    static __Get(Name, Params) => this.Default.%Name%
    static __Set(Name, Params, Value) => this.Default.%Name% := Value
    static __Call(Name, Params) => this.Default.%Name%(Params*)
    __New(keybd := true, mouse := false, timeout := 0) {
        if !keybd && !mouse
            throw Error("At least one input type must be specified")
        this.Timeout := timeout
        this.Keybd := keybd, this.Mouse := mouse
        if keybd {
            if keybd is String {
                if RegExMatch(keybd, "i)I *(\d+)", &lvl)
                    this.SendLevel := Integer(lvl[1])
            }
            this.InputHook := InputHook(keybd is String ? keybd : "I" (this.SendLevel) " L0 B0")
            this.InputHook.NotifyNonText  := true
            this.InputHook.VisibleNonText := false
            this.InputHook.OnKeyDown      := this.BufferKey.Bind(this,,,, "Down")
            this.InputHook.OnKeyUp        := this.BufferKey.Bind(this,,,, "Up")
            this.InputHook.KeyOpt("{All}", "N S")
        }
        this.HotIfIsActive := this.GetActiveCount.Bind(this)
    }
    BufferMouse(ThisHotkey, Opts := "") {
        savedCoordMode := A_CoordModeMouse, CoordMode("Mouse", "Screen")
        MouseGetPos(&X, &Y)
        ThisHotkey := StrReplace(ThisHotkey, "Button")
        this.Buffer.Push(Format("{Click {1} {2} {3} {4}}", X, Y, ThisHotkey, Opts))
        CoordMode("Mouse", savedCoordMode)
    }
    BufferKey(ih, VK, SC, UD) => (this.Buffer.Push(Format("{{1} {2}}", GetKeyName(Format("vk{:x}sc{:x}", VK, SC)), UD)))
    Start() {
        this.ActiveCount += 1
        SetTimer(this.Stop.Bind(this), -this.Timeout)

        if this.ActiveCount > 1
            return

        this.Buffer := [], this.ModifierKeyStates := Map()
        for modifier in this.ModifierKeys
            this.ModifierKeyStates[modifier] := GetKeyState(modifier)

        if this.Keybd
            this.InputHook.Start()
        if this.Mouse {
            HotIf this.HotIfIsActive
            if this.Mouse is String && RegExMatch(this.Mouse, "i)I *(\d+)", &lvl)
                this.SendLevel := Integer(lvl[1])
            opts := this.Mouse is String ? this.Mouse : ("I" this.SendLevel)
            for key in this.MouseButtons {
                if InStr(key, "Wheel")
                    HotKey key, this.BufferMouse.Bind(this), opts
                else {
                    HotKey key, this.BufferMouse.Bind(this,, "Down"), opts
                    HotKey key " Up", this.BufferMouse.Bind(this), opts
                }
            }
            HotIf ; Disable context sensitivity
        }
    }
    Release() {
        if this.IsReleasing || !this.Buffer.Length
            return []

        sent := [], clickSent := false, this.IsReleasing := 1
        if this.Mouse
            savedCoordMode := A_CoordModeMouse, CoordMode("Mouse", "Screen"), MouseGetPos(&X, &Y)

        ; Theoretically the user can still input keystrokes between ih.Stop() and Send, in which case
        ; they would get interspersed with Send. So try to send all keystrokes, then check if any more
        ; were added to the buffer and send those as well until the buffer is emptied.
        PrevSendLevel := A_SendLevel
        SendLevel this.SendLevel - 1

        ; Restore the state of any modifier keys before input buffering was started
        modifierList := ""
        for modifier, state in this.ModifierKeyStates
            if GetKeyState(modifier) != state
                modifierList .= "{" modifier (state ? " Down" : " Up") "}"
        if modifierList
            Send modifierList

        while this.Buffer.Length {
            key := this.Buffer.RemoveAt(1)
            sent.Push(key)
            if InStr(key, "{Click ")
                clickSent := true
            Send("{Blind}" key)
        }
        SendLevel PrevSendLevel

        if this.Mouse && clickSent {
            MouseMove(X, Y)
            CoordMode("Mouse", savedCoordMode)
        }
        this.IsReleasing := 0
        return sent
    }
    Stop(release := true) {
        if !this.ActiveCount
            return

        sent := release ? this.Release() : []

        if --this.ActiveCount
            return

        if this.Keybd
            this.InputHook.Stop()

        if this.Mouse {
            HotIf this.HotIfIsActive
            for key in this.MouseButtons
                HotKey key, "Off"
            HotIf ; Disable context sensitivity
        }

        return sent
    }
    GetActiveCount(HotkeyName) => this.ActiveCount
}