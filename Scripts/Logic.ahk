;
;Main
;
ModifyText(StartStr, Preset) {
	StrObj := MakeCharObjs(StartStr)

	For i,FunctionName in Preset["Conf"]["Order"] {
		PresetFunctions[FunctionName](&StrObj, Preset)
	}

	return ToNormalStr(StrObj)
}

;
;Preset functions
;
PresetFunctions := Map()

PresetFunctions["Words"] := Step_Words
Step_Words(&StrObj, Preset) {
	Regex(&StrObj, "iS)(\b(" Preset["Words"]["RegexStr"] ")\b)", Fn, Map("PresetWords", Preset["Words"]))

	Fn(&StrObj, Str, Match, FoundPos, Parameters) {
		If ShouldIgnore(StrObj, FoundPos)
			Return

		Key := StrLower(Match[])

		Chances := GetInfluencedChances(StrObj, FoundPos, Parameters["PresetWords"]["Keys"][Key]["Chances"])
		RandomIndex := GetRandomIndexFromChances(Chances)

		If RandomIndex != 0 {
			Replacement := Parameters["PresetWords"]["Keys"][Key]["Replacements"][RandomIndex]
			Replacement := MatchCase(Replacement, Match[])

			ModifyStrObj(&StrObj, FoundPos, Match.Len, Replacement)
		}
	}
}

PresetFunctions["Letters"] := Step_Letters
Step_Letters(&StrObj, Preset) {
	Regex(&StrObj, "iS)(" Preset["Letters"]["RegexStr"] ")", Fn, Map("PresetLetters", Preset["Letters"]))
	RemoveAllFlags(&StrObj, "Marked_Letter")

	Fn(&StrObj, Str, Match, FoundPos, Parameters) {
		If ShouldIgnore(StrObj, FoundPos)
			Return

		Key := StrLower(Match[])

		If Conf["Misc"]["GuaranteeIfPreviousLetter"] and FoundPos - 1 >= 1 and HasFlag(StrObj[FoundPos - 1], "Marked_Letter") {
			Last := ReadFlag(StrObj[FoundPos - 1], "Marked_Letter")
			If Last["Key"] = Key {
				Replacement := Last["Passed"]

				RemoveAllFlags(&StrObj, "Marked_Letter")
				FlagSegment(&StrObj, FoundPos, Match.Len, "Marked_Letter", Map("Key", Key, "Passed", Replacement))

				If Replacement != 0 {
					Replacement := MatchCase(Replacement, Match[])
					ModifyStrObj(&StrObj, FoundPos, Match.Len, Replacement)
				}
			}
		} Else {
			Replacement := 0

			Chances := GetInfluencedChances(StrObj, FoundPos, Parameters["PresetLetters"]["Keys"][Key]["Chances"])
			RandomIndex := GetRandomIndexFromChances(Chances)
			If RandomIndex != 0 {
				Replacement := Parameters["PresetLetters"]["Keys"][Key]["Replacements"][RandomIndex]
				Replacement := MatchCase(Replacement, Match[])
			}

			If Conf["Misc"]["NoNonAsciiFirstCharacter"] {
				FirstAsciiCharacter := RegExMatch(Str, "iS)[a-zA-Z]")
				If FoundPos <= FirstAsciiCharacter and Replacement != 0 and not IsAlpha(Replacement) {
					Replacement := 0
				}
			}

			RemoveAllFlags(&StrObj, "Marked_Letter")
			FlagSegment(&StrObj, FoundPos, Match.Len, "Marked_Letter", Map("Key", Key, "Passed", Replacement))

			If Replacement != 0
				ModifyStrObj(&StrObj, FoundPos, Match.Len, Replacement)
		}
	}
}

