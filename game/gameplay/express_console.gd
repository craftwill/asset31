class_name ExpressConsole
extends StaticBody3D
## Interactive dispatch & boarding console for the Inter-Stack Express (EXP-077).
## station_side: 0 = onboard cab control, -1 = STA-0413-N (South / Twin-Stack), +1 = STA-0414-S (North / 17.5 km).

var express: InterStackExpress
var station_side := 0


func prompt_text() -> String:
	if express == null:
		return ""
	return express.console_prompt(station_side)
