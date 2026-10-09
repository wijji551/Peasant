extends Control
## The one window: a scroll in the middle of the screen, used for every notice (a place, your pack, the dawn,
## the handbook, the home screen, the end of the week). Only one is ever open, so nothing overlaps; the rest
## of the screen dims a little behind it. Esc or the cross closes it (when it may be closed).

signal closed(what: String)

var kind := ""                      # what is open: "", "home", "notice", "pack", "dawn", "menu", "end"
var closable := true
var _frame: PanelContainer
var _title: Label
var _close: Button
var _top: HBoxContainer
var _tabs: HBoxContainer
var _intro: Label
var _scroll: ScrollContainer
var body: VBoxContainer
var _foot: HBoxContainer
var _hint: Label
var _dim: ColorRect


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = Look.theme()
	_dim = ColorRect.new()
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.color = Color(0.08, 0.05, 0.02, 0.35)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dim)
	_frame = PanelContainer.new()
	_frame.add_theme_stylebox_override("panel", Look.scroll())
	add_child(_frame)
	_frame.resized.connect(_place)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	_frame.add_child(v)
	var top := HBoxContainer.new()
	v.add_child(top)
	_top = top
	_title = Look.label(top, "", 34, Look.INK, true)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_close = Button.new()
	_close.text = "✕"
	_close.tooltip_text = "Close (Esc)"
	_close.focus_mode = Control.FOCUS_NONE
	_close.pressed.connect(func(): close())
	top.add_child(_close)
	_tabs = HBoxContainer.new()
	_tabs.add_theme_constant_override("separation", 6)
	v.add_child(_tabs)
	_intro = Look.para(v, "", 16, Look.INK_SOFT)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(_scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 6)
	_scroll.add_child(body)
	_foot = HBoxContainer.new()
	_foot.add_theme_constant_override("separation", 10)
	v.add_child(_foot)
	_hint = Look.para(_foot, "", 14, Look.INK_SOFT)
	_hint.custom_minimum_size.x = 280
	_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	visible = false
	get_viewport().size_changed.connect(_fit)


## Open (or refill) the window. w and h are its size at most, in screen pixels at 1280 by 720.
func open(k: String, title: String, intro: String = "", w: float = 640, h: float = 560, can_close: bool = true, dim: bool = true) -> VBoxContainer:
	var same := kind == k and visible
	kind = k
	closable = can_close
	_close.visible = can_close
	_dim.visible = dim
	_title.text = title
	_top.visible = title != "" or can_close
	pin = Vector2(-1, -1)
	_intro.text = Keys.fill(intro)
	_intro.visible = intro != ""
	for c in _tabs.get_children():          # out at once: left waiting to be freed, they would widen the window
		_tabs.remove_child(c)
		c.queue_free()
	_tabs.visible = false
	for c in body.get_children():
		body.remove_child(c)
		c.queue_free()
	for c in _foot.get_children():
		if c != _hint:
			_foot.remove_child(c)
			c.queue_free()
	_hint.text = ""
	_foot.visible = false                   # until something is put in it
	_want = Vector2(w, h)
	visible = true
	_fit()
	_fit.call_deferred()                    # and again once what goes in it has been put in and laid out
	if not same:
		_scroll.scroll_vertical = 0
		Sound.play("page", 0.8)
	return body


var _want := Vector2(640, 560)
var pin := Vector2(-1, -1)          # not in the middle: its top left corner, as a share of the screen (the title screen sits under the title)


func _process(_delta: float) -> void:   # what was asked for, or what the contents need if that is more: never wider
	if not visible: return
	var vs := get_viewport_rect().size
	var top := 40.0 if _dim.visible else 62.0
	var bottom := 40.0 if _dim.visible else 78.0
	var want := Vector2(minf(_want.x, vs.x - 40), minf(_want.y, vs.y - top - bottom))
	var m := _frame.get_combined_minimum_size()
	var t := Vector2(maxf(want.x, m.x), maxf(want.y, m.y))
	if absf(_frame.size.x - t.x) > 1 or absf(_frame.size.y - t.y) > 1:
		_frame.size = t
		_place()


func covers() -> bool:   # does it take the whole screen (rather than sit between the readouts)?
	return _dim.visible


