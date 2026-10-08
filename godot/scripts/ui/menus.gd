extends RefCounted
## What goes in the window: the home screen, the handbook (guide, controls, options), a place's notice,
## your pack, the dawn notice, and the end of the week. main.gd says which; this fills it in.

const GUIDE := [
	["The short version", ["By day, gather and build. At dusk the bell rings. At night the dead rise along the graveyard to the north, one after another without a pause and faster as the night goes on, and make for the keep, where the families are hiding. If the keep falls, Thornhallow is lost. Hold for seven nights.", "Nearly everything is done by walking up to it and holding {interact}."]],
	["The day", ["A day lasts six minutes, or until everyone presses {ready}.", "Wood comes from trees, stone from the rocky outcrop, iron from the mine, food from the farms to the west or the jetty on the river. The stone, the iron and the fishing move every morning: the dawn notice says where, and the map marks them. You carry 20 of each.", "At the jetty, hold {interact} and press {attack} when something bites."]],
	["Defences", ["The north wall has seven foundations: six walls and a gate. Stand on one and hold {interact}. Barricades and spike rows go anywhere: press {build} or 1 to 4 (or click one, bottom right), then {interact} or click.", "Hold {interact} at a damaged defence to repair it with wood. Carrying stone or iron, hold {interact} again to face a wall with stone, band the gate or brace a barricade. An unbraced barricade rots by half every evening after its first night.", "Nobody can be hit through a standing wall or gate, in either direction. Go out through the gate, or shoot over."]],
	["Your posse", ["Hold {interact} beside a neighbour to rally them. They gather when you gather and fight when you fight. The slum has more, for food. The smithy gives them spears.", "They can die, and they have nerve: when friends fall they may run for the keep until dawn. {toilet} is the emergency toilet break, which sends the dead nearby running. With rank 3 of the leadership book, {orders} tells them to follow, hold or charge."]],
	["Fighting", ["{attack} or a click attacks. {trick} or a right-click is your weapon’s own trick: every weapon has a different one, with a short wait between uses. {eat} eats one food.", "Knocked down, you have 15 seconds for a team-mate to hold {interact} over you. After that a relative takes over your cottage at dawn, with your books but not your gear. Relics lie where you fell.", "From dusk you can hide in your own cottage. It is safe, and the village will call you a coward until the next dusk."]],
	["Things you carry", ["{pack} opens your pack: what is on you, and six places for spares. Click a thing to use it or put it away. {swap} swaps to the next weapon in the pack without opening it. {carry} throws a slop bucket or rings a handbell.", "A bow needs the book Slings, Bows and Thrown Turnips, which comes with a sling. A crossbow needs rank 3 of it. Heavy arms need rank 2 of Hammer and Tongs to forge."]],
	["Places", ["The library: three books out of ten, seven ranks each, earned by doing what the book teaches. The smithy: weapons, armour, spears for the posse. The storehouse: shared materials and a shared arms rack. The market: sells at a penny a piece, buys at two. The slum: recruits.", "The Thorny Rose: bring the innkeeper food by day; from dusk go in, bar the door and drink. At full courage you burst out and charge. The priest, by the chapel: blessings for two shillings, and holy studies.", "The ruins, by the chapel and outside the wall to the south-west and south-east: hold {interact} at a heap of rubble. Relics turn up, more often by moonlight. Searching outside the wall is noisy."]],
	["Reading the screen", ["Top left: the day and the time left, and whether you are ready. Top middle: the keep, and the Steward when he comes. Top right: the map. Left: what you carry, and your books. Bottom: your hand, bucket, posse, pack and toilet break, with their keys, and the four things you can place, bottom right. What holding {interact} would do shows just above the bar at the bottom.", "Places, your pack, the dawn and this handbook all open in one window in the middle. Esc closes it, or the cross; walking away closes a place's notice."]],
]

