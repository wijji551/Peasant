class_name Net
extends Node
## Playing together: one player hosts, up to seven more join by the village code.
##
## The host's game runs the rules for everybody, as in the web version. A joined game sends what its player does
## (where they have walked to, each swing, each thing chosen from a notice) and is sent back, twelve times a second,
## where everything is: players, peasants, the dead, the defences, the trees and what lies on the ground.
##
## The connection is Godot's own (ENet, over UDP port 24565). Hosting asks the router to open that port (UPnP);
## most home routers say yes. The village code is the host's address written as letters. Players on the same home
## network can always join, with the code shown for "the same network".
##
## This node lives above the game's scene, so the connection survives the scene starting again (a new week, or
## trying a day again). main.gd tells it which scene is current with attach().

signal changed          # the lobby, or the connection, has changed: the window showing it should redraw

const PORT := 24565
const RELAY_PORT := 24566
## The village server (relay) everyone uses unless the options say otherwise: "address" or "address:port".
## Empty: no server, and hosting is direct (the host's router has to let friends in).
const DEFAULT_RELAY := "132.145.58.190"
const MAX_PLAYERS := 8
const SEND_RATE := 1.0 / 12.0
const INPUT_RATE := 1.0 / 15.0
const ALPHA := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"   # no I, O, 0 or 1: they are too easy to mix up
const PSTATE := ["ok", "down", "dead", "hide", "inn"]
const QSTATE := ["idle", "follow", "chop", "fight", "hide", "body", "gone", "inn"]
const USTATE := ["rise", "walk", "atk", "pile", "stun", "dig"]
# a player's fields, in the order they are sent
const PF := ["dn", "x", "z", "r", "hp", "wood", "stone", "iron", "food", "coin", "bodies", "bbod", "wpn", "head", "body", "off", "trk",
	"bless", "holy", "holyT", "study", "gab", "spare", "coward", "deaths", "cg", "charge", "hang", "drinkT", "abCd", "useCd", "tbCd",
	"order", "parry", "guard", "state", "ready", "posse", "ac", "hc", "cc", "gk", "prog", "tp", "bite", "downT"]

static var me: Net

var role := "solo"            # "solo", "host" or "client"
var my_id := 1
var code := ""                 # the village code, for over the internet
var lan_code := ""             # the code for the same home network
var port_open := ""            # hosting: "trying", "open" or "closed" (the router would not open the port)
var lobby: Array = []          # [{id, name, col}], in the order they joined
var saved_day := 0             # the host's saved morning, for the lobby's "Carry on" (0: none)
var status := ""               # joining: what is happening, or what went wrong
var kicked := ""               # why the host sent us away, if it did
var main: Node = null          # the game scene

var via_relay := false         # connected through the village server rather than directly
var _peer: ENetMultiplayerPeer
var _conns := {}               # host: network peer id -> player id
var _last_in := {}             # host: player id -> when we last heard from them
var _next_id := 2
var _acc := 0.0
var _in_acc := 0.0
var _sent_sv := -1
var _sent_tv := -1
var _sent_dawn := -1
var _tick := 0
var ev_out: Array = []          # host: what happened since the last snapshot
var _pending: Array = []        # client: messages that came while no game scene was ready
var _upnp: UPNP
var _thread: Thread


static func ensure(tree: SceneTree) -> Net:
	if me == null or not is_instance_valid(me):
		me = Net.new()
		me.name = "Net"
		tree.root.add_child.call_deferred(me)
	return me


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var mp := multiplayer as SceneMultiplayer
	mp.peer_connected.connect(func(pid): if not via_relay: _on_peer_joined(pid))
	mp.peer_disconnected.connect(func(pid): if not via_relay: _on_peer_left(pid))
	mp.peer_packet.connect(_on_packet)
	mp.connected_to_server.connect(_on_connected)
	mp.connection_failed.connect(_on_failed)
	mp.server_disconnected.connect(_on_server_gone)


func attach(m: Node) -> void:
	main = m
	if role == "client":
		var q := _pending
		_pending = []
		for msg in q:
			_client_msg(msg)


func is_client() -> bool: return role == "client"
func is_host() -> bool: return role == "host"
func online() -> bool: return role != "solo"


