class_name Update
extends Node
## Keeps the game up to date from GitHub, for the copy that is handed out as a single file.
##
## The file people are given has build N inside it. When we publish a newer build, GitHub holds a small pack of the
## whole game ("thornhallow.pck") and a note saying which build it is ("version.json"). The game asks for the note
## when it reaches the title screen, fetches the pack if it is newer, and from then on boot.gd puts that pack over
## the build the file was born with every time the game starts. The copy in the Godot editor never does any of this.
##
## Safety: a pack that does not get as far as the title screen is thrown away the next time the game starts, and is
## not fetched again, so a bad build cannot lock anybody out.

signal changed

const REPO := "wijji551/Peasant"
const PAGE := "https://github.com/" + REPO + "/releases/latest"
const DIR := "user://update"
const STATE := DIR + "/state.json"

static var me: Update
static var _build := -1
static var _what := ""

var line := ""               # one line for the title screen
var ready_build := 0         # a newer build is on the disk, waiting for a restart
var need_full := false       # the newer build needs the whole file fetched again (a new engine)
var _note := {}
var _http: HTTPRequest
var _dl: HTTPRequest
var _part := ""


# ---------------------------------------------------------------- which build this is
static func build() -> int:
	if _build < 0:
		_build = 0
		var d = JSON.parse_string(FileAccess.get_file_as_string("res://version.json"))
		if d is Dictionary:
			_build = int(d.get("build", 0)); _what = str(d.get("what", ""))
	return _build


## Only the handed-out game updates itself (or a test that asks for it).
static func on() -> bool:
	return OS.has_feature("template") or OS.get_environment("DTV_UPDATE") != ""


## True when this is the game started again from a fetched pack.
static func from_pack() -> bool:
	return Engine.has_meta("dtv_pack")


static func base_url() -> String:
	var e := OS.get_environment("DTV_UPDATE_URL")
	return e if e != "" else "https://github.com/" + REPO + "/releases/latest/download/"


static func _read() -> Dictionary:
	if not FileAccess.file_exists(STATE): return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(STATE))
	return d if d is Dictionary else {}


static func _write(d: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	var f := FileAccess.open(STATE, FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(d))


static func _pack(n: int) -> String:
	return "%s/build-%d.pck" % [DIR, n]


## The title screen is up: this build works.
static func mark_ok() -> void:
	if not from_pack(): return
	var st := _read()
	if int(st.get("ok", 0)) == build(): return
	st["ok"] = build()
	_write(st)


# ---------------------------------------------------------------- looking for a newer build
func _ready() -> void:
	me = self
	line = "Build %d" % build()
	if not on():
		return
	_http = HTTPRequest.new()
	_http.timeout = 20.0
	add_child(_http)
	_http.request_completed.connect(_got_note)
	if _http.request(base_url() + "version.json") != OK:
		_http.queue_free(); _http = null


func _say(t: String) -> void:
	line = t
	changed.emit()


func _got_note(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		return                                 # no internet, or nothing published yet: carry on as we are
	var d = JSON.parse_string(body.get_string_from_utf8())
	if not d is Dictionary: return
	_note = d
	var n := int(d.get("build", 0))
	if n <= build():
		_say("Build %d, the newest" % build())
		return
	var st := _read()
	if int(st.get("bad", 0)) == n:
		_say("Build %d (build %d would not start here)" % [build(), n])
		return
	var eng := Engine.get_version_info()
	if str(d.get("engine", "")) != "%d.%d" % [eng.major, eng.minor]:
		need_full = true
		_say("Build %d is out, and needs a fresh download" % n)
		return
	if int(st.get("build", 0)) == n and FileAccess.file_exists(_pack(n)):
		ready_build = n
		_say("This is build %d. Build %d is ready" % [build(), n])
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	_part = _pack(n) + ".part"
	_dl = HTTPRequest.new()
	_dl.download_file = _part
	_dl.use_threads = true
	add_child(_dl)
	_dl.request_completed.connect(_got_pack.bind(n))
	if _dl.request(base_url() + str(d.get("pack", "thornhallow.pck"))) != OK:
		_dl.queue_free(); _dl = null
		return
	_say("Fetching build %d" % n)
	set_process(true)


func _process(_dt: float) -> void:
	if _dl == null:
		set_process(false)
		return
	var size := int(_note.get("size", 0))
	if size > 0:
		var t := "Fetching build %d: %d%%" % [int(_note.build), clampi(int(100.0 * _dl.get_downloaded_bytes() / size), 0, 99)]
		if t != line: _say(t)


func _got_pack(result: int, code: int, _h: PackedStringArray, _body: PackedByteArray, n: int) -> void:
	_dl.queue_free(); _dl = null
	var good := result == HTTPRequest.RESULT_SUCCESS and code == 200 and FileAccess.file_exists(_part)
	if good and int(_note.get("size", 0)) > 0:
		var f := FileAccess.open(_part, FileAccess.READ)
		good = f != null and f.get_length() == int(_note.size)
	if good and str(_note.get("sha256", "")) != "":
		good = FileAccess.get_sha256(_part) == str(_note.sha256)
	if not good:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_part))
		_say("Build %d (could not fetch build %d; it will try again next time)" % [build(), n])
		return
	DirAccess.rename_absolute(ProjectSettings.globalize_path(_part), ProjectSettings.globalize_path(_pack(n)))
	var st := _read()
	st["build"] = n
	_write(st)
	ready_build = n
	_say("This is build %d. Build %d is ready" % [build(), n])
	if OS.get_environment("DTV_UPDATE_RESTART") != "": restart()       # for testing: straight into it


## What the newer build is, in a few words, if its note says.
func what() -> String:
	return str(_note.get("what", ""))


## Close, and start again in the newer build.
func restart() -> void:
	if ready_build <= 0: return
	OS.set_restart_on_exit(true, OS.get_cmdline_args())
	get_tree().quit()
