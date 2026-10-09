extends Control
## The gambler's three cups. He shows you the pea, shuffles, and you pick. The rules decided the swaps; this only shows them,
## at the pace the rules set, so that anybody who watches closely enough can follow the pea.

signal picked(i: int)

var ball := 0                       # the place (0 left, 1 middle, 2 right) the pea starts in
var swaps: Array = []               # pairs of places, swapped in turn
var sp := 0.5                       # seconds a swap
var can_pick := false               # the rules say the shuffling is over
var shown := -1                     # once it is settled: where the pea was
var chosen := -1                    # and which cup was lifted

var _t := 0.0
var _cups: Array = []               # the cup in each place now


## One wooden cup, upside down: narrower at the top, with a turned rim. It can be clicked.
class Cup extends Control:
	signal clicked
	var hot := false

	func _ready() -> void:
		mouse_entered.connect(func(): hot = true; queue_redraw())
		mouse_exited.connect(func(): hot = false; queue_redraw())

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT: clicked.emit()

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var body := PackedVector2Array([Vector2(w * 0.24, 4), Vector2(w * 0.76, 4), Vector2(w * 0.98, h - 8), Vector2(w * 0.02, h - 8)])
		draw_colored_polygon(body, Color("a8703f") if hot else Color("8a5a34"))
		draw_colored_polygon(PackedVector2Array([Vector2(w * 0.24, 4), Vector2(w * 0.42, 4), Vector2(w * 0.3, h - 8), Vector2(w * 0.02, h - 8)]), Color(1, 1, 1, 0.1))
		draw_rect(Rect2(w * 0.2, 0, w * 0.6, 8), Color("6b4326"))
		draw_rect(Rect2(0, h - 10, w, 10), Color("6b4326"))
		draw_line(Vector2(w * 0.12, h * 0.55), Vector2(w * 0.88, h * 0.55), Color(0.2, 0.12, 0.06, 0.5), 2.0)
		draw_polyline(PackedVector2Array([body[0], body[1], body[2], body[3], body[0]]), Color("3a2614"), 2.0)
var _pea: ColorRect
var _pea_cup: Control
var _next := 0
const SHOW := 1.2
const W := 104.0
const CUP := Vector2(78, 84)


func _ready() -> void:
	custom_minimum_size = Vector2(W * 3 + 40, 150)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_pea = ColorRect.new()
	_pea.color = Color("6b8f3a")
	_pea.size = Vector2(16, 14)
	add_child(_pea)
	for i in 3:
		var b := Cup.new()
		b.size = CUP
		b.position = _home(i)
		var me := b
		b.clicked.connect(func(): if can_pick and _t >= _total() and shown < 0: picked.emit(_cups.find(me)))
		add_child(b)
		_cups.append(b)
	_pea_cup = _cups[ball]
	if can_pick and shown < 0:                        # he has stopped already (the table was redrawn): the cups as they ended
		_t = _total() + 1.0
		_next = swaps.size()
		for s in swaps:
			var c0 = _cups[int(s[0])]; _cups[int(s[0])] = _cups[int(s[1])]; _cups[int(s[1])] = c0
		for i in 3: _cups[i].position = _home(i)
	if shown >= 0:                                    # it is over: the cups where they ended, the right one lifted (and yours)
		_t = _total() + 1.0
		for s in swaps:
			var c = _cups[int(s[0])]; _cups[int(s[0])] = _cups[int(s[1])]; _cups[int(s[1])] = c
		for i in 3: _cups[i].position = _home(i)
		_cups[shown].position.y -= 34
		if chosen >= 0 and chosen != shown: _cups[chosen].position.y -= 18
		_pea_cup = _cups[shown]
	_place_pea()


func _total() -> float:
	return SHOW + swaps.size() * sp


func _home(i: int) -> Vector2:
	return Vector2(20 + i * W + (W - CUP.x) / 2, 54)


func _place_pea() -> void:
	_pea.position = Vector2(_pea_cup.position.x + CUP.x / 2 - 8, 54 + CUP.y - 14)
	_pea.visible = shown >= 0 or _t < SHOW
	move_child(_pea, 0)


func _process(delta: float) -> void:
	if shown >= 0: return
	_t += delta
	if _t < SHOW:                                     # he lifts the cup: there it is
		var k := sin(clampf(_t / SHOW, 0, 1) * PI)
		_pea_cup.position.y = 54 - 34 * k
		_place_pea()
		return
	_pea.visible = false
	var done := mini(swaps.size(), floori((_t - SHOW) / sp))
	while _next < done:                               # swaps already finished: settle them
		var s: Array = swaps[_next]
		var c = _cups[int(s[0])]; _cups[int(s[0])] = _cups[int(s[1])]; _cups[int(s[1])] = c
		_next += 1
	for i in 3: _cups[i].position = _home(i)
	if done < swaps.size():                           # the one in hand: the two cups cross, one behind the other
		var s2: Array = swaps[done]
		var f := ((_t - SHOW) - done * sp) / sp
		var e := f * f * (3 - 2 * f)
		var a: Control = _cups[int(s2[0])]
		var b: Control = _cups[int(s2[1])]
		var pa := _home(int(s2[0]))
		var pb := _home(int(s2[1]))
		a.position = pa.lerp(pb, e) + Vector2(0, -22 * sin(e * PI))
		b.position = pb.lerp(pa, e) + Vector2(0, 22 * sin(e * PI))
