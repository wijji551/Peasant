class_name Notices
extends RefCounted
## What each place offers: the notice that opens when you hold E at the market, the smithy, the storehouse,
## the library, the slum, the Thorny Rose Inn or the priest, and your own pack.
## Each option is {label, sub, ok, a (the action), arg} or {head} for a heading, or {page} to turn to another page.

const WEARV := {"w": "Take in hand", "h": "Put on", "b": "Put on", "o": "Take up", "t": "Carry", "c": "Read", "k": "Hand to one of your posse"}
const SLOTN := {"wpn": "In hand", "head": "Head", "body": "Body", "off": "Off hand", "trk": "Carried", "feet": "Feet"}


static func lower(t: String) -> String:
	return t[0].to_lower() + t.substr(1) if t.length() else t

static func book_need(n: Array) -> String:
	return "rank %d of %s" % [n[1], D.book_title(n[0])]

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
	if D.RELIC_LORE.has(id):                         # what it does with the book it goes with
		var L: Array = D.RELIC_LORE[id]
		t += " With %s: %s.%s" % [D.book_title(L[0]), lower(L[1]), " (You have it.)" if Rules.rk(p, L[0]) > 0 else ""]
	if not I.need.is_empty() and not Rules.can_use(p, id):
		t += " You cannot use it yet: it needs %s." % book_need(I.need)
	return t


## The Lord of Ashhollow's letters: one of them (page "l<n>"), or the list of them all.
static func letters_page(R: Rules, page: String, title: String, intro: String, back: String) -> Dictionary:
	var o := []
	var one := int(page.substr(1)) if page.begins_with("l") and page != "letters" else -1
	if one >= 0 and one < R.letters.size():
		var L: Dictionary = D.LETTERS[R.letters[one][0]]
		o.append({"text": "To the Occupants, Thornhallow."})
		o.append({"text": L.t})
		o.append({"text": D.LETTER_SIGN})
		if R.letters.size() > 1: o.append({"label": "His earlier letters", "sub": "%d in all." % R.letters.size(), "ok": true, "page": "letters"})
		if back != "": o.append({"label": back, "sub": "", "ok": true, "page": ""})
		return {"title": "%s: %s" % ["The Lord’s letter" if back != "" else title, L.sub], "intro": "It came on the morning of day %d, by headless rider." % R.letters[one][1], "o": o}
	o.append({"head": "The newest first"})
	for i in range(R.letters.size() - 1, -1, -1):
		var L: Dictionary = D.LETTERS[R.letters[i][0]]
		o.append({"label": "Day %d: %s" % [R.letters[i][1], L.sub], "sub": L.t.substr(0, 78) + "…", "ok": true, "page": "l%d" % i})
	if back != "": o.append({"label": back, "sub": "", "ok": true, "page": ""})
	return {"title": "The Lord’s letters", "intro": intro if intro != "" else "All of them, nailed one on top of another.", "o": o}


## A watch tower's notice: who is up it, and the two choices (send one up, coax one down), and the upkeep.
static func tower_page(R: Rules, i: int, p: E.Player) -> Dictionary:
	var s := R.tower(i)
	if s == null: return {}
	var o := []
	var crew := R.tower_crew(s)
	var mine := crew.filter(func(q): return q.owner == p.id)
	var free := R.peasants.any(func(q): return q.owner == p.id and (q.kind == 0 or q.kind == 2) and q.plat == 0 and Rules.active(q))
	var full := crew.size() >= D.TOWER.seats
	var names := []
	for q in crew:
		var own := R.player_by_id(q.owner)
		names.append(D.qname(q) + (" (%s’s)" % own.dn if own and own != p else ""))
	o.append({"label": "Send one of your posse up", "sub": "It is full: six is as many as it holds." if full else "You have nobody free to send." if not free else "They go up at dusk and throw stones over the wall at anything within about fifteen paces.", "ok": free and not full, "a": "tup", "arg": i})
	o.append({"label": "Coax one of yours down", "sub": "None of yours are up it." if mine.is_empty() else "From the safety of the tower. %s is nearest the ladder." % D.qname(mine[mine.size() - 1]), "ok": not mine.is_empty(), "a": "tdown", "arg": i})
	o.append({"head": "The tower"})
	var up: Dictionary = Rules.upkeep(p)
	o.append({"label": "See to it (%s)" % D.cost_text(up), "sub": "Seen to today." if s.kept else "Nobody will climb it tonight until somebody has.", "ok": not s.kept and Rules.has(p, up), "a": "tkeep", "arg": i})
	if s.hp < s.mhp - 0.5:
		var rc := Rules.repair_cost(p, s)
		o.append({"label": "Repair it (%s)" % D.cost_text(rc), "sub": "%d of %d left." % [ceili(s.hp), roundi(s.mhp)], "ok": Rules.has(p, rc), "a": "trep", "arg": i})
	if not s.re:
		var rf := Rules.reinf_cost(p, "tower")
		o.append({"label": "Roof it (%s)" % D.cost_text(rf), "sub": "Keeps the arrows off whoever is up it. The only thing that can reach them otherwise.", "ok": Rules.has(p, rf), "a": "troof", "arg": i})
	o.append({"label": "Take it down", "sub": "Everybody off it, and half of what it cost back. The site stays, for next time.", "ok": true, "a": "tdis", "arg": i})
	var intro := ("%d of %d places taken: %s." % [crew.size(), D.TOWER.seats, ", ".join(names)]) if crew.size() else "Nobody is up it. Six can be, from anybody’s posse."
	if not s.kept: intro += " Nobody has seen to it today, and nobody will climb it until somebody has."
	if s.re: intro += " It has a roof."
	return {"title": "The watch tower, %s" % D.TOWER_NAMES[i], "intro": intro, "o": o}


## A merchant's wares, as options to buy (pre: "t:" for the travelling merchant at the Riverside).
static func wares_list(o: Array, p: E.Player, wl: Array, pre: String, lore: bool) -> void:
	for i in wl.size():
		var wv: Dictionary = wl[i]
		var gone: bool = wv.left <= 0
		if wv.give == "page":
			for b in p.books.size():
				var r := Rules.rk(p, b)
				if r > 0 and r < D.MAX_RANK:
					o.append({"label": "A loose page of " + D.book_title(b), "sub": D.coins(Rules.price_for(p, wv.price)) + ". A quarter of the way to your next rank." + (" Not today: you are on the job." if p.jobT > 0 else ""), "ok": not gone and p.coin >= Rules.price_for(p, wv.price) and p.jobT <= 0, "a": "mbuy", "arg": pre + "%d:%d" % [i, b]})
			continue
		var sub: String = D.coins(Rules.price_for(p, wv.price)) + (". Sold." if gone else ".") + (" (A tenth off, for your manners.)" if Rules.price_for(p, wv.price) < wv.price and not gone else "")
		if wv.give == "it": sub += " " + item_sub(p, wv.it)
		elif wv.give == "relic":
			sub += " He swears it is genuine." + ((" Your relic lore says: it is!" if wv.real >= 0 else " Your relic lore says: it is not.") if lore else "")
		elif wv.give == "cogs": sub += " Lets you build a contraption you have not learned yet. You have %d." % p.cogs
		elif wv.give == "index": sub += " A fifth book." if not p.xslot else " You have read it already."
		o.append({"label": wv.n[0].to_upper() + wv.n.substr(1), "sub": sub, "ok": not gone and p.coin >= Rules.price_for(p, wv.price) and not (wv.give == "index" and p.xslot), "a": "mbuy", "arg": pre + str(i)})


