extends RefCounted
## What goes in the window: the home screen, the handbook (guide, controls, options), a place's notice,
## your backpack, the dawn notice, and the end of the week. main.gd says which; this fills it in.

const GUIDE := [
	["The short version", ["By day, gather and build. At dusk the bell rings. At night the dead rise along the graveyard to the north, one after another without a pause and faster as the night goes on, and make for the keep, where the families are hiding. If the keep falls, Thornhallow is lost. Hold for seven nights.", "Nearly everything is done by walking up to it and holding {interact}."]],
	["The day", ["A day lasts six minutes, or until everyone presses {ready}.", "Wood comes from trees, stone from the rocky outcrop, iron from the mine, food from the farms to the west or the jetty on the river. The stone, the iron and the fishing move every morning: the dawn notice says where, and the map marks them. You carry 20 of each.", "At the jetty, hold {interact} and press {attack} when something bites."]],
	["Defences", ["The north wall has seven foundations: six walls and a gate. Stand on one and hold {interact}. Barricades and spike rows go anywhere: press {build} or 1 to 4 (or click one, bottom right), then {interact} or click.", "Hold {interact} at a damaged defence to repair it with wood. Carrying stone or iron, hold {interact} again to face a wall with stone, band the gate or brace a barricade. An unbraced barricade rots by half every evening after its first night.", "Nobody can be hit through a standing wall or gate, in either direction. Go out through the gate, or shoot over."]],
	["Your posse", ["Hold {interact} beside a neighbour to rally them. They gather when you gather and fight when you fight. The slum has more, for food. The smithy gives them spears.", "They can die, and they have nerve: when friends fall they may run for the keep until dawn. {toilet} is the emergency toilet break, which sends the dead nearby running. With rank 3 of the leadership book, {orders} tells them to follow, hold or charge."]],
	["Fighting", ["{attack} or a click attacks. {trick} or a right-click is your weapon’s own trick: every weapon has a different one, with a short wait between uses. {eat} eats one food.", "Knocked down, you have 15 seconds for a team-mate to hold {interact} over you. After that a relative takes over your cottage at dawn, with your books but not your gear. Relics lie where you fell.", "From dusk you can hide in your own cottage. It is safe, and the village will call you a coward until the next dusk."]],
	["Things you carry", ["{pack} opens your backpack: what is on you, and six places for spares. Click a thing to use it or put it away. {swap} swaps to the next weapon in the backpack without opening it. {carry} throws a slop bucket or rings a handbell.", "A bow needs the book Slings, Bows and Thrown Turnips, which comes with a sling. A crossbow needs rank 3 of it. Heavy arms need rank 2 of Hammer and Tongs to forge."]],
	["Places", ["The library: three books out of ten, seven ranks each, earned by doing what the book teaches. {skills} shows your books as skill trees: what every rank does and how close the next is. Learning past rank VII is spare, and sells for coin there. The smithy: weapons, armour, spears for the posse. The storehouse: shared materials and a shared arms rack. The market: sells at a penny a piece, buys at two. The slum: recruits.", "The Thorny Rose Inn: bring the innkeeper food by day; from dusk go in, bar the door and drink. At full courage you burst out and charge. The priest, by the chapel: blessings for two shillings, and holy studies.", "The ruins, by the chapel and outside the wall to the south-west and south-east: hold {interact} at a heap of rubble. Relics turn up, more often by moonlight. Searching outside the wall is noisy."]],
	["Playing together", ["Up to eight can play. One of you presses Host a village on the home screen and reads out the village code; the others type it into Join. Everyone gets their own cottage, posse and books; the storehouse, the arms rack and the keep are shared. The host starts the week when everyone is in, and the host's game keeps the save.", "With a village server set (Options), villages go through it: a five-letter code that works from anywhere, and nobody's router matters. Without one, the host's computer asks its router to let friends in; if the router says no, that code only works on the same home network, unless the host opens port 24565 (UDP). The game does not pause for the handbook when others are playing."]],
	["Reading the screen", ["Top left: the day and the time left, and whether you are ready. Top middle: the keep, and the Steward when he comes. Top right: the map. Left: what you carry. Bottom: your hand, bucket, posse, backpack, skills and toilet break, with their keys, and the four things you can place, bottom right. What holding {interact} would do shows just above the bar at the bottom.", "Places, your backpack, the dawn and this handbook all open in one window in the middle. Esc closes it, or the cross; walking away closes a place's notice."]],
]

