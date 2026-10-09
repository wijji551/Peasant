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
	"smite": "M13 2L6 13h5l-2 9l9-12h-5l3-8z", "pray": "M12 4v17M7 9h10M5 3c4 2 10 2 14 0",
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
	"contr": "M12 8a4 4 0 1 0 .01 0zM12 2v3M12 19v3M2 12h3M19 12h3M5 5l2 2M17 17l2 2M5 19l2-2M17 7l2-2",
}

# the readouts' pictures in colour, so each looks like what it is (24 by 24)
const ICON_COL := {
	# two logs, cut ends showing their rings
	"wood": '<g stroke="#3a2614" stroke-width="1.1" stroke-linejoin="round"><rect x="2.5" y="12.5" width="15" height="7" rx="3.5" fill="#8a5a2b"/><path d="M5 14.5h8M6 17.5h9" stroke="#5e3b1a" fill="none"/><ellipse cx="17.5" cy="16" rx="3.4" ry="3.5" fill="#e6be82"/><ellipse cx="17.5" cy="16" rx="1.6" ry="1.7" fill="none" stroke="#a8743a"/><rect x="5.5" y="5" width="14" height="7" rx="3.5" fill="#9a6532"/><path d="M8 7h7M8.5 10h8" stroke="#5e3b1a" fill="none"/><ellipse cx="19.5" cy="8.5" rx="3.2" ry="3.5" fill="#efc98d"/><ellipse cx="19.5" cy="8.5" rx="1.5" ry="1.7" fill="none" stroke="#a8743a"/></g>',
	# a heap of grey stones
	"stone": '<g stroke="#2e2a26" stroke-width="1.1" stroke-linejoin="round"><path d="M2 20l2-6l5-2l4 3l1 5z" fill="#8d877d"/><path d="M11 20l1-6l4-4l5 2l1 8z" fill="#a39d91"/><path d="M6 13l2-6l5-2l4 4l-3 4l-4 0z" fill="#bab4a7"/><path d="M8 8l4-2M13 15l3-3" stroke="#e2ddd2" fill="none"/></g>',
	# an iron ingot
	"iron": '<g stroke="#1d2228" stroke-width="1.1" stroke-linejoin="round"><path d="M3 16l4-6h12l-2 6z" fill="#9aa6b2"/><path d="M3 16h14v4H3z" fill="#5d6874"/><path d="M17 16l2-6v4l-2 6z" fill="#47515c"/><path d="M8 12h8" stroke="#d3dde6" fill="none"/></g>',
	# a loaf, and a fish in front of it
	"food": '<g stroke="#3a2614" stroke-width="1.1" stroke-linejoin="round"><path d="M3 12c0-4 4-6 9-6s9 2 9 6c0 2-1 3-3 3H6c-2 0-3-1-3-3z" fill="#c98a3d"/><path d="M8 8l-1 3M12 7.5v3.5M16 8l1 3" stroke="#f0c47e" fill="none"/><path d="M4 18c3-3 8-3 12 0c-4 3-9 3-12 0zM16 18l4-3v6z" fill="#7fa7b8"/><circle cx="7" cy="17.6" r="0.9" fill="#1d2228" stroke="none"/></g>',
	# a coin
	"coin": '<g stroke="#5a3d08" stroke-width="1.1"><circle cx="12" cy="12" r="9" fill="#d9a62e"/><circle cx="12" cy="12" r="6.6" fill="#ecc458" stroke="#a87a18"/><path d="M12 8v8M10 10h4" stroke="#8a6110" stroke-width="1.6" fill="none"/></g>',
	# a backpack
	"pack": '<g stroke="#3a2614" stroke-width="1.1" stroke-linejoin="round"><path d="M9 6V5a3 3 0 0 1 6 0v1" fill="none"/><path d="M5 9a3 3 0 0 1 3-3h8a3 3 0 0 1 3 3v12H5z" fill="#8a5a2b"/><path d="M7 12h10v5H7z" fill="#a8743a"/><path d="M5 10h14" stroke="#5e3b1a" fill="none"/><rect x="11" y="13" width="2" height="2" fill="#d9a62e"/></g>',
	# an open book, for the skills
	"smite": '<path d="M13 1L5 13h5.5l-2 10L19 10h-5.5l3-9z" fill="#f2c94c" stroke="#7a5212" stroke-width="1.1" stroke-linejoin="round"/>',
	"pray": '<g stroke="#7a5212" stroke-width="1.1"><ellipse cx="12" cy="3.6" rx="6" ry="2" fill="none" stroke="#f2c94c" stroke-width="1.6"/><path d="M10.5 7h3v4h4v3h-4v8h-3v-8h-4v-3h4z" fill="#f6e3a0"/></g>',
	"book": '<g stroke="#3a2614" stroke-width="1.1" stroke-linejoin="round"><path d="M2 6c3-1 7-1 10 1v14c-3-2-7-2-10-1z" fill="#f3e2b0"/><path d="M22 6c-3-1-7-1-10 1v14c3-2 7-2 10-1z" fill="#ead39a"/><path d="M4 9c2-.5 4-.4 6 .4M4 12c2-.5 4-.4 6 .4M14 9.4c2-.8 4-.9 6-.4M14 12.4c2-.8 4-.9 6-.4" stroke="#8a6a45" fill="none"/><path d="M12 7v14" stroke="#7a1e18"/></g>',
	# a tankard
	"ale": '<g stroke="#3a2614" stroke-width="1.1" stroke-linejoin="round"><path d="M16 10h3a2 2 0 0 1 2 2v3a2 2 0 0 1-2 2h-3" fill="none"/><path d="M5 8h11v12a1 1 0 0 1-1 1H6a1 1 0 0 1-1-1z" fill="#9a6532"/><path d="M5 8c0-3 3-4 5-3c1-2 5-2 6 1c1 0 1 2 0 2z" fill="#fbf3dc"/><path d="M8 11v7M11 11v7M14 11v7" stroke="#5e3b1a" fill="none"/></g>',
}

