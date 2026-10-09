class_name Settings
extends RefCounted
## What the player has chosen, kept between games: their name and colour, their keys, and a few options.

const PATH := "user://settings.json"

static var name := ""
static var col := 0
static var vol := 70                 # all sound, 0 to 100
static var fx_vol := 80              # the effects
static var amb_vol := 70             # the ambience: birds, crickets, rain, the castle
static var music_vol := 50           # the tunes
static var muted := false            # M
static var relay := ""               # the village server's address, if not the usual one
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
	fx_vol = clampi(int(d.get("fx_vol", 80)), 0, 100)
	amb_vol = clampi(int(d.get("amb_vol", 70)), 0, 100)
	music_vol = clampi(int(d.get("music_vol", 50)), 0, 100)
	muted = bool(d.get("muted", false))
	relay = str(d.get("relay", ""))
	tags = bool(d.get("tags", true))
	see_keep = bool(d.get("see_keep", true))
	var b = d.get("binds", {})
	if b is Dictionary:
		for a in b:
			if Keys.DEF.has(a) and b[a] is Array:
				binds[a] = b[a].map(func(k): return int(k))


## The volumes by name, for the sliders in the options.
static func volume(k: String) -> int:
	match k:
		"vol": return vol
		"fx_vol": return fx_vol
		"amb_vol": return amb_vol
		"music_vol": return music_vol
	return 0


static func set_volume(k: String, v: int) -> void:
	match k:
		"vol": vol = v
		"fx_vol": fx_vol = v
		"amb_vol": amb_vol = v
		"music_vol": music_vol = v


static func save() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f: f.store_string(JSON.stringify({"name": name, "col": col, "vol": vol, "fx_vol": fx_vol, "amb_vol": amb_vol, "music_vol": music_vol, "muted": muted, "relay": relay, "tags": tags, "see_keep": see_keep, "binds": binds}))