# ---------------------------------------------------------------- the code
static func encode(ip: String) -> String:
	var parts := ip.split(".")
	if parts.size() != 4: return ""
	var n := 0
	for p in parts: n = n * 256 + int(p)
	var s := ""
	for i in 7:
		s = ALPHA[n % 32] + s
		n = n / 32
	return s.substr(0, 4) + "-" + s.substr(4)


## A code, or a plain address ("192.168.1.20"), as an address to connect to. "" if it is neither.
static func decode(text: String) -> String:
	var t := text.strip_edges().to_upper().replace(" ", "")
	if t.count(".") == 3:
		return t.split(":")[0]
	t = t.replace("-", "")
	if t.length() != 7: return ""
	var n := 0
	for ch in t:
		var v := ALPHA.find(ch)
		if v < 0: return ""
		n = n * 32 + v
	if n > 0xFFFFFFFF: return ""
	return "%d.%d.%d.%d" % [(n >> 24) & 255, (n >> 16) & 255, (n >> 8) & 255, n & 255]


static func local_ip() -> String:
	for a in IP.get_local_addresses():
		if a.begins_with("192.168.") or a.begins_with("10."): return a
		if a.begins_with("172."):
			var b := int(a.split(".")[1])
			if b >= 16 and b <= 31: return a
	return "127.0.0.1"


# ---------------------------------------------------------------- the village server
static func relay_address() -> String:
	var a: String = Settings.relay.strip_edges() if Settings.relay.strip_edges() != "" else DEFAULT_RELAY
	return "" if a.to_lower() == "none" else a   # "none": host straight from this computer


func _relay_connect() -> String:
	var a := relay_address()
	var host_ := a
	var port := RELAY_PORT
	if a.count(":") == 1:
		host_ = a.split(":")[0]; port = int(a.split(":")[1])
	_peer = ENetMultiplayerPeer.new()
	if _peer.create_client(host_, port, 3) != OK:
		_peer = null
		return "Could not reach the village server (%s)." % a
	_peer.host.compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.multiplayer_peer = _peer
	via_relay = true
	return ""


func _relay_timeout() -> void:   # no code from the village server within eight seconds: host from here instead
	await get_tree().create_timer(8.0).timeout
	if role == "host" and via_relay and code == "":
		_on_failed()


func _relay_msg(m: Dictionary) -> void:   # from the village server itself
	match str(m.r):
		"room":                                   # hosting: our village has a code
			code = str(m.code)
			port_open = "relay"
			changed.emit()
		"in":
			status = "In. Waiting for the host to let us in..."
			changed.emit()
		"err":
			var why := str(m.why)
			leave()
			status = why
			changed.emit()
		"joined":
			_on_peer_joined(int(m.pid))
		"left":
			_on_peer_left(int(m.pid))
		"closed":
			kicked = str(m.get("why", "The host has closed the village."))
			_on_server_gone()
		"from":
			var inner = bytes_to_var(m.d)
			if inner is Dictionary and inner.has("t"):
				if role == "host": _host_msg(int(m.from), inner)
				elif role == "client":
					if main == null or not is_instance_valid(main): _pending.append(inner)
					else: _client_msg(inner)


# ---------------------------------------------------------------- hosting
func host(name_: String, col: int) -> String:
	leave()
	if relay_address() != "":                    # through the village server: nobody's router matters
		var why := _relay_connect()
		if why == "":
			role = "host"
			my_id = 1
			_next_id = 2
			_conns.clear()
			lobby = [{"id": 1, "name": name_, "col": col}]
			port_open = "trying"
			status = ""
			set_meta("fallback", [name_, col])
			changed.emit()
			_relay_timeout()
			return ""
	return _host_direct(name_, col)


func _host_direct(name_: String, col: int) -> String:
	leave()
	_peer = ENetMultiplayerPeer.new()
	var err := _peer.create_server(PORT, MAX_PLAYERS - 1)
	if err != OK:
		_peer = null
		return "Could not open a village on this computer (port %d is busy: is another copy of the game hosting?)." % PORT
	_peer.host.compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.multiplayer_peer = _peer
	role = "host"
	my_id = 1
	_next_id = 2
	_conns.clear()
	lobby = [{"id": 1, "name": name_, "col": col}]
	lan_code = encode(local_ip())
	code = ""
	port_open = "trying"
	_thread = Thread.new()
	_thread.start(_open_port)
	changed.emit()
	return ""