static var _theme: Theme
static var _icons := {}
static var _scroll: StyleBoxTexture
static var _display: Font
static var _body: Font


## The display face (Pirata One, a blackletter, for titles and numbers) and the body face (IM Fell English, cut
## from the type of a 17th-century press). Both are in fonts/, under the SIL Open Font License.
static func display_font() -> Font:
	if _display == null:
		_display = _font("res://fonts/PirataOne-Regular.ttf")
	return _display


static func body_font() -> Font:
	if _body == null:
		_body = _font("res://fonts/IMFellEnglish.ttf")
	return _body


static func _font(path: String) -> Font:   # through Godot's importer, so the fonts go with an exported game
	var f: FontFile = load(path)
	f.hinting = TextServer.HINTING_LIGHT
	return f


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


## A parchment card, for the readouts and anything else that is not the big scroll: torn, slightly burnt edges,
## the paper a little blotchy. Made once per tone, when the game starts.
static var _parch := {}

static func card(bg: Color = PAPER_LIGHT, border: Color = OUTLINE, pad: float = 10) -> StyleBoxTexture:
	var k := "%s|%s|%s" % [bg.to_html(), border.to_html(), pad]
	if _parch.has(k):
		return _parch[k]
	var sb := StyleBoxTexture.new()
	sb.texture = ImageTexture.create_from_image(parchment(128, 128, bg, border, 11))
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		sb.set_texture_margin(side, 26)
		sb.set_content_margin(side, pad + 4)
	_parch[k] = sb
	return sb


