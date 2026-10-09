extends CanvasLayer
## The readouts round the edge of the screen. Each has its own place, so nothing sits on anything else:
##
##   top left      the day, the time, and whether you are ready         top middle   the keep (and the Steward)
##   left          what you carry                                      top right    the map, and the handbook button
##   bottom left   your health, and the news                            bottom right the four things you can place
##   bottom middle what holding E would do, and your hand, bucket, posse, pack and courage
##
## Notices, the backpack, the dawn and the handbook open in the one window in the middle (window.gd); while it is
## open the big announcements wait.

const ScrollWindow := preload("res://scripts/ui/window.gd")

signal build_pressed(k: String)
signal pack_pressed
signal skills_pressed
signal menu_pressed

var window: Control
var root: Control

var _phase: Label
var _timer: Label
var _ready_lab: Label
var _keep_bar: ProgressBar
var _keep_num: Label
var _boss: Control
var _boss_bar: ProgressBar
var _boss_num: Label
var _boss_name: Label
var _title: Label
var _powers: HBoxContainer
var _res := {}                       # name -> Label
var _carry: Label
var _hp_bar: ProgressBar
var _hp_lab: Label
var _feed: VBoxContainer
var _prompt: Label
var _prompt_bar: ProgressBar
var _prompt_box: Control
var _hotbar: HBoxContainer
var _chips := {}                     # name -> {box, icon, text, key}
var _builds: HBoxContainer
var _build_cards := {}
var _banner: Label
var _banner_sub: Label
var _banner_box: Control
var _banner_t := 0.0
var _queued: Array = []              # announcements waiting for the window to close
var map_slot: Control                # where the map goes (main puts it in)
var _zones: Array[Control] = []      # everything that labels in the world must keep clear of


