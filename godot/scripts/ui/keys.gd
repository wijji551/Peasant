class_name Keys
extends RefCounted
## Every action and its keys. They are set up as Godot input actions when the game starts, so the
## handbook (a later stage of the move) can let players change them. Words on screen name the keys
## as they are set: "{interact}" in any text becomes "E", or whatever E has been changed to.

const ACTIONS := [
	["up", "Move north"], ["left", "Move west"], ["down", "Move south"], ["right", "Move east"],
	["attack", "Attack, and land a fish"], ["trick", "Your weapon’s trick"],
	["interact", "Gather, build, search, rally, use a place (hold)"], ["eat", "Eat"], ["pack", "Open your pack"],
	["carry", "Use what you carry: bucket or handbell"], ["swap", "Swap to the next weapon in your pack"],
	["orders", "Posse orders: follow, hold, charge"], ["toilet", "Emergency toilet break"],
	["build", "Next thing to place"], ["ready", "Ready for the night"], ["mute", "Sound on or off"],
]
const DEF := {
	"up": [KEY_W, KEY_UP], "left": [KEY_A, KEY_LEFT], "down": [KEY_S, KEY_DOWN], "right": [KEY_D, KEY_RIGHT],
	"attack": [KEY_SPACE], "trick": [KEY_SHIFT], "interact": [KEY_E], "eat": [KEY_F], "pack": [KEY_I],
	"carry": [KEY_G], "swap": [KEY_X], "orders": [KEY_Q], "toilet": [KEY_T], "build": [KEY_TAB],
	"ready": [KEY_R], "mute": [KEY_M],
}


static func setup() -> void:
	for a in DEF:
		var act: String = "dtv_" + a
		if InputMap.has_action(act):
			continue
		InputMap.add_action(act)
		for k in DEF[a]:
			var e := InputEventKey.new()
			e.physical_keycode = k
			InputMap.action_add_event(act, e)
	if not InputMap.has_action("dtv_attack_mouse"):
		InputMap.add_action("dtv_attack_mouse")
		var m := InputEventMouseButton.new()
		m.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("dtv_attack_mouse", m)
		InputMap.add_action("dtv_trick_mouse")
		var m2 := InputEventMouseButton.new()
		m2.button_index = MOUSE_BUTTON_RIGHT
		InputMap.action_add_event("dtv_trick_mouse", m2)


static func held(a: String) -> bool:
	return Input.is_action_pressed("dtv_" + a)


static func is_act(e: InputEvent, a: String) -> bool:
	return e.is_action_pressed("dtv_" + a, false, true)


## The name of the first key for an action, as a player would say it.
static func name(a: String) -> String:
	if not InputMap.has_action("dtv_" + a):
		return a
	for e in InputMap.action_get_events("dtv_" + a):
		if e is InputEventKey:
			var k: int = e.physical_keycode
			match k:
				KEY_SPACE: return "Space"
				KEY_SHIFT: return "Shift"
				KEY_TAB: return "Tab"
			return OS.get_keycode_string(k)
	return "no key"


## "{interact}" becomes "E", and so on, for every action.
static func fill(t: String) -> String:
	if not t.contains("{"):
		return t
	for a in DEF:
		t = t.replace("{" + a + "}", name(a))
	return t