func _open_port() -> void:   # in its own thread: asking the router can take a few seconds
	var u := UPNP.new()
	var ok := false
	var ext := ""
	if u.discover(2000, 2, "") == UPNP.UPNP_RESULT_SUCCESS and u.get_gateway() and u.get_gateway().is_valid_gateway():
		if u.add_port_mapping(PORT, PORT, "Defend the Village", "UDP", 0) == UPNP.UPNP_RESULT_SUCCESS:
			ok = true
			ext = u.query_external_address()
	_port_result.call_deferred(ok, ext, u)


func _port_result(ok: bool, ext: String, u: UPNP) -> void:
	if _thread: _thread.wait_to_finish(); _thread = null
	if role != "host": return
	_upnp = u if ok else null
	port_open = "open" if ok and ext != "" else "closed"
	code = encode(ext) if ok and ext != "" else ""
	changed.emit()


func _on_peer_joined(pid: int) -> void:
	if role != "host": return
	if main and main.screen == "game":
		_send({"t": "no", "why": "The week has already begun in that village. Ask the host to start a new one, then join before it starts."}, pid)
		_drop_later(pid)
		return
	if lobby.size() >= MAX_PLAYERS:
		_send({"t": "no", "why": "That village is full: eight peasants already."}, pid)
		_drop_later(pid)
		return
	var id := _next_id
	_next_id += 1
	_conns[pid] = id
	lobby.append({"id": id, "name": "Peasant", "col": _free_col(-1)})
	_send({"t": "you", "id": id}, pid)
	send_lobby()


func _drop_later(pid: int) -> void:
	await get_tree().create_timer(0.4).timeout
	_drop(pid)


func _drop(pid: int) -> void:
	if _peer == null or role != "host": return
	if via_relay: _raw({"r": "kick", "pid": pid})
	else: _peer.disconnect_peer(pid)


func _on_peer_left(pid: int) -> void:
	if role != "host" or not _conns.has(pid): return
	var id: int = _conns[pid]
	_conns.erase(pid)
	lobby = lobby.filter(func(l): return l.id != id)
	if main and main.screen == "game":
		main.R.remove_player(id)
		send_roster()
	else:
		send_lobby()


func _free_col(want: int) -> int:
	var used := lobby.map(func(l): return l.col)
	if want >= 0 and not used.has(want): return want
	for i in 8:
		if not used.has(i): return i
	return 0


func send_lobby() -> void:
	_send({"t": "lobby", "pl": lobby.map(func(l): return [l.id, l.name, l.col]), "code": code, "lan": lan_code, "sv": saved_day})
	changed.emit()


## The game has started (or started again): everyone is told who is playing, and gets the whole picture.
func send_roster() -> void:
	if role != "host" or main == null: return
	var R: Rules = main.R
	_send({"t": "ros", "pm": R.pm, "sd": R.gseed, "ln": R.last_day, "pl": R.players.map(func(p): return [p.id, p.name, p.col, p.slot])})
	_sent_sv = -1
	_sent_tv = -1
	_sent_dawn = -1


func restart() -> void:   # the host is starting a new week, or trying a day again: everyone waits for it
	if role == "host": _send({"t": "restart"})


## Who is playing, for main.begin(): the host first, everyone in the lobby after.
func infos() -> Array:
	return lobby.map(func(l): return {"id": l.id, "name": l.name, "col": l.col, "remote": l.id != my_id})


# ---------------------------------------------------------------- joining
func join(text: String, name_: String, col: int) -> String:
	leave()
	var t := text.strip_edges().to_upper()
	if t.length() == 5 and t.is_valid_identifier() and not t.contains("_"):   # five letters: a village on the village server
		if relay_address() == "":
			return "That is a village server code, but this game has no village server set (the handbook's options)."
		var why := _relay_connect()
		if why != "": return why
		role = "client"
		my_id = 0
		kicked = ""
		status = "Asking the village server for %s..." % t
		lobby = []
		set_meta("hello", [name_, col])
		set_meta("room", t)
		changed.emit()
		_join_timeout()
		return ""
	var ip := decode(text)
	if ip == "":
		return "That is not a village code. It looks like ABCD-EFG (letters and numbers), or an address like 192.168.1.20."
	_peer = ENetMultiplayerPeer.new()
	if _peer.create_client(ip, PORT) != OK:
		_peer = null
		return "Could not start the connection."
	_peer.host.compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.multiplayer_peer = _peer
	role = "client"
	my_id = 0
	kicked = ""
	status = "Knocking on the village gate..."
	lobby = []
	set_meta("hello", [name_, col])
	changed.emit()
	_join_timeout()
	return ""