func _ready() -> void:
	layer = 5
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = Look.theme()
	add_child(root)

	# --- top left: the day
	var tl := _card(root)
	_pin(tl, Control.PRESET_TOP_LEFT, 14, 12, 254, 12)
	var v := _vbox(tl, 0)
	_phase = Look.label(v, "Day 1", 30, Look.INK, true)
	_timer = Look.label(v, "", 15, Look.INK_SOFT)
	_title = Look.label(v, "", 13, Color("5d2a6e"))
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ready_lab = Look.label(v, "", 13, Look.RUST)
	_ready_lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# --- top middle: the keep, and the Steward when he comes
	var tm := _card(root)
	_pin(tm, Control.PRESET_CENTER_TOP, -180, 12, 180, 12)
	var kv := _vbox(tm, 3)
	var row := HBoxContainer.new()
	kv.add_child(row)
	var ki := TextureRect.new(); ki.texture = Look.icon("keep", 18); row.add_child(ki)
	var kl := Look.label(row, " The keep", 14, Look.INK)
	kl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_keep_num = Look.label(row, "", 14, Look.INK_SOFT)
	_keep_bar = _bar(kv, Color("8f8a7c"), 12)
	_boss = VBoxContainer.new()
	kv.add_child(_boss)
	var br := HBoxContainer.new(); _boss.add_child(br)
	var bl := Look.label(br, "The Steward", 14, Color("5d2a6e")); bl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_boss_name = bl
	_boss_num = Look.label(br, "", 14, Look.INK_SOFT)
	_boss_bar = _bar(_boss, Color("8e3fa0"), 10)
	_boss.visible = false

	# --- top right: the map, and the handbook
	var top_right := VBoxContainer.new()
	root.add_child(top_right)
	_pin(top_right, Control.PRESET_TOP_RIGHT, -200, 12, -14, 12)
	top_right.add_theme_constant_override("separation", 6)
	map_slot = Control.new()
	map_slot.custom_minimum_size = Vector2(186, 186)
	map_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_right.add_child(map_slot)
	var mb := Button.new()
	mb.text = "Handbook  (Esc)"
	mb.focus_mode = Control.FOCUS_NONE
	mb.pressed.connect(func(): menu_pressed.emit())
	top_right.add_child(mb)
	_zones.append(top_right)

	# --- left: what you carry
	var lc := VBoxContainer.new()
	root.add_child(lc)
	_pin(lc, Control.PRESET_TOP_LEFT, 14, 142, 254, 142)
	lc.add_theme_constant_override("separation", 8)
	lc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rc := _card(lc)
	rc.custom_minimum_size.x = 240
	var rv := _vbox(rc, 2)
	Look.label(rv, "What you carry", 20, Look.RUST, true)
	for r in ["wood", "stone", "iron", "food", "coin"]:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rv.add_child(h)
		var ic := TextureRect.new(); ic.texture = Look.icon(r, 30); ic.custom_minimum_size = Vector2(30, 30)
		ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED; h.add_child(ic)
		var nm := Look.label(h, r.capitalize(), 18, Look.INK)
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_res[r] = Look.label(h, "0", 22, Look.INK, true)
		_res[r].vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		if r != "coin":
			_res[r + "_cap"] = Look.label(h, "/30", 14, Look.INK_SOFT)
			_res[r + "_cap"].custom_minimum_size.x = 28
			_res[r + "_cap"].vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_carry = Look.para(rv, "", 14, Look.INK_SOFT)
	_zones.append(lc)

	# --- bottom left: health, and above it the news
	var hb := _card(root)
	_pin(hb, Control.PRESET_BOTTOM_LEFT, 14, -14, 254, -14)
	hb.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var hv := _vbox(hb, 3)
	_hp_lab = Look.label(hv, "Your health", 13, Look.INK)
	_hp_bar = _bar(hv, Look.ROSE, 12)
	_feed = VBoxContainer.new()
	root.add_child(_feed)
	_pin(_feed, Control.PRESET_BOTTOM_LEFT, 16, -76, 300, -76)
	_feed.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_feed.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_feed.add_theme_constant_override("separation", 2)

	# --- bottom right: the things you can place
	_builds = HBoxContainer.new()
	root.add_child(_builds)
	_pin(_builds, Control.PRESET_BOTTOM_RIGHT, -14, -14, -14, -14)
	_builds.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_builds.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_builds.add_theme_constant_override("separation", 4)
	var bn := {"barricade": "Barricade", "spikes": "Spikes", "bodywall": "Body wall", "decoy": "Decoy", "contr": "Contraption"}
	for i in D.BUILDS.size() + 1:
		var k: String = D.BUILDS[i] if i < D.BUILDS.size() else "contr"
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(64, 70)
		b.tooltip_text = "Place a %s (%d, or %s steps through these)" % [D.SNAME.get(k, "contraption"), i + 1, "{build}"]
		b.pressed.connect(func(): build_pressed.emit(k))
		var bv := VBoxContainer.new()
		bv.set_anchors_preset(Control.PRESET_FULL_RECT)
		bv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bv.alignment = BoxContainer.ALIGNMENT_CENTER
		bv.add_theme_constant_override("separation", 0)
		b.add_child(bv)
		var top := HBoxContainer.new(); top.alignment = BoxContainer.ALIGNMENT_CENTER; bv.add_child(top)
		top.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var num := Look.label(top, str(i + 1) + " ", 12, Look.ROSE)
		num.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ic := TextureRect.new(); ic.texture = Look.icon(k, 22); ic.mouse_filter = Control.MOUSE_FILTER_IGNORE; top.add_child(ic)
		var nm := Look.label(bv, bn[k], 12, Look.INK); nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var cost := Look.label(bv, "", 11, Look.INK_SOFT); cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		for l in [nm, cost]: l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_builds.add_child(b)
		_build_cards[k] = {"b": b, "cost": cost, "name": nm, "icon": ic}
	_zones.append(_builds)

	# --- bottom middle: your hand and the rest, and above them what holding E would do
	_hotbar = HBoxContainer.new()
	root.add_child(_hotbar)
	_pin(_hotbar, Control.PRESET_CENTER_BOTTOM, -56, -14, -56, -14)   # a little left of centre, to leave room for the five things you can place
	_hotbar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_hotbar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_hotbar.add_theme_constant_override("separation", 3)
	for c in ["hand", "carry", "posse", "pack", "skills", "toilet", "courage"]:
		_chip(c)
	_zones.append(_hotbar)
	# a calling's two powers: their own little bar, above your health
	_powers = HBoxContainer.new()
	root.add_child(_powers)
	_pin(_powers, Control.PRESET_BOTTOM_LEFT, 14, -80, 14, -80)
	_powers.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_powers.add_theme_constant_override("separation", 3)
	_chip("power1", _powers)
	_chip("power2", _powers)
	_zones.append(_powers)
	_prompt_box = VBoxContainer.new()
	root.add_child(_prompt_box)
	_pin(_prompt_box, Control.PRESET_CENTER_BOTTOM, -280, -96, 280, -96)
	_prompt_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_prompt_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt = _shout(_prompt_box, 20)
	_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_prompt_bar = _bar(_prompt_box, Color("e0b44a"), 7)

	# --- the big announcements: under the keep, only when nothing is open
	_banner_box = VBoxContainer.new()
	root.add_child(_banner_box)
	_pin(_banner_box, Control.PRESET_CENTER_TOP, -420, 110, 420, 110)
	_banner_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner = _shout(_banner_box, 58, true)
	_banner_sub = _shout(_banner_box, 20)
	_banner_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_banner_box.modulate.a = 0.0

	window = ScrollWindow.new()
	root.add_child(window)
	_zones.append_array([tl, tm, hb])