const CHANGES := [
	["Godot: the menus (stage 3 of the move)", [
		"Everything that opens now opens in one window in the middle, framed by the scroll, so nothing sits on anything else. Esc or the cross closes it.",
		"The readouts have fixed places round the edge: the day top left, the keep top middle, the map top right, what you carry and your books on the left, your health bottom left, and a bar along the bottom with your weapon’s trick, your bucket, your posse, your pack and the toilet break, each with its key.",
		"The four things you can place sit bottom right, with their costs. Click one, or press 1 to 4.",
		"Your pack is slots with pictures: click a thing to use it or put it away, the cross drops it.",
		"A home screen with your name and colour, Carry on and New village, and this list.",
		"The handbook on Esc: a guide, the controls (change any key) and options. The game waits while it is open.",
		"Lose, and you can try the same day again from its morning."]],
	["Godot: the map and models (stage 2)", ["Every model from the web version, the see-through keep, the effects, the map in the corner and the signs over places."]],
	["Godot: the rules (stage 1)", ["The whole game’s rules, moved across unchanged, with the web version’s 107 checks passing."]],
	["Build 3 (web): the inn and the ruins", ["The Thorny Rose, ruins and relics, a trick for every weapon, the pack and arms rack, ten books of seven ranks, the priest, posse nerve and orders, a continuous stream of the dead, moving outcrop, mine and fishing, regrowing trees, rotting barricades."]],
]

var m                                  # main.gd
var w                                  # the window
var menu_tab := "guide"
var rebinding := ""
var bind_msg := ""
var notice_sig := ""


func _init(main_, window_) -> void:
	m = main_
	w = window_


# ---------------------------------------------------------------- home
func home() -> void:
	var b: VBoxContainer = w.open("home", "Defend the Village!", "", 1000, 660, false, false)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 26)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	b.add_child(cols)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 10)
	cols.add_child(left)
	Look.para(left, "Every night the dead walk down from Ashhollow Castle to the keep, where Thornhallow’s families are hiding. Robert Bailiff has bolted his door. Hold for seven nights.", 15, Look.INK_SOFT)
	Look.label(left, "YOUR NAME AND COLOUR", 13, Look.RUST)
	var name := LineEdit.new()
	name.text = Settings.name
	name.placeholder_text = "Peasant"
	name.max_length = 14
	name.custom_minimum_size.x = 260
	name.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	name.text_changed.connect(func(t): Settings.name = t.strip_edges(); Settings.save())
	left.add_child(name)
	var sw := HBoxContainer.new()
	sw.add_theme_constant_override("separation", 6)
	left.add_child(sw)
	for i in 8:
		var s := Button.new()
		s.custom_minimum_size = Vector2(30, 30)
		s.tooltip_text = D.PCOLN[i]
		s.focus_mode = Control.FOCUS_NONE
		var st := StyleBoxFlat.new()
		st.bg_color = Color(D.PCOL[i])
		st.set_corner_radius_all(15)
		st.set_border_width_all(4 if i == Settings.col else 2)
		st.border_color = Look.INK if i == Settings.col else Color(Look.OUTLINE, 0.4)
		for k in ["normal", "hover", "pressed"]: s.add_theme_stylebox_override(k, st)
		s.pressed.connect(func(): Settings.col = i; Settings.save(); home())
		sw.add_child(s)
	var saved = m.read_save()
	if saved:
		var who: Array = saved.players.map(func(p): return p.dn)
		var cb := _big(left, "Carry on from day %d" % int(saved.day), func(): m.begin(saved), true)
		cb.tooltip_text = "Saved: " + ", ".join(who) + "."
	_big(left, "New village", func(): m.begin(null), saved == null)
	var co := Look.para(left, "Playing together comes back in the last stage of the move to Godot. Until then, co-op is in the web version.", 13, Look.INK_SOFT)
	co.custom_minimum_size.x = 300
	w.foot_button("Handbook: guide, controls, options", func(): menu("guide"))
	w.hint("%s move · %s or click attacks · %s or right-click: your weapon’s trick · hold %s to do things · Esc: the handbook" % [
		" ".join(["up", "left", "down", "right"].map(func(a): return Keys.name(a))), Keys.name("attack"), Keys.name("trick"), Keys.name("interact")])
	# the change log
	var right := PanelContainer.new()
	right.add_theme_stylebox_override("panel", Look.card(Color("f3e2b0"), Color(Look.OUTLINE, 0.5), 12))
	right.custom_minimum_size.x = 380
	cols.add_child(right)
	var rs := ScrollContainer.new()
	rs.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(rs)
	var rv := VBoxContainer.new()
	rv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rv.add_theme_constant_override("separation", 6)
	rs.add_child(rv)
	Look.label(rv, "What is new", 24, Look.INK, true)
	for c in CHANGES:
		Look.label(rv, c[0], 15, Look.RUST).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		for line in c[1]:
			Look.para(rv, "•  " + line, 13, Look.INK)