PresetFunctions["LettersAdvanced"] := Step_LettersAdvanced
Step_LettersAdvanced(&StrObj, Preset) {
	Regex(&StrObj, "iS)(" Preset["LettersAdvanced"]["RegexStr"] ")", Fn, Map("PresetLettersAdvanced", Preset["LettersAdvanced"]))
	RemoveAllFlags(&StrObj, "Marked_LettersAdvanced")

	Fn(&StrObj, Str, Match, FoundPos, Parameters) {
		If ShouldIgnore(StrObj, FoundPos)
			Return

		Char := StrLower(Match[])
		PrevChar := FoundPos - 1 >= 1 and HasFlag(StrObj[FoundPos - 1], "Marked_LettersAdvanced") ? StrLower(ReadFlag(StrObj[FoundPos - 1], "Marked_LettersAdvanced")) : ""
		NextChar := FoundPos + 1 <= StrObj.Length ? StrLower(ReadChar(StrObj[FoundPos + 1])) : ""

		RemoveAllFlags(&StrObj, "Marked_LettersAdvanced")
		FlagSegment(&StrObj, FoundPos, Match.Len, "Marked_LettersAdvanced", Char)

		Single := Parameters["PresetLettersAdvanced"]["Keys"][Char]["Single"]
		Start := Parameters["PresetLettersAdvanced"]["Keys"][Char]["Start"]
		Middle := Parameters["PresetLettersAdvanced"]["Keys"][Char]["Middle"]
		End := Parameters["PresetLettersAdvanced"]["Keys"][Char]["End"]

		Replacement := ReplaceLong(Single, Start, Middle, End, PrevChar = Char, Nextchar = Char)

		If Replacement != "" {
			Replacement := MatchCase(Replacement, Match[])
			ModifyStrObj(&StrObj, FoundPos, Match.Len, Replacement)
		}
	}

	ReplaceLong(Single, Start, Middle, End, IsPrev, IsNext) {
		If not IsPrev and not IsNext
			Return Single
		Else If not IsPrev and IsNext
			Return Start
		Else If IsPrev and IsNext
			Return Middle
		Else If IsPrev and not IsNext
			Return End

		Return Single
	}
}

PresetFunctions["ReplaceVowelsWithV"] := Step_ReplaceVowelsWithV
Step_ReplaceVowelsWithV(&StrObj, Preset) {
	Regex(&StrObj, "iS)([" Preset["ReplaceVowelsWithV"]["RegexStr"] "])", Fn, Map("ReplaceVowelsWithV", Preset["ReplaceVowelsWithV"]))
	RemoveAllFlags(&StrObj, "Marked_Vowel")

	Fn(&StrObj, Str, Match, FoundPos, Parameters) {
		If ShouldIgnore(StrObj, FoundPos)
			Return

		FlagSegment(&StrObj, FoundPos, Match.Len, "Marked_Vowel")

		Key := StrLower(Match[])
		PrevCharExists := FoundPos - 1 >= 1

		If not ( PrevCharExists and HasFlag(StrObj[FoundPos - 1], "Marked_Vowel") ) {
			PrevChar := PrevCharExists ? ReadChar(StrObj[FoundPos - 1]) : 0
			If PrevChar = 0 or PrevChar = A_Space or PrevChar = "v" or PrevChar = "w"
				Return

			Chances := GetInfluencedChances(StrObj, FoundPos, [Parameters["ReplaceVowelsWithV"]["Keys"][Key]])
			RandomIndex := GetRandomIndexFromChances(Chances)

			If RandomIndex = 1 {
				Replacement := MatchCase("v", Match[])
				ModifyStrObj(&StrObj, FoundPos, Match.Len, Replacement)
			}
		}
	}
}

PresetFunctions["IgnoredWords"] := Step_IgnoredWords
Step_IgnoredWords(&StrObj, Preset) {
	Regex(&StrObj, "iS)(\b(" Preset["IgnoredWords"]["RegexStr"] ")\b)", Fn)

	Fn(&StrObj, Str, Match, FoundPos, Parameters) {
		FlagSegment(&StrObj, FoundPos, Match.Len, "Ignore_Word")
	}
}