func _join_timeout() -> void:
	await get_tree().create_timer(12.0).timeout
	if role == "client" and my_id == 0:
		var why := "No answer from that village. Check the code with the host. Over the internet, the host's router may not have opened the way in: they can try the code for the same network if you are both at home, or open port %d (UDP) on their router." % PORT
		leave()
		status = why
		changed.emit()


func _on_connected() -> void:
	if via_relay:                                 # connected to the village server: ask for a village, or to join one
		if role == "host": _raw({"r": "host"})
		else: _raw({"r": "join", "code": get_meta("room", "")})
		return
	status = "In. Waiting to be let in..."
	changed.emit()


func _raw(m: Dictionary) -> void:   # straight to the village server
	if _peer: (multiplayer as SceneMultiplayer).send_bytes(var_to_bytes(m), 1, MultiplayerPeer.TRANSFER_MODE_RELIABLE, 0)


func _on_failed() -> void:
	if via_relay and role == "host":               # the village server is not answering: host directly instead
		var h: Array = get_meta("fallback", ["Peasant", 0])
		var why := _host_direct(h[0], h[1])
		status = "The village server did not answer, so this village is hosted from this computer instead." if why == "" else why
		changed.emit()
		return
	var was_relay := via_relay
	leave()
	status = "The village server did not answer. Try again in a minute." if was_relay else "Could not reach that village."
	changed.emit()


func _on_server_gone() -> void:
	var why := kicked if kicked != "" else ("Lost the connection to the village server." if via_relay else "The host has closed the village.")
	var in_game: bool = main != null and main.screen == "game"
	leave()
	status = why
	changed.emit()
	if in_game and main: main.host_left(why)


## Close the connection, whichever side we are on.
func leave() -> void:
	if role == "host" and _peer:
		_send({"t": "bye"})
		_peer.host.flush()
	if _upnp:
		_upnp.delete_port_mapping(PORT, "UDP")
		_upnp = null
	if _peer:
		_peer.close()
	multiplayer.multiplayer_peer = null
	_peer = null
	role = "solo"
	via_relay = false
	my_id = 1
	_conns.clear()
	_last_in.clear()
	lobby = []
	code = ""
	lan_code = ""
	port_open = ""
	saved_day = 0
	ev_out = []
	_pending = []


func _exit_tree() -> void:
	leave()


# ---------------------------------------------------------------- sending
func _send(m: Dictionary, to: int = 0, reliable: bool = true) -> void:
	if _peer == null or _peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED: return
	var mp := multiplayer as SceneMultiplayer
	if via_relay:                                 # wrapped for the village server, which passes it on
		var w := {"r": "to", "to": -1 if role == "client" else to, "u": not reliable, "d": var_to_bytes(m)}
		mp.send_bytes(var_to_bytes(w), 1, MultiplayerPeer.TRANSFER_MODE_RELIABLE if reliable else MultiplayerPeer.TRANSFER_MODE_UNRELIABLE_ORDERED, 0 if reliable else 1)
		return
	mp.send_bytes(var_to_bytes(m), to, MultiplayerPeer.TRANSFER_MODE_RELIABLE if reliable else MultiplayerPeer.TRANSFER_MODE_UNRELIABLE_ORDERED, 0 if reliable else 1)


## A joined game: tell the host what our player did.
func send_host(m: Dictionary) -> void:
	_send(m, 1, m.t != "in")


func _on_packet(pid: int, bytes: PackedByteArray) -> void:
	var m = bytes_to_var(bytes)
	if via_relay:
		if m is Dictionary and m.has("r"): _relay_msg(m)
		return
	if not m is Dictionary or not m.has("t"): return
	if role == "host":
		_host_msg(pid, m)
	elif role == "client":
		if main == null or not is_instance_valid(main): _pending.append(m)
		else: _client_msg(m)


func _host_msg(pid: int, m: Dictionary) -> void:
	if not _conns.has(pid): return
	var id: int = _conns[pid]
	_last_in[id] = Time.get_ticks_msec()
	if m.t == "hi":
		for l in lobby:
			if l.id == id:
				l.name = str(m.get("name", "Peasant")).strip_edges().substr(0, 14)
				if l.name == "": l.name = "Peasant"
				l.col = _free_col(int(m.get("col", -1)))
		send_lobby()
		return
	if main == null or main.screen != "game": return
	var p: E.Player = main.R.player_by_id(id)
	if p: apply(main.R, p, m)


