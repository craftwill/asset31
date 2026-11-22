class_name TramConsole
extends StaticBody3D
## Diegetic control lever / station call box for the BR-077-A Maintenance Rail Tram.
## station_side: 0 = on-board drive lever, -1 = STK-0412 west station, +1 = STK-0413 east station.

var tram: BridgeTram
var station_side := 0


func prompt_text() -> String:
	if tram == null:
		return ""
	return tram.console_prompt(station_side)