PresetFunctions["RecursiveLetters"] := Step_RecursiveLetters
Step_RecursiveLetters(&StrObj, Preset) {
	Regex(&StrObj, "iS)(" Preset["RecursiveLetters"]["RegexStr"] ")", Fn, Map("PresetRecursiveLetters", Preset["RecursiveLetters"]))

	Fn(&StrObj, Str, Match, FoundPos, Parameters) {
		If ShouldIgnore(StrObj, FoundPos)
			Return

		Key := StrLower(Match[])
		StartChance := Parameters["PresetRecursiveLetters"]["Keys"][Key]["StartChance"]
		Multiplier := Parameters["PresetRecursiveLetters"]["Keys"][Key]["Multiplier"]

		Chance := StartChance
		Loop {
			Replacing := GetRandomIndexFromChances([Chance])
			If Replacing {
				Chance := Chance * Multiplier

				ModifyStrObj(&StrObj, FoundPos, 0, Match[])
			} Else {
				Break
			}
		}
	}
}

PresetFunctions["SpanishMarks"] := Step_SpanishMarks
Step_SpanishMarks(&StrObj, Preset) {
	Marks := []
	Pos := StrObj.Length
	Loop {
		Char := ReadChar(StrObj[Pos])
		If Char = "?" or Char = "!" {
			Marks.Push(Char)
			Pos := Pos - 1
		} Else
			Break
	}

	Prefix := ""
	For _,Mark in Marks {
		If Mark = "?"
			Mark := "¿"
		Else If Mark = "!"
			Mark := "¡"

		Prefix := Prefix Mark
	}

	If Prefix != "" {
		If Conf["Misc"]["NoNonAsciiFirstCharacter"]
			Prefix := "." Prefix

		ModifyStrObj(&StrObj, 1, 0, Prefix)
	}
}

PresetFunctions["SpanishAccentMarks"] := Step_SpanishAccentMarks
Step_SpanishAccentMarks(&StrObj, Preset) {
	Regex(&StrObj, "iS)([aeioun])", Fn)

	Fn(&StrObj, Str, Match, FoundPos, Parameters) {
		If ShouldIgnore(StrObj, FoundPos)
			Return

		NextChar := StrObj.Has(FoundPos + 1) ? ReadChar(StrObj[FoundPos + 1]) : ""
		Char := Match[]

		Replacement := ""
		If NextChar = "``" {
			Switch Char, false
			{
			Case "a":
				Replacement := "á"
			Case "e":
				Replacement := "é"
			Case "i":
				Replacement := "í"
			Case "o":
				Replacement := "ó"
			Case "u":
				Replacement := "ú"
			Case "n":
				Replacement := "ñ"
			}
		} Else If NextChar = "~" {
			Switch Char, false
			{
			Case "n":
				Replacement := "ñ"
			Case "u":
				Replacement := "ü"
			}
		}

		If Replacement != "" {
			Replacement := MatchCase(Replacement, Char)
			ModifyStrObj(&StrObj, FoundPos, Match.Len, Replacement)
		}
	}
}

PresetFunctions["CapitalizeFirstLetter"] := Step_CapitalizeFirstLetter
Step_CapitalizeFirstLetter(&StrObj, Preset) {
	Pos := 1
	Loop {
		Char := ReadChar(StrObj[Pos])

		If IsUpper(Char) or IsLower(Char) {
			ModifyStrObj(&StrObj, Pos, 1, StrUpper(Char))
			Break
		}

		Pos := Pos + 1
		If Pos > StrObj.Length
			Break
	}
}

PresetFunctions["CapitalizeLetters"] := Step_CapitalizeLetters
Step_CapitalizeLetters(&StrObj, Preset) {
	Regex(&StrObj, "iS)(" Preset["CapitalizeLetters"]["RegexStr"] ")", Fn, Map("PresetCapitalizeLetters", Preset["CapitalizeLetters"]))

	Fn(&StrObj, Str, Match, FoundPos, Parameters) {
		If ShouldIgnore(StrObj, FoundPos)
			Return

		Key := StrLower(Match[])

		Chances := GetInfluencedChances(StrObj, FoundPos, [Parameters["PresetCapitalizeLetters"]["Keys"][Key]])
		RandomIndex := GetRandomIndexFromChances(Chances)

		If RandomIndex = 1 {
			Replacement := StrUpper(Key)
			ModifyStrObj(&StrObj, FoundPos, Match.Len, Replacement)
		}
	}
}