func _big(parent: Control, text: String, cb: Callable, primary: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(260, 40)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	b.add_theme_font_size_override("font_size", 19)
	if primary:
		b.add_theme_stylebox_override("normal", w._primary())
		b.add_theme_stylebox_override("hover", w._primary())
		b.add_theme_color_override("font_color", Color("fbeec2"))
		b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


# ---------------------------------------------------------------- the handbook
func menu(tab: String = "") -> void:
	if tab != "": menu_tab = tab
	var in_game: bool = m.in_game()
	var b: VBoxContainer = w.open("menu", "The handbook", "", 760, 600, true)
	w.tabs([["guide", "Guide"], ["keys", "Controls"], ["opts", "Options"]], menu_tab, func(t): rebinding = ""; bind_msg = ""; menu(t))
	match menu_tab:
		"guide":
			for g in GUIDE:
				w.head(g[0])
				for p in g[1]: w.para(p, 16)
		"keys":
			var grid := GridContainer.new()
			grid.columns = 3
			grid.add_theme_constant_override("h_separation", 14)
			grid.add_theme_constant_override("v_separation", 4)
			b.add_child(grid)
			for a in Keys.ACTIONS:
				var l := Look.label(grid, a[1], 15, Look.INK)
				l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				Look.label(grid, "Press a key…" if rebinding == a[0] else Keys.all_names(a[0]), 15, Look.ROSE if rebinding == a[0] else Look.INK_SOFT)
				var c := Button.new()
				c.text = "Cancel" if rebinding == a[0] else "Change"
				c.focus_mode = Control.FOCUS_NONE
				var act: String = a[0]
				c.pressed.connect(func(): rebinding = "" if rebinding == act else act; bind_msg = ""; menu())
				grid.add_child(c)
			w.para(bind_msg if bind_msg != "" else "Choose Change, then press the key you want. A key does one thing: whatever had it before is left without.", 14, Look.INK_SOFT)
			w.para("Fixed: a click attacks and a right-click is your weapon’s trick. The numbers pick from a notice, your pack, or the things to place. Esc closes whatever is open, and otherwise opens this handbook.", 14, Look.INK_SOFT)
			var r := Button.new(); r.text = "Back to the usual keys"; r.focus_mode = Control.FOCUS_NONE
			r.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			r.pressed.connect(func(): Keys.reset(); rebinding = ""; bind_msg = "The usual keys are back."; menu())
			b.add_child(r)
		"opts":
			var g := GridContainer.new()
			g.columns = 2
			g.add_theme_constant_override("h_separation", 16)
			g.add_theme_constant_override("v_separation", 10)
			b.add_child(g)
			Look.label(g, "Sound (it arrives in the next stage)", 15)
			var vh := HBoxContainer.new(); g.add_child(vh)
			var vs := HSlider.new(); vs.min_value = 0; vs.max_value = 100; vs.step = 5; vs.value = Settings.vol; vs.custom_minimum_size.x = 180
			var vl := Look.label(vh, "", 15)
			vh.add_child(vs); vh.move_child(vs, 0)
			vl.text = "%d%%" % Settings.vol if Settings.vol else "off"
			vs.value_changed.connect(func(v): Settings.vol = int(v); vl.text = "%d%%" % Settings.vol if Settings.vol else "off"; Settings.save())
			Look.label(g, "Names over the other players", 15)
			var tg := CheckBox.new(); tg.button_pressed = Settings.tags; tg.toggled.connect(func(on): Settings.tags = on; Settings.save()); g.add_child(tg)
			Look.label(g, "See through the keep when something is behind it", 15)
			var sk := CheckBox.new(); sk.button_pressed = Settings.see_keep; sk.toggled.connect(func(on): Settings.see_keep = on; Settings.save()); g.add_child(sk)
			w.para("These are kept on this computer.", 13, Look.INK_SOFT)
	w.hint("The game waits while you read." if in_game else "")
	if in_game:
		var lv: Button = w.foot_button("Leave the village", func(): _leave())
		lv.tooltip_text = "Back to the home screen. The village was saved this morning."
	w.foot_button("Back to the game" if in_game else "Close", func(): w.close(), true)


var _leave_armed := false
func _leave() -> void:
	if not _leave_armed:
		_leave_armed = true
		bind_msg = ""
		w.hint("Really leave? Press it again. You will carry on from this morning next time.")
		return
	_leave_armed = false
	w.close()
	m.to_home()


## A key was pressed while the handbook waits for one.
func take_key(k: int) -> void:
	var a := rebinding
	rebinding = ""
	if k == KEY_ESCAPE:
		bind_msg = "Left as it was."
	elif k >= KEY_0 and k <= KEY_9:
		bind_msg = "The numbers are kept for notices, the pack and the things to place."
	else:
		var had := Keys.action_of(k)
		Keys.set_bind(a, k)
		bind_msg = ("%s now does “%s”. “%s” %s." % [Keys.key_name(k), _act_label(a), _act_label(had), ("keeps " + Keys.all_names(had)) if Keys.keys_of(had).size() else "has no key now"]) if had != "" and had != a else "%s it is." % Keys.key_name(k)
	menu()


static func _act_label(a: String) -> String:
	for y in Keys.ACTIONS:
		if y[0] == a: return y[1]
	return a


# ---------------------------------------------------------------- a place's notice
func notice(id: String, page: String, force: bool = false) -> void:
	var d := Notices.data(m.R, id, m.me, page)
	if d.is_empty():
		return
	var sig := str(d) + str(Settings.binds)
	if sig == notice_sig and w.is_open("notice") and not force:
		return
	notice_sig = sig
	w.open("notice", d.title, d.intro, 600, 580, m.me.state != "inn", false)
	var n := 0
	for o in d.o:
		if o.has("head"):
			w.head(o.head)
			continue
		n += 1
		var i := n - 1
		w.option(n, o.label, o.get("sub", ""), o.ok, func(): m.option(i))
	w.hint("Press the number, or click." + ("" if m.me.state == "inn" else " Walk away or press Esc to close."))


# ---------------------------------------------------------------- your pack, as slots
var _pack_sig := ""
var _info: Label

func pack(force: bool = false) -> void:
	var p: E.Player = m.me
	var sig := str([p.inv, p.wpn, p.head, p.body, p.off, p.trk, p.bless, p.holy, p.books, p.bodies, p.bbod, p.coin >= D.BLESS_FEE, Settings.binds])
	if sig == _pack_sig and w.is_open("pack") and not force:
		return
	_pack_sig = sig
	var W: Dictionary = D.IT[p.wpn]
	w.open("pack", "Your pack", "In your hand: %s. {trick}: %s, %s." % [W.n, D.AB[W.ab].n, D.AB[W.ab].d], 640, 560, true, false)
	w.head("On you")
	var on := HBoxContainer.new()
	on.add_theme_constant_override("separation", 8)
	w.body.add_child(on)
	for k in D.SLOTS:
		var id: int = p.get(k)
		var has_it: bool = id >= 0 and not (k != "wpn" and id == 0)
		var tip := (D.it_cap(id) + ". " + (Notices.item_sub(p, id) if Notices.item_sub(p, id) != "" else "Everyone has one. It cannot be put away.") + (" Click to put it away." if id > 0 else "")) if has_it else ""
		var blessed: bool = (k == "wpn" and p.bless & 1) or (k == "trk" and p.bless & 2)
		var slot: String = k
		_slot(on, id if has_it else -1, Notices.SLOTN[k], "", tip, blessed, func(): m.inv_do("uneq", slot), Callable())
	w.head("In your pack (%d of %d)" % [p.inv.size(), D.PACK_MAX])
	var inv := HBoxContainer.new()
	inv.add_theme_constant_override("separation", 8)
	w.body.add_child(inv)
	for i in D.PACK_MAX:
		if i >= p.inv.size():
			_slot(inv, -1, "", str(i + 1), "", false, Callable(), Callable())
			continue
		var id: int = p.inv[i]
		var can := Rules.can_use(p, id)
		var j := i
		_slot(inv, id, "", str(i + 1), "%s. %s Click to %s." % [D.it_cap(id), Notices.item_sub(p, id), Notices.lower(Notices.WEARV[D.IT[id].s])], false,
			func(): m.inv_do("eq", j), func(): m.inv_do("dropi", j), not can)
	_info = w.para("Point at a thing to read about it. Click it to use it or put it away; the little cross drops it on the ground.", 14, Look.INK_SOFT)
	_info.custom_minimum_size.y = 58
	var bl: Array = Notices.data(m.R, "pack", p, "").o.filter(func(o): return o.get("a") == "bless")
	if bl.size():
		w.head("Blessings")
		for o in bl:
			var arg: String = o.arg
			var bt := Button.new()
			bt.text = o.label
			bt.tooltip_text = Keys.fill(o.sub)
			bt.disabled = not o.ok
			bt.focus_mode = Control.FOCUS_NONE
			bt.alignment = HORIZONTAL_ALIGNMENT_LEFT
			bt.pressed.connect(func(): m.inv_do("bless", arg))
			w.body.add_child(bt)
	w.hint("1 to 6: use it. {swap}: next weapon, without opening this. {pack} or Esc: close. Spare arms can go on the rack in the storehouse.")


func _slot(parent: Control, id: int, label: String, num: String, tip: String, blessed: bool, cb: Callable, drop: Callable, locked: bool = false) -> void:
	var box := Control.new()
	box.custom_minimum_size = Vector2(88, 96)
	parent.add_child(box)
	var b := Button.new()
	b.set_anchors_preset(Control.PRESET_FULL_RECT)
	b.focus_mode = Control.FOCUS_NONE
	b.disabled = id < 0
	var st := Look.card(Color("fff6dc") if id >= 0 else Color(Look.PAPER, 0.4), Look.OUTLINE if id >= 0 else Color(Look.OUTLINE, 0.3), 4)
	st.shadow_size = 0
	b.add_theme_stylebox_override("normal", st)
	b.add_theme_stylebox_override("disabled", st)
	var hv := Look.card(Color("fffbe9"), Look.ROSE, 4); hv.shadow_size = 0
	b.add_theme_stylebox_override("hover", hv)
	b.add_theme_stylebox_override("pressed", hv)
	box.add_child(b)
	if cb.is_valid(): b.pressed.connect(cb)
	if tip != "":
		b.mouse_entered.connect(func(): if _info: _info.text = Keys.fill(tip))
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_top = 4; v.offset_bottom = -4; v.offset_left = 2; v.offset_right = -2
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 0)
	box.add_child(v)
	if num != "":
		var nl := Look.label(v, num, 11, Look.ROSE)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if id >= 0:
		var ic := TextureRect.new()
		ic.texture = Look.icon(id, 40)
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.custom_minimum_size = Vector2(40, 40)
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if locked: ic.modulate = Color(1, 1, 1, 0.4)
		v.add_child(ic)
		var nm := Look.label(v, D.IT[id].n + (" ✝" if blessed else ""), 11, Look.INK if not locked else Color(Look.INK, 0.5))
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nm.custom_minimum_size.x = 80
	if label != "":
		var ll := Look.label(v, label, 11, Look.INK_SOFT)
		ll.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for c in v.get_children(): c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if drop.is_valid():
		var x := Button.new()
		x.text = "✕"
		x.tooltip_text = "Drop it on the ground"
		x.focus_mode = Control.FOCUS_NONE
		x.add_theme_font_size_override("font_size", 11)
		x.position = Vector2(64, -6)
		x.size = Vector2(26, 24)
		x.pressed.connect(drop)
		box.add_child(x)


