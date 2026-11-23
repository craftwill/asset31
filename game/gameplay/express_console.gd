class_name ExpressConsole
extends StaticBody3D
## Interactive dispatch & boarding console for the Inter-Stack Express (EXP-077),
## or Resonance Strike Console for the Void Bell Sanctum (when sanctum != null).
## station_side: 0 = onboard cab control, -1 = STA-0413-N (South / Twin-Stack), +1 = STA-0414-S (North / 17.5 km).

var express: InterStackExpress
var sanctum: Node
var station_side := 0


func prompt_text() -> String:
	if sanctum != null and sanctum.has_method(&"console_prompt"):
		return String(sanctum.call(&"console_prompt"))
	if express == null:
		return ""
	return express.console_prompt(station_side)
