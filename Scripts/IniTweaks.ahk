﻿Global IniMapTweaks := Map()

IniMapTweaks["Sections"] := Map()
IniMapTweaks["Keys"] := Map()

IniMapTweaks["Sections"]["Letters"] := Section_ReplacementChance
IniMapTweaks["Sections"]["Words"] := Section_ReplacementChance
Section_ReplacementChance(&IniMap, SectionName, Section) {
	NewSection := Map()
	NewSection["RegexStr"] := ""
	NewSection["Keys"] := Map()

	For Key,Arrays in Section {
		NewSection["RegexStr"] := NewSection["RegexStr"] Key "|"

		NewSection["Keys"][Key] := Map()
		NewSection["Keys"][Key]["Replacements"] := []
		NewSection["Keys"][Key]["Chances"] := []

		For i,Arr in Arrays {
			NewSection["Keys"][Key]["Replacements"].Push(Arr[1])
			NewSection["Keys"][Key]["Chances"].Push(Arr[2])
		}
	}
	NewSection["RegexStr"] := SubStr(NewSection["RegexStr"], 1, StrLen(NewSection["RegexStr"]) - 1)

	IniMap[SectionName] := NewSection
}

IniMapTweaks["Sections"]["IgnoredWords"] := Section_IgnoredWords
Section_IgnoredWords(&IniMap, SectionName, Section) {
	NewSection := Map()
	NewSection["RegexStr"] := ""
	NewSection["IgnoredWords"] := Array()

	For Key,Arr in Section {
		NewSection["RegexStr"] := NewSection["RegexStr"] Key "|"
		NewSection["IgnoredWords"].Push(Key)
	}
	NewSection["RegexStr"] := SubStr(NewSection["RegexStr"], 1, StrLen(NewSection["RegexStr"]) - 1)

	IniMap[SectionName] := NewSection
}

IniMapTweaks["Sections"]["RecursiveLetters"] := Section_ChanceChance
Section_ChanceChance(&IniMap, SectionName, Section) {
	NewSection := Map()
	NewSection["RegexStr"] := ""
	NewSection["Keys"] := Map()

	For Key,Arr in Section {
		NewSection["RegexStr"] := NewSection["RegexStr"] Key "|"

		NewSection["Keys"][Key] := Map()
		NewSection["Keys"][Key] := Map("StartChance", Arr[1], "Multiplier", Arr[2])
	}
	NewSection["RegexStr"] := SubStr(NewSection["RegexStr"], 1, StrLen(NewSection["RegexStr"]) - 1)

	IniMap[SectionName] := NewSection
}

IniMapTweaks["Sections"]["RollingSounds"] := Section_RollingSounds
Section_RollingSounds(&IniMap, SectionName, Section) {
	NewSection := Array()
	For Key,_ in Section {
		NewSection.Push(Key)
	}
	IniMap[SectionName] := NewSection
}