## What a player did, done to the rules. The host does this for everyone: for its own player straight away, and for
## the others when their messages arrive. Everything is checked again by the rules.
static func apply(R: Rules, p: E.Player, m: Dictionary) -> void:
	match str(m.t):
		"in":
			if p.state == "ok" and int(m.get("tp", -1)) == p.tp:   # where they walked to (ignored just after the rules moved them)
				p.tx = clampf(float(m.x), D.X0, D.X1); p.tz = clampf(float(m.z), D.Z0, D.Z1); p.goal_r = float(m.r)
			p.eHold = bool(m.get("e", false)) and R.live() and (p.state == "ok" or p.state == "hide")
		"atk": p.r = float(m.r); p.goal_r = p.r; R.do_attack(p)
		"abl": p.r = float(m.r); p.goal_r = p.r; R.do_ability(p)
		"use": p.r = float(m.r); p.goal_r = p.r; R.do_use(p)
		"tb": R.do_toilet(p)
		"ord": R.do_order(p)
		"bld": R.try_place(p, str(m.k), float(m.x), float(m.z), float(m.rot))
		"rdy": if R.phase == "day": p.ready = bool(m.v)
		"act": R.do_act(p, str(m.a), m.get("arg"))
		"eat": R.do_eat(p)
		"fish": R.do_fish(p)
		"sell": R.sell_spare(p)


# ---------------------------------------------------------------- every frame
func _process(delta: float) -> void:
	if main == null or not is_instance_valid(main) or main.screen != "game": return
	if role == "host":
		_host_tick(delta)
	elif role == "client":
		_client_tick(delta)


func _host_tick(delta: float) -> void:
	var R: Rules = main.R
	var now := Time.get_ticks_msec()
	for pid in _conns.keys():                     # gone quiet for twelve seconds: they have gone
		var id: int = _conns[pid]
		if now - int(_last_in.get(id, now)) > 12000:
			_drop(pid)
			_on_peer_left(pid)
	_acc += delta
	if _acc < SEND_RATE or _conns.is_empty(): return
	_acc = 0.0
	_tick += 1
	if _sent_dawn != R.dawn.seq:
		_sent_dawn = R.dawn.seq
		_send({"t": "dawn", "d": R.dawn})
	if R.sv != _sent_sv:
		_sent_sv = R.sv
		_send({"t": "st", "a": R.structs.map(func(s): return [s.id, s.k, s.x, s.z, s.rot, s.built, s.hp, s.mhp, s.slot, s.hc, s.re, s.bl, s.nr])})
	if R.tv != _sent_tv:
		_sent_tv = R.tv
		var codes := []
		for t in R.trees:
			if t.st or t.par: codes.append([t.i, t.st, t.par, t.gd])
		_send({"t": "tr", "a": codes, "tv": R.tv})
	var big := R.undead.size() > 120
	var send_un := not big or _tick % 2 == 0      # a big horde goes every other time, to spare the host's connection
	_send(pack(R, send_un), 0, false)
	ev_out = []


## Where everything is now, for the joined games.
func pack(R: Rules, with_undead: bool) -> Dictionary:
	var pl := []
	for p in R.players:
		var a := [p.id]
		for f in PF:
			var v = p.get(f)
			if f == "state": v = PSTATE.find(v)
			a.append(v)
		a.append(p.inv.duplicate()); a.append(p.books.duplicate()); a.append(p.xp.map(func(x): return floorf(x)))
		pl.append(a)
	var pe := PackedFloat32Array()
	for q in R.peasants:
		if q.state == "gone" or q.state == "inn": continue
		pe.append_array([q.id, q.x, q.z, q.r, q.hp, q.owner, QSTATE.find(q.state), q.ac, q.hc, q.ni, q.armed, q.nv])
	var o := {"t": "s", "ph": R.phase, "d": R.day, "tl": R.timeLeft, "nf": R.nf, "k": R.keepHp, "kc": R.keepHc,
		"w": [R.wave, R.waves, R.left], "stt": R.stats, "so": R.store, "si": R.sites, "sp": R.spots, "rs": R.ruins_seen,
		"al": R.ale, "ih": R.innHp, "wx": R.weather, "it": R.items, "dr": R.drops.map(func(d): return [d.id, d.it, d.x, d.z]),
		"pl": pl, "pe": pe, "ev": ev_out}
	if with_undead:
		var un := PackedFloat32Array()
		for u in R.undead:
			var fl: int = (1 if u.stun > 0 else 0) | (2 if u.pin > 0 else 0) | (4 if u.fear > 0 else 0) | (8 if u.vuln > 0 else 0) | (16 * u.stage) | (64 if u.march else 0)
			un.append_array([u.id, u.k, u.x, u.z, u.r, u.hp, u.mhp, USTATE.find(u.state), u.ac, u.hc, fl])
		o.un = un
	return o


