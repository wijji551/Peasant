extends CanvasLayer
## The readouts: the day, the keep, your health, what you carry, what holding E would do, the notices,
## the dawn notice, and a big line of text when something happens.
## (Plain parchment for now; the scroll look from the web version comes with the menus stage.)

signal option(i: int)            # a numbered option in the open notice was clicked
signal dawn_closed

const INK := Color("2f2318")
const PARCH := Color("ecdcae")
const OUTLINE := Color("4a2a12")

var _phase: Label
var _timer: Label
var _keep_bar: ProgressBar
var _keep_num: Label
var _hp_bar: ProgressBar
var _banner: Label
var _banner_sub: Label
var _banner_t := 0.0
var _res: Label
var _chips: Label
var _prompt: Label
var _prompt_bar: ProgressBar
var _hint: Label
var _feed: VBoxContainer
var _notice: PanelContainer
var _n_title: Label
var _n_intro: Label
var _n_opts: VBoxContainer
var _n_hint: Label
var _n_sig := ""
var _dawn: PanelContainer
var _dawn_text: Label
var _dawn_title: Label


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var tl := _chip(root)
	_pin(tl, Control.PRESET_TOP_LEFT, 14, 12, 14, 12)
	var v := VBoxContainer.new()
	tl.add_child(v)
	_phase = _label(v, "Day 1", 34)
	_timer = _label(v, "", 16)

	var tm := _chip(root)
	_pin(tm, Control.PRESET_CENTER_TOP, -170, 12, 170, 12)
	var kv := VBoxContainer.new()
	tm.add_child(kv)
	var row := HBoxContainer.new()
	kv.add_child(row)
	var kl := _label(row, "THE KEEP", 13)
	kl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_keep_num = _label(row, "", 13)
	_keep_bar = _bar(kv, Color("b3aa98"))

	var bl := _chip(root)
	_pin(bl, Control.PRESET_BOTTOM_LEFT, 14, -52, 314, -52)
	bl.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var hv := VBoxContainer.new()
	bl.add_child(hv)
	_label(hv, "YOUR HEALTH", 13)
	_hp_bar = _bar(hv, Color("a8362c"))

	var top_right := _chip(root)
	_pin(top_right, Control.PRESET_TOP_RIGHT, -330, 12, -14, 12)
	top_right.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	var rv := VBoxContainer.new()
	top_right.add_child(rv)
	_res = _label(rv, "", 15)
	_chips = _label(rv, "", 13)
	_chips.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_chips.custom_minimum_size = Vector2(300, 0)

	_feed = VBoxContainer.new()
	root.add_child(_feed)
	_pin(_feed, Control.PRESET_BOTTOM_LEFT, 16, -130, 600, -130)
	_feed.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_feed.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var pv := VBoxContainer.new()
	root.add_child(pv)
	_pin(pv, Control.PRESET_CENTER_BOTTOM, -330, -60, 330, -60)
	pv.grow_vertical = Control.GROW_DIRECTION_BEGIN
	pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt = _shout(pv, 20)
	_prompt_bar = _bar(pv, Color("e0b44a"))
	_prompt_bar.custom_minimum_size = Vector2(0, 8)

	_notice = PanelContainer.new()
	_notice.add_theme_stylebox_override("panel", _parch_box())
	root.add_child(_notice)
	_pin(_notice, Control.PRESET_RIGHT_WIDE, -470, 90, -16, -90)
	_notice.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	var nv := VBoxContainer.new()
	_notice.add_child(nv)
	_n_title = _label(nv, "", 26)
	_n_intro = _label(nv, "", 14)
	_n_intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	nv.add_child(sc)
	_n_opts = VBoxContainer.new()
	_n_opts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(_n_opts)
	_n_hint = _label(nv, "", 12)
	_notice.visible = false

	_dawn = PanelContainer.new()
	_dawn.add_theme_stylebox_override("panel", _parch_box())
	root.add_child(_dawn)
	_pin(_dawn, Control.PRESET_CENTER, -330, -110, 330, 110)
	_dawn.grow_vertical = Control.GROW_DIRECTION_BOTH
	var dv := VBoxContainer.new()
	_dawn.add_child(dv)
	_dawn_title = _label(dv, "", 30)
	_dawn_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dawn_text = _label(dv, "", 16)
	_dawn_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dawn_text.custom_minimum_size = Vector2(600, 0)
	var ok := Button.new()
	ok.text = "To work (Esc)"
	ok.pressed.connect(func(): _dawn.visible = false; dawn_closed.emit())
	dv.add_child(ok)
	_dawn.visible = false

	var hint := Label.new()
	_hint = hint
	root.add_child(hint)
	hint.text = ""
	_pin(hint, Control.PRESET_CENTER_BOTTOM, -520, -16, 520, -16)
	hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color("f6ebc9"))
	hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	hint.add_theme_constant_override("outline_size", 6)

	var bv := VBoxContainer.new()
	root.add_child(bv)
	_pin(bv, Control.PRESET_CENTER_TOP, -560, 130, 560, 130)
	bv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner = _shout(bv, 76)
	_banner_sub = _shout(bv, 22)
	_banner.modulate.a = 0.0
	_banner_sub.modulate.a = 0.0