func _pin(c: Control, preset: Control.LayoutPreset, left: float, top: float, right: float, bottom: float) -> void:
	c.set_anchors_preset(preset)
	c.offset_left = left; c.offset_top = top; c.offset_right = right; c.offset_bottom = bottom


func _card(parent: Control) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Look.card())
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(p)
	return p


func _vbox(parent: Control, sep: int) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(v)
	return v


func _shout(parent: Control, size: int, display: bool = false) -> Label:
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	if display: l.add_theme_font_override("font", Look.display_font())
	l.add_theme_color_override("font_color", Color("f8eed3"))
	l.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.02, 0.9))
	l.add_theme_constant_override("outline_size", 9 if size > 30 else 4)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


func _bar(parent: Control, fill: Color, h: float) -> ProgressBar:
	var b := ProgressBar.new()
	b.custom_minimum_size = Vector2(0, h)
	b.show_percentage = false
	b.max_value = 1.0
	b.value = 1.0
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new(); bg.bg_color = Color("3a2d22"); bg.set_corner_radius_all(3)
	var fg := StyleBoxFlat.new(); fg.bg_color = fill; fg.set_corner_radius_all(3)
	b.add_theme_stylebox_override("background", bg)
	b.add_theme_stylebox_override("fill", fg)
	parent.add_child(b)
	return b


func _chip(name_: String, parent: Control = null) -> void:   # one slot in the bar at the bottom: a picture, a word or two, and its key
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(96, 58)
	b.mouse_filter = Control.MOUSE_FILTER_STOP if name_ in ["pack", "skills"] else Control.MOUSE_FILTER_IGNORE
	if name_ == "pack": b.pressed.connect(func(): pack_pressed.emit())
	if name_ == "skills": b.pressed.connect(func(): skills_pressed.emit())
	var h := HBoxContainer.new()
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 9; h.offset_right = -5
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_theme_constant_override("separation", 6)
	b.add_child(h)
	var ic := TextureRect.new()
	ic.custom_minimum_size = Vector2(30, 30)
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(ic)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", -2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(v)
	var key := Look.label(v, "", 12, Look.ROSE)
	var text := Look.label(v, "", 15, Look.INK)
	(parent if parent else _hotbar).add_child(b)
	_chips[name_] = {"box": b, "icon": ic, "text": text, "key": key}


