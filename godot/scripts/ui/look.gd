class_name Look
extends RefCounted
## How the menus and readouts look: parchment, ink, the scroll frame with its rolled ends and wax seals,
## the two typefaces, and small drawn pictures of things for the pack. One Theme for everything.

const INK := Color("2f2318")
const INK_SOFT := Color("5a4632")
const RUST := Color("7a4a22")
const PAPER := Color("edd69d")
const PAPER_LIGHT := Color("f6e8c0")
const PAPER_DARK := Color("d9b872")
const OUTLINE := Color("4a2a12")
const ROSE := Color("a8362c")
const GOLD := Color("b8862b")

const SCROLL_SCALE := 0.8          # the scroll frame, a little smaller than in the web version
const ScrollSvg := preload("res://scripts/ui/scroll_svg.gd")

# small pictures of things, the same as the web version's (24 by 24, drawn as ink lines)
const ICON := {
	"fork": "M12 22V8M7 3v5h10V3M12 3v5", "sword": "M12 2l2 3v10h-4V5zM8 15h8M12 15v6", "spear": "M12 22V7M12 1l3 6H9z",
	"mace": "M12 22V11M8 7a4 4 0 1 0 8 0a4 4 0 1 0-8 0M12 1v2M5 7h2M17 7h2", "bill": "M10 22V3M10 3c5 0 7 3 7 7c-2-2-4-3-7-3",
	"hammer": "M12 22V9M6 3h12v6H6z", "club": "M10 22l1-9c-2-4-1-10 2-10s4 6 2 10l-1 9z", "spade": "M12 2v12M9 2h6M7 14h10v3c0 3-3 5-5 5s-5-2-5-5z",
	"rake": "M12 22V6M5 6h14M5 6v4M8.5 6v4M12 6v4M15.5 6v4M19 6v4", "scythe": "M8 22V3M8 4c6-2 11 0 13 5c-4-3-8-3-13-2",
	"dagger": "M12 3l2.5 9h-5zM8 13h8M12 13v7", "pan": "M3 9a6 6 0 1 0 12 0a6 6 0 1 0-12 0M13.5 13.5L21 21",
	"sling": "M5 4c3 8 3 8 7 12M19 4c-3 8-3 8-7 12M9.5 18.5a2.5 2.5 0 1 0 5 0a2.5 2.5 0 1 0-5 0",
	"bow": "M7 2c10 4 10 16 0 20M7 2v20M7 12h13M17 9l3 3-3 3", "xbow": "M3 8c5-5 13-5 18 0M12 5v16M3 8l9 5l9-5",
	"helm": "M4 16v-3a8 8 0 0 1 16 0v3zM12 9v7", "mail": "M7 3L2 7l3 4l2-1v11h10V10l2 1l3-4l-5-4c-1 2-9 2-10 0z",
	"shield": "M12 2l8 3v6c0 6-4 9-8 11c-4-2-8-5-8-11V5z", "bucket": "M5 8h14l-2 13H7zM5 8c2-7 12-7 14 0",
	"bell": "M12 2v3M6 17c0-9 2-12 6-12s6 3 6 12zM4 17h16M12 17v3", "censer": "M12 2v6M7 12a5 5 0 0 0 10 0zM7 12h10M10 20h4M12 17v3M9 6c-2-1 0-3-2-4M15 6c2-1 0-3 2-4",
	# for the readouts
	"wood": "M4 18l14-12M7 21l14-12M4 18l3 3M18 6l3 3", "stone": "M3 18l4-8l5-3l6 2l3 9z", "iron": "M4 15l4-6h8l4 6zM4 15h16v3H4z",
	"food": "M12 21c-5 0-8-4-8-8c0-3 2-5 5-5c1 0 2 1 3 1s2-1 3-1c3 0 5 2 5 5c0 4-3 8-8 8zM12 8c0-3 1-5 3-6",
	"coin": "M12 3a9 9 0 1 0 0.01 0zM12 7v10M9 9.5c0-1.5 1.3-2.5 3-2.5s3 1 3 2.2c0 3-6 1.6-6 4.6c0 1.3 1.3 2.2 3 2.2s3-1 3-2.5",
	"posse": "M8 11a3 3 0 1 0 0.01 0zM16 11a3 3 0 1 0 0.01 0zM3 21c0-3 2-5 5-5s5 2 5 5M11 21c0-3 2-5 5-5s5 2 5 5",
	"body": "M3 16h18M5 16c0-3 3-5 7-5s7 2 7 5M8 11a2 2 0 1 0 0.01 0z", "book": "M4 4h7c1 0 1 1 1 2v14c0-1-1-2-2-2H4zM20 4h-7c-1 0-1 1-1 2v14c0-1 1-2 2-2h6z",
	"ale": "M6 7h10v13H6zM16 10h3v6h-3M6 7c0-2 2-3 4-2c1-2 4-2 5 0c2 0 2 2 1 2", "pack": "M6 8h12l1 13H5zM9 8V6a3 3 0 0 1 6 0v2",
	"trick": "M12 2l2.5 6.5L21 9l-5 4.5l1.5 7L12 17l-5.5 3.5l1.5-7L3 9l6.5-.5z", "toilet": "M7 3h10v6H7zM5 9h14c0 5-3 8-7 8s-7-3-7-8zM9 17l-1 4h8l-1-4",
	"keep": "M5 21V8h3V5h3v3h2V5h3v3h3v13zM10 21v-5h4v5", "barricade": "M3 10l18 6M3 16l18-6M6 7v13M18 7v13",
	"spikes": "M3 20l3-10l3 10l3-10l3 10l3-10l3 10", "bodywall": "M3 18h18M4 18c0-2 2-4 4-4s4 2 4 4M12 18c0-2 2-4 4-4s4 2 4 4M8 10a2 2 0 1 0 0.01 0zM16 10a2 2 0 1 0 0.01 0z",
	"decoy": "M12 3v18M7 8h10M12 6a2 2 0 1 0 0.01 0zM9 12h6v5H9z",
}