func _client_tick(delta: float) -> void:
	var R: Rules = main.R
	var k := minf(1.0, delta * 11.0)              # ease everything toward where the host last said it was
	for p in R.players:
		if p.id == my_id: continue
		p.x = lerpf(p.x, p.tx, k); p.z = lerpf(p.z, p.tz, k); p.r = D.ang_lerp(p.r, p.goal_r, k)
	for q in R.peasants:
		q.x = lerpf(q.x, q.tx, k); q.z = lerpf(q.z, q.tz, k); q.r = D.ang_lerp(q.r, q.tr, k)
	for u in R.undead:
		u.x = lerpf(u.x, u.tx, k); u.z = lerpf(u.z, u.tz, k); u.r = D.ang_lerp(u.r, u.tr, k)
	_in_acc += delta
	var p: E.Player = R.player_by_id(my_id)
	if _in_acc >= INPUT_RATE and p:
		_in_acc = 0.0
		send_host({"t": "in", "x": p.x, "z": p.z, "r": p.r, "e": p.eHold, "tp": p.tp})


func _client_msg(m: Dictionary) -> void:
	var R: Rules = main.R
	match str(m.t):
		"you":
			my_id = int(m.id)
			status = ""
			var h: Array = get_meta("hello", ["Peasant", 0])
			send_host({"t": "hi", "name": h[0], "col": h[1]})
			changed.emit()
		"no":
			kicked = str(m.why)
		"bye":
			kicked = "The host has closed the village."
		"lobby":
			lobby = []
			for a in m.pl: lobby.append({"id": int(a[0]), "name": str(a[1]), "col": int(a[2])})
			code = str(m.get("code", "")); lan_code = str(m.get("lan", "")); saved_day = int(m.get("sv", 0))
			changed.emit()
		"restart":
			main.client_restart()
		"ros":
			R.pm = int(m.pm); R.gseed = int(m.sd); R.last_day = int(m.get("ln", D.MONTH))
			var keep := {}
			for a in m.pl:
				var p: E.Player = R.player_by_id(int(a[0]))
				if p == null:
					p = E.Player.new()
					p.id = int(a[0])
					p.remote = p.id != my_id
					R.players.append(p)
				p.name = str(a[1]); p.col = int(a[2]); p.slot = int(a[3])
				if p.dn == "": p.dn = p.name
				keep[p.id] = true
			R.players = R.players.filter(func(p): return keep.has(p.id))
		"dawn":
			R.dawn = m.d
		"st":
			var by := {}
			for s in R.structs: by[s.id] = s
			var out := []
			for a in m.a:
				var s: E.Struct = by.get(int(a[0]))
				if s == null:
					s = R.mk_struct(str(a[1]), a[2], a[3], a[4], a[5], a[6], a[7], int(a[8]))
					s.id = int(a[0])
				s.k = str(a[1]); s.x = a[2]; s.z = a[3]; s.rot = a[4]; s.built = a[5]; s.hp = a[6]; s.mhp = a[7]
				s.slot = int(a[8]); s.hc = int(a[9]); s.re = a[10]; s.bl = a[11]; s.nr = a[12]
				s.hw = D.SDIM[s.k].x; s.hd = D.SDIM[s.k].y
				out.append(s)
			R.structs = out
			R.sv += 1
		"tr":
			for t in R.trees: t.set_state(0, 0)
			for a in m.a:
				if int(a[0]) < R.trees.size():
					var t: E.Trunk = R.trees[int(a[0])]
					t.set_state(int(a[1]), int(a[2])); t.gd = int(a[3])
			R.tv += 1
		"s":
			_snapshot(R, m)


