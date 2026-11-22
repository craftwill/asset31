class_name SurvivalComponent
extends Node
## Minimal, slow-paced survival state (brief §8.4): health, hunger, thirst and
## environmental exposure (shelter / foundry heat / bridge wind). Designed to
## reward preparation without forcing constant meter maintenance.

signal stats_changed
signal status_message(text: String)

const BASE_HUNGER_DRAIN := 0.0032   # ~0.19 / min (~8+ hours full -> empty)
const BASE_THIRST_DRAIN := 0.0046   # ~0.28 / min
const STARVE_HP_DRAIN := 0.25       # per second only when hunger or thirst == 0

var health := 100.0
var hunger := 88.0
var thirst := 84.0
var condition := ""                 # "", "SHELTER", "HEAT", "EXPOSED"
var enabled := true


func tick(delta: float, sprinting: bool, env_condition: String) -> void:
	if not enabled:
		return
	var prev_cond := condition
	condition = env_condition
	var h_mult := 1.0
	var t_mult := 1.0
	if sprinting:
		h_mult *= 1.6
		t_mult *= 1.8
	match condition:
		"SHELTER":
			h_mult *= 0.25
			t_mult *= 0.25
		"HEAT":
			t_mult *= 3.8
		"EXPOSED":
			h_mult *= 1.35
			t_mult *= 2.2
	hunger = maxf(0.0, hunger - BASE_HUNGER_DRAIN * h_mult * delta)
	thirst = maxf(0.0, thirst - BASE_THIRST_DRAIN * t_mult * delta)
	if hunger <= 0.0 or thirst <= 0.0:
		health = maxf(5.0, health - STARVE_HP_DRAIN * delta)
	if condition != prev_cond:
		stats_changed.emit()


func apply_fall_injury(height: float) -> void:
	if not enabled or height < 5.0:
		return
	var dmg := clampf((height - 4.5) * 4.2, 4.0, 65.0)
	health = maxf(5.0, health - dmg)
	stats_changed.emit()
	status_message.emit("Hard landing (-%d HP)" % int(roundf(dmg)))


func use_item(item_id: String) -> bool:
	var d := ItemDB.get_item(item_id)
	if d.is_empty() or not ItemDB.is_consumable(item_id):
		return false
	var dh := float(d.get("hunger", 0))
	var dt := float(d.get("thirst", 0))
	var dhp := float(d.get("health", 0))
	hunger = clampf(hunger + dh, 0.0, 100.0)
	thirst = clampf(thirst + dt, 0.0, 100.0)
	health = clampf(health + dhp, 0.0, 100.0)
	stats_changed.emit()
	var parts: Array[String] = []
	if dh > 0: parts.append("+%d food" % int(dh))
	if dt > 0: parts.append("+%d water" % int(dt))
	elif dt < 0: parts.append("%d water" % int(dt))
	if dhp > 0: parts.append("+%d HP" % int(dhp))
	status_message.emit("Used %s (%s)" % [String(d.name), ", ".join(parts)])
	return true


func serialize() -> Dictionary:
	return {
		"health": snappedf(health, 0.1),
		"hunger": snappedf(hunger, 0.1),
		"thirst": snappedf(thirst, 0.1),
	}


func deserialize(d: Dictionary) -> void:
	health = clampf(float(d.get("health", 100.0)), 1.0, 100.0)
	hunger = clampf(float(d.get("hunger", 88.0)), 0.0, 100.0)
	thirst = clampf(float(d.get("thirst", 84.0)), 0.0, 100.0)
	stats_changed.emit()