static var _theme: Theme
static var _icons := {}
static var _scroll: StyleBoxTexture
static var _display: Font
static var _body: Font


## The display face (for titles) and the body face. The web version's Pirata One and Alegreya are not
## bundled; these ask Windows for the nearest it has (Palatino, Book Antiqua, Georgia), which read well.
static func display_font() -> Font:
	if _display == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Old English Text MT", "Blackadder ITC", "Palatino Linotype", "Book Antiqua", "Georgia", "serif"])
		f.font_weight = 600
		_display = f
	return _display


static func body_font() -> Font:
	if _body == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Palatino Linotype", "Book Antiqua", "Georgia", "Cambria", "serif"])
		_body = f
	return _body


## The scroll frame: rolled ends top and bottom, wax seals, knots in the corners, a torn edge.
static func scroll() -> StyleBoxTexture:
	if _scroll == null:
		var img := Image.new()
		img.load_svg_from_string(ScrollSvg.SVG, SCROLL_SCALE)
		# the middle of the picture is left open (in the web version the page shows through); fill it with paper here
		var s := SCROLL_SCALE
		for y in range(int(40 * s), int(300 * s)):
			for x in range(int(22 * s), int(318 * s)):
				if img.get_pixel(x, y).a < 0.99:
					var c := img.get_pixel(x, y)
					img.set_pixel(x, y, PAPER.lerp(c, c.a) if c.a > 0 else PAPER)
		var t := ImageTexture.create_from_image(img)
		var sb := StyleBoxTexture.new()
		sb.texture = t
		sb.texture_margin_left = 100 * s; sb.texture_margin_right = 100 * s
		sb.texture_margin_top = 110 * s; sb.texture_margin_bottom = 110 * s
		sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
		sb.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
		sb.content_margin_left = 62 * s; sb.content_margin_right = 62 * s
		sb.content_margin_top = 72 * s; sb.content_margin_bottom = 74 * s
		_scroll = sb
	return _scroll


## A small parchment card, for the readouts round the edge of the screen.
static func card(bg: Color = PAPER_LIGHT, border: Color = OUTLINE, pad: float = 8) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(bg, 0.94)
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(pad)
	sb.shadow_color = Color(0, 0, 0, 0.3)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(0, 2)
	return sb


