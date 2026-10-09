extends SceneTree
## The village server. It does not run any game: it lets players find each other and passes their messages on.
##
## A host asks for a village and is given a five-letter code. Friends join with that code. From then on, what the
## host sends goes to everyone in its village, and what a friend sends goes to the host. Everybody connects out to
## this server, so nobody's router has to let anyone in.
##
## Run:  godot --headless --path relay -s relay.gd [-- --port 24566]
## Messages (Dictionaries, as Godot's var_to_bytes):
##   to the server:   {r: "host"}  {r: "join", code}  {r: "to", to: 0 everyone / pid one / -1 the host, u: unreliable?, d: bytes}
##                    {r: "kick", pid}
##   from the server: {r: "room", code}  {r: "in", code}  {r: "err", why}  {r: "joined", pid}  {r: "left", pid}
##                    {r: "from", from: pid, d: bytes}  {r: "closed", why}

const DEFAULT_PORT := 24566
const MAX_PEERS := 400
const MAX_ROOM := 8                 # the host and seven more
const MAX_ROOMS := 200
const MAX_BYTES := 262144           # a message bigger than this is dropped
const LETTERS := "ABCDEFGHJKLMNPQRSTUVWXYZ"

var peer := ENetMultiplayerPeer.new()
var mp := SceneMultiplayer.new()
var rooms := {}                     # code -> {host: pid, members: [pid]}
var where := {}                     # pid -> code
var started := Time.get_unix_time_from_system()


func _init() -> void:
	var port := DEFAULT_PORT
	var args := OS.get_cmdline_user_args()
	var i := args.find("--port")
	if i >= 0 and i + 1 < args.size(): port = int(args[i + 1])
	if peer.create_server(port, MAX_PEERS, 3) != OK:
		printerr("Could not open UDP port %d. Is another village server running?" % port)
		quit(1)
		return
	peer.host.compress(ENetConnection.COMPRESS_RANGE_CODER)
	mp.multiplayer_peer = peer
	mp.allow_object_decoding = false
	set_multiplayer(mp)                     # the tree polls it every frame
	mp.peer_connected.connect(func(pid): _log("in %d" % pid))
	mp.peer_disconnected.connect(_gone)
	mp.peer_packet.connect(_packet)
	_log("Village server listening on UDP port %d" % port)


func _log(t: String) -> void:
	print("[%s] %s  (villages %d, people %d)" % [Time.get_datetime_string_from_system(), t, rooms.size(), where.size()])


func _send(pid: int, m: Dictionary, reliable: bool = true) -> void:
	mp.send_bytes(var_to_bytes(m), pid, MultiplayerPeer.TRANSFER_MODE_RELIABLE if reliable else MultiplayerPeer.TRANSFER_MODE_UNRELIABLE_ORDERED, 0 if reliable else 1)


func _new_code() -> String:
	for attempt in 50:
		var c := ""
		for k in 5: c += LETTERS[randi() % LETTERS.length()]
		if not rooms.has(c): return c
	return ""


func _packet(pid: int, bytes: PackedByteArray) -> void:
	if bytes.size() > MAX_BYTES: return
	var m = bytes_to_var(bytes)
	if not m is Dictionary or not m.has("r"): return
	match str(m.r):
		"host":
			_leave_room(pid)
			if rooms.size() >= MAX_ROOMS:
				_send(pid, {"r": "err", "why": "The village server is full. Try again later."})
				return
			var c := _new_code()
			rooms[c] = {"host": pid, "members": []}
			where[pid] = c
			_send(pid, {"r": "room", "code": c})
			_log("village %s opened by %d" % [c, pid])
		"join":
			_leave_room(pid)
			var c := str(m.get("code", "")).strip_edges().to_upper()
			if not rooms.has(c):
				_send(pid, {"r": "err", "why": "No village is using that code. Check it with the host."})
				return
			var room: Dictionary = rooms[c]
			if room.members.size() + 1 >= MAX_ROOM:
				_send(pid, {"r": "err", "why": "That village is full: eight peasants already."})
				return
			room.members.append(pid)
			where[pid] = c
			_send(pid, {"r": "in", "code": c})
			_send(room.host, {"r": "joined", "pid": pid})
			_log("%d joined %s" % [pid, c])
		"to":
			if not where.has(pid): return
			var room: Dictionary = rooms.get(where[pid], {})
			if room.is_empty(): return
			var rel := not bool(m.get("u", false))
			var out := {"r": "from", "from": pid, "d": m.get("d", PackedByteArray())}
			var to := int(m.get("to", -1))
			if pid == room.host:
				if to == 0:
					for p in room.members: _send(p, out, rel)
				elif room.members.has(to):
					_send(to, out, rel)
			else:
				_send(room.host, out, rel)
		"kick":
			if where.has(pid):
				var room: Dictionary = rooms.get(where[pid], {})
				var who := int(m.get("pid", 0))
				if room.get("host") == pid and room.members.has(who):
					peer.disconnect_peer(who)


func _gone(pid: int) -> void:
	_leave_room(pid)


func _leave_room(pid: int) -> void:
	if not where.has(pid): return
	var c: String = where[pid]
	where.erase(pid)
	var room: Dictionary = rooms.get(c, {})
	if room.is_empty(): return
	if room.host == pid:                       # the host has gone: the village closes
		for p in room.members:
			_send(p, {"r": "closed", "why": "The host has closed the village."})
			where.erase(p)
		rooms.erase(c)
		_log("village %s closed" % c)
	else:
		room.members.erase(pid)
		_send(room.host, {"r": "left", "pid": pid})
		_log("%d left %s" % [pid, c])