# ---------------------------------------------------------------- dawn, and the end
func dawn(day: int, lines: Array) -> void:
	w.open("dawn", "Day %d of %d" % [day, D.LAST_DAY], "", 620, minf(560, 250 + 52 * lines.size()), true)
	for l in lines:
		w.para("•  " + l, 16)
	w.foot_button("To work", func(): w.close(), true)
	w.hint("Esc closes this. It says where the stone, the iron and the fish are today; so does the map.")


func ending(won: bool) -> void:
	var R: Rules = m.R
	w.open("end", "The first week is over" if won else "The keep has fallen", "", 620, 520, false)
	w.para("Thornhallow has held for seven nights, and the Steward has gone back up the hill in several pieces. Robert Bailiff has opened an upstairs window to say that it all went exactly as he planned." if won else "The dead reached the families in the keep. Robert Bailiff’s door remains bolted.", 16)
	if won:
		for l in R.dawn.lines: w.para("•  " + l, 14, Look.INK_SOFT)
	w.para("Undead put down: %d  ·  Peasants lost: %d  ·  Defences built: %d  ·  Keep: %d of %d" % [R.stats.kills, R.stats.lost, R.stats.built, maxi(0, roundi(R.keepHp)), roundi(D.KEEP_HP)], 15, Look.RUST)
	w.para("That was the first week of the month. Nights 8 to 30 arrive in later builds." if won else "Day %d was saved at dawn, so you can have it again." % R.day, 14, Look.INK_SOFT)
	w.foot_button("Home", func(): m.to_home())
	if won:
		w.foot_button("Start a new week", func(): m.begin(null), true)
	else:
		w.foot_button("Try day %d again" % R.day, func(): m.begin(m.read_save()), true)