func _snapshot(R: Rules, m: Dictionary) -> void:
	R.phase = str(m.ph); R.day = int(m.d); R.timeLeft = m.tl; R.nf = m.nf; R.keepHp = m.k; R.keepHc = int(m.kc)
	R.wave = int(m.w[0]); R.waves = int(m.w[1]); R.left = int(m.w[2])
	R.stats = m.stt; R.store = m.so; R.spots = m.sp; R.ruins_seen = m.rs; R.ale = int(m.al); R.innHp = m.ih; R.items = m.it; R.weather = str(m.get("wx", "clear"))
	if str(m.si) != str(R.sites):
		R.sites = m.si
		R.set_sites(R.sites)
	R.drops = []
	for a in m.dr:
		var d := E.Drop.new(); d.id = int(a[0]); d.it = int(a[1]); d.x = a[2]; d.z = a[3]
		R.drops.append(d)
	for a in m.pl:
		var p: E.Player = R.player_by_id(int(a[0]))
		if p == null: continue
		var mine := p.id == my_id
		var old_tp := p.tp
		var old_state := p.state
		for i in PF.size():
			var f: String = PF[i]
			var v = a[i + 1]
			if f == "state": v = PSTATE[int(v)]
			if mine and (f == "x" or f == "z" or f == "r"): continue      # our own player walks where we walk
			if f == "x": p.tx = v; continue
			if f == "z": p.tz = v; continue
			if f == "r": p.goal_r = v; continue
			if mine and f == "ac": continue                                   # we count our own swings
			p.set(f, v)
		p.inv = a[PF.size() + 1]; p.books = a[PF.size() + 2]; p.xp = a[PF.size() + 3]
		var moved: bool = p.tp != old_tp or (mine and p.state != "ok" and old_state == "ok")
		if mine and moved:                          # the rules moved us (home at dawn, into the inn): go there
			p.x = a[2]; p.z = a[3]; p.r = a[4]
		elif not mine and (moved or (p.x == 0 and p.z == 0)):
			p.x = p.tx; p.z = p.tz; p.r = p.goal_r
	var by := {}
	for q in R.peasants: by[q.id] = q
	var pe: PackedFloat32Array = m.pe
	var out := []
	for i in range(0, pe.size(), 12):
		var id := int(pe[i])
		var q: E.Peasant = by.get(id)
		if q == null:
			q = E.Peasant.new(); q.id = id; q.x = pe[i + 1]; q.z = pe[i + 2]; q.r = pe[i + 3]
		q.tx = pe[i + 1]; q.tz = pe[i + 2]; q.tr = pe[i + 3]; q.hp = pe[i + 4]; q.owner = int(pe[i + 5]); q.state = QSTATE[int(pe[i + 6])]
		q.ac = int(pe[i + 7]); q.hc = int(pe[i + 8]); q.ni = int(pe[i + 9]); q.armed = int(pe[i + 10]); q.nv = pe[i + 11]
		out.append(q)
	R.peasants = out
	if m.has("un"):
		var ub := {}
		for u in R.undead: ub[u.id] = u
		var un: PackedFloat32Array = m.un
		var uo := []
		for i in range(0, un.size(), 11):
			var id := int(un[i])
			var u: E.Undead = ub.get(id)
			if u == null:
				u = E.Undead.new(); u.id = id; u.x = un[i + 2]; u.z = un[i + 3]; u.r = un[i + 4]
			u.k = int(un[i + 1]); u.tx = un[i + 2]; u.tz = un[i + 3]; u.tr = un[i + 4]; u.hp = un[i + 5]; u.mhp = un[i + 6]
			u.state = USTATE[int(un[i + 7])]; u.ac = int(un[i + 8]); u.hc = int(un[i + 9])
			var fl := int(un[i + 10])
			u.stun = 1.0 if fl & 1 else 0.0; u.pin = 1.0 if fl & 2 else 0.0; u.fear = 1.0 if fl & 4 else 0.0; u.vuln = 1.0 if fl & 8 else 0.0
			u.stage = (fl >> 4) & 3; u.march = (fl & 64) != 0
			uo.append(u)
		R.undead = uo
		R.boss = null
		for u in uo:
			if D.UN[u.k].boss: R.boss = u
	R.ev.append_array(m.ev)
	if main.screen != "game" and R.player_by_id(my_id) != null:
		main.client_enter()