const CHANGES := [
	["Godot: the village server is open", [
		"The game now has its own village server, always on, in London. Host and Join use it by themselves: nothing to type, no routers to fiddle with. Hosting gives a five-letter code; send it to your friends.",
		"Your own server can still go in the handbook's Options, if you ever want one.",
	]],
	["Godot: the village server", [
		"Playing together can now go through a village server: a small program on an always-on machine (a free Oracle Cloud one will do) that introduces players and passes their messages on. Nobody's router has to let anyone in, and your friends can host their own villages when you are not on.",
		"A village on the server has a five-letter code. Older codes (with a dash) still work, straight to the host.",
		"Put the server's address in the handbook's Options. If the server does not answer, hosting falls back to your own computer.",
	]],
	["Godot: playing together (stage 5 of the move: the move is done)", [
		"Up to eight in one village. Host a village from the home screen and give your friends the code; they type it into Join.",
		"Your computer asks your router to let them in by itself. If your router will not, the code still works for anyone on the same wifi.",
		"A lobby shows who has come; the host starts the week, or carries on from the saved morning. The host's game keeps the save.",
		"Your own walking happens at once on your screen; everything else follows the host's game, twelve times a second.",
		"If someone's connection goes, their relics stay in the village and their posse goes home. If the host leaves, everyone is sent home and told so.",
	]],
	["Godot: sound (stage 4 of the move)", [
		"Every sound from the web version, made again, and new ones: the dead groaning and rattling as they come near, crows, an owl, thunder after the lightning, a knock, a creaking door, a page turning when a window opens.",
		"Birds and a breeze by day, crickets and wind at night, rain when it rains, and a low moaning drone the closer you get to the castle.",
		"Two tunes: a lute in the village by day, and something slower and less friendly at night.",
		"The handbook's options have a volume for everything, the effects, the ambience and the music. M mutes it all.",
	]],
	["Godot: the look of the place", [
		"Proper medieval lettering, and every card and button is now torn parchment, like the scroll.",
		"What you carry says what it is, with pictures that look like wood, stone, iron, food and coin.",
		"Your pack is now your Backpack. It was always a backpack. It feels better for the name.",
		"The books have moved to a Skills window (K): each book is a ladder of seven ranks showing what every rank does and how near the next one is. Past rank VII, extra learning becomes spare points you can sell for coin.",
		"The game opens in a bigger window, and the home screen is smaller.",
		"Fixed: a notice after the home screen sat off to the right and down. Fixed: trees outside the hedge showed on the map.",
		"Bailiff’s House and the Thorny Rose Inn, by their proper names. The chapel looks like a chapel: a bell tower, a spire, coloured windows. The priest wears white and gold and is, frankly, glowing.",
		"The haybales are haybales, not tents.",
		"The two outer ruins wander off to a new clearing every night, and nobody is told where. Find one and it goes on the map for everyone.",
		"Mist creeps over the ground at night and never quite leaves the castle. Some days it rains, some are grey, some misty. Chimneys smoke.",
		"Ashhollow is haunted now: dead trees, a gibbet, green fires at the gate, purple windows, will-o’-wisps, crows, and lightning at night.",
		"Smoother edges (anti-aliasing).",
	]],
	["Godot: stage 3, patched", [
		"Clicking the mouse no longer crashes the game. It asked the old readouts whether a notice was open, and they had been thrown out. They did not answer, and the game took it badly.",
	]],
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
	var b: VBoxContainer = w.open("home", "Defend the Village!", "", 820, 560, false, false)
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
	# playing together
	Look.label(left, "PLAY TOGETHER (UP TO 8)", 13, Look.RUST)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	left.add_child(row)
	var hb := Button.new(); hb.text = "Host a village"; hb.focus_mode = Control.FOCUS_NONE
	hb.pressed.connect(func(): _host())
	row.add_child(hb)
	var jc := LineEdit.new(); jc.placeholder_text = "Village code"; jc.custom_minimum_size.x = 150; jc.max_length = 21
	jc.text_submitted.connect(func(t): _join(t))
	row.add_child(jc)
	var jb := Button.new(); jb.text = "Join"; jb.focus_mode = Control.FOCUS_NONE
	jb.pressed.connect(func(): _join(jc.text))
	row.add_child(jb)
	var note: String = Net.me.status
	if note != "" and not Net.me.online():
		var nl := Look.para(left, note, 14, Look.ROSE)
		nl.custom_minimum_size.x = 300
		Net.me.status = ""
	w.foot_button("Handbook: guide, controls, options", func(): menu("guide"))
	w.hint("%s move · %s attacks · hold %s to do things · Esc: the handbook" % [
		" ".join(["up", "left", "down", "right"].map(func(a): return Keys.name(a))), Keys.name("attack"), Keys.name("interact")])
	# the change log
	var right := PanelContainer.new()
	right.add_theme_stylebox_override("panel", Look.card(Color("f3e2b0"), Color(Look.OUTLINE, 0.5), 12))
	right.custom_minimum_size.x = 300
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
		b.add_theme_stylebox_override("hover", Look.primary_hover())
		b.add_theme_stylebox_override("pressed", Look.primary_hover())
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
			w.para("Fixed: a click attacks and a right-click is your weapon’s trick. The numbers pick from a notice, your backpack, or the things to place. Esc closes whatever is open, and otherwise opens this handbook.", 14, Look.INK_SOFT)
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
			for row in [["All sound", "vol"], ["Effects", "fx_vol"], ["Birds, wind and rain", "amb_vol"], ["Music", "music_vol"]]:
				Look.label(g, row[0], 15)
				var vh := HBoxContainer.new(); g.add_child(vh)
				var vs := HSlider.new(); vs.min_value = 0; vs.max_value = 100; vs.step = 5; vs.value = Settings.volume(row[1]); vs.custom_minimum_size.x = 180
				var vl := Look.label(vh, "", 15)
				vh.add_child(vs); vh.move_child(vs, 0)
				var key: String = row[1]
				vl.text = "%d%%" % Settings.volume(key) if Settings.volume(key) else "off"
				vs.value_changed.connect(func(v): Settings.set_volume(key, int(v)); vl.text = "%d%%" % int(v) if v else "off"; Settings.save(); Sound.apply_settings(); Sound.play("pop"))
			Look.label(g, "Mute (%s)" % Keys.name("mute"), 15)
			var mu := CheckBox.new(); mu.button_pressed = Settings.muted; mu.toggled.connect(func(on): Settings.muted = on; Settings.save(); Sound.apply_settings()); g.add_child(mu)
			Look.label(g, "Village server, for playing together", 15)
			var rv := LineEdit.new()
			rv.text = Settings.relay
			rv.placeholder_text = Net.DEFAULT_RELAY if Net.DEFAULT_RELAY != "" else "none: host from this computer"
			rv.custom_minimum_size.x = 260
			rv.text_changed.connect(func(t): Settings.relay = t.strip_edges(); Settings.save())
			g.add_child(rv)
			Look.label(g, "Names over the other players", 15)
			var tg := CheckBox.new(); tg.button_pressed = Settings.tags; tg.toggled.connect(func(on): Settings.tags = on; Settings.save()); g.add_child(tg)
			Look.label(g, "See through the keep when something is behind it", 15)
			var sk := CheckBox.new(); sk.button_pressed = Settings.see_keep; sk.toggled.connect(func(on): Settings.see_keep = on; Settings.save()); g.add_child(sk)
			w.para("These are kept on this computer.", 13, Look.INK_SOFT)
	var code_txt := ""
	if Net.me.is_host(): code_txt = "  Village code: %s." % (Net.me.code if Net.me.code != "" else Net.me.lan_code)
	w.hint(("The game goes on while you read: the others are still out there." if Net.me.online() else "The game waits while you read." if in_game else "") + code_txt)
	if in_game:
		var lv: Button = w.foot_button("Leave the village", func(): _leave())
		lv.tooltip_text = "Back to the home screen. The village was saved this morning."
	w.foot_button("Back to the game" if in_game else "Close", func(): w.close(), true)


var _leave_armed := false
func _leave() -> void:
	if not _leave_armed:
		_leave_armed = true
		bind_msg = ""
		w.hint("Really? That closes the village for everyone. Press it again." if Net.me.is_host() else "Really leave? Press it again." if Net.me.is_client() else "Really leave? Press it again. You will carry on from this morning next time.")
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
		bind_msg = "The numbers are kept for notices, the backpack and the things to place."
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


# ---------------------------------------------------------------- your backpack, as slots
var _pack_sig := ""
var _info: Label

func pack(force: bool = false) -> void:
	var p: E.Player = m.me
	var sig := str([p.inv, p.wpn, p.head, p.body, p.off, p.trk, p.bless, p.holy, p.books, p.bodies, p.bbod, p.coin >= D.BLESS_FEE, Settings.binds])
	if sig == _pack_sig and w.is_open("pack") and not force:
		return
	_pack_sig = sig
	var W: Dictionary = D.IT[p.wpn]
	w.open("pack", "Your backpack", "In your hand: %s. {trick}: %s, %s." % [W.n, D.AB[W.ab].n, D.AB[W.ab].d], 640, 560, true, false)
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
	w.head("In your backpack (%d of %d)" % [p.inv.size(), D.PACK_MAX])
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


# ---------------------------------------------------------------- playing together
func _host() -> void:
	var why: String = Net.me.host(Settings.name if Settings.name != "" else "Peasant", Settings.col)
	if why != "":
		Net.me.status = why
		home()
		return
	var saved = m.read_save()
	Net.me.saved_day = int(saved.day) if saved else 0
	lobby()


func _join(text: String) -> void:
	var why: String = Net.me.join(text, Settings.name if Settings.name != "" else "Peasant", Settings.col)
	if why != "":
		Net.me.status = why
		home()
		return
	lobby()


## Who is coming: the code to give your friends, and everyone who has joined. The host starts the week.
func lobby() -> void:
	var N: Net = Net.me
	if not N.online():                               # the connection has gone (or never came): back home, saying why
		home()
		return
	var host := N.is_host()
	var b: VBoxContainer = w.open("lobby", "Your village" if host else "Joining a village", "", 640, 540, false, false)
	if host:
		w.head("The village code")
		var cr := HBoxContainer.new()
		cr.add_theme_constant_override("separation", 14)
		b.add_child(cr)
		var shown: String = N.code if N.code != "" else ("....." if N.via_relay else N.lan_code)
		var cl := Look.label(cr, shown, 34, Look.INK, true)
		cl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cp := Button.new(); cp.text = "Copy"; cp.focus_mode = Control.FOCUS_NONE
		cp.pressed.connect(func(): DisplayServer.clipboard_set(shown); cp.text = "Copied")
		cr.add_child(cp)
		match N.port_open:
			"relay": w.para("Friends type this into Join on their home screen. It works from anywhere: everyone goes through the village server.", 14, Look.INK_SOFT)
			"trying": w.para("Asking the village server for a code..." if N.via_relay else "Asking your router to let friends in...", 14, Look.INK_SOFT)
			"open": w.para("Friends type this into Join on their home screen. On the same home network, %s works too." % N.lan_code, 14, Look.INK_SOFT)
			_: w.para("Your router would not open the way in by itself, so this is the code for your home network only: it works for anyone on the same wifi. For friends elsewhere, open port %d (UDP) to this computer on your router, then give them your internet address instead." % N.PORT, 14, Look.ROSE)
	elif N.my_id == 0:
		w.para(N.status if N.status != "" else "Knocking on the village gate...", 16, Look.INK)
	w.head("Who is here (%d of %d)" % [N.lobby.size(), N.MAX_PLAYERS])
	for l in N.lobby:
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 10)
		b.add_child(r)
		var dot := Panel.new()
		var st := StyleBoxFlat.new(); st.bg_color = Color(D.PCOL[int(l.col) % 8]); st.set_corner_radius_all(9); st.border_color = Look.INK; st.set_border_width_all(1)
		dot.add_theme_stylebox_override("panel", st)
		dot.custom_minimum_size = Vector2(18, 18)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		r.add_child(dot)
		Look.label(r, str(l.name) + ("  (host)" if int(l.id) == 1 else "") + ("  (you)" if int(l.id) == N.my_id else ""), 18)
	if host:
		w.foot_button("Close the village", func(): N.leave(); home())
		if N.saved_day > 0:
			w.foot_button("Carry on from day %d" % N.saved_day, func(): m.begin(m.read_save()))
		w.foot_button("Start a new week", func(): m.begin(null), true)
		w.hint("Start when everyone is in. Nobody can join once the week has begun.")
	else:
		w.foot_button("Leave", func(): N.leave(); home())
		w.hint("Waiting for the host to start." if N.my_id != 0 else "")


