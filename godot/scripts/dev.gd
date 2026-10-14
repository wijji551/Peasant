class_name Dev
extends RefCounted
## The test copy (version 7.15). The same game, with a developer console in the handbook: go to any day, everything
## always full, and a handful of short cuts for trying things out. It is on when the game file's name has "test" in it
## (Thornhallow-Test.exe), or when DTV_DEV is set. Its saved game is kept
## apart from the real one, so testing never spoils a month in progress.

static var _on := -1
static var full := true              # every material, coin, potion and fire rock kept full
static var safe := false             # nothing can hurt you


static func on() -> bool:
	if _on < 0:
		var exe := OS.get_executable_path().get_file().to_lower()
		_on = 1 if (exe.contains("test") and not exe.begins_with("godot")) or OS.get_environment("DTV_DEV") != "" else 0
	return _on == 1


## Called every moment on the host: keep everyone topped up, and (if asked) unhurt.
static func step(R: Rules) -> void:
	if not on(): return
	for p in R.players:
		if full:
			var c := Rules.cap(p)
			for k in ["wood", "stone", "iron", "food", "steel", "mith", "rune"]:
				if p.get(k) < c: p.set(k, c)
			if p.coin < 9600: p.coin = 9600                       # forty gold pieces
			for k in ["pot_a", "pot_s", "pot_d", "pot_i"]:
				if p.get(k) < 3: p.set(k, 3)
			if p.frock < 3: p.frock = 3
		if safe and (p.state == "ok" or p.state == "down"):
			p.state = "ok"; p.hp = Rules.max_hp(p); p.frozen = 0.0


## Every book but the two callings, at rank r (and the slots to hold them).
static func books(p: E.Player, r: int) -> void:
	for b in D.BOOKS.size():
		if Rules.is_class_book(b): continue
		p.books[b] = r
		p.xp[b] = float(Rules.need_xp(b, r - 1)) if r > 1 else 0.0
	p.xslot = true


static func calling(p: E.Player, c: int) -> void:   # 0 a priest, 1 a jester (all three lessons), -1 neither
	p.books[D.B_HOLY] = 10 if c == 0 else 0
	p.books[D.B_JEST] = 10 if c == 1 else 0
	p.jl = 3 if c == 1 else 0
	p.holy = 2 if c == 0 else p.holy


## One of every relic, the relic boots, the Tithe Collector and a set of rune arms and armour, on the storehouse rack.
static func rack(R: Rules) -> void:
	for id in D.RELICS + D.BOOT_RELICS:
		if not R.items.has(id): R.items.append(id)
		if not R.relics.has(id): R.relics.append(id)
	for b in D.STEEL_W + D.BOWS + D.ARMOUR:
		var id := D.tier_item(b, "rune")
		if id >= 0 and not R.items.has(id): R.items.append(id)
