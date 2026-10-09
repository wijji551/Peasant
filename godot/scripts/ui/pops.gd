extends Control
## Numbers that jump off the dead when they are hit, so a blow can be seen to have landed and how hard.
## Big and gold for a telling blow, small and grey for one that barely scratched, and so on. Drawn over the
## world, under the readouts.

const MAX := 56
const INKY := Color(0.1, 0.07, 0.05, 0.9)

var camera: Camera3D
var _live := []            # [label, where in the world, age, life, sideways drift]
var _spare: Array[Label] = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## A word or a number at a place in the world, rising and fading.
func pop(at: Vector3, text: String, col: Color, size: int, life: float = 0.8) -> void:
	var l: Label
	if not _spare.is_empty():
		l = _spare.pop_back()
	elif _live.size() < MAX:
		l = Label.new()
		l.add_theme_font_override("font", Look.display_font())
		l.add_theme_color_override("font_outline_color", INKY)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(l)
	else:                                              # all in use: take the oldest
		var old: Array = _live.pop_front()
		l = old[0]
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_constant_override("outline_size", 4 if size < 20 else 5)
	l.add_theme_color_override("font_color", col)
	l.size = l.get_minimum_size()
	l.pivot_offset = l.size / 2
	l.visible = false
	_live.append([l, at + Vector3(randf_range(-0.45, 0.45), randf_range(-0.25, 0.25), randf_range(-0.2, 0.2)), 0.0, life, randf_range(-0.7, 0.7)])


func _process(delta: float) -> void:
	if camera == null: return
	var i := _live.size() - 1
	while i >= 0:
		var a: Array = _live[i]
		a[2] += delta
		var l: Label = a[0]
		var k: float = a[2] / a[3]
		if k >= 1.0:
			l.visible = false
			_spare.append(l)
			_live.remove_at(i)
			i -= 1
			continue
		var up := 1.9 * (1.0 - (1.0 - k) * (1.0 - k))             # quick at first, then hanging
		var w: Vector3 = a[1] + Vector3(a[4] * k, up, 0)
		if camera.is_position_behind(w):
			l.visible = false
		else:
			l.position = (camera.unproject_position(w) - l.size / 2).round()
			var s := 1.0 + 0.7 * maxf(0.0, 1.0 - k * 7.0)         # a pop as it appears
			l.scale = Vector2(s, s)
			l.modulate.a = clampf((1.0 - k) * 3.0, 0.0, 1.0)
			l.visible = true
		i -= 1