func _set_chip(name_: String, shown: bool, icon_key, key: String, text: String, tip: String, dim: bool = false) -> void:
	var c: Dictionary = _chips[name_]
	c.box.visible = shown
	if not shown: return
	if c.get("ik") != icon_key:                    # a number is an item; a word is one of the readout pictures
		c.ik = icon_key
		c.icon.texture = Look.icon(int(icon_key) if str(icon_key).is_valid_int() else icon_key, 30)
	c.key.text = key
	c.text.text = text
	var need: float = maxf(c.key.get_minimum_size().x, c.text.get_minimum_size().x) + 30 + 6 + 20
	c.box.custom_minimum_size.x = maxf(80, need)
	c.box.tooltip_text = Keys.fill(tip)
	c.box.modulate = Color(1, 1, 1, 0.55) if dim else Color.WHITE


# ---------------------------------------------------------------- told by main.gd
## On the home screen only the window shows; in the game, everything.
var _covered := false
var _playing := true

func playing(on: bool) -> void:
	_playing = on
	_covered = false
	for c in root.get_children():
		if c != window: c.visible = on
	if not on: _banner_t = 0.0



func banner(title: String, sub: String = "", seconds: float = 3.2) -> void:
	if window.visible and window.kind != "notice" and window.kind != "pack":
		_queued.append([title, sub, seconds])      # wait for the window to close
		if _queued.size() > 3: _queued.pop_front()
		return
	_banner.text = title
	_banner_sub.text = Keys.fill(sub)
	_banner_t = seconds


func feed(msg: String) -> void:   # a line of news, which fades after a while
	var l := Label.new()
	l.text = msg
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", Color("f8eed3"))
	l.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.02, 0.9))
	l.add_theme_constant_override("outline_size", 5)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.set_meta("t", 9.0)
	_feed.add_child(l)
	while _feed.get_child_count() > 4:
		var c := _feed.get_child(0)
		_feed.remove_child(c)
		c.queue_free()


## Rectangles on screen that words over the world (signs, names) should not sit on.
func zones() -> Array[Rect2]:
	var out: Array[Rect2] = []
	if _prompt_box.visible: out.append(_prompt_box.get_global_rect().grow(6))
	for z in _zones:
		if z.visible: out.append(z.get_global_rect())
	if window.visible: out.append(Rect2(Vector2.ZERO, root.size))
	return out


func _process(delta: float) -> void:
	for l in _feed.get_children():
		var t: float = l.get_meta("t") - delta
		l.set_meta("t", t)
		l.modulate.a = clampf(t, 0, 1)
		if t <= 0:
			_feed.remove_child(l)
			l.queue_free()
	if _banner_t <= 0 and _queued.size() and not (window.visible and window.kind != "notice" and window.kind != "pack"):
		var q: Array = _queued.pop_front()
		banner(q[0], q[1], q[2])
	_banner_t -= delta
	_banner_box.modulate.a = clampf(_banner_t / 0.6, 0.0, 1.0)
	_banner_box.visible = _banner_t > 0 and not (window.visible and window.kind != "notice" and window.kind != "pack")
	# a window that covers the game (the handbook, the dawn, the end) has the screen to itself
	var covered: bool = window.visible and window.covers()
	if covered != _covered and _playing:
		_covered = covered
		for c in _zones: c.visible = not covered
		_feed.visible = not covered


