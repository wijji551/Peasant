extends Node
## The first thing to run, before the game itself.
##
## The game that is handed out as a single file can fetch newer builds of itself from GitHub (see update.gd). A
## fetched build is a pack of the whole game, kept in the player's own folder. This script puts the newest good
## pack over the game the file was born with, and then starts the game.
##
## This script stays as it was in the file people were first given, whatever is fetched later. So it is small,
## it stands alone (it must not name any other script of the game), and it should not need to change.
##
## Safety: a pack that does not get as far as the title screen is given up on the next time the game starts.

const DIR := "user://update"
const STATE := DIR + "/state.json"


func _ready() -> void:
	if OS.has_feature("template") or OS.get_environment("DTV_UPDATE") != "":
		_newest()
	get_tree().change_scene_to_file.call_deferred("res://main.tscn")


func _born() -> int:
	var d = JSON.parse_string(FileAccess.get_file_as_string("res://version.json"))
	return int(d.get("build", 0)) if d is Dictionary else 0


func _pack(n: int) -> String:
	return "%s/build-%d.pck" % [DIR, n]


func _newest() -> void:
	if not FileAccess.file_exists(STATE): return
	var st = JSON.parse_string(FileAccess.get_file_as_string(STATE))
	if not st is Dictionary: return
	var born := _born()
	var want: Array = [int(st.get("build", 0)), int(st.get("ok", 0))]     # the newest fetched, then the last that worked
	if want[0] > 0 and int(st.get("tried", 0)) == want[0] and want[0] != want[1]:
		st["bad"] = want[0]                   # it never reached the title screen: go back a build, and do not fetch it again
		want.remove_at(0)
	var have := 0
	for n in want:
		if have > 0 or n <= born or not FileAccess.file_exists(_pack(n)): continue
		if ProjectSettings.load_resource_pack(_pack(n), true): have = n
		else: st["bad"] = n
	st["build"] = have
	if have > 0:
		st["tried"] = have
		Engine.set_meta("dtv_pack", have)     # tells the game it is running from a fetched pack
	var f := FileAccess.open(STATE, FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(st))
	_tidy(have)


## Throw away fetched packs that are no longer wanted: all but the one in use and the one before it (in case
## another copy of the game is still running from that).
func _tidy(keep: int) -> void:
	var d := DirAccess.open(DIR)
	if d == null: return
	var all: Array = []
	for f in d.get_files():
		if f.ends_with(".part"): d.remove(f)
		elif f.begins_with("build-") and f.ends_with(".pck"): all.append(int(f.trim_prefix("build-").trim_suffix(".pck")))
	var before := 0
	for n in all:
		if n < keep: before = maxi(before, n)
	for n in all:
		if n != keep and n != before: d.remove("build-%d.pck" % n)
