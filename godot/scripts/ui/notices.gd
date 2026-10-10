class_name Notices
extends RefCounted
## What each place offers: the notice that opens when you hold E at the market, the smithy, the storehouse,
## the library, the slum, the Thorny Rose Inn or the priest, and your own pack.
## Each option is {label, sub, ok, a (the action), arg} or {head} for a heading, or {page} to turn to another page.

const WEARV := {"w": "Take in hand", "h": "Put on", "b": "Put on", "o": "Take up", "t": "Carry", "c": "Read"}
const SLOTN := {"wpn": "In hand", "head": "Head", "body": "Body", "off": "Off hand", "trk": "Carried"}


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


static func data(R: Rules, id: String, p: E.Player, page: String) -> Dictionary:
	var o := []
	match id:
		"market":
			var pr := func(n: int) -> int: return floori(n * 1.5) if p.gab else n
			o.append({"head": "Sell"})
			for r in D.RES:
				o.append({"label": "Sell 5 " + r, "sub": "for %dd. You carry %d." % [pr.call(mini(5, p.get(r)) * (D.STEEL_SELL if r == "steel" else 1)), p.get(r)], "ok": p.get(r) > 0, "a": "sell", "arg": r})
			o.append({"head": "Buy"})
			for r in D.RES:
				if r == "steel": continue                  # nobody sells steel
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
		"smithy":
			var forge := func(i: int) -> void:
				var I: Dictionary = D.IT[i]
				var c := Rules.forge_cost(p, I.cost)
				var why := Rules.forge_why(p, i)
				var locked := why != ""
				var sub := why if locked else D.cost_text(c) + ". " + \
					(("%s. %d damage. {trick}: %s." % [I.note, I.dmg, D.AB[I.ab].n]) + ("" if Rules.can_use(p, i) else " You cannot use it yet: it needs %s." % book_need(I.need)) if I.s == "w" else item_sub(p, i))
				o.append({"label": ("Make " if I.tier == "made" else "Forge ") + D.it_a(i), "sub": sub, "ok": not locked and Rules.has(p, c), "a": "forge", "arg": i})
			var h3 := Rules.rk(p, 3)
			if page == "armour":
				o.append({"head": "Armour"})
				for i in D.FORGE_A: forge.call(i)
				if h3 >= 4:
					o.append({"head": "Steel armour"})
					for b in D.STEEL_A: forge.call(D.steel_of(b))
				var c := Rules.forge_cost(p, D.PEASANT_ARM)
				var un := R.peasants.filter(func(q): return q.owner == p.id and not q.armed and q.state != "body").size()
				o.append({"head": "Your posse"})
				o.append({"label": "Arm your whole posse with spears" if Rules.rk(p, 3) >= 3 else "Arm one of your posse with a spear", "sub": "%s each. %d of yours still %s a pitchfork." % [D.cost_text(c), un, "carries" if un == 1 else "carry"], "ok": un > 0 and Rules.has(p, c), "a": "armp"})
				o.append({"label": "Back to the weapons", "sub": "", "ok": true, "page": ""})
			else:
				o.append({"head": "Crude weapons: anyone can make these. They wear out"})
				for b in D.CRUDE_W: forge.call(D.crude_of(b))
				o.append({"head": "Refined weapons: Hammer and Tongs" + ("" if h3 >= 1 else " (you have not read it)")})
				for i in D.FORGE_W: forge.call(i)
				if h3 >= 4:
					o.append({"head": "Steel weapons: from the old steel mine. You carry %d steel" % p.steel})
					for b in D.STEEL_W: forge.call(D.steel_of(b))
				o.append({"head": "Rune weapons: the best there are. You carry %d rune%s and %d steel" % [p.rune, "" if p.rune == 1 else "s", p.steel]})
				if h3 >= D.RUNE_RANK:
					for b in D.STEEL_W: forge.call(D.rune_of(b))
				else:
					o.append({"label": "Not yet", "sub": "Rune weapons need rank %d of Hammer and Tongs, the last: you are at rank %d. They are steel with runes worked in, hit harder than anything else a smith can make, and bite wraiths. Runes come from the old workings, under the steel mine: take a torch." % [D.RUNE_RANK, h3], "ok": false})
				o.append({"head": "Fire"})
				forge.call(D.I_TORCH)
				o.append({"head": "More"})
				o.append({"label": "Armour, and spears for your posse", "sub": "Iron cap, chain shirt, shield.", "ok": true, "page": "armour"})
			return {"title": "The smithy", "intro": "You carry %d iron and %d wood. What you forge goes on; what it replaces goes in your backpack." % [p.iron, p.wood] + ("" if p.books[3] else " Anyone can make crude weapons. Hammer and Tongs, in the library, makes refined ones, then steel, and at its last rank rune weapons."), "o": o}
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
			var owned: int = p.books.filter(func(r): return r > 0).size()
			for b in D.BOOKS.size():
				var B: Dictionary = D.BOOKS[b]
				var r: int = Rules.rk(p, b)
				var other_call: bool = Rules.is_class_book(b) and not r and Rules.class_of(p) >= 0
				var sub := "One calling at a time." if other_call else ("%s." % Keys.fill(B.ranks[0])) if not r else ("Latest: %s." % lower(B.ranks[r - 1])) + ((" Next: %s (%d of %d, by %s)." % [lower(B.ranks[r]), floori(p.xp[b]), Rules.need_xp(b, r), B.by]) if r < 7 else " You have finished it.")
				o.append({"label": D.book_title(b) + (" · rank %d of 7" % r if r else ""), "sub": sub, "ok": not r and slots > 0 and not other_call, "a": "book", "arg": b})
			var most := 4 if p.xslot else 3
			var intro := ("You may take up another book." if owned else "The peasants’ section is one shelf of eleven books, with seven ranks in each. Choose your first. The Holy Book, at the end, makes you an apprentice priest.") if slots > 0 else ("You have your %s books." % ["", "one", "two", "three", "four"][most] if owned >= most else "Reach rank 2 in a book to take up a second, and rank 3 in two books to take up a third." + (" Your Index of Further Reading allows a fourth." if p.xslot else " A fourth needs An Index of Further Reading, which turns up in the ruins."))
			if p.card_rank > 1: intro += " Your card has been stamped: the next book you take up starts at rank %d." % p.card_rank
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
			o.append({"head": "The innkeeper"})
			o.append({"label": "Hire a mercenary until dawn", "sub": "You have one already. One is plenty." if p.merc else "%s. A hired fighter for your posse: stronger than a guard, and not to be trusted. About one in seven turns on his employer at dawn for two shillings more." % D.coins(D.MERC_FEE), "ok": not p.merc and p.coin >= D.MERC_FEE, "a": "merc"})
			o.append({"label": "Give the innkeeper 5 food", "sub": "He turns each piece into a tankard for tonight. %d in the barrel. You carry %d." % [R.ale, p.food], "ok": p.food > 0, "a": "ale"})
			o.append({"label": "Sit down to drink, and have the door barred", "sub": "He only pours for Dutch courage after dark." if is_day else "The door is in pieces until morning." if R.innHp <= 0 else "Your posse comes in with you. The dead will try the door.", "ok": not is_day and R.innHp > 0, "a": "innin"})
			return {"title": "The bar of the Thorny Rose", "intro": "Dutch courage: %d%%. Drink here at night until you are brave enough to charge. The innkeeper only has as much ale as the village brings him food that day. There are people to talk to, a gambler in the corner, and a bookshelf with one book on it." % p.cg, "o": o}
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
			o.append({"text": "It has one book on it, and the shelf has bent."})
			o.append({"text": "JESTER: The Faux Magician. His Art, his Mystery, and his Excuses. Being a Complete Course in the Appearance of Magic, with Some Remarks on What to Do when it Works."})
			o.append({"text": "It is the size of a paving stone. You open it at random and understand one word in five. The innkeeper says nobody has ever finished it, and that it would take a peasant three days at the least to get through, several times over."})
			o.append({"text": "Not today. (The Jester’s calling comes with the next big update.)"})
			return {"title": "The inn’s bookshelf", "intro": "", "o": o}
		"cart":
			if R.merchant < 0:
				return {"title": "An empty spot", "intro": "No merchant today.", "o": o}
			var M: Dictionary = D.MERCHANTS[R.merchant]
			var lore := Rules.rk(p, 8) >= 2
			o.append({"head": "For sale"})
			for i in R.wares.size():
				var wv: Dictionary = R.wares[i]
				var gone: bool = wv.left <= 0
				if wv.give == "page":
					for b in p.books.size():
						var r := Rules.rk(p, b)
						if r > 0 and r < 7:
							o.append({"label": "A loose page of " + D.book_title(b), "sub": D.coins(wv.price) + ". A quarter of the way to your next rank." + (" Not today: you are on the job." if p.jobT > 0 else ""), "ok": not gone and p.coin >= wv.price and p.jobT <= 0, "a": "mbuy", "arg": "%d:%d" % [i, b]})
					continue
				var sub: String = D.coins(wv.price) + (". Sold." if gone else ".")
				if wv.give == "it": sub += " " + item_sub(p, wv.it)
				elif wv.give == "relic":
					sub += " He swears it is genuine." + ((" Your relic lore says: it is!" if wv.real >= 0 else " Your relic lore says: it is not.") if lore else "")
				elif wv.give == "cogs": sub += " Lets you build a contraption you have not learned yet. You have %d." % p.cogs
				elif wv.give == "index": sub += " A fourth book." if not p.xslot else " You have read it already."
				o.append({"label": wv.n[0].to_upper() + wv.n.substr(1), "sub": sub, "ok": not gone and p.coin >= wv.price and not (wv.give == "index" and p.xslot), "a": "mbuy", "arg": str(i)})
			o.append({"head": "The job"})
			var pct := roundi(R.job.work / D.JOB_WORK * 100)
			if R.job.done:
				o.append({"label": M.job + ": done", "sub": "He is very pleased, in his way.", "ok": false, "a": "job"})
			else:
				var where: String = {"stone": "at the rocky outcrop", "cart": "here by the cart", "priest": "up at the chapel", "library": "in the library"}[M.where]
				o.append({"label": ("Stop: " if p.job else "Take the job: ") + M.job, "sub": ("You are %s (%d%% done). Stay %s. " % [M.doing, pct, where] if p.job else "Pay: %s. It is done %s, and takes most of a day alone, or half a day each with a team-mate. %s" % [M.pay, where, "(%d%% done.) " % pct if pct > 0 else ""]) + "Nobody learns anything from a book on a day they work for a merchant.",
					"ok": R.phase == "day", "a": "job"})
			return {"title": M.name[0].to_upper() + M.name.substr(1), "intro": "Selling %s. You have %s. He leaves at dusk." % [M.sells, D.coins(p.coin)], "o": o}
		"bailiff":
			var left := D.GUARDS - R.guards
			var fee := R.guard_fee()
			o.append({"label": "Hire a village guard for tonight", "sub": ("%s%s. He holds %s until dawn. %d of the %d guards are still free." % [D.coins(fee), " (the Bailiff has been jeered at today)" if R.bail_mood > 0 else "", D.POST_NAMES[R.guards % D.POSTS.size()], left, D.GUARDS]) if left > 0 else "Every guard is out tonight already.", "ok": left > 0 and p.coin >= fee, "a": "guard"})
			return {"title": "Robert Bailiff’s back door", "intro": "You knock. After a while a voice says the Bailiff is not at home, and that his guards cost %s a night, paid in advance, through the letterbox." % D.coins(fee), "o": o}
		"board":
			if page == "letters" or page.begins_with("l"):
				return letters_page(R, page, "The Lord’s letters", "Somebody has been copying the Lord of Ashhollow’s letters out and pinning them up here, with the spelling corrected.", "Back to the notices")
			var md := R.mday()
			var w: String = D.WEATHER_LINE.get(R.weather, "")
			o.append({"head": "From the castle"})
			o.append({"label": "The Lord’s letters", "sub": "%d so far. He writes every other morning, to complain." % R.letters.size() if R.letters.size() else "None yet. He is said to be a great writer of letters.", "ok": R.letters.size() > 0, "page": "letters"})
			o.append({"head": "Today"})
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