PresetFunctions["ReplaceC"] := Step_ReplaceC
Step_ReplaceC(&StrObj, Preset) {
	Regex(&StrObj, "iS)(c)", Fn)

	Fn(&StrObj, Str, Match, FoundPos, Parameters) {
		If ShouldIgnore(StrObj, FoundPos)
			Return

		Replacement := "s"
		If FoundPos + 1 <= StrObj.Length {
			NextChar := StrObj.Has(FoundPos + 1) ? ReadChar(StrObj[FoundPos + 1]) : ""
			If NextChar != "e" and NextChar != "i" and NextChar != "y" {
			 	If NextChar != "k" and NextChar != "h" and NextChar != "'"
					Replacement := "k"
				Else
					Replacement := "c"
			}
		}

		If Replacement != "c" {
			Replacement := MatchCase(Replacement, Match[])
			ModifyStrObj(&StrObj, FoundPos, Match.Len, Replacement)
		}
	}
}

PresetFunctions["OldZinzo"] := Step_OldZinzo
Step_OldZinzo(&StrObj, Preset) {
	ConstantsArr := ["б", "в", "г", "д", "ж", "з", "к", "л", "м", "н", "п", "р", "с", "т", "ф", "х", "ц", "ч", "ш", "щ"]
	VowelsArr := ["а", "е", "и", "i", "о", "у", "ы", "э", "ю", "я", "v", "ё", "й"]

	ConstantsMap := Map()
	For i,Letter in ConstantsArr
		ConstantsMap[Letter] := true

	VowelsMap := Map()
	For i,Letter in VowelsArr
		VowelsMap[Letter] := true

	Regex(&StrObj, "iS)(*UCP)(\b(\w+)\b)", Fn1)
	Fn1(&StrObj, Str, Match, FoundPos, Parameters) {
		If ShouldIgnore(StrObj, FoundPos)
			Return

		LastChar := SubStr(Match[], Match.Len, 1)
		If ConstantsMap.Has(LastChar)
			ModifyStrObj(&StrObj, FoundPos + Match.Len, 0, "ъ")
	}

	Regex(&StrObj, "iS)(и)", Fn2)
	Fn2(&StrObj, Str, Match, FoundPos, Parameters) {
		If ShouldIgnore(StrObj, FoundPos)
			Return

		If FoundPos + 1 <= StrObj.Length and VowelsMap.Has(ReadChar(StrObj[FoundPos + 1]))
			ModifyStrObj(&StrObj, FoundPos, 1, "i")
	}
}

;
;Regex logic
;
Regex(&StrObj, Regex, Fn, Parameters := Map()) {
	Str := ToNormalStr(StrObj)

	Pos := 1
    While (FoundPos := RegExMatch(Str, Regex, &Match, Pos)) {
		;MsgBox(A_Index " Start`n`n" ObjectToString(StrObj))

		FlagSegment(&StrObj, FoundPos, Match.Len, "Marked_Regex")
        Fn(&StrObj, Str, Match, FoundPos, Parameters)

		Str := ToNormalStr(StrObj)

		FlagPos := FindLastWithFlag(StrObj, "Marked_Regex")
        Pos := FlagPos != 0 ? FlagPos + 1 : 0

		;MsgBox(Pos "`n" DisplayStrPos(Str, Pos))

		RemoveAllFlags(&StrObj, "Marked_Regex")

		;MsgBox(A_Index " End`n`n" ObjectToString(StrObj))
    }
}

