extends CanvasLayer
## The readouts: the day, the keep, your health, and a big line of text when something happens.

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

	var hint := Label.new()
	root.add_child(hint)
	hint.text = "W A S D to move   ·   Space or click to attack   ·   R when you are ready for the night   ·   Esc to stop"
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


func _process(delta: float) -> void:
	_banner_t -= delta
	var a := clampf(_banner_t / 0.6, 0.0, 1.0)
	_banner.modulate.a = a
	_banner_sub.modulate.a = a
