class_name RelayConsole
extends StaticBody3D
## Interactive console for the 41 km Deep Express Ore-Relay Cage (EL-DEEP-00).
## station_side: 0 = on-board cage control, +1 = Undercroft 76-B (40,780 m), -1 = Planetary Crust (0 m).

var relay: DeepRelayLift
var station_side := 0


func prompt_text() -> String:
	if relay == null:
		return ""
	return relay.console_prompt(station_side)