## Everything that changes, from the rules. R and me, plus what main knows: the prompt, what is being placed.
func update(R: Rules, me: E.Player, prompt: String, prog: float, prompt_ok: bool, build_sel: String, ready_line: String) -> void:
	var p := me
	var ph := R.phase
	_phase.text = "Dusk" if ph == "dusk" else "Night %d" % R.day if ph == "night" or ph == "lost" else "Day %d of %d" % [R.day, R.last_day]
	var timer := ""
	match ph:
		"day": timer = "Dusk in " + _fmt(R.timeLeft)
		"dusk": timer = "Night falls in " + _fmt(R.timeLeft)
		"night": timer = ("%d undead left · %d still to rise" % [R.left, R.wave] if R.wave > 0 else "%d undead left · the last have risen" % R.left) if R.left > 0 else "The graveyard is quiet"
		"won": timer = "It is over. You held."
		"lost": timer = "The keep has fallen"
	_timer.text = timer
	_title.text = "%s, %s" % [p.dn, Rules.title_of(p)]
	_ready_lab.text = ready_line
	_ready_lab.visible = ready_line != ""
	_keep_bar.value = maxf(0, R.keepHp) / D.KEEP_HP
	_keep_num.text = "%d / %d" % [maxi(0, roundi(R.keepHp)), roundi(D.KEEP_HP)]
	_boss.visible = R.boss != null
	if R.boss:
		var bn: String = D.UN[R.boss.k].name
		_boss_name.text = bn[0].to_upper() + bn.substr(1)
		_boss_bar.value = maxf(0, R.boss.hp) / maxf(1, R.boss.mhp)
		_boss_num.text = "%d / %d" % [maxi(0, ceili(R.boss.hp)), roundi(R.boss.mhp)]
	# what you carry
	var c := Rules.cap(p)
	for r in ["wood", "stone", "iron", "food"]:
		var n: int = p.get(r)
		_res[r].text = str(n)
		_res[r].add_theme_color_override("font_color", Look.ROSE if n >= c else Look.INK)
		_res[r + "_cap"].text = "/%d" % c
	_res.coin.text = D.coins(p.coin)
	_carry.text = "Bodies: %d of %d%s" % [p.bodies, D.MAX_BODIES, " (%d blessed)" % p.bbod if p.bbod else ""] if p.bodies else ""
	_carry.visible = p.bodies > 0
	# health
	_hp_bar.value = p.hp / Rules.max_hp(p)
	_hp_lab.text = "Your health. %s eats." % Keys.name("eat") if p.food > 0 and p.hp < Rules.max_hp(p) and p.state == "ok" else "Your health"
	# the bar at the bottom
	var W: Dictionary = D.IT[p.wpn]
	var A: Dictionary = D.AB[W.ab]
	_set_chip("hand", true, str(p.wpn), Keys.name("trick"), A.n + (" %ds" % ceili(p.abCd) if p.abCd > 0 else ""),
		"In your hand: %s%s. {trick} or right-click: %s, %s." % [W.n, " (blessed)" if p.bless & 1 else "", A.n, A.d], p.abCd > 0)
	var cl := Rules.class_of(p)
	for i in 2:
		var shown := false
		if cl >= 0:
			var pw: Dictionary = D.CLASSES[cl].powers[i]
			var has_it: bool = Rules.rk(p, D.CLASSES[cl].book) >= pw.rank
			var cd: float = p.p1Cd if i == 0 else p.p2Cd
			shown = true
			_set_chip("power%d" % (i + 1), true, pw.icon, Keys.name("power%d" % (i + 1)) if has_it else "rank %d" % pw.rank, pw.n + (" %ds" % ceili(cd) if cd > 0 else ""),
				"%s: %s. %s" % [pw.full, pw.d, "{power%d}." % (i + 1) if has_it else "It comes at rank %d of %s." % [pw.rank, D.BOOKS[D.CLASSES[cl].book].name]], cd > 0 or not has_it)
		if not shown: _set_chip("power%d" % (i + 1), false, "", "", "", "")
	_powers.visible = cl >= 0 and not _covered
	_feed.offset_top = -148 if cl >= 0 else -76
	_feed.offset_bottom = _feed.offset_top
	_set_chip("carry", p.trk >= 0, str(p.trk) if p.trk >= 0 else "pack", Keys.name("carry"), (["Handbell", "Censer", "Bucket"][p.trk - 26] if p.trk >= 26 else D.IT[p.trk].n) if p.trk >= 0 else "",
		(D.IT[p.trk].note if p.trk >= 0 else ""), p.trk == 26 and p.useCd > 0)
	var nv := 100.0
	for q in R.peasants:
		if q.owner == p.id and q.state != "body" and q.state != "hide" and q.nv < nv: nv = q.nv
	var orders := Rules.rk(p, 6) >= 3
	_set_chip("posse", true, "posse", (Keys.name("orders") + " " + ["follow", "hold", "charge"][p.order]) if orders else "", "Posse %d/%d" % [p.posse, R.posse_max(p)],
		"Your posse." + (" About to run." if p.posse and nv < 40 else " Uneasy." if p.posse and nv < 70 else "") + (" {orders}: follow, hold, charge." if orders else ""), p.posse == 0)
	_set_chip("pack", true, "pack", Keys.name("pack"), "Backpack %d/%d" % [p.inv.size(), D.PACK_MAX], "Your backpack: what is on you, and six places for spares. Click or press {pack}.")
	var owned := p.books.filter(func(r): return r > 0).size()
	_set_chip("skills", true, "book", Keys.name("skills"), ("Skills +" if p.spare >= 1 else "Skills") if owned else "No book",
		"Your skills: each book you have read, what every rank does, and how close the next is. Click or press {skills}." if owned else "The library has a book for you.", owned == 0)
	_set_chip("toilet", p.posse > 0, "toilet", Keys.name("toilet"), "Toilet" if p.tbCd <= 0 else "Toilet %ds" % ceili(p.tbCd), "Emergency toilet break: the dead nearby run from your posse.", p.tbCd > 0)
	var cg := p.state == "inn" or p.cg > 0 or p.charge > 0 or p.hang > 0
	_set_chip("courage", cg, "ale", "", "Charging %ds" % ceili(p.charge) if p.charge > 0 else "Hangover %ds" % ceili(p.hang) if p.hang > 0 else "Courage %d%%" % p.cg, "Dutch courage, from the Thorny Rose Inn.")
	# what you can place
	for k in _build_cards:
		var e: Dictionary = _build_cards[k]
		if k == "contr":                             # one card for every contraption: 5 steps through the ones you can build
			var avail := D.CONTRAPTIONS.filter(func(c): return Rules.can_contr(p, c))
			e.b.visible = avail.size() > 0
			var cur: String = build_sel if D.CONTR.has(build_sel) else avail[0] if avail.size() else ""
			e.b.button_pressed = D.CONTR.has(build_sel)
			if cur != "":
				var nm_: String = D.SNAME[cur]
				e.name.text = {"chicken": "Chicken", "pitfall": "Pitfall", "tar": "Tar pit", "trough": "Holy water", "logs": "Log roller", "thresher": "Thresher"}[cur]
				e.cost.text = D.cost_text(Rules.cost_of(p, cur)).replace(" and ", ", ")
				e.b.tooltip_text = Keys.fill("%s. %s. Press %d to step through your contraptions%s." % [nm_[0].to_upper() + nm_.substr(1), D.CONTR[cur].d, D.BUILDS.size() + 1,
					" (a box of cogs will be used: you have %d)" % p.cogs if Rules.rk(p, 2) < D.CONTR[cur].rank else ""])
			continue
		var need_bodies: bool = D.COST[k].has("bodies")
		e.b.visible = not need_bodies or p.bodies >= D.COST[k].bodies
		e.b.button_pressed = build_sel == k
		e.cost.text = D.cost_text(Rules.cost_of(p, k)).replace(" and ", ", ")
		e.b.tooltip_text = Keys.fill("Place a %s. Press %d, or {build} to step through these." % [D.SNAME[k], D.BUILDS.find(k) + 1])
	_builds.visible = p.state == "ok" and R.live() and not _covered
	# the prompt
	_prompt.text = Keys.fill(prompt)
	_prompt.modulate = Color.WHITE if prompt_ok else Color(1, 0.75, 0.7, 0.95)
	_prompt_bar.visible = prog > 0.0
	_prompt_bar.value = prog
	_prompt_box.visible = prompt != "" and not window.visible


static func _fmt(s: float) -> String:
	var n := maxi(0, ceili(s))
	return "%d:%02d" % [floori(n / 60.0), n % 60]