## Fix a control to an edge of the screen: the preset says which, the numbers are how far from it.
func _pin(c: Control, preset: Control.LayoutPreset, left: float, top: float, right: float, bottom: float) -> void:
	c.set_anchors_preset(preset)
	c.offset_left = left
	c.offset_top = top
	c.offset_right = right
	c.offset_bottom = bottom


func _parch_box() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = PARCH
	sb.border_color = OUTLINE
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(16)
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 8
	return sb


func _chip(parent: Control) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = PARCH
	sb.border_color = OUTLINE
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(5)
	sb.set_content_margin_all(9)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 5
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(p)
	return p


func _label(parent: Control, text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", INK)
	parent.add_child(l)
	return l


func _shout(parent: Control, size: int) -> Label:
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color("f8eed3"))
	l.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.02, 0.85))
	l.add_theme_constant_override("outline_size", 10)
	parent.add_child(l)
	return l


func _bar(parent: Control, fill: Color) -> ProgressBar:
	var b := ProgressBar.new()
	b.custom_minimum_size = Vector2(0, 14)
	b.show_percentage = false
	b.max_value = 1.0
	b.value = 1.0
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("3a2d22")
	bg.set_corner_radius_all(2)
	var fg := StyleBoxFlat.new()
	fg.bg_color = fill
	fg.set_corner_radius_all(2)
	b.add_theme_stylebox_override("background", bg)
	b.add_theme_stylebox_override("fill", fg)
	parent.add_child(b)
	return b


func banner(title: String, sub: String = "", seconds: float = 3.2) -> void:
	_banner.text = title
	_banner_sub.text = sub
	_banner_t = seconds


func show_state(phase_text: String, timer_text: String, keep: float, keep_max: float, hp: float, hp_max: float) -> void:
	_phase.text = phase_text
	_timer.text = timer_text
	_keep_bar.value = keep / keep_max
	_keep_num.text = "%d / %d" % [maxi(0, roundi(keep)), roundi(keep_max)]
	_hp_bar.value = hp / hp_max


func show_res(text: String, chips: String) -> void:
	if _res.text != text: _res.text = text
	if _chips.text != chips: _chips.text = chips


func show_hint(text: String) -> void:
	if _hint.text != text: _hint.text = text


## What holding E would do here; prog is how far through it you are (0 to 1); ok false greys it out.
func show_prompt(text: String, prog: float, ok: bool) -> void:
	_prompt.text = text
	_prompt.modulate = Color(1, 1, 1, 1) if ok else Color(1, 0.75, 0.7, 0.9)
	_prompt_bar.visible = prog > 0.0
	_prompt_bar.value = prog


func feed(msg: String) -> void:   # a line of news, which fades after a while
	var l := _shout(_feed, 16)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.text = msg
	l.set_meta("t", 9.0)
	while _feed.get_child_count() > 6:
		var c := _feed.get_child(0)
		_feed.remove_child(c)
		c.queue_free()


## A notice from a place, or none. d is from Notices.data().
func show_notice(d: Dictionary, hint: String) -> void:
	if d.is_empty():
		_notice.visible = false
		_n_sig = ""
		return
	var sig := str(d) + hint
	_notice.visible = true
	if sig == _n_sig:
		return
	_n_sig = sig
	_n_title.text = d.title
	_n_intro.text = Keys.fill(d.intro)
	for c in _n_opts.get_children():
		_n_opts.remove_child(c)
		c.queue_free()
	var n := 0
	for o in d.o:
		if o.has("head"):
			var h := _label(_n_opts, o.head.to_upper(), 13)
			h.add_theme_color_override("font_color", Color("7a4a22"))
			continue
		n += 1
		var b := Button.new()
		b.text = "%s  %s" % [str(n % 10) if n <= 10 else "·", o.label]
		b.tooltip_text = Keys.fill(o.get("sub", ""))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.disabled = not o.ok
		var i := n - 1
		b.pressed.connect(func(): option.emit(i))
		_n_opts.add_child(b)
		if o.get("sub", "") != "":
			var s := _label(_n_opts, Keys.fill(o.sub), 12)
			s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			s.add_theme_color_override("font_color", Color("5a4632"))
	_n_hint.text = hint


func notice_open() -> bool:
	return _notice.visible


func show_dawn(title: String, lines: Array) -> void:
	_dawn_title.text = title
	_dawn_text.text = "\n\n".join(lines)
	_dawn.visible = true


func dawn_open() -> bool:
	return _dawn.visible


func close_dawn() -> void:
	_dawn.visible = false


func _process(delta: float) -> void:
	for l in _feed.get_children():
		var t: float = l.get_meta("t") - delta
		l.set_meta("t", t)
		l.modulate.a = clampf(t, 0, 1)
		if t <= 0:
			_feed.remove_child(l)
			l.queue_free()
	_banner_t -= delta
	var a := clampf(_banner_t / 0.6, 0.0, 1.0)
	_banner.modulate.a = a
	_banner_sub.modulate.a = a