# ---------------------------------------------------------------- skills: each book as a ladder of seven ranks
var skill_book := -1
var _skills_sig := ""
const ROMAN := ["", "I", "II", "III", "IV", "V", "VI", "VII"]

func skills(force: bool = false) -> void:
	var p: E.Player = m.me
	var owned: Array = []
	for i in 10:
		if p.books[i] > 0: owned.append(i)
	if skill_book < 0 or not owned.has(skill_book):
		skill_book = owned[0] if owned.size() else -1
	var sig := str(p.books) + str(p.xp.map(func(x): return floori(x))) + str(floori(p.spare)) + str(skill_book) + str(p.coward)
	if not force and w.is_open("skills") and sig == _skills_sig:
		return
	_skills_sig = sig
	var slots := Rules.book_slots(p)
	w.open("skills", "Your skills", "Every book is learned by doing what it teaches, and each rank takes more practice than the last." + (" You can take %s more from the library." % ("one" if slots == 1 else str(slots)) if slots > 0 else ""), 940, 640, true, true)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 18)
	w.body.add_child(cols)
	# left: the ten books
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 270
	left.add_theme_constant_override("separation", 4)
	cols.add_child(left)
	for i in 10:
		var bk: Dictionary = D.BOOKS[i]
		var bt := Button.new()
		bt.focus_mode = Control.FOCUS_NONE
		bt.toggle_mode = true
		bt.button_pressed = i == skill_book
		bt.disabled = p.books[i] == 0
		bt.alignment = HORIZONTAL_ALIGNMENT_LEFT
		bt.text = ("%s   %s" % [ROMAN[p.books[i]], bk.what]) if p.books[i] else "—   " + bk.what
		bt.tooltip_text = bk.name if p.books[i] else bk.name + ". In the library."
		bt.add_theme_font_size_override("font_size", 16)
		var bi := i
		bt.pressed.connect(func(): skill_book = bi; skills.call_deferred(true))
		left.add_child(bt)
	# right: the chosen book's ranks
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 0)
	cols.add_child(right)
	if skill_book < 0:
		Look.para(right, "No book yet. The library has one waiting for you: walk in and hold {interact}.".replace("{interact}", Keys.name("interact")), 18, Look.INK_SOFT)
	else:
		var b := skill_book
		var bk: Dictionary = D.BOOKS[b]
		var rank: int = p.books[b]
		Look.label(right, bk.name, 26, Look.INK, true)
		Look.para(right, "%s. You learn it by %s.%s" % [bk.what, bk.by, " Halved while you are a coward." if p.coward else ""], 15, Look.INK_SOFT)
		var gap := Control.new(); gap.custom_minimum_size.y = 8; right.add_child(gap)
		for r in range(1, 8):
			var got := rank >= r
			var next := rank + 1 == r
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 12)
			right.add_child(row)
			var med := PanelContainer.new()
			var ms := StyleBoxFlat.new()
			ms.bg_color = Look.GOLD if got else Color("efe0b6") if next else Color("e2d3aa")
			ms.border_color = Look.OUTLINE if got or next else Color(Look.OUTLINE, 0.35)
			ms.set_border_width_all(2)
			ms.set_corner_radius_all(20)
			med.add_theme_stylebox_override("panel", ms)
			med.custom_minimum_size = Vector2(40, 40)
			med.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			row.add_child(med)
			var num := Look.label(med, ROMAN[r], 17, Look.INK if got or next else Color(Look.INK, 0.4))
			num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			var tv := VBoxContainer.new()
			tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			tv.add_theme_constant_override("separation", 1)
			row.add_child(tv)
			var t := Look.para(tv, Keys.fill(bk.ranks[r - 1]), 16, Look.INK if got else Look.INK_SOFT if next else Color(Look.INK_SOFT, 0.6))
			if next:
				var lo := Rules.need_xp(b, rank - 1) if rank > 1 else 0
				var hi := Rules.need_xp(b, rank)
				var f := clampf((p.xp[b] - lo) / float(hi - lo), 0, 1)
				var bar := ProgressBar.new()
				bar.custom_minimum_size = Vector2(0, 8)
				bar.show_percentage = false
				bar.max_value = 1.0
				bar.value = f
				var bg := StyleBoxFlat.new(); bg.bg_color = Color("3a2d22"); bg.set_corner_radius_all(3)
				var fg := StyleBoxFlat.new(); fg.bg_color = Look.GOLD; fg.set_corner_radius_all(3)
				bar.add_theme_stylebox_override("background", bg)
				bar.add_theme_stylebox_override("fill", fg)
				tv.add_child(bar)
				Look.label(tv, "Next rank: %d%% of the way" % roundi(f * 100), 13, Look.RUST)
			if r < 7:                                              # the line joining one rank to the next
				var link := HBoxContainer.new()
				right.add_child(link)
				var stem := ColorRect.new()
				stem.color = Look.GOLD if rank > r else Color(Look.OUTLINE, 0.3)
				stem.custom_minimum_size = Vector2(4, 10)
				var pad := Control.new(); pad.custom_minimum_size.x = 18
				link.add_child(pad); link.add_child(stem)
		if rank >= 7:
			var done := Look.para(right, "Mastered. What you learn from this book now is spare.", 15, Look.RUST)
			done.custom_minimum_size.y = 26
	# spare learning, sold for coin
	w.head("Spare learning")
	var sp := floori(p.spare)
	var srow := HBoxContainer.new()
	srow.add_theme_constant_override("separation", 14)
	w.body.add_child(srow)
	var st := Look.para(srow, ("%d spare point%s, worth %s." % [sp, "" if sp == 1 else "s", D.coins(sp * D.SPARE_PAY)]) if sp > 0 else "When a book reaches rank VII, whatever more you learn from it is kept here as spare points, and sold for %s each." % D.coins(D.SPARE_PAY), 15, Look.INK_SOFT)
	st.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sell := Button.new()
	sell.text = "Sell for coin"
	sell.disabled = sp <= 0
	sell.focus_mode = Control.FOCUS_NONE
	sell.pressed.connect(func(): m.sell_spare())
	srow.add_child(sell)
	w.hint("{skills} or Esc: close.")


func _slot(parent: Control, id: int, label: String, num: String, tip: String, blessed: bool, cb: Callable, drop: Callable, locked: bool = false) -> void:
	var box := Control.new()
	box.custom_minimum_size = Vector2(88, 96)
	parent.add_child(box)
	var b := Button.new()
	b.set_anchors_preset(Control.PRESET_FULL_RECT)
	b.focus_mode = Control.FOCUS_NONE
	b.disabled = id < 0
	var st := Look.card(Color("fff6dc") if id >= 0 else Color("e2cf9c"), Look.OUTLINE if id >= 0 else Color("8a7556"), 4)
	if id < 0: b.self_modulate = Color(1, 1, 1, 0.6)
	b.add_theme_stylebox_override("normal", st)
	b.add_theme_stylebox_override("disabled", st)
	var hv := Look.card(Color("fffbe9"), Look.ROSE, 4)
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
	if Net.me.is_client():
		w.hint("The host chooses what happens next.")
	elif won:
		w.foot_button("Start a new week", func(): m.begin(null), true)
	else:
		w.foot_button("Try day %d again" % R.day, func(): m.begin(m.read_save()), true)
