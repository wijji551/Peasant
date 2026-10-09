extends Control
## Words over the 3D world: the name of each place when you are near it (as the web version's signs), and the
## names of the other players (your own banner is enough for you).

const PLACES := [
	["Market", 0.0, 21.6, 3.2], ["Smithy", 16.5, -4.7, 6.0], ["Storehouse", 17.0, 10.6, 6.5], ["Library", 17.0, 20.4, 8.0],
	["Slum", -17.6, 20.5, 3.4], ["The Thorny Rose Inn", -17.5, -4.7, 7.5], ["Bailiff’s House", -14.5, -12.6, 8.6],
	["Farms: food", -58.0, 30.0, 1.5], ["The keep", 0.0, 0.0, 12.4], ["Chapel: the priest", 17.0, -14.0, 8.4],
	["Old ruins: search", 10.8, -15.4, 3.4], ["Ruins: search", "ruin1", 0.0, 5.0], ["Ruins: search", "ruin2", 0.0, 5.0],
	["Outcrop: stone", "quarry", 0.0, 3.6], ["Mine: iron", "mine", 0.0, 4.0], ["Jetty: fishing", "jetty", 0.0, 1.6],
	["Old mine: steel", -108.0, -44.0, 4.0], ["The old mill", 104.0, 30.0, 9.0], ["Merchant", "cart", 0.0, 3.2], ["Bailiff’s back door", -14.5, -16.4, 2.8],
	["A chest", "chest", 0.0, 1.9], ["Notice board", -5.5, -9.5, 2.5], ["A new letter from the castle", "letter", 0.0, 2.9],
]

var R: Rules
var me: E.Player
var camera: Camera3D
var hud: CanvasLayer
var _zones: Array[Rect2] = []
var _taken: Array[Rect2] = []       # where this frame's signs are, so that no sign sits on another when the view is turned
var focus := Vector3.ZERO
var _signs: Array[Label] = []
var _names: Array[Label] = []
var _bubbles := {}                  # peasant id -> [label, seconds left]
var _bailiff: Label


## A peasant says something: a little speech bubble over their head for a few seconds.
func bark(qid: int, text: String) -> void:
	if _bubbles.has(qid): _bubbles[qid][0].queue_free()
	var l := _label(text, 13, Color("2f2318"), Color("fffaf0"))
	_bubbles[qid] = [l, 3.5]


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for p in PLACES:
		var l := _label(p[0], 14, Color("2f2318"), Color("ecdcae"))
		_signs.append(l)


func _label(text: String, size_: int, ink: Color, bg: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size_)
	l.add_theme_color_override("font_color", ink)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(bg, 0.92)
	sb.border_color = Color("4a2a12")
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	sb.set_content_margin_all(3)
	sb.content_margin_left = 6; sb.content_margin_right = 6
	l.add_theme_stylebox_override("normal", sb)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


func _put(l: Label, at: Vector3, sign_: bool = false) -> void:   # centred over the point, sitting on it
	if camera.is_position_behind(at):
		l.visible = false
		return
	var q := camera.unproject_position(at)
	l.position = (q - Vector2(l.size.x / 2, l.size.y)).round()
	var r := Rect2(l.position, l.size)
	for z in _zones:                                  # never on top of a readout or the window
		if z.intersects(r):
			l.visible = false
			return
	if sign_:
		for z in _taken:
			if z.intersects(r):
				l.visible = false
				return
		_taken.append(r)
	l.visible = true


func _process(_delta: float) -> void:   # (_delta is used: bubbles fade)
	if R == null or camera == null: return
	_zones = hud.zones() if hud else []
	_taken.clear()
	for i in PLACES.size():
		var p: Array = PLACES[i]
		var x: float = p[1] if not (p[1] is String) else 0.0
		var z: float = p[2]
		match p[1]:
			"quarry": x = R.QUARRY.x; z = R.QUARRY.z
			"mine": x = R.MINEC.x; z = R.MINEC.z
			"jetty": x = R.JETTY.x; z = R.JETTY.z + 2.6
			"cart":
				if R.merchant < 0 or R.phase != "day":
					_signs[i].visible = false
					continue
				x = 10.4; z = 23.0
				_signs[i].text = D.MERCHANTS[R.merchant].name.capitalize()
			"chest":
				if R.chest.is_empty() or R.chest.open or not R.chest.seen:
					_signs[i].visible = false
					continue
				x = R.chest.x; z = R.chest.z
			"letter":
				if not R.letter_new:
					_signs[i].visible = false
					continue
				x = -4.2; z = -19.4
			"ruin1", "ruin2":                          # the outer ruins: only once someone has found them today
				var k := 1 if p[1] == "ruin1" else 2
				var c: Dictionary = Map.ruin_layout(R.gseed, R.day).centres[k]
				x = c.x; z = c.z - 1.6
				if not R.ruins_seen[k]:
					_signs[i].visible = false
					continue
		var l := _signs[i]
		if D.d2(focus.x, focus.z, x, z) < 30 * 30 and R.live():
			_put(l, Vector3(x, p[3], z), true)
			# near a place you know where you are: its sign fades to half, so you can see what is under it
			var near := 1.0 - smoothstep(9.0, 15.0, sqrt(D.d2(me.x if me else focus.x, me.z if me else focus.z, x, z)))
			l.modulate.a = lerpf(l.modulate.a, lerpf(1.0, 0.45, near), minf(1.0, _delta * 6.0))
		else:
			l.visible = false
	for qid in _bubbles.keys():                       # what peasants are saying
		var b: Array = _bubbles[qid]
		b[1] -= _delta
		var q = null
		for o in R.peasants:
			if o.id == qid: q = o
		if b[1] <= 0 or q == null or q.state == "gone" or q.state == "inn":
			b[0].queue_free(); _bubbles.erase(qid)
			continue
		_put(b[0], Vector3(q.x, 2.6, q.z))
	if _bailiff == null:
		_bailiff = _label("", 13, Color("2f2318"), Color("fffaf0"))
		_bailiff.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_bailiff.custom_minimum_size.x = 260
	_bailiff.text = R.bail_line
	if R.bail_t > 0 and R.bail_line != "" and D.d2(focus.x, focus.z, -14.5, -9.3) < 30 * 30:   # Robert Bailiff, from his window
		_put(_bailiff, Vector3(-14.5, 5.6, -9.3))
	else:
		_bailiff.visible = false
	var shown := R.players.filter(func(p): return p != me and p.state != "hide" and p.state != "inn") if Settings.tags else []
	while _names.size() < shown.size(): _names.append(_label("", 13, Color("2f2318"), Color("f6ebc9")))
	for i in _names.size():
		var l := _names[i]
		if i >= shown.size():
			l.visible = false
			continue
		var p: E.Player = shown[i]
		l.text = p.dn + (" (coward)" if p.coward else "")
		(l.get_theme_stylebox("normal") as StyleBoxFlat).border_color = Color(D.PCOL[p.col % 8])
		_put(l, Vector3(p.x, 3.75 + maxf(0, p.bodies - 2) * 0.4, p.z))