;
;Segments
;
ShouldIgnore(StrObj, Pos) {
	Str := ToNormalStr(StrObj)
	StrCut := SubStr(Str, 1, Pos)

	If HasFlag(StrObj[Pos], "Ignore_Word") {
		Return true
	}

	If Conf["Misc"]["IgnoreActions"] {
		FoundPos := InStr(Str, "*")
		If FoundPos = 1 or FoundPos != 0 and Pos < FoundPos
			Return true
	}

	If Conf["Misc"]["IgnoreQuoted"] {
		IsQuoted := false
		Pos := 1
		While (FoundPos := InStr(StrCut, "`"", 1, Pos)) {
			IsQuoted := !IsQuoted
			Pos := FoundPos + 1
		}

		Return IsQuoted
	}

	Return false
}

ShouldExtraChance(StrObj, Pos) {
	If Conf["ExtraChance"]["Enabled"] {
		CapsCount := 0
		For i,CharObj in StrObj {
			If i > Pos
				Break

			If IsUpper(CharObj["Char"], "Locale")
				CapsCount := CapsCount + 1
			Else
				CapsCount := 0
		}

		Return CapsCount >= 2
	}

	Return false
}

;
;String Object
;
ModifyStrObj(&StrObj, Pos, EraseLength := 0, Replace := "", Flags := Map()) {
	NewCharObjs := 0
	If Replace != "" {
		NewCharObjs := MakeCharObjs(Replace)

		If EraseLength > 0 and Flags.Count = 0 {
			OldCharObjs := GetCharObjs(StrObj, Pos, EraseLength)

			For i,_ in NewCharObjs {
				If OldCharObjs.Has(i) {
					NewCharObjs[i]["Flags"] := OldCharObjs[i]["Flags"].Clone()
				} Else {
					NewCharObjs[i]["Flags"] := NewCharObjs[i-1]["Flags"].Clone()
				}
			}
		} Else If Flags.Count > 1 {
			For i,_ in NewCharObjs {
				NewCharObjs[i]["Flags"] := Flags.Clone()
			}
		} Else {
			If Pos - 1 >= 1 {
				For i,_ in NewCharObjs {
					NewCharObjs[i]["Flags"] := StrObj[Pos - 1]["Flags"].Clone()
				}
			} Else {
				For i,_ in NewCharObjs {
					NewCharObjs[i]["Flags"] := Map()
				}
			}
		}
	}
	If EraseLength > 0 {
		StrObj.RemoveAt(Pos, EraseLength)
	}
	If NewCharObjs != 0 {
		StrObj.InsertAt(Pos, NewCharObjs*)
	}
}

GetCharObjs(StrObj, Start, Length := 1) {
	CharObjs := []
	Loop Length {
		CharObjs.Push(StrObj[Start + A_Index - 1])
	}

	Return CharObjs
}

MakeCharObjs(Str) {
	CharObjs := StrSplit(Str)
	For i,Char in CharObjs {
		CharObjs[i] := Map("Char", Char, "Flags", Map())
	}

	Return CharObjs
}

;
;Flags
;
RemoveAllFlags(&StrObj, Flag) {
	For i,CharObj in FindAllWithFlag(StrObj, Flag) {
		RemoveFlag(CharObj, Flag)
	}
}

FindAllWithFlag(StrObj, Flag) {
	CharObjs := []

	For i,CharObj in StrObj {
		If HasFlag(CharObj, Flag) {
			CharObjs.Push(CharObj)
		}
	}

	Return CharObjs
}

FindFirstWithFlag(StrObj, Flag) {
	For i,CharObj in StrObj {
		If HasFlag(CharObj, Flag) {
			Return i
		}
	}

	Return 0
}

FindLastWithFlag(StrObj, Flag) {
	Loop StrObj.Length {
		Index := StrObj.Length - A_Index + 1
		If HasFlag(StrObj[Index], Flag) {
			Return Index
		}
	}

	Return 0
}

SquashFlags(CharObjs) {
	Flags := Map()
	For i,CharObj in CharObjs {
		For Flag,FlagData in CharObj["Flags"] {
			If not Flags.Has(Flag) {
				Flags[Flag] := FlagData
			}
		}
	}

	Return Flags
}

FlagSegment(&StrObj, Start, Length, Flag, Data := 0) {
	Loop Length
		AddFlag(StrObj[Start + A_Index - 1], Flag, Data)
}

UnFlagSegment(&StrObj, Start, Length, Flag) {
	Loop Length
		RemoveFlag(StrObj[Start + A_Index - 1], Flag)
}

AddFlag(CharObj, Flag, Data := 0) {
	CharObj["Flags"][Flag] := Data
}

RemoveFlag(CharObj, Flag) {
	If HasFlag(CharObj, Flag)
		CharObj["Flags"].Delete(Flag)
}

HasFlag(CharObj, Flag) {
	Return CharObj["Flags"].Has(Flag)
}

ReadFlag(CharObj, Flag) {
	Return CharObj["Flags"][Flag]
}

ReadChar(CharObj) {
	Return CharObj["Char"]
}

;
;Randomization functions
;
GetRandomIndexFromChances(Chances) {
	Roll := Random(0.0, 1.0)

	ChancesStr := ""
	For i,v in Chances
		ChancesStr := ChancesStr v ","

	ChancesStr := SubStr(ChancesStr, 1, StrLen(ChancesStr) - 1)

	ChancesStr := Sort(ChancesStr, "NRD,")
	ChancesSorted := StrSplit(ChancesStr, ",")

	For i,v in ChancesSorted {
		If ChancesSorted.Has(i - 1)
			ChancesSorted[i] := LockNumberToRange(ChancesSorted[i - 1] - v, 0.0, 1.0)
		Else
			ChancesSorted[i] := LockNumberToRange(1.0 - v, 0.0, 1.0)
	}

	BestPick := 0
	For i,v in ChancesSorted {
		If Roll > v {
			BestPick := i
			Break
		}
	}

	Return BestPick
}

GetInfluencedChances(StrObj, Pos, Chances) {
	Mult := Conf["Misc"]["GlobalMult"]

	If ShouldExtraChance(StrObj, Pos)
		Mult := Mult * Conf["ExtraChance"]["Mult"]

	Return InfluenceChances(Chances, Mult)
}

InfluenceChances(Chances, Mult) {
	Sum := 0.0
	For i,v in Chances
		Sum := Sum + v

	MaxMult := 1.0 / Sum
	Mult := LockNumberToRange(Mult, 0.0, MaxMult)

	NewChances := []
	For i,v in Chances
		NewChances.Push(v * Mult)

	Return NewChances
}

;
;Case matching functions
;
MatchCase(ToMatch, MatchThis) {
    ToMatchArray := StrSplit(ToMatch)
	ToMatchArrayGood := []
	For i,Char in ToMatchArray {
		If IsLower(Char, "Locale") or IsUpper(Char, "Locale")
			ToMatchArrayGood.Push(Char)
	}

    MatchThisArray := StrSplit(MatchThis)
	MatchThisArrayGood := []
	For i,Char in MatchThisArray {
		If IsLower(Char, "Locale") or IsUpper(Char, "Locale")
			MatchThisArrayGood.Push(Char)
	}

    Final := []
    For i,Char in ToMatchArrayGood {
        If MatchThisArrayGood.Has(i) {
            Final.Push(ConvertCase(Char, MatchThisArrayGood[i]))
        } Else If i-1 >= 1 and Final.Has(i-1) {
            Final.Push(ConvertCase(Char, Final[i-1]))
        } Else {
            Final.Push(Char)
        }
    }

	For i,Char in ToMatchArray {
		If not IsLower(Char, "Locale") and not IsUpper(Char, "Locale")
			Final.InsertAt(i, Char)
	}

    Return ArrayToString(Final)
}

ConvertCase(ToMatch, MatchThis) {
    If IsUpper(MatchThis, "Locale") {
        Return StrUpper(ToMatch)
    } Else If IsLower(MatchThis, "Locale") {
        Return StrLower(ToMatch)
    } Else {
        Return ToMatch
    }
}

;
;Basic helpers
;
LockNumberToRange(Num, MinRange := "Unlimited", MaxRange := "Unlimited") {
	If MaxRange != "Unlimited" and Num > MaxRange
		Num := MaxRange
	Else If MinRange != "Unlimited" and Num < MinRange
		Num := MinRange

	Return Num
}

ArrayToString(Arr) {
	Str := ""
	For i,Char in Arr
		Str := Str Char

	Return Str
}

ToNormalStr(StrObj) {
	Str := ""
	For i,Arr in StrObj {
		Str := Str Arr["Char"]
	}

	Return Str
}