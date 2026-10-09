class_name Notices
extends RefCounted
## What each place offers: the notice that opens when you hold E at the market, the smithy, the storehouse,
## the library, the slum, the Thorny Rose Inn or the priest, and your own pack.
## Each option is {label, sub, ok, a (the action), arg} or {head} for a heading, or {page} to turn to another page.

const WEARV := {"w": "Take in hand", "h": "Put on", "b": "Put on", "o": "Take up", "t": "Carry"}
const SLOTN := {"wpn": "In hand", "head": "Head", "body": "Body", "off": "Off hand", "trk": "Carried"}


static func lower(t: String) -> String:
	return t[0].to_lower() + t.substr(1) if t.length() else t

static func book_need(n: Array) -> String:
	return "rank %d of %s" % [n[1], D.BOOKS[n[0]].name]

static func item_sub(p: E.Player, id: int) -> String:   # one line about a thing, for a notice
	var I: Dictionary = D.IT[id]
	var t := ""
	if I.s == "w":
		var A: Dictionary = D.AB[I.ab]
		t = "%d damage%s%s. {trick}: %s, %s." % [I.dmg, ", ranged" if I.rng else "", ", holy" if I.holy else "", A.n, A.d]
	elif I.cut:
		t = "Takes %d%% off every blow%s%s." % [roundi(I.cut * 100), (" and stops %d%% of arrows" % roundi(I.arrow * 100)) if I.arrow else "", ", and slows you a little" if I.slow else ""]
	if I.note != "" and I.s != "w":
		t += (" " if t != "" else "") + I.note + "."
	if not I.need.is_empty() and not Rules.can_use(p, id):
		t += " You cannot use it yet: it needs %s." % book_need(I.need)
	return t


static func data(R: Rules, id: String, p: E.Player, page: String) -> Dictionary:
	var o := []
	match id:
		"market":
			var pr := func(n: int) -> int: return floori(n * 1.5) if p.gab else n
			o.append({"head": "Sell"})
			for r in D.RES:
				o.append({"label": "Sell 5 " + r, "sub": "for %dd. You carry %d." % [pr.call(mini(5, p.get(r))), p.get(r)], "ok": p.get(r) > 0, "a": "sell", "arg": r})
			o.append({"head": "Buy"})
			for r in D.RES:
				o.append({"label": "Buy 5 " + r, "sub": "for 10d", "ok": p.coin >= 2 and p.get(r) < Rules.cap(p), "a": "buy", "arg": r})
			return {"title": "The market", "intro": "You have %s. " % D.coins(p.coin) + ("You have the Gift of the Gab: the stalls pay you three pence for every two pieces, and still charge two a piece." if p.gab else "The stalls pay a penny a piece and charge two."), "o": o}
		"store":
			if page == "arms":
				o.append({"head": "Put on the rack"})
				for i in p.inv.size():
					o.append({"label": "Put in: " + D.IT[p.inv[i]].n, "sub": "From your backpack.", "ok": true, "a": "puti", "arg": i})
				for k in D.SLOTS:
					if p.get(k) > 0:
						o.append({"label": "Put in: " + D.IT[p.get(k)].n, "sub": "It is in your hand. You go back to the pitchfork." if k == "wpn" else "You are wearing it.", "ok": true, "a": "pute", "arg": k})
				o.append({"head": "Take from the rack"})
				for i in R.items.size():
					var it: int = R.items[i]
					o.append({"label": "Take: " + D.IT[it].n, "sub": item_sub(p, it), "ok": p.inv.size() < D.PACK_MAX or Rules.wears_now(p, it), "a": "takei", "arg": i})
				o.append({"label": "Back to the materials", "sub": "", "ok": true, "page": ""})
				return {"title": "The arms rack", "intro": "Spare arms, shared by the whole village: %d on the rack. Your backpack holds %d of %d." % [R.items.size(), p.inv.size(), D.PACK_MAX], "o": o}
			o.append({"head": "Put in"})
			for r in D.RES:
				o.append({"label": "Put in your " + r, "sub": "You carry %d." % p.get(r), "ok": p.get(r) > 0, "a": "put", "arg": r})
			o.append({"head": "Take out"})
			for r in D.RES:
				o.append({"label": "Take 5 " + r, "sub": "%d inside" % R.store[r], "ok": R.store[r] > 0 and p.get(r) < Rules.cap(p), "a": "take", "arg": r})
			o.append({"head": "Spare arms"})
			o.append({"label": "The arms rack", "sub": "%d spare weapon%s and bits of armour. Leave what you do not need for the others." % [R.items.size(), "" if R.items.size() == 1 else "s"], "ok": true, "page": "arms"})
			return {"title": "The storehouse", "intro": "Shared by the whole village. Anyone can put in or take out.", "o": o}
		"smithy":
			var forge := func(i: int) -> void:
				var I: Dictionary = D.IT[i]
				var c := Rules.forge_cost(p, I.cost)
				var locked: bool = I.heavy and Rules.rk(p, 3) < 2
				var sub := "Heavy arms need rank 2 of Hammer and Tongs." if locked else D.cost_text(c) + ". " + \
					(("%s. %d damage. {trick}: %s." % [I.note, I.dmg, D.AB[I.ab].n]) + ("" if Rules.can_use(p, i) else " You cannot use it yet: it needs %s." % book_need(I.need)) if I.s == "w" else item_sub(p, i))
				o.append({"label": "Forge " + D.it_a(i), "sub": sub, "ok": not locked and Rules.has(p, c), "a": "forge", "arg": i})
			if page == "armour":
				o.append({"head": "Armour"})
				for i in D.FORGE_A: forge.call(i)
				var c := Rules.forge_cost(p, D.PEASANT_ARM)
				var un := R.peasants.filter(func(q): return q.owner == p.id and not q.armed and q.state != "body").size()
				o.append({"head": "Your posse"})
				o.append({"label": "Arm your whole posse with spears" if Rules.rk(p, 3) >= 3 else "Arm one of your posse with a spear", "sub": "%s each. %d of yours still %s a pitchfork." % [D.cost_text(c), un, "carries" if un == 1 else "carry"], "ok": un > 0 and Rules.has(p, c), "a": "armp"})
				o.append({"label": "Back to the weapons", "sub": "", "ok": true, "page": ""})
			else:
				o.append({"head": "Weapons"})
				for i in D.FORGE_W: forge.call(i)
				o.append({"head": "More"})
				o.append({"label": "Armour, and spears for your posse", "sub": "Iron cap, chain shirt, shield.", "ok": true, "page": "armour"})
			return {"title": "The smithy", "intro": "You carry %d iron and %d wood. What you forge goes on; what it replaces goes in your backpack." % [p.iron, p.wood] + ("" if p.books[3] else " Hammer and Tongs, in the library, makes all of this cheaper."), "o": o}
		"library":
			var slots := Rules.book_slots(p)
			var owned: int = p.books.filter(func(r): return r > 0).size()
			for b in D.BOOKS.size():
				var B: Dictionary = D.BOOKS[b]
				var r: int = p.books[b]
				var sub := ("%s. %s." % [B.what, B.ranks[0]]) if not r else ("Latest: %s." % lower(B.ranks[r - 1])) + ((" Next: %s (%d of %d, by %s)." % [lower(B.ranks[r]), floori(p.xp[b]), Rules.need_xp(b, r), B.by]) if r < 7 else " You have finished it.")
				o.append({"label": B.name + (" · rank %d of 7" % r if r else ""), "sub": sub, "ok": not r and slots > 0, "a": "book", "arg": b})
			var intro := ("You may take up another book." if owned else "The peasants’ section is one shelf of ten books, with seven ranks in each. Choose your first.") if slots > 0 else ("You have your three books." if owned >= 3 else "Reach rank 2 in a book to take up a second, and rank 3 in two books to take up a third.")
			return {"title": "The library", "intro": intro + (" Cowards learn at half speed today." if p.coward else ""), "o": o}
		"slum":
			var c := {"food": Rules.slum_food(p)}
			var pop := R.peasants.filter(func(q): return q.state != "body").size()
			var full := pop >= R.pop_cap()
			var pfull := p.posse >= R.posse_max(p)
			var sub := "The village has no room for more." if full else ("Your posse is full (%d of %d)." % [p.posse, R.posse_max(p)]) if pfull else "%s%s. You carry %d." % [D.cost_text(c), ", double for a coward" if p.coward else "", p.food]
			o.append({"label": "Recruit a peasant", "sub": sub, "ok": not full and not pfull and Rules.has(p, c), "a": "recruit"})
			return {"title": "The slum", "intro": "There are always more peasants here, and they will follow anyone who feeds them.", "o": o}
		"inn":
			if p.state == "inn":
				o.append({"label": "Drink a tankard", "sub": "Drinking…" if p.drinkT > 0 else ("%d left in the barrel." % R.ale) if R.ale > 0 else "The barrel is empty. Somebody should have brought the innkeeper food.", "ok": R.ale > 0 and p.drinkT <= 0 and p.cg < 100, "a": "drink"})
				o.append({"label": "Unbar the door and go out", "sub": "Sober, more or less.", "ok": true, "a": "innout"})
				return {"title": "Inside the Thorny Rose Inn", "intro": "Dutch courage: %d%%. At 100 you burst out and charge for %d seconds: faster, stronger and tougher. Nothing can reach you in here until the door gives way (%d%% left)." % [p.cg, Rules.charge_len(p), roundi(R.innHp / D.INN_HP * 100)], "o": o}
			var is_day := R.phase == "day"
			o.append({"label": "Give the innkeeper 5 food", "sub": "He turns each piece into a tankard for tonight. %d in the barrel. You carry %d." % [R.ale, p.food], "ok": p.food > 0, "a": "ale"})
			o.append({"label": "Go in and bar the door", "sub": "The Rose opens at dusk." if is_day else "The door is in pieces until morning." if R.innHp <= 0 else "Your posse comes in with you. The dead will try the door.", "ok": not is_day and R.innHp > 0, "a": "innin"})
			return {"title": "The Thorny Rose Inn", "intro": "Dutch courage: %d%%. Drink inside at night until you are brave enough to charge. The innkeeper only has as much ale as the village brings him food that day." % p.cg, "o": o}
		"priest", "pack":
			var here := id == "priest"
			var fee := func(f: bool) -> String: return "Free: you have the learning." if f else D.coins(D.BLESS_FEE) + "."
			var can := func(f: bool) -> bool: return f or (here and p.coin >= D.BLESS_FEE)
			var W: Dictionary = D.IT[p.wpn]
			var bless := func() -> void:
				if here or p.holy >= 1:
					o.append({"label": "Bless your " + W.n, "sub": "It is holy already." if W.holy else "Blessed until dawn." if p.bless & 1 else fee.call(p.holy >= 1) + " Holy until dawn: half as much damage again, and bones stay down.", "ok": not W.holy and not (p.bless & 1) and can.call(p.holy >= 1), "a": "bless", "arg": "w"})
					o.append({"label": "Bless your slop bucket", "sub": "You carry no bucket. The ruins have them." if p.trk != 28 else "Blessed. Heaven help whoever it lands on." if p.bless & 2 else fee.call(p.holy >= 1) + " It will burn as well as stink.", "ok": p.trk == 28 and not (p.bless & 2) and can.call(p.holy >= 1), "a": "bless", "arg": "k"})
				if here or p.holy >= 2:
					o.append({"label": "Bless a body you carry", "sub": "You carry none." if not p.bodies else "%d of %d blessed. " % [p.bbod, p.bodies] + fee.call(p.holy >= 2) + " A blessed body can be built into a wall, gate or barricade.", "ok": p.bbod < p.bodies and can.call(p.holy >= 2), "a": "bless", "arg": "b"})
			if here:
				o.append({"head": "Blessings"})
				bless.call()
				o.append({"head": "Holy studies"})
				var lab := "Holy studies: finished" if p.holy >= 2 else ("In class: %d of %d seconds" % [floori(p.holyT), D.HOLY_TIME]) if p.study else "Sit a class in holy studies (%d of 2 done)" % p.holy
				var sub := "You can bless anything yourself, anywhere, from your backpack ({pack})." if p.holy >= 2 else "Stay beside the priest. Press again to walk out; he will remember where you got to." if p.study else "About %d seconds beside the priest. After one class you can bless your own weapon and bucket for nothing; after two, the departed as well. It does not count as one of your three books." % D.HOLY_TIME
				o.append({"label": lab, "sub": sub, "ok": p.holy < 2, "a": "study"})
				return {"title": "The priest", "intro": "A blessing lasts until dawn. You have %s." % D.coins(p.coin), "o": o}
			if page == "drop":
				o.append({"head": "Throw away"})
				for i in p.inv.size():
					o.append({"label": "Drop: " + D.IT[p.inv[i]].n, "sub": "It stays on the ground where you stand.", "ok": true, "a": "dropi", "arg": i})
				o.append({"label": "Back", "sub": "", "ok": true, "page": ""})
				return {"title": "Your backpack", "intro": "Anything dropped can be picked up again, by anyone.", "o": o}
			o.append({"head": "In your backpack (%d of %d)" % [p.inv.size(), D.PACK_MAX]})
			for i in p.inv.size():
				var it: int = p.inv[i]
				o.append({"label": "%s: %s" % [WEARV[D.IT[it].s], D.IT[it].n], "sub": item_sub(p, it), "ok": Rules.can_use(p, it), "a": "eq", "arg": i})
			var on := D.SLOTS.filter(func(k): return p.get(k) > 0)
			if on.size():
				o.append({"head": "On you"})
				for k in on:
					o.append({"label": "Put away: " + D.IT[p.get(k)].n, "sub": "Your backpack is full." if p.inv.size() >= D.PACK_MAX else "Back to the pitchfork." if k == "wpn" else "", "ok": p.inv.size() < D.PACK_MAX, "a": "uneq", "arg": k})
			if p.holy >= 1:
				o.append({"head": "Blessings"})
				bless.call()
			if p.inv.size():
				o.append({"label": "Throw something away", "sub": "", "ok": true, "page": "drop"})
			return {"title": "Your backpack", "intro": "In your hand: %s. {trick}: %s, %s. Spare arms can go on the rack in the storehouse for the others." % [W.n, D.AB[W.ab].n, D.AB[W.ab].d], "o": o}
	return {}