static func data(R: Rules, id: String, p: E.Player, page: String) -> Dictionary:
	var o := []
	if id.begins_with("tower"):
		return tower_page(R, int(id.substr(5)), p)
	match id:
		"market":
			var pr := func(n: int) -> int: return floori(n * 1.5) if p.gab else n
			o.append({"head": "Sell"})
			for r in D.RES:
				var each: int = D.STEEL_SELL if r == "steel" else (D.FISH.sell5 if Rules.rk(p, 1) >= 5 else D.FISH.sell) if r == "fish" else 1
				o.append({"label": "Sell 5 " + r, "sub": "for %dd. You carry %d." % [pr.call(mini(5, p.get(r)) * each), p.get(r)], "ok": p.get(r) > 0, "a": "sell", "arg": r})
			o.append({"head": "Buy"})
			for r in D.RES:
				if r == "steel" or r == "fish": continue   # nobody sells steel, and the market's fish is not fit to eat
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
			# (The storehouse has a window of its own, menus.store(), with buttons: there is nothing here for the number keys.)
			return {"title": "The storehouse", "intro": "Shared by the whole village. Anyone can put in or take out.", "o": o}
		"smithy":                                     # (the window itself is pictures, menus.smithy(); this is the same, as a list, by tier)
			var forge := func(i: int) -> void:
				if i < 0: return
				var I: Dictionary = D.IT[i]
				var c := Rules.forge_cost(p, I.cost)
				var why := Rules.forge_why(p, i)
				var locked := why != "" or not Rules.can_forge(p, i)
				var sub: String = why if why != "" else D.cost_text(c) + ". " + \
					((("%s. %d damage. {trick}: %s." % [I.note, I.dmg, D.AB[I.ab].n]) + ("" if Rules.can_use(p, i) else " You cannot use it yet: it needs %s." % book_need(I.need))) if I.s == "w" else I.note + "." if I.s == "k" else item_sub(p, i))
				o.append({"label": ("Make " if I.tier == "made" else "Forge ") + D.it_a(i), "sub": sub, "ok": not locked and Rules.has(p, c), "a": "forge", "arg": i})
			var t := page if page != "" else "crude"
			o.append({"head": D.TIER_NAME.get(t, "Posse kits") if t != "kits" else "Posse kits"})
			match t:
				"crude":
					for b in D.CRUDE_W: forge.call(D.crude_of(b))
					for b in D.BOWS + D.ARMOUR: forge.call(D.tier_item(b, "crude"))
					forge.call(D.I_TORCH)
				"forged":
					for i in D.FORGE_W.filter(func(x): return not D.BOWS.has(x)) + D.BOWS + D.ARMOUR + [D.I_HOBNAILS]: forge.call(i)
				"steel", "mithril", "rune":
					for b in D.STEEL_W + D.BOWS + D.ARMOUR: forge.call(D.tier_item(b, t) if t != "steel" or b in D.BOWS else D.steel_of(b))
					if t == "steel": forge.call(D.I_SABATONS)
				"kits":
					for i in D.kits(): forge.call(i)
			if t != "kits" and Rules.rk(p, D.B_SQUIRE) > 0: forge.call(D.great_of(t))   # (version 7.30) a greatsword, for a squire
			for tt in D.TIERS + ["kits"]:
				if tt != t: o.append({"label": D.TIER_NAME.get(tt, "Posse kits") if tt != "kits" else "Posse kits", "sub": "", "ok": true, "page": tt})
			return {"title": "The smithy", "intro": "You carry %d iron, %d steel, %d mithril and %d wood." % [p.iron, p.steel, p.mith, p.wood], "o": o}
		"library":
			if page == "card":
				o.append({"head": "Give up which book?"})
				for b in D.BOOKS.size():
					if p.books[b] > 0:
						o.append({"label": "Give up %s, rank %d" % [D.book_title(b), p.books[b]], "sub": "Everything it taught you goes. The next book you take up starts at rank %d." % maxi(1, p.books[b] - 1), "ok": true, "a": "card", "arg": b})
				o.append({"label": "Keep the card for now", "sub": "", "ok": true, "page": ""})
				return {"title": "Your library card", "intro": "The librarian will take back one of your books and let you choose another: one go, and the card is stamped. You do not start again from nothing: the new book begins a rank behind where the old one was.", "o": o}
			var slots := Rules.book_slots(p)
			if p.inv.has(D.I_CARD) and p.books.any(func(r): return r > 0):
				o.append({"label": "Hand in your library card", "sub": "Give up one of your books, to take up another.", "ok": true, "page": "card"})
			var owned := 0
			for b in p.books.size():
				if p.books[b] > 0 and not D.FREE_BOOKS.has(b): owned += 1
			var order := []                                   # (version 7.37) the shelf in kinds, each under its heading
			for G in D.BOOK_GROUPS:
				order.append(G[0])
				order.append_array(G[1])
			for b_ in order:
				if b_ is String:
					o.append({"head": b_})
					continue
				var b: int = b_
				var B: Dictionary = D.BOOKS[b]
				var r: int = Rules.rk(p, b)
				if b == D.B_SQUIRE and not r:                 # (version 7.30) not on the shelf: a gap, and a card in it
					o.append({"label": D.book_title(b), "sub": "A gap on the shelf, and a card in it: “Out on loan to Sir Aldous, who is not to be disturbed.” He is at the desk behind the rope.", "ok": false})
					continue
				var other_call: bool = Rules.is_class_book(b) and not r and Rules.class_of(p) >= 0
				if b == D.B_JEST and not r:                   # the Jester: withdrawn by its author, and a note in its place
					o.append({"label": D.book_title(b), "sub": "One calling at a time." if other_call else "You have the note that was in its place. Prospero, at the Thorny Rose, by the fire." if p.jnote else "Withdrawn by its author, it says on the spine. Take it, and see.", "ok": not other_call and not p.jnote, "a": "book", "arg": b})
					continue
				var sub := "One calling at a time." if other_call else ("%s." % Keys.fill(B.ranks[0])) if not r else ("Latest: %s." % lower(B.ranks[r - 1])) + ((" Next: %s (%d of %d, by %s)." % [lower(B.ranks[r]), floori(p.xp[b]), Rules.need_xp(b, r), B.by]) if r < D.MAX_RANK else " You have finished it.")
				if D.FREE_BOOKS.has(b) and not r and not other_call: sub += " It does not count against your books."
				o.append({"label": D.book_title(b) + (" · rank %d of %d" % [r, D.MAX_RANK] if r else ""), "sub": sub, "ok": not r and (slots > 0 or D.FREE_BOOKS.has(b)) and not other_call, "a": "book", "arg": b})
			var most := 5 if p.xslot else 4
			var intro := ("You may take up another book." if owned else "The Peasants’ Section: one shelf, propped up with a brick, of books with ten ranks in each. Choose your first. The Holy Book makes you an apprentice priest; one of them comes with a dog; one is not there at all; and one is out on loan. The Holy Book, the Jester and the Knight’s Squire do not count against your books.") if slots > 0 else ("You have your %s books." % ["", "one", "two", "three", "four", "five"][most] if owned >= most else "Reach rank 2 in a book to take up a second, rank 3 in two books to take up a third, and rank 4 in three to take up a fourth." + (" Your Index of Further Reading allows a fifth." if p.xslot else " A fifth needs An Index of Further Reading, which turns up in the ruins."))
			if p.card_rank > 1: intro += " Your card has been stamped: the next book you take up starts at rank %d." % p.card_rank
			return {"title": "The Peasants’ Section", "intro": intro + (" Cowards learn at half speed today." if p.coward else ""), "o": o}
		"slum":
			var c := {"food": Rules.slum_food(p)}
			var pop := R.peasants.filter(func(q): return q.state != "body" and q.kind != 3).size()
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
			o.append({"head": "The innkeeper"})
			o.append({"label": "Hire a mercenary until dawn", "sub": "You have one already. One is plenty." if p.merc else "%s. A hired fighter for your posse: stronger than a guard, and not to be trusted. About one in seven turns on his employer at dawn for two shillings more." % D.coins(D.MERC_FEE), "ok": not p.merc and p.coin >= D.MERC_FEE, "a": "merc"})
			o.append({"label": "Give the innkeeper 5 food", "sub": "He turns each piece into a tankard for tonight. %d in the barrel. You carry %d." % [R.ale, p.food], "ok": p.food > 0, "a": "ale"})
			o.append({"label": "Sit down to drink, and have the door barred", "sub": "He only pours for Dutch courage after dark." if is_day else "The door is in pieces until morning." if R.innHp <= 0 else "Your posse comes in with you. The dead will try the door.", "ok": not is_day and R.innHp > 0, "a": "innin"})
			return {"title": "The bar of the Thorny Rose", "intro": "Dutch courage: %d%%. Drink here at night until you are brave enough to charge. The innkeeper only has as much ale as the village brings him food that day. There are people to talk to, a gambler in the corner, an empty bookshelf, and an old jester by the fire." % p.cg, "o": o}
		"local0", "local1", "local2":
			var li := int(id.substr(5))
			var Lc: Dictionary = D.LOCALS[li]
			var topic := int(page.substr(1)) if page.begins_with("t") else -1
			var nm: String = Lc.name[0].to_upper() + Lc.name.substr(1)
			var intro: String = "%s: %s." % [nm, Lc.what]
			if topic >= 0 and topic < 3:
				var ls: Array = Lc.say[topic]
				intro = "“%s”" % ls[(R.day + li * 2 + topic) % ls.size()]
			o.append({"head": "Ask about"})
			for t in 3:
				o.append({"label": Lc.ask[t][0].to_upper() + Lc.ask[t].substr(1), "sub": "", "ok": true, "page": "t%d" % t})
			o.append({"head": "Or"})
			var done := (p.treated & (1 << li)) != 0
			o.append({"label": "Stand %s a drink" % ("her" if li == 0 else "him"), "sub": "You have stood one already today." if done else "%s. In return: %s." % [D.coins(D.TREAT), Lc.treat],
				"ok": not done and p.coin >= D.TREAT, "a": "treat", "arg": li})
			return {"title": nm, "intro": intro, "o": o}
		"shelf":
			o.append({"text": "It is empty. There is a clean patch in the dust the size of a paving stone, where a book used to be."})
			o.append({"text": "“That was mine,” says Prospero, from the stool by the fire. “Jester: the Faux Magician. Volume one. I never got round to the others, and I took the first one back, because nobody was reading it properly. If you want it, you will have to have it from me, out loud.”"})
			return {"title": "The inn’s bookshelf", "intro": "", "o": o}
		"prospero":
			var why := R.jest_why(p)
			var jl: int = p.jl
			if p.jlQ >= 0 and jl < 3:                    # his questions
				var L: Dictionary = D.JEST_LESSONS[jl]
				var Q: Dictionary = L.q[p.jlQ]
				var rot: int = (p.id + p.jlQ + jl) % Q.a.size()
				o.append({"head": "Question %d of %d" % [p.jlQ + 1, L.q.size()]})
				for k in Q.a.size():
					var ai: int = (k + rot) % Q.a.size()
					o.append({"label": Q.a[ai], "sub": "", "ok": true, "a": "jans", "arg": ai})
				return {"title": "Prospero asks", "intro": ("“%s” Try again. %s" % [L.q[p.jlW].no, Q.q]) if p.jlW >= 0 else Q.q, "o": o}
			if jl >= 3:
				o.append({"text": "“You have had everything I know,” Prospero says, “and one or two things I do not. Go and be insufferable. It is a calling.”"})
				return {"title": "Prospero", "intro": "The old jester, on the stool by the fire, with his cap and bells beside him. He is asleep, or pretending.", "o": o}
			var L: Dictionary = D.JEST_LESSONS[jl]
			if p.jlL or p.jlT > 0:
				var said := mini(L.talk.size(), floori(p.jlT / D.JEST.time * L.talk.size()) + 1)
				for k in said: o.append({"text": L.talk[k]})
			o.append({"head": "Lesson %d of 3: %s" % [jl + 1, L.n]})
			var lab := ("Listening: %d of %d seconds" % [floori(p.jlT), D.JEST.time]) if p.jlL else ("Listen to the rest of the lesson" if p.jlT > 0 else "Buy him a drink, and take the lesson" if not p.jlPaid else "Take the lesson")
			var sub := why if why != "" else "Stay by his stool. Press again to walk off; he will remember where he got to." if p.jlL else "About %d seconds of Prospero, and then a question or two. It costs a tankard from the barrel (%d in it). It teaches %s." % [D.JEST.time, R.ale, L.gives]
			o.append({"label": lab, "sub": sub, "ok": why == "" or p.jlL, "a": "jlisten"})
			if jl > 0: o.append({"text": "Homework: your newest trick played on %d of the %d dead he asks for." % [mini(p.jhw, D.JEST.hw), D.JEST.hw]})
			var intro := "An old jester, on the stool by the fire, with his cap and bells on the floor beside him. “Ah,” he says. “The note. Nobody reads the book, so I teach it myself. Three lessons. Each costs a drink.”" if jl == 0 else "Prospero looks up. “Back again. Did they laugh?”"
			return {"title": "Prospero", "intro": intro, "o": o}
		"cart":
			if R.merchant < 0:
				return {"title": "An empty spot", "intro": "No merchant today.", "o": o}
			var M: Dictionary = D.MERCHANTS[R.merchant]
			var lore := Rules.rk(p, 8) >= 2
			o.append({"head": "For sale"})
			wares_list(o, p, R.wares, "", lore)
			o.append({"head": "The job"})
			var pct := roundi(R.job.work / D.JOB_WORK * 100)
			if R.job.done:
				o.append({"label": M.job + ": done", "sub": "He is very pleased, in his way.", "ok": false, "a": "job"})
			else:
				var where: String = {"stone": "at the rocky outcrop", "cart": "here by the cart", "priest": "inside the chapel", "library": "in the library"}[M.where]
				o.append({"label": ("Stop: " if p.job else "Take the job: ") + M.job, "sub": ("You are %s (%d%% done). Stay %s. " % [M.doing, pct, where] if p.job else "Pay: %s. It is done %s, and takes most of a day alone, or half a day each with a team-mate. %s" % [M.pay, where, "(%d%% done.) " % pct if pct > 0 else ""]) + "Nobody learns anything from a book on a day they work for a merchant.",
					"ok": R.phase == "day", "a": "job"})
			return {"title": M.name[0].to_upper() + M.name.substr(1), "intro": "Selling %s. You have %s. He leaves at dusk." % [M.sells, D.coins(p.coin)], "o": o}
		"bailiff":
			var left := D.GUARDS - R.guards
			var fee := R.guard_fee()
			o.append({"label": "Hire a village guard for tonight", "sub": ("%s%s. He holds %s until dawn. %d of the %d guards are still free." % [D.coins(fee), " (the Bailiff has been jeered at today)" if R.bail_mood > 0 else "", D.POST_NAMES[R.guards % D.POSTS.size()], left, D.GUARDS]) if left > 0 else "Every guard is out tonight already.", "ok": left > 0 and p.coin >= fee, "a": "guard"})
			return {"title": "Robert Bailiff’s back door", "intro": "You knock. After a while a voice says the Bailiff is not at home, and that his guards cost %s a night, paid in advance, through the letterbox." % D.coins(fee), "o": o}
		"tmerch":                                     # the travelling merchant at the Riverside: never today's one in the village, and dearer
			if R.merch2 < 0 or R.merch2 >= D.MERCHANTS.size():
				return {"title": "The travelling merchant", "intro": "He has gone to find more things to sell.", "o": o}
			var M2: Dictionary = D.MERCHANTS[R.merch2]
			o.append({"head": "For sale, at Riverside prices"})
			wares_list(o, p, R.wares2, "t:", Rules.rk(p, 8) >= 2)
			return {"title": M2.name[0].to_upper() + M2.name.substr(1) + ", at the Riverside", "intro": "Selling %s, at half as much again as he would charge in Thornhallow. He says it is the cost of the river. You have %s." % [M2.sells, D.coins(p.coin)], "o": o}
		"rmerch":                                     # the merchant who never leaves
			o.append({"head": "Materials"})
			for k in ["wood", "stone", "iron", "food", "steel", "mith", "rune"]:
				var one: bool = k == "mith" or k == "rune"
				o.append({"label": "Buy %s %s" % ["1" if one else "5", D.RES_NAME[k].to_lower()], "sub": "%s. You carry %d." % [D.coins(D.RESIDENT[k]), p.get(k)], "ok": p.coin >= D.RESIDENT[k] and p.get(k) < Rules.cap(p), "a": "rbuy", "arg": k})
			o.append({"head": "Rune arms and armour"})
			for b in D.STEEL_W + D.BOWS + D.ARMOUR:
				var rid := D.tier_item(b, "rune")
				if rid < 0: continue
				var pr: int = D.RESIDENT.armour if D.IT[rid].s != "w" else D.RESIDENT.weapon
				o.append({"label": "Buy " + D.it_a(rid), "sub": D.coins(pr) + ". " + item_sub(p, rid), "ok": p.coin >= pr and (p.inv.size() < D.PACK_MAX or Rules.wears_now(p, rid)), "a": "rbuy", "arg": rid})
			return {"title": "The merchant who never leaves", "intro": "He has been here longer than the river, he says, and he knows exactly how far it is to the nearest other shop. You have %s." % D.coins(p.coin), "o": o}
		"druid":
			var granny := Rules.rk(p, 9) >= 1
			o.append({"head": "Today he asks"})
			for k in D.POTIONS.size():
				var P: Dictionary = D.POTIONS[k]
				var known: bool = (p.recipes & (1 << k)) != 0
				var c: Dictionary = R.brew[k] if k < R.brew.size() else {}
				if known:
					o.append({"label": "Have him brew %s (%s)" % [P.n, D.cost_text(c)], "sub": "%s. You carry %d." % [P.d[0].to_upper() + P.d.substr(1), p.get(P.k)], "ok": Rules.has(p, c), "a": "brew", "arg": k})
				else:
					o.append({"label": "Buy the recipe for %s (%s)" % [P.n, D.coins(D.POT.recipe)], "sub": ("%s. The recipe is a list of what to bring him; he does the rest, and will not say how." % (P.d[0].to_upper() + P.d.substr(1))) if granny else "He only sells recipes to readers of Granny’s Remedies. Granny was very firm about it.", "ok": granny and p.coin >= D.POT.recipe, "a": "recipe", "arg": k})
			o.append({"text": "What he asks for changes every morning, and is the same for everybody. Fire rocks come out of the campfire. Potions go in your backpack; drink one from the action bar. One of each kind works at a time."})
			return {"title": "The druid", "intro": "A man in a robe the colour of moss, who knows how Granny’s potions are made and is not going to tell a peasant. Did anybody honestly believe we would be taught the secret art of alchemy?", "o": o}
		"hv0", "hv1":                                 # the folk of the Riverside
			var hi := int(id.substr(2))
			var F: Dictionary = D.HAMLET_FOLK[hi]
			var topic := int(page.substr(1)) if page.begins_with("t") else -1
			var intro: String = "%s: %s." % [F.name, F.what]
			if topic >= 0 and topic < F.say.size():
				var ls: Array = F.say[topic]
				intro = "“%s”" % ls[(R.day + hi) % ls.size()]
			o.append({"head": "Ask about"})
			for t in F.ask.size():
				o.append({"label": F.ask[t][0].to_upper() + F.ask[t].substr(1), "sub": "", "ok": true, "page": "t%d" % t})
			return {"title": F.name, "intro": intro, "o": o}
		"hsign":
			o.append({"text": D.HALLOWSHIRE_SIGN})
			return {"title": "A signpost", "intro": "", "o": o}
		"knight":                                     # (version 7.30) Sir Aldous, at his desk beyond the rope
			if p.sqsay != "": o.append({"text": p.sqsay})
			match p.sq:
				0:
					if p.sqsay == "": o.append({"text": D.SQ_ASK[R.day % D.SQ_ASK.size()]})
					var any := false
					if Rules.sq_tier(p.wpn) != "":
						o.append({"label": "Show him the %s in your hand" % D.IT[p.wpn].n, "sub": "He will keep it if it is the one.", "ok": true, "a": "sqsword", "arg": "w"}); any = true
					for i in p.inv.size():
						if Rules.sq_tier(p.inv[i]) != "":
							o.append({"label": "Show him the %s in your backpack" % D.IT[p.inv[i]].n, "sub": "He will keep it if it is the one.", "ok": true, "a": "sqsword", "arg": "i%d" % i}); any = true
					if not any: o.append({"text": "You have no short sword about you. The smithy makes them, crude for anybody, and better ones for a reader of Hammer and Tongs. The merchant’s cart has one now and then."})
				1:
					if p.sqsay != D.SQ_RIGHT: o.append({"text": "“The notebook,” he says. “In the chest at the cabin, at the end of the lane past the western hedge. The lock is the paintings. He painted everything. Do keep up.”"})
				2:
					o.append({"label": "Give Sir Aldous the squire’s notebook", "sub": "He will read you some of it. It does not count against your books.", "ok": true, "a": "sqbook"})
				3:
					if Rules.rk(p, D.B_SQUIRE) >= D.MAX_RANK and p.kn == 0:
						o.append({"text": "“You have learned all a squire can be taught,” he says, “and some things I would rather you had not. Kneel.”"})
						o.append({"label": "Kneel, to be dubbed Sir", "sub": "", "ok": true, "a": "sqdub", "arg": 1})
						o.append({"label": "Kneel, to be dubbed Dame", "sub": "", "ok": true, "a": "sqdub", "arg": 2})
					elif p.sqsay == "":
						o.append({"text": ("“%s.” He nods to you as to an equal. Nearly." % p.dn) if p.kn else "“Carry on, squire. Both hands. Stand up straight.”"})
			return {"title": "Sir Aldous", "intro": D.SQ_NOTES[(R.day + p.slot) % D.SQ_NOTES.size()] + " Sir Aldous de Vere is a knight errant, and at present an errant knight: he has mislaid his squire.", "o": o}
		"librarian":
			o.append({"text": "“The Peasants’ Section is on your right,” she says, before you have said anything. “The rest of the library is for those with a coat of arms. Do you have a coat of arms?” You have a coat. She looks at it."})
			o.append({"text": "“A library card lets you give a book back and take another. They turn up in the ruins, for some reason. Do not ask me how. Do not ask me anything.”" + (" She looks at Sir Aldous, and sighs." if p.sq < 3 else "")})
			return {"title": "The librarian", "intro": "Behind her desk, in spectacles, stamping something. She has run this library for forty years and has not enjoyed one of them.", "o": o}
		"rope":
			o.append({"text": "A red rope, on two brass posts, and a card on a stand: “BEYOND THIS ROPE: THE LIBRARY. Members of the Nobility only. Kindly show your coat of arms to the librarian. Peasants: see the Peasants’ Section.”"})
			o.append({"text": "Beyond it: shelves to the ceiling, a ladder on wheels, a globe of the known world (most of it labelled “Here Be Dragons”), and every book there is. You can see them. You cannot have them." + (" Not even now that you are %s. Your arms have not been registered." % p.dn if p.kn else "")})
			return {"title": "The rest of the library", "intro": "", "o": o}
		"sqsign":
			o.append({"text": "Nailed to a tree, in red paint: “SIR ALDOUS DE VERE, KNIGHT. PRIVATE. NO PEASANTS.” And underneath, smaller, in another hand: “(except on business) (wipe your feet) — W.”"})
			return {"title": "A sign", "intro": "", "o": o}
		"sqnote":
			o.append({"text": "Pinned to the stable post, in a careful hand: “Sir. Have gone after the horse, who has gone after something. Back soon. Do NOT let anybody touch my notebook. It is in the chest. The lock is the paintings, in order. — Wat (your squire).”"})
			o.append({"text": "The note is some weeks old. The stable is empty, and so is the saddle."})
			return {"title": "A note", "intro": "", "o": o}
		"sqtrail":
			o.append({"text": "A boot. A little further on, a gauntlet. Then a helmet, upside down, with a bird’s nest in it already. Then nothing: only the woods, and a great many hoofprints, going somewhere in a hurry."})
			o.append({"text": "Wherever the squire went, he went quickly, and got lighter on the way."})
			return {"title": "A trail", "intro": "", "o": o}
		"paint0", "paint1", "paint2":
			var pi_ := int(id.substr(5))
			var n_: int = Rules.sq_code(R.gseed)[pi_]
			o.append({"text": "A painting of %s, done with great care and very little skill. You count: %d %s. On the frame, a numeral: %s." % [D.SQ_PAINT[pi_][1], n_, D.SQ_PAINT[pi_][0], ["I", "II", "III"][pi_]]})
			return {"title": "A painting", "intro": "Signed, in the corner, “W.”", "o": o}
		"sqchest":
			var dg := [floori(p.sqd / 100.0) % 10, floori(p.sqd / 10.0) % 10, p.sqd % 10]
			var open_: bool = p.sqd == R.sq_code_n()
			if open_:
				o.append({"text": "The lid is up. Inside: a great many notebooks, all labelled “Things Sir Aldous Has Told Me”, a sock, and a letter to the squire’s mother, not sent." + (" You have taken one of the notebooks. There are plenty." if p.sq >= 2 else "")})
				if p.sq == 1: o.append({"label": "Take a notebook", "sub": "For Sir Aldous, in the library.", "ok": true, "a": "sqopen"})
			else:
				for i in 3:
					o.append({"label": "The %s dial, with a %s scratched on it: %d" % [["first", "second", "third"][i], ["sheep", "candle", "crow"][i], dg[i]], "sub": "Turn it on.", "ok": true, "a": "sqdial", "arg": "%d+" % i})
				for i in 3:
					o.append({"label": "Turn the %s dial back" % ["first", "second", "third"][i], "sub": "", "ok": true, "a": "sqdial", "arg": "%d-" % i})
				o.append({"label": "Lift the lid", "sub": "", "ok": true, "a": "sqopen"})
			return {"title": "The squire’s chest", "intro": "A stout chest with a lock of three dials." if not open_ else "The squire’s chest.", "o": o}
		"keeper":
			var fee := R.tithe_fee()
			if p.tithe:
				o.append({"text": "“You have found it,” he says. “I should have charged more.”"})
			else:
				o.append({"label": "Pay for a search of the rubble (%s)" % D.coins(fee), "sub": "Paid: go and search. It takes a whole minute." if p.tpaid else "One search, of one minute. Not every search finds it. It is said to be easier to find after dark, when the raft has stopped.", "ok": not p.tpaid and p.coin >= fee, "a": "tpay"})
			o.append({"text": "There is a single piece of ore in there as well: rune or mithril, for whoever gets to it first today. He does not charge for that, because he has not noticed it."})
			return {"title": "Garrick’s Cave", "intro": "Garrick: an unscrupulous villager, who knows perfectly well how desperate Thornhallow is. In a chest, under the rubble in his cave, he says, is the best weapon there is. He charges by the search, and his price goes up every week. It is %s today." % D.coins(fee), "o": o}
		"rcave":
			if R.rcave:
				o.append({"text": "“It’s safe,” he says. “Safe enough. Go on in.” Three seams of runes glow blue at the back, %s to a seam each day. Stand beside one and hold the interact key. He will not go in himself. He says it is his knees." % ["two", "three", "four", "five"][clampi(R.ore_extra(), 0, 3)]})
			else:
				o.append({"label": "Give him %d wood to make it safe" % D.RCAVE_WOOD, "sub": "Once, for everybody: props, planks, and a promise. You carry %d wood." % p.wood, "ok": p.wood >= D.RCAVE_WOOD, "a": "rcfix"})
			return {"title": "A shady fellow", "intro": "He leans on a post by the boarded-up mouth of the Rune Cave, as though the post were his. For twenty wood, he says, he will shore it up so it can be gone into. He does not say who he is. He does not say where the last lot of wood went.", "o": o}
		"mill", "plate":                              # the windmill's banquet, paid for at the mill or from the plate by the east gate
			var mill := id == "mill"
			var c: Dictionary = D.BANQUET.mill if mill else D.BANQUET.plate
			var carrier := R.peasants.any(func(q): return q.owner == p.id and q.kind == 0 and q.plat == 0 and Rules.active(q) and not q.errand)
			var why := "Your posse has a banquet tonight already." if p.banq == R.day else "One of your posse is on his way to the windmill with it." if p.banqP else \
				"The miller only cooks by day. He is a miller." if R.phase != "day" else "Somebody from your posse has to carry it out to the windmill, and you have nobody." if not mill and not carrier else ""
			o.append({"label": "Lay on a banquet for your posse tonight (%s)" % D.cost_text(c), "sub": why if why != "" else "It mends your posse slowly, all night long. Not you: only them." + ("" if mill else " One of them carries it out to the windmill, and comes back."), "ok": why == "" and Rules.has(p, c), "a": "banq", "arg": id})
			var fed := []
			for o2 in R.players:
				if o2.banq == R.day: fed.append(o2.dn)
			o.append({"text": ("Tonight’s banquet is for the posses of %s." % ", ".join(fed)) if fed.size() else "Nobody has paid for a banquet tonight. Each posse’s share is paid for by its own leader, afresh each day."})
			if mill:
				return {"title": "The windmill", "intro": "The miller says the windmill has never done anything useful in its life, and that he would like that to change. For %s he will lay on a banquet for your posse, all through the night." % D.cost_text(c), "o": o}
			return {"title": "The offering plate", "intro": "A plate on a post, by the east gate. Leave %s on it and one of your posse will take it out to the windmill for you. It costs more than going yourself, which is the convenience." % D.cost_text(c), "o": o}
		"herder":
			if p.herd:
				var sh := R.sheep_of(p)
				o.append({"label": "Tame a sheep of your own (%d food)" % D.SHEEP.food, "sub": ("You have one: %s. It is %s." % [D.qname(sh) if sh else "under the stairs", "fed today" if p.sheepFed == R.day else "hungry, and wants one food"]) if p.sheep else "He picks you one out. Its first meal is on you.", "ok": not p.sheep and p.food >= D.SHEEP.food, "a": "tame"})
				o.append({"text": "Your sheep is on the action bar: press it to get on, and again to get off. It is a quarter quicker than walking, and boots do nothing for it. You cannot fight, gather or use any place from its back. It goes under the stairs at dusk, and wants one food a day."})
				return {"title": "The Herder", "intro": "“Mind how you lean,” the Herder says.", "o": o}
			if p.herdQ >= 0:                           # his questions
				var qi := (p.herdQ + p.id) % D.HERD_Q.size()
				var Q: Dictionary = D.HERD_Q[qi]
				var rot: int = (p.id + qi) % Q.a.size()
				o.append({"head": "Question %d of 2" % (p.herdQ + 1)})
				for k in Q.a.size():
					var ai: int = (k + rot) % Q.a.size()
					o.append({"label": Q.a[ai], "sub": "", "ok": true, "a": "hans", "arg": ai})
				return {"title": "The Herder asks", "intro": ("“%s” Try again. %s" % [D.HERD_Q[(p.herdW + p.id) % D.HERD_Q.size()].no, Q.q]) if p.herdW >= 0 else Q.q, "o": o}
			var said := mini(D.HERD_TALK.size(), floori(p.herdT / D.HERD_TIME * D.HERD_TALK.size()) + (1 if p.herdL else 0))
			for k in said: o.append({"text": D.HERD_TALK[k]})
			o.append({"label": ("Listening: %d of %d seconds" % [floori(p.herdT), D.HERD_TIME]) if p.herdL else "Listen to his lesson in sheep herding" if p.herdT <= 0 else "Listen to the rest of his lesson", "sub": "Stay beside him. Press again to walk off; he will remember where he got to." if p.herdL else "About %d seconds, and then a question or two. Nobody fails; some take longer." % D.HERD_TIME, "ok": true, "a": "hlisten"})
			return {"title": "The Herder", "intro": "A man in a smock, leaning on a crook, watching seven sheep. He says there are seven. He says he would know.", "o": o}
		"board":
			if page == "letters" or page.begins_with("l"):
				return letters_page(R, page, "The Lord’s letters", "Somebody has been copying the Lord of Ashhollow’s letters out and pinning them up here, with the spelling corrected.", "Back to the notices")
			var md := R.mday()
			var w: String = D.WEATHER_LINE.get(R.weather, "")
			o.append({"head": "From the castle"})
			o.append({"label": "The Lord’s letters", "sub": "%d so far. He writes every other morning, to complain." % R.letters.size() if R.letters.size() else "None yet. He is said to be a great writer of letters.", "ok": R.letters.size() > 0, "page": "letters"})
			o.append({"head": "Today"})
			if D.MOON_LINE.has(R.moon()): w = D.MOON_LINE[R.moon()]
			o.append({"text": w if w != "" else "A fine, clear day. Make the most of it."})
			if R.bells(): o.append({"text": D.BELLS_LINE + " The dead will be quicker, hit a quarter harder and take a quarter more putting down. The hat goes round twice in the morning."})
			if R.merchant >= 0 and R.phase == "day":
				o.append({"text": "A merchant is in: %s, by the market, until dusk." % D.MERCHANTS[R.merchant].name})
			o.append({"head": "Tonight"})
			var tl := R.tonight_lines()
			for t in tl: o.append({"text": t})
			if tl.is_empty(): o.append({"text": "The usual. More of them than last night."})
			var nb := 0
			for d in D.BOSS_NIGHTS:
				if R.last_day >= D.MONTH and int(d) > R.day and (nb == 0 or int(d) < nb): nb = int(d)
			if nb: o.append({"text": "Something worse is expected on night %d: %s." % [nb, D.UN[D.BOSS_NIGHTS[nb]].name]})
			o.append({"head": "Pinned up"})
			var rng := RandomNumberGenerator.new()
			rng.seed = R.gseed * 3 + R.day * 977
			var pool := range(D.NOTICES.size())
			for i in 3:
				var j := rng.randi() % pool.size()
				o.append({"text": D.NOTICES[pool[j]]})
				pool.remove_at(j)
			return {"title": "The notice board", "intro": "Day %d of %d, week %d. Robert Bailiff has the notices pinned up fresh each morning, by a servant, from the inside." % [R.day, R.last_day, Rules.week_of(md)], "o": o}
		"letter":
			return letters_page(R, page if page != "" else "l%d" % (R.letters.size() - 1), "A letter from the castle", "", "")
		"window":
			o.append({"label": "Talk to Robert Bailiff", "sub": "He has opinions. Mostly about you.", "ok": true, "a": "btalk"})
			o.append({"label": "Knock on his door", "sub": "It will not open. It never opens.", "ok": true, "a": "bknock"})
			o.append({"label": "Jeer at him", "sub": "Very satisfying. He remembers, though: each jeer makes his guards a shilling dearer today." + (" (Jeered at %d time%s today.)" % [R.bail_mood, "" if R.bail_mood == 1 else "s"] if R.bail_mood else ""), "ok": true, "a": "bjeer"})
			var said := ("“%s”" % R.bail_line if not R.bail_line.begins_with("“") and not R.bail_line.begins_with("You") and not R.bail_line.begins_with("A ") and not R.bail_line.begins_with("He") else R.bail_line) if R.bail_t > 0 else "Robert Bailiff peers down from his upstairs window, ready to look busy."
			return {"title": "Robert Bailiff, at his window", "intro": said, "o": o}
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
				var runes := ["head", "body", "off"].filter(func(k): return p.get(k) >= 0 and D.IT[p.get(k)].tier == "rune" and not D.IT[p.get(k)].blessed)
				for k in runes:                         # rune armour, blessed for good
					o.append({"label": "Bless your %s for good" % D.IT[p.get(k)].n, "sub": ("%s. For good: whatever strikes you is scorched, and wraiths do half their harm. The priest is not doing this for free." % D.coins(Rules.rune_bless(p))) if p.holy >= 2 else "He will only bless rune armour for somebody who has sat both his classes in holy studies.",
						"ok": p.holy >= 2 and p.coin >= Rules.rune_bless(p), "a": "rbless", "arg": k})
				o.append({"head": "Holy studies"})
				var lab := "Holy studies: finished" if p.holy >= 2 else ("In class: %d of %d seconds" % [floori(p.holyT), D.HOLY_TIME]) if p.study else "Sit a class in holy studies (%d of 2 done)" % p.holy
				var sub := "You can bless anything yourself, anywhere, from your backpack ({pack})." if p.holy >= 2 else "Stay in your pew. Get up, or press again, to stop; he will remember where you got to." if p.study else ("Take a pew and read the bible, about %d seconds of it%s. After one class you can bless your own weapon and bucket for nothing; after two, the departed as well. It does not count as one of your three books." % [D.HOLY_TIME, ", from where you left off" if p.holyT > 0 else ""])
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
