class_name Keys
extends RefCounted
## Every action and its keys, as Godot input actions. The handbook lets the player change them, and they are
## kept in Settings. Words on screen name the keys as they are set: "{interact}" in any text becomes "E", or
## whatever E has been changed to.

const ACTIONS := [
	["up", "Move up the screen"], ["left", "Move left"], ["down", "Move down the screen"], ["right", "Move right"],
	["cam_left", "Turn the view left"], ["cam_right", "Turn the view right"], ["look", "Look around: hold, and move the mouse"], ["cam_reset", "Put the view back: north up"],
	["attack", "Attack, and land a fish"], ["trick", "Your weapon’s trick"],
	["interact", "Gather, build, search, rally, use a place (hold)"], ["eat", "Eat"], ["pack", "Open your backpack"], ["skills", "Your skills: books and ranks"],
	["carry", "Use what you carry: bucket or handbell"], ["swap", "Swap to the next weapon in your backpack"],
	["orders", "Posse orders: follow, hold, charge"], ["toilet", "Emergency toilet break"],
	["power1", "Your calling’s first power (the Holy Book: Smite)"], ["power2", "Your calling’s second power (the Holy Book: Pray)"],
	["build", "Next thing to place"], ["ready", "Ready for the night"], ["mute", "Sound on or off"],
]
const DEF := {
	"up": [KEY_W, KEY_UP], "left": [KEY_A, KEY_LEFT], "down": [KEY_S, KEY_DOWN], "right": [KEY_D, KEY_RIGHT],
	"attack": [KEY_SPACE], "trick": [KEY_SHIFT], "interact": [KEY_E], "eat": [KEY_F], "pack": [KEY_I], "skills": [KEY_K],
	"carry": [KEY_G], "swap": [KEY_X], "orders": [KEY_Q], "toilet": [KEY_T], "build": [KEY_TAB], "power1": [KEY_Z], "power2": [KEY_C],
	"ready": [KEY_R], "mute": [KEY_M],
	"cam_left": [KEY_COMMA], "cam_right": [KEY_PERIOD], "look": [KEY_V], "cam_reset": [KEY_N],
}


static func keys_of(a: String) -> Array:
	return Settings.binds.get(a, DEF[a])


## Make the input actions from the keys as they are set now.
static func setup() -> void:
	Settings.load_all()
	for a in DEF:
		var act: String = "dtv_" + a
		if InputMap.has_action(act):
			InputMap.action_erase_events(act)
		else:
			InputMap.add_action(act)
		for k in keys_of(a):
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


## Which action a key does now, or "".
static func action_of(k: int) -> String:
	for a in DEF:
		if keys_of(a).has(k): return a
	return ""


## Give a key to an action. A key does one thing: whatever had it loses it.
static func set_bind(a: String, k: int) -> void:
	for o in DEF:
		var l: Array = keys_of(o).duplicate()
		if l.has(k):
			l.erase(k)
			Settings.binds[o] = l
	Settings.binds[a] = [k]
	Settings.save()
	setup()


static func reset() -> void:
	Settings.binds = {}
	Settings.save()
	setup()


static func held(a: String) -> bool:
	return Input.is_action_pressed("dtv_" + a)


static func is_act(e: InputEvent, a: String) -> bool:
	return e.is_action_pressed("dtv_" + a, false, true)


static func key_name(k: int) -> String:
	match k:
		KEY_SPACE: return "Space"
		KEY_SHIFT: return "Shift"
		KEY_TAB: return "Tab"
		KEY_CTRL: return "Ctrl"
		KEY_ALT: return "Alt"
		KEY_UP: return "Up arrow"
		KEY_DOWN: return "Down arrow"
		KEY_LEFT: return "Left arrow"
		KEY_RIGHT: return "Right arrow"
		KEY_COMMA: return ","
		KEY_PERIOD: return "."
	return OS.get_keycode_string(k)


## The name of the first key for an action, as a player would say it.
static func name(a: String) -> String:
	if not DEF.has(a): return a
	var l := keys_of(a)
	return key_name(l[0]) if l.size() else "no key"


static func all_names(a: String) -> String:
	var l := keys_of(a)
	return " or ".join(l.map(func(k): return key_name(k))) if l.size() else "no key set"


## "{interact}" becomes "E", and so on, for every action.
static func fill(t: String) -> String:
	if not t.contains("{"):
		return t
	for a in DEF:
		t = t.replace("{" + a + "}", name(a))
	return t
