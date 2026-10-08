class_name Settings
extends RefCounted
## What the player has chosen, kept between games: their name and colour, their keys, and a few options.

const PATH := "user://settings.json"

static var name := ""
static var col := 0
static var vol := 70                 # sound, 0 to 100 (sound arrives in a later stage)
static var tags := true              # names over the other players
static var see_keep := true          # see through the keep when something is behind it
static var binds := {}               # action -> [physical keycodes]; empty means the usual keys
static var _loaded := false


static func load_all() -> void:
	if _loaded: return
	_loaded = true
	if not FileAccess.file_exists(PATH): return
	var d = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not d is Dictionary: return
	name = str(d.get("name", ""))
	col = clampi(int(d.get("col", 0)), 0, 7)
	vol = clampi(int(d.get("vol", 70)), 0, 100)
	tags = bool(d.get("tags", true))
	see_keep = bool(d.get("see_keep", true))
	var b = d.get("binds", {})
	if b is Dictionary:
		for a in b:
			if Keys.DEF.has(a) and b[a] is Array:
				binds[a] = b[a].map(func(k): return int(k))


static func save() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f: f.store_string(JSON.stringify({"name": name, "col": col, "vol": vol, "tags": tags, "see_keep": see_keep, "binds": binds}))