func _fit() -> void:   # centred, and never bigger than the screen; a notice keeps between the top readouts and the bar at the bottom
	var vs := get_viewport_rect().size
	var top := 40.0 if _dim.visible else 62.0
	var bottom := 40.0 if _dim.visible else 78.0
	var w := minf(_want.x, vs.x - 40)
	var h := minf(_want.y, vs.y - top - bottom)
	# the smallest size first, or the frame keeps the last window's size and sits off to the right and down
	_frame.custom_minimum_size = Vector2(w, h)
	_frame.reset_size()                     # down to the smallest it can be, then up to what was asked
	_frame.size = Vector2(w, h)
	_place()


func _place() -> void:   # centre what the frame actually came to (its contents can make it bigger than asked)
	var vs := get_viewport_rect().size
	var top := 40.0 if _dim.visible else 62.0
	var bottom := 40.0 if _dim.visible else 78.0
	var fs := _frame.size
	if pin.x >= 0:
		_frame.position = Vector2(round(clampf(vs.x * pin.x, 8, vs.x - fs.x - 8)), round(clampf(vs.y * pin.y, 8, maxf(8, vs.y - fs.y - 8))))
		return
	_frame.position = Vector2(round((vs.x - fs.x) / 2), round(maxf(top, top + (vs.y - top - bottom - fs.y) / 2)))


func close() -> void:
	if not visible: return
	visible = false
	var k := kind
	kind = ""
	closed.emit(k)


func is_open(k: String = "") -> bool:
	return visible and (k == "" or kind == k)


func tabs(list: Array, current: String, cb: Callable) -> void:   # list of [id, label]
	_tabs.visible = true
	for t in list:
		var b := Button.new()
		b.text = t[1]
		b.toggle_mode = true
		b.button_pressed = t[0] == current
		b.focus_mode = Control.FOCUS_NONE
		var id: String = t[0]
		b.pressed.connect(func(): cb.call(id))
		_tabs.add_child(b)


func hint(text: String) -> void:
	_foot.visible = true
	_hint.text = Keys.fill(text)


func foot_button(text: String, cb: Callable, primary: bool = false) -> Button:
	_foot.visible = true
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	if primary:
		b.add_theme_stylebox_override("normal", _primary())
		b.add_theme_stylebox_override("hover", Look.primary_hover())
		b.add_theme_stylebox_override("pressed", Look.primary_hover())
		b.add_theme_color_override("font_color", Color("fbeec2"))
		b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.pressed.connect(cb)
	_foot.add_child(b)
	return b


static func _primary() -> StyleBox:
	return Look.primary()


# --- things to put in the body
func head(text: String) -> Label:
	var l := Look.label(body, text.to_upper(), 13, Look.RUST)
	l.add_theme_constant_override("line_spacing", 0)
	return l


func para(text: String, font_size: int = 16, color: Color = Look.INK) -> Label:
	return Look.para(body, Keys.fill(text), font_size, color)


## A numbered choice: the number to press, what it does in bold, and a line about it underneath.
func option(n: int, label: String, sub: String, ok: bool, cb: Callable) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.disabled = not ok
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size.y = 34
	b.pressed.connect(cb)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 8; row.offset_right = -8
	row.add_theme_constant_override("separation", 10)
	b.add_child(row)
	var key := Look.label(row, str(n % 10) if n > 0 and n <= 10 else "·", 15, Look.ROSE if ok else Color(Look.INK, 0.35))
	key.custom_minimum_size.x = 16
	key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	key.size_flags_vertical = Control.SIZE_FILL
	var lab := Look.label(row, label, 17, Look.INK if ok else Color(Look.INK, 0.45))
	lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lab.size_flags_vertical = Control.SIZE_FILL
	lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lab.clip_text = true
	lab.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	body.add_child(b)
	if sub != "":
		var s := Look.para(body, Keys.fill(sub), 14, Look.INK_SOFT if ok else Color(Look.INK_SOFT, 0.6))
		s.add_theme_constant_override("line_spacing", -2)
		var m := MarginContainer.new()
		m.add_theme_constant_override("margin_left", 34)
		m.add_theme_constant_override("margin_bottom", 4)
		body.remove_child(s)
		m.add_child(s)
		body.add_child(m)
	return b


func _unhandled_input(e: InputEvent) -> void:
	if visible and e is InputEventMouseButton:
		get_viewport().set_input_as_handled()