## The picture behind a card or button: paper with a torn, darkened edge and a thin ink line just inside it.
static func parchment(w: int, h: int, base: Color, edge: Color, seed_: int, rim := 0.0) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var n := FastNoiseLite.new(); n.seed = seed_; n.frequency = 0.045; n.fractal_octaves = 3
	var g := FastNoiseLite.new(); g.seed = seed_ + 9; g.frequency = 0.5
	var half := Vector2(w, h) / 2.0
	var r := 9.0
	for y in h:
		for x in w:
			var q := (Vector2(x + 0.5, y + 0.5) - half).abs() - (half - Vector2(r, r))
			var d := -(Vector2(maxf(q.x, 0), maxf(q.y, 0)).length() + minf(maxf(q.x, q.y), 0.0) - r)   # inside distance to the edge
			var torn := 2.2 + n.get_noise_2d(x * 3.1, y * 3.1) * 2.4 + g.get_noise_2d(x, y) * 0.8
			var a := clampf(d - torn, 0.0, 1.0)
			if a <= 0.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var c := base.darkened(n.get_noise_2d(x, y) * 0.07 + 0.02).lightened(maxf(0.0, g.get_noise_2d(x * 0.7, y * 0.7)) * 0.04)
			var burn := clampf(1.0 - (d - torn) / 11.0, 0.0, 1.0)
			c = c.lerp(edge, burn * burn * 0.7)
			if d - torn < 1.4: c = edge.darkened(0.35)
			if rim > 0.0 and absf(d - torn - 6.0) < 0.7: c = c.lerp(edge, rim)          # an inked border, for buttons
			c.a = a
			img.set_pixel(x, y, c)
	return img


static func _plaque(base: Color, edge: Color, seed_: int, rim: float) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = ImageTexture.create_from_image(parchment(96, 64, base, edge, seed_, rim))
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		sb.set_texture_margin(side, 20)
	sb.content_margin_left = 14; sb.content_margin_right = 14; sb.content_margin_top = 8; sb.content_margin_bottom = 8
	return sb


## The red wax button, for the thing you most likely want.
static func primary() -> StyleBoxTexture:
	if not _parch.has("primary"):
		_parch.primary = _plaque(ROSE, Color("4a120c"), 5, 0.0)
		_parch.primary_hover = _plaque(ROSE.lightened(0.12), Color("4a120c"), 5, 0.0)
	return _parch.primary


static func primary_hover() -> StyleBoxTexture:
	primary()
	return _parch.primary_hover


static func _button(bg: Color, border: Color) -> StyleBoxFlat:   # a plain box, for typing in
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 10; sb.content_margin_right = 10; sb.content_margin_top = 6; sb.content_margin_bottom = 6
	return sb


static func theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font = body_font()
	t.default_font_size = 18
	t.set_color("font_color", "Label", INK)
	t.set_color("font_color", "Button", INK)
	t.set_color("font_hover_color", "Button", INK)
	t.set_color("font_pressed_color", "Button", INK)
	t.set_color("font_focus_color", "Button", INK)
	t.set_color("font_disabled_color", "Button", Color(INK, 0.4))
	t.set_stylebox("normal", "Button", _plaque(PAPER_LIGHT, Color("6b4423"), 3, 0.35))
	t.set_stylebox("hover", "Button", _plaque(Color("fff6d8"), Color("6b4423"), 3, 0.55))
	t.set_stylebox("pressed", "Button", _plaque(PAPER_DARK, Color("4a2a12"), 3, 0.6))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_stylebox("disabled", "Button", _plaque(Color("e3d3a8"), Color("9c8a6a"), 3, 0.2))
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
	t.set_stylebox("panel", "TooltipPanel", card(PAPER_LIGHT, OUTLINE, 6))
	t.set_font_size("font_size", "TooltipLabel", 16)
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
	var inner: String = ICON_COL[name] if ICON_COL.has(name) and not gold and not (key is int) else '<path d="%s" fill="none" stroke="%s" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>' % [ICON.get(name, ""), col]
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">%s</svg>' % inner
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