static func _button(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(5)
	sb.content_margin_left = 12; sb.content_margin_right = 12; sb.content_margin_top = 6; sb.content_margin_bottom = 6
	return sb


static func theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font = body_font()
	t.default_font_size = 17
	t.set_color("font_color", "Label", INK)
	t.set_color("font_color", "Button", INK)
	t.set_color("font_hover_color", "Button", INK)
	t.set_color("font_pressed_color", "Button", INK)
	t.set_color("font_focus_color", "Button", INK)
	t.set_color("font_disabled_color", "Button", Color(INK, 0.4))
	t.set_stylebox("normal", "Button", _button(PAPER_LIGHT, Color(OUTLINE, 0.7)))
	t.set_stylebox("hover", "Button", _button(Color("fff3cf"), OUTLINE))
	t.set_stylebox("pressed", "Button", _button(PAPER_DARK, OUTLINE))
	t.set_stylebox("focus", "Button", _button(Color("fff3cf"), ROSE))
	t.set_stylebox("disabled", "Button", _button(Color(PAPER, 0.5), Color(OUTLINE, 0.25)))
	t.set_stylebox("normal", "LineEdit", _button(Color("fffaf0"), Color(OUTLINE, 0.7)))
	t.set_stylebox("focus", "LineEdit", _button(Color("fffaf0"), ROSE))
	t.set_color("font_color", "LineEdit", INK)
	t.set_color("caret_color", "LineEdit", INK)
	t.set_color("font_color", "CheckBox", INK)
	t.set_color("font_hover_color", "CheckBox", INK)
	t.set_color("font_pressed_color", "CheckBox", INK)
	t.set_stylebox("normal", "CheckBox", StyleBoxEmpty.new())
	t.set_stylebox("hover", "CheckBox", StyleBoxEmpty.new())
	t.set_stylebox("pressed", "CheckBox", StyleBoxEmpty.new())
	t.set_stylebox("focus", "CheckBox", StyleBoxEmpty.new())
	t.set_stylebox("panel", "PanelContainer", card())
	t.set_stylebox("panel", "TooltipPanel", card(PAPER_LIGHT, OUTLINE, 8))
	t.set_color("font_color", "TooltipLabel", INK)
	var grab := StyleBoxFlat.new(); grab.bg_color = Color(OUTLINE, 0.5); grab.set_corner_radius_all(4)
	t.set_stylebox("grabber", "VScrollBar", grab)
	t.set_stylebox("grabber_highlight", "VScrollBar", grab)
	t.set_stylebox("grabber_pressed", "VScrollBar", grab)
	var track := StyleBoxFlat.new(); track.bg_color = Color(OUTLINE, 0.12); track.set_corner_radius_all(4); track.content_margin_left = 5; track.content_margin_right = 5
	t.set_stylebox("scroll", "VScrollBar", track)
	_theme = t
	return t


## A small picture of a thing (an item number) or of a readout (a name from ICON), in ink, or gold for a relic.
static func icon(key, px: int = 40) -> Texture2D:
	var name := ""
	var gold := false
	if key is int:
		name = "bell" if key == 26 else "censer" if key == 27 else D.IT[key].pool
		gold = D.IT[key].tier == "relic"
	else:
		name = key
	var k := "%s|%d|%s" % [name, px, gold]
	if _icons.has(k):
		return _icons[k]
	var col := "#a8761c" if gold else "#3a2614"
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24"><path d="%s" fill="none" stroke="%s" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>' % [ICON.get(name, ""), col]
	var img := Image.new()
	img.load_svg_from_string(svg, px / 24.0)
	var tex := ImageTexture.create_from_image(img)
	_icons[k] = tex
	return tex


## A label in the theme, quickly.
static func label(parent: Node, text: String, size: int = 17, color: Color = INK, display: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if display: l.add_theme_font_override("font", display_font())
	parent.add_child(l)
	return l


## Words to read: wrapped to the width they are given.
static func para(parent: Node, text: String, size: int = 16, color: Color = INK) -> Label:
	var l := label(parent, text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 160            # wrapped words need a width to wrap to, or they stand one to a line
	return l
