class_name Rules
extends RefCounted
## The rules. The host runs these; everyone else is sent the result.
## Moved across from the web version's 05-sim.js, function for function, so the two play the same.

# --- the state of the game
var phase := "title"
var day := 1
var timeLeft := 0.0
var nf := 0.0                 # how far into night it is: 0 by day, 1 at night
var keepHp := D.KEEP_HP
var keepHc := 0
var players: Array = []       # E.Player
var peasants: Array = []      # E.Peasant
var undead: Array = []        # E.Undead
var structs: Array = []       # E.Struct
var ev: Array = []            # things that happened this moment, for the view: [kind, ...]
var store := {"wood": 0, "stone": 0, "iron": 0, "food": 0, "steel": 0}
var items: Array = []         # the arms rack in the storehouse
var drops: Array = []         # E.Drop
var spots: Array = [0, 0, 0, 0, 0, 0, 0, 0]   # searches left in each heap of rubble
var ruins_seen: Array = [true, false, false]   # has anyone found the outer ruins today? Until then the map and the signs keep quiet
var sites: Array = [0, 0, 0]
var gseed := 1
var ale := 0
var innHp := D.INN_HP
var innIn := 0
var relics: Array = []
var nid := 100
var sv := 1                   # bumped when the defences change
var tv := 1                   # bumped when the trees change
var tpc := 1
var pm := D.POSSE_MAX
var night = null              # Dictionary while the dead are rising
var wave := 0
var waves := 3
var left := 0
var boss: E.Undead = null
var graves: Array = []
var fallen: Array = []
var dawn := {"seq": 0, "day": 1, "lines": []}
var stats := {"kills": 0, "wood": 0, "built": 0, "lost": 0}
var rage := 1.0
var last_day := D.MONTH        # 30 for the month, 7 for the short game
var weather := "clear"         # tonight's weather: clear, overcast, rain, fog, snow, moon
var crowd := 1.0              # when the horde is too big to show, there are fewer of them, each this many times as hard to put down
var crowd_d := 1.0            # and hitting this much harder
var tough := 1.0              # the dead hit harder and last longer as the weeks go on
var merchant := -1            # today's merchant (an index into D.MERCHANTS), or -1
var wares: Array = []         # what is on the cart: [{n, price, left, give, ...}]
var job := {"work": 0.0, "done": false}   # the merchant's job, today
var reserve := false          # the brewer's reserve: tonight every tankard counts double
var guards := 0               # village guards hired for tonight
var bail_line := ""           # what Robert Bailiff last said from his window
var bail_t := 0.0             # and how long he stays at it
var letters: Array = []        # the Lord's letters so far: [which of D.LETTERS, the day it came]
var letter_new := false        # one is nailed to the gatepost, and nobody has read it yet
var seen := {}                 # things the Lord might write about, and how often each has happened
var rune_left: Array = [D.RUNE_PER_VEIN, D.RUNE_PER_VEIN, D.RUNE_PER_VEIN]   # what is left in each vein today
var tenant_day := 0           # the last day the Previous Tenant was woken: once a day is plenty
var chest := {}               # the chest that never arrived: {x, z, from, road, seen, open}, or empty when there is none
var bail_mood := 0            # how many times he has been jeered at today: each makes his guards a shilling dearer
var bell_t := 0.0             # the village bell, swinging

# --- the map as the rules see it
var trees: Array = Map.trees()
var colliders: Array = Map.colliders()
var QUARRY := E.Box.new(60, -8, 2.3, 1.9)
var MINEC := E.Box.new(58, 24, 2.2, 2.2)
var MINE := {"x": 55.0, "z": 24.0, "dir": 1}
var STEELC := E.Box.new(D.STEEL_MINE.x, D.STEEL_MINE.z, 2.2, 2.2)
var STEELM := {"x": D.STEEL_MINE.x + 3.0, "z": D.STEEL_MINE.z}   # its mouth faces the village
var JETTY := {"x": 12.0, "z": 53.4}

var save_hook: Callable       # called with the save data each morning, when set

# The solid things by 8-unit square, so each of the dead only checks the few near it (a big horde stays cheap).
const CG := 8.0
var _cgrid := {}
var _cgrid_ok := false
const _NONE := []

func near_colliders(x: float, z: float) -> Array:
	if not _cgrid_ok:
		_cgrid = {}; _cgrid_ok = true
		for c in colliders:
			var e: float = (maxf(c.hw, c.hd) * 1.42 if c.rot else 0.0) + 2.6      # room for the biggest of them, and a step
			var ex: float = e if c.rot else c.hw + e
			var ez: float = e if c.rot else c.hd + e
			for gx in range(floori((c.x - ex) / CG), floori((c.x + ex) / CG) + 1):
				for gz in range(floori((c.z - ez) / CG), floori((c.z + ez) / CG) + 1):
					var k := Vector2i(gx, gz)
					if _cgrid.has(k): _cgrid[k].append(c)
					else: _cgrid[k] = [c]
	return _cgrid.get(Vector2i(floori(x / CG), floori(z / CG)), _NONE)

var _tgrid := {}

func near_trees(x: float, z: float) -> Array:   # every tree within 3 of here (and some further): trees do not move
	if _tgrid.is_empty():
		for t in trees:
			for gx in range(floori((t.x - 3.3) / CG), floori((t.x + 3.3) / CG) + 1):
				for gz in range(floori((t.z - 3.3) / CG), floori((t.z + 3.3) / CG) + 1):
					var k := Vector2i(gx, gz)
					if _tgrid.has(k): _tgrid[k].append(t)
					else: _tgrid[k] = [t]
	return _tgrid.get(Vector2i(floori(x / CG), floori(z / CG)), _NONE)


func _init() -> void:
	colliders.append(QUARRY)
	colliders.append(MINEC)
	colliders.append(STEELC)


func say(t: String) -> void:
	ev.append(["msg", t])

func live() -> bool:
	return phase == "day" or phase == "dusk" or phase == "night"

func rnd2(a: float, b: float) -> float:
	return a + (b - a) * randf()

func note(k: String, n: int = 1) -> void:   # something the Lord of Ashhollow may have a view on
	seen[k] = int(seen.get(k, 0)) + n

static func letter_ix(id: String) -> int:
	for i in D.LETTERS.size():
		if D.LETTERS[i].id == id: return i
	return -1

## Which letter comes this morning, or -1. He writes on the second morning, then every other morning (every morning in the
## short game), the morning after one of his household is beaten, and on the last morning. He complains first of whatever
## the village has newly done; when it has done nothing new, of something else.
func next_letter() -> int:
	var had := letters.map(func(l): return int(l[0]))
	var want := ""
	var b := boss_of(day - 1, last_day)
	if day == last_day: want = "final"
	elif day == 2: want = "intro"
	elif b == D.U_STEWARD: want = "steward"
	elif b == D.U_COACH: want = "coach"
	elif b == D.U_CAPTAIN: want = "captain"
	if want != "":
		var w := letter_ix(want)
		return -1 if had.has(w) else w
	if day < 2 or (last_day >= D.MONTH and day % 2 == 1): return -1
	var spare := []
	for i in D.LETTERS.size():
		var L: Dictionary = D.LETTERS[i]
		if had.has(i) or ["intro", "steward", "coach", "captain", "final"].has(L.id): continue
		if not L.has("why"): spare.append(i)
		elif (stats.kills if L.why == "kills" else int(seen.get(L.why, 0))) >= L.n: return i
	if spare.is_empty(): return -1
	var rng := RandomNumberGenerator.new()
	rng.seed = gseed * 13 + day * 71
	return spare[rng.randi() % spare.size()]

func pick(a: Array):
	return a[randi() % a.size()]

static func r1(v: float) -> float:
	return roundf(v * 10) / 10

static func r2(v: float) -> float:
	return roundf(v * 100) / 100

func player_by_id(id: int) -> E.Player:
	for p in players:
		if p.id == id:
			return p
	return null

# --- the month
## Which night of the month night d is like. In the short game the month is squeezed into seven nights.
static func month_day(d: int, last: int) -> int:
	if last >= D.MONTH: return d
	return D.SHORT_NIGHTS[clampi(d - 1, 0, D.SHORT_NIGHTS.size() - 1)]

func mday() -> int:
	return month_day(day, last_day)

static func week_of(md: int) -> int:   # 1 to 4
	return clampi(floori((md - 1) / 7.0) + 1, 1, 4)

static func tough_of(md: int) -> float:   # each week the dead last a tenth longer and hit a tenth harder
	return 1.0 + 0.1 * (week_of(md) - 1)

## The weather for a day: the same on every computer, from the game's seed. Night 15 is the full moon.
static func weather_of(game_seed: int, d: int, last: int) -> String:
	if last >= D.MONTH and d == 15: return "moon"
	if d == 1: return "clear"
	var rng := RandomNumberGenerator.new()
	rng.seed = game_seed * 7 + d * 191
	var w: String = D.WEATHER[rng.randi() % D.WEATHER.size()]
	return "clear" if w == "snow" and month_day(d, last) < 8 else w   # no snow in the first week

static func boss_of(d: int, last: int) -> int:   # the undead kind of tonight's boss, or -1
	if last >= D.MONTH: return D.BOSS_NIGHTS.get(d, -1)
	return D.U_LORD if d == last else -1

static func is_boss(u: E.Undead) -> bool:
	return D.UN[u.k].boss

static func big(u: E.Undead) -> bool:   # too big to shove about, frighten or stun for long
	return D.UN[u.k].boss or D.UN[u.k].ram

func wspeed() -> float:   # how the weather changes the pace of the dead
	return 0.85 if weather == "rain" or weather == "snow" else 1.15 if weather == "moon" else 1.0

## Which merchant (if any) comes on day d: one in each stretch of days, every one of the five at least once.
static func merchant_on(game_seed: int, d: int, last: int) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = game_seed * 13 + 5
	var order := [0, 1, 2, 3, 4]
	for i in range(order.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var t = order[i]; order[i] = order[j]; order[j] = t
	order.append(rng.randi() % 5)
	var windows := [[2, 5], [6, 9], [11, 13], [16, 19], [22, 24], [26, 28]] if last >= D.MONTH else [[2, 2], [4, 4], [6, 6]]
	for i in windows.size():
		var w: Array = windows[i]
		if w[0] + rng.randi() % (w[1] - w[0] + 1) == d: return order[i]
	return -1

func guard_fee() -> int:
	return D.GUARD_FEE + 12 * bail_mood

func bark(q: E.Peasant, lines: Array) -> void:   # a peasant says something
	if q: ev.append(["bark", q.id, pick(lines)])

static func q_max(q: E.Peasant) -> float:   # a village guard and a mercenary are sturdier than a villager
	return 200.0 if q.kind == 1 else 160.0 if q.kind == 2 else D.PEASANT_HP

static func active(q: E.Peasant) -> bool:   # up and about: following, fighting, working, or (a guard) at his post
	return q.state == "follow" or q.state == "fight" or q.state == "chop" or q.state == "post"

func set_sites(a: Array) -> void:
	var q: Dictionary = D.SITES[0][a[0]]
	var m: Dictionary = D.SITES[1][a[1]]
	var j: Dictionary = D.SITES[2][a[2]]
	QUARRY.x = q.x; QUARRY.z = q.z
	MINEC.x = m.x; MINEC.z = m.z
	_cgrid_ok = false
	MINE.dir = 1 if m.x >= 0 else -1
	MINE.x = m.x - MINE.dir * 3; MINE.z = m.z
	JETTY.x = j.x; JETTY.z = j.z


# --- small rules shared by host and clients (clients use them for prompts and notices)
static func rk(p: E.Player, b: int) -> int:
	return p.books[b] if b < p.books.size() else 0

## The calling a player has taken up (an index into D.CLASSES), or -1 for a plain peasant.
static func class_of(p: E.Player) -> int:
	for i in D.CLASSES.size():
		if rk(p, D.CLASSES[i].book) > 0: return i
	return -1

static func is_class_book(b: int) -> bool:
	return D.BOOKS[b].has("class")

## What the village calls you, from the books you know best: "the Sooty Ringleader", "the Holy Apprentice Priest".
static func title_of(p: E.Player) -> String:
	var order := []
	for b in p.books.size():
		if p.books[b] > 0: order.append(b)
	if order.is_empty(): return "the Unread"
	order.sort_custom(func(a, b): return p.books[a] > p.books[b] or (p.books[a] == p.books[b] and p.xp[a] > p.xp[b]))
	var c := class_of(p)
	var noun_b: int = D.CLASSES[c].book if c >= 0 else order[0]
	var adj_b := -1
	for b in order:
		if b != noun_b:
			adj_b = b
			break
	return "the " + (D.TITLE_ADJ[adj_b] + " " if adj_b >= 0 else "") + ("Master " if p.books[noun_b] >= 7 else "") + D.TITLE_NOUN[noun_b]

## Does a relic in hand, worn or carried go with a book this player has read?
static func lore(p: E.Player, id: int) -> bool:
	return D.RELIC_LORE.has(id) and rk(p, D.RELIC_LORE[id][0]) > 0 and (p.wpn == id or p.head == id or p.body == id or p.off == id or p.trk == id)

static func power_wait(p: E.Player, i: int) -> float:
	var f := 0.67 if rk(p, D.B_HOLY) >= 5 else 1.0
	return (5.0 if i == 0 else 30.0) * f

static func cap(p: E.Player) -> int:
	var r := rk(p, 0)
	return 50 if r >= 7 else 40 if r >= 5 else 30 if r >= 2 else D.CARRY

func posse_max(p: E.Player) -> int:
	var r := rk(p, 6)
	return maxi(1, pm + (3 if r >= 6 else 2 if r >= 4 else 1 if r >= 2 else 0) - (1 if p.coward else 0))

## The more of you there are, the more of the dead come at the same seven foundations and the one keep. So what the
## village builds is stouter with company: a blow from the dead does this many times less to a defence or to the keep
## (1 alone, 1.4 for two, 2 for four, 2.8 for eight).
func stout() -> float:
	return sqrt(float(maxi(1, players.size())))

func pop_cap() -> int:
	return D.POP_PER_PLAYER * players.size() + (2 if players.size() == 1 else 0)

static func max_hp(p: E.Player) -> float:
	return D.PLAYER_HP + (20.0 if rk(p, 4) >= 6 else 0.0)

static func meal_hp(p: E.Player) -> float:
	var r := rk(p, 1)
	return 65.0 if r >= 7 else 50.0 if r >= 5 else 35.0 if r >= 2 else 20.0

static func slum_food(p: E.Player) -> int:
	return (3 if rk(p, 1) >= 6 else D.SLUM_FOOD) * (2 if p.coward else 1)

static func has(p: E.Player, c: Dictionary) -> bool:
	for k in c:
		if p.get(k) < c[k]:
			return false
	return true

static func pay(p: E.Player, c: Dictionary) -> void:
	for k in c:
		p.set(k, p.get(k) - c[k])
	if p.bbod > p.bodies:
		p.bbod = p.bodies

static func scale(c: Dictionary, f: float, only: String = "") -> Dictionary:
	var o := {}
	for r in c:
		o[r] = maxi(1, ceili(c[r] * f)) if only == "" or r == only else c[r]
	return o

## Can this player build a contraption: learned from the book, or with a box of cogs (and holy water for the trough)?
static func can_contr(p: E.Player, k: String) -> bool:
	if not D.CONTR.has(k): return true
	if k == "trough" and p.holy < 1 and rk(p, D.B_HOLY) < 1: return false
	return rk(p, 2) >= D.CONTR[k].rank or p.cogs > 0

static func cost_of(p: E.Player, k: String) -> Dictionary:
	var c: Dictionary = D.COST[k]
	var r := rk(p, 2)
	return c if c.has("bodies") or r < 1 else scale(c, 0.8 - 0.03 * (r - 1))

static func forge_cost(p: E.Player, c: Dictionary) -> Dictionary:
	var r := rk(p, 3)
	return c if r < 1 else scale(c, 0.67 - 0.04 * (r - 1), "iron")

## What the smithy will let this player make: crude weapons, anyone; refined, Hammer and Tongs; steel, rank 4 of it.
## Heavy arms (and the crossbow) need rank 2 whatever the grade.
static func can_forge(p: E.Player, id: int) -> bool:
	var I: Dictionary = D.IT[id]
	if I.cost.is_empty() or I.wear == 2: return false
	if I.heavy and I.tier != "crude" and rk(p, 3) < 2: return false
	match I.tier:
		"crude", "made": return true
		"steel": return rk(p, 3) >= 4
		"forged": return I.s != "w" or rk(p, 3) >= 1           # anyone can make armour; refined weapons need the book
	return false

static func forge_why(p: E.Player, id: int) -> String:   # why not, for the smithy's notice
	var I: Dictionary = D.IT[id]
	if I.tier == "steel" and rk(p, 3) < 4: return "Steel needs rank 4 of Hammer and Tongs."
	if I.heavy and I.tier != "crude" and rk(p, 3) < 2: return "Heavy arms need rank 2 of Hammer and Tongs."
	if I.tier == "forged" and I.s == "w" and rk(p, 3) < 1: return "Refined weapons need Hammer and Tongs, from the library."
	return ""

static func reinf_cost(p: E.Player, k: String) -> Dictionary:
	return scale(D.REINF[k].cost, 0.5) if rk(p, 3) >= 7 else D.REINF[k].cost

static func gather_time(p: E.Player, kind: String) -> float:
	var g: Dictionary = D.GATHER[kind]
	var r := rk(p, g.book)
	return g.time * (1.0 if r < 1 else (0.7 if g.book else 0.78) - 0.04 * (r - 1))

func fish_wait(p: E.Player) -> float:
	return rnd2(2.2, 4.8) * (1.0 if rk(p, 1) < 1 else 0.7 - 0.04 * (rk(p, 1) - 1))

static func search_time(p: E.Player) -> float:
	return D.SEARCH_TIME * (1 - 0.1 * rk(p, 8))

static func need_xp(b: int, r: int) -> int:   # what rank r needs to become rank r + 1
	return roundi(D.BOOKS[b].base * D.XPM[r - 1])

static func book_slots(p: E.Player) -> int:
	var owned := 0
	var any2 := false
	var n3 := 0
	for r in p.books:
		if r > 0: owned += 1
		if r >= 2: any2 = true
		if r >= 3: n3 += 1
	var allow := 1 + (1 if any2 else 0) + (1 if n3 >= 2 else 0) + (1 if p.xslot else 0)
	return maxi(0, allow - owned)

static func gear_cut(p: E.Player) -> float:
	var m := 1.0
	var any := false
	for id in [p.head, p.body, p.off]:
		if id >= 0:
			m *= 1 - D.IT[id].cut
			any = true
	return m * 0.95 if any and rk(p, 3) >= 5 else m

static func can_use(p: E.Player, id: int) -> bool:
	var n: Array = D.IT[id].need
	return n.is_empty() or rk(p, n[0]) >= n[1]

static func ab_wait(p: E.Player) -> float:
	var I: Dictionary = D.IT[p.wpn]
	if not D.AB.has(I.ab):
		return 0.0
	var r := rk(p, 4)
	return D.AB[I.ab].cd * (0.67 if r >= 5 else 0.8 if r >= 3 else 1.0) * (0.5 if I.rng and rk(p, 5) >= 7 else 1.0)

static func charge_len(p: E.Player) -> float:
	var r := rk(p, 7)
	return (32.0 if r >= 6 else 26.0 if r >= 2 else 20.0) * (1.5 if lore(p, 20) else 1.0)

static func repair_cost(p: E.Player, s: E.Struct) -> Dictionary:
	var base: float = D.COST[s.k].get("wood", 2) / 2.0
	var n := maxi(1, ceili(base * (1 - s.hp / s.mhp)))
	return {"wood": ceili(n / 2.0) if rk(p, 2) >= 2 else n}

func add_xp(p: E.Player, b: int, n: float) -> void:
	if not rk(p, b) or p.jobT > 0:          # a day spent on a merchant's job teaches you nothing
		return
	n = n * 0.5 if p.coward else n
	if p.books[b] >= 7:                           # the book is mastered: what is learned now is spare, to be sold
		var before := floori(p.spare)
		p.spare += n / float(D.BOOKS[b].base)
		if floori(p.spare) > before and before == 0:
			say("%s has learned more than %s can teach. Spare learning can be sold for coin in the skills window." % [p.dn, D.BOOKS[b].name])
		return
	p.xp[b] += n
	var t0 := title_of(p)
	while p.books[b] < 7 and p.xp[b] >= need_xp(b, p.books[b]):
		p.books[b] += 1
		say("%s has reached rank %d of %s." % [p.dn, p.books[b], D.BOOKS[b].name])
	retitle(p, t0)

func retitle(p: E.Player, before: String) -> void:   # tell the village when someone's title changes
	var t := title_of(p)
	if t != before and before != "the Unread":
		say("%s is now known as %s." % [p.dn, t])


## Someone has left a game in progress (they closed the game, or lost their connection). Their relics stay in
## the village, where they stood; their posse goes home.
func remove_player(id: int) -> void:
	var p := player_by_id(id)
	if p == null:
		return
	if p.state == "inn":
		leave_inn(p, false)
	for it in [p.wpn, p.head, p.body, p.off, p.trk] + p.inv:
		if it > 0 and D.IT[it].tier == "relic":
			drop_item(it, p.x, p.z)
	players.erase(p)
	for q in peasants:
		if q.owner == id:
			q.owner = 0
			q.state = "idle" if phase == "day" else "hide"
	say("%s has left the village." % p.dn)


## Sell whole spare points of learning for coin. Returns the pence paid.
func sell_spare(p: E.Player) -> int:
	var n := floori(p.spare)
	if n <= 0:
		return 0
	p.spare -= n
	p.coin += n * D.SPARE_PAY
	return n * D.SPARE_PAY


func mk_player(id: int, name: String, col: int, slot: int) -> E.Player:
	var c := D.cottage(slot)
	var p := E.Player.new()
	p.id = id; p.name = name; p.dn = name; p.col = col; p.slot = slot
	p.x = c.sx; p.z = c.sz; p.r = 0.0 if c.dir > 0 else PI; p.tx = c.sx; p.tz = c.sz
	p.hp = D.PLAYER_HP; p.tp = tpc
	tpc += 1
	return p

# where a cottage's people stand in the morning: in a row outside the door, clear of the keep
static func home_spot(slot: int, j: int, n: int) -> Dictionary:
	var c := D.cottage(slot)
	return {"x": c.sx + (j - (n - 1) / 2.0) * 1.05, "z": c.sz + c.dir * (0.15 + (j % 2) * 0.85), "r": 0.0 if c.dir > 0 else PI}

func mk_peasant(ni: int, x: float, z: float, hx: float, hz: float, owner: int) -> E.Peasant:
	var q := E.Peasant.new()
	q.id = nid; nid += 1
	q.ni = ni; q.x = x; q.z = z; q.hx = hx; q.hz = hz; q.hp = D.PEASANT_HP; q.owner = owner
	q.state = "follow" if owner else "idle"; q.px = x; q.pz = z
	return q

func add_villagers(slot: int, n: int) -> void:
	for j in n:
		var h := home_spot(slot, j, n)
		var q := mk_peasant((slot * 5 + j) % D.PNAMES.size(), h.x, h.z, h.x, h.z, 0)
		q.r = h.r
		peasants.append(q)

func clear_world() -> void:
	peasants = []; undead = []; structs = []; night = null; wave = 0; left = 0; boss = null; graves = []; fallen = []; ev = []
	keepHp = D.KEEP_HP; keepHc = 0; nf = 0; store = {"wood": 0, "stone": 0, "iron": 0, "food": 0, "steel": 0}; stats = {"kills": 0, "wood": 0, "built": 0, "lost": 0}
	items = []; drops = []; relics = []; ale = 0; innHp = D.INN_HP; innIn = 0
	letters = []; letter_new = false; seen = {}; chest = {}; tenant_day = 0
	for t in trees:
		t.wood = D.TREE_WOOD; t.gd = 0; t.set_state(0, 0)
	tv += 1; sv += 1

func mk_struct(k: String, x: float, z: float, rot: float, built: bool, hp: float, mx: float, slot: int) -> E.Struct:
	var s := E.Struct.new()
	s.id = nid; nid += 1
	s.k = k; s.x = x; s.z = z; s.rot = rot; s.built = built; s.hp = hp; s.mhp = mx; s.slot = slot
	s.hw = D.SDIM[k].x; s.hd = D.SDIM[k].y
	return s

# infos: [{id, name, col}] for the people playing
func new_game(infos: Array, last: int = D.MONTH) -> void:
	clear_world(); day = 1; gseed = 1 + randi() % 1000000; last_day = last
	players = []
	for i in infos.size():
		var np := mk_player(infos[i].id, infos[i].name, infos[i].get("col", i), i)
		np.remote = infos[i].get("remote", false)
		players.append(np)
	for i in D.SLOTX.size():
		var k := "gate" if i == 3 else "wall"
		structs.append(mk_struct(k, D.SLOTX[i], D.VN, 0, false, 0, D.SHP[k], i))
	pm = D.POSSE_SOLO if players.size() == 1 else D.POSSE_PAIR if players.size() == 2 else D.POSSE_MAX
	for p in players:
		add_villagers(p.slot, pm)
	roll_day(true)
	start_day(["The dead have begun walking down from Ashhollow Castle at night. Robert Bailiff has bolted his door and wishes you all the best.", "Start at the library: there is a book in it for each of you.", site_line()])

## Once a week a chest sets out for Thornhallow and does not arrive. It lies where the messenger fell, somewhere outside the
## village wall, until somebody finds it. Returns true on the morning one goes astray.
static func chest_day(game_seed: int, week: int, last: int) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = game_seed * 31 + week * 1009
	if last < D.MONTH: return 2 + rng.randi() % 3 if week == 1 else 0     # the short game: one chest, early
	return (week - 1) * 7 + 2 + rng.randi() % 4

func new_chest() -> bool:
	if not chest.is_empty() and not chest.open: return false       # the last one is still lying out there
	var w := floori((day - 1) / 7.0) + 1
	if day != chest_day(gseed, w, last_day): return false
	var rng := RandomNumberGenerator.new()
	rng.seed = gseed * 77 + day * 131
	for i in 200:
		var road := rng.randi() % 3
		var x := rng.randf_range(D.X0 + 8, -D.VW - 14) if road == 0 else rng.randf_range(D.VW + 14, D.X1 - 8) if road == 1 else rng.randf_range(D.X0 + 8, D.X1 - 8)
		var z := rng.randf_range(D.VS + 8, D.Z1 - 6) if road == 2 else rng.randf_range(D.VN - 4, D.Z1 - 6)
		var ok := true
		for c in colliders:
			if in_box(x, z, 5.0, c): ok = false
		for c in D.RUIN_SITES:
			if absf(x - c.x) < 12 and absf(z - c.z) < 9: ok = false
		if x > -76 and x < -40 and z > 15 and z < 46: ok = false           # not in the farm
		for t in near_trees(x, z):
			if D.d2(x, z, t.x, t.z) < 2.6: ok = false
		if not ok: continue
		chest = {"x": snappedf(x, 0.1), "z": snappedf(z, 0.1), "from": rng.randi() % D.CHEST_FROM.size(), "road": road, "seen": false, "open": false, "rot": snappedf(rng.randf() * TAU, 0.01)}
		return true
	return false

## Lifting the lid: a good sum, and perhaps a relic or a library card. It is the finder's; they can drop a thing for a friend.
func open_chest(p: E.Player) -> void:
	if chest.is_empty() or chest.open: return
	chest.open = true; chest.seen = true
	var w := week_of(mday())
	var sum := 72 + 24 * w
	var got := "nothing else"
	var r := randf()
	var left_ := D.RELICS.filter(func(id): return not relics.has(id))
	if r < 0.3 and left_.size():
		var id: int = pick(left_)
		relics.append(id); gain_or_drop(p, id); got = D.IT[id].n
	elif r < 0.72:
		gain_or_drop(p, D.I_CARD); got = "a library card"
	else:
		sum += 48
	p.coin += sum
	var F: Array = D.CHEST_FROM[chest.from]
	say("%s has found the chest %s sent. Inside: %s, %s, and a note: “%s”" % [p.dn, F[0], D.coins(sum), got, F[1]])
	ev.append(["found", p.id, "%s’s chest: %s and %s" % [F[0], D.coins(sum), got], r1(chest.x), r1(chest.z), 1, 1 if got != "nothing else" else 0])
	ev.append(["coin", r1(chest.x), r1(chest.z)])

func gain_or_drop(p: E.Player, id: int) -> void:
	if wears_now(p, id) or p.inv.size() < D.PACK_MAX: gain(p, id)
	else: drop_item(id, p.x, p.z)

func roll_day(first: bool) -> void:   # a new morning: the stone, the iron and the fish have moved, and the ruins hide new things
	if first:
		sites = [0, 0, 0]
	else:
		for k in 3:
			var n: int = sites[k]
			while n == sites[k]:
				n = randi() % D.SITES[k].size()
			sites[k] = n
	set_sites(sites)
	for i in spots.size():
		spots[i] = D.SEARCHES
	rune_left = [D.RUNE_PER_VEIN, D.RUNE_PER_VEIN, D.RUNE_PER_VEIN]
	ruins_seen = [true, false, false]
	weather = weather_of(gseed, day, last_day)
	merchant = merchant_on(gseed, day, last_day)
	job = {"work": 0.0, "done": false}
	reserve = false
	make_wares()
	for p in players:
		p.job = false; p.jobT = 0.0; p.merc = false; p.drill = 0.0; p.game = {}; p.gwon = 0; p.treated = 0
	bail_mood = 0
	ale = 0; innHp = D.INN_HP
	for e in drops:
		push_out(e, 0.7, QUARRY); push_out(e, 0.7, MINEC)
	for q in peasants:
		if q.state == "body":
			push_out(q, 0.9, QUARRY); push_out(q, 0.9, MINEC)
	for s in structs.duplicate():
		if s.slot < 0 and (in_box(s.x, s.z, 1.2, QUARRY) or in_box(s.x, s.z, 1.2, MINEC)):
			destroy_struct(s)

## What is on today's merchant's cart. Prices in pence. The better things turn up later in the month.
func make_wares() -> void:
	wares = []
	if merchant < 0: return
	var w := week_of(mday())
	var it := func(id: int, price: int) -> Dictionary: return {"n": D.it_a(id), "price": price, "left": 1, "give": "it", "it": id}
	match D.MERCHANTS[merchant].id:
		"tinker":
			wares = [{"n": "5 iron", "price": 9, "left": 4, "give": "iron"}, it.call(7, 14), it.call(8, 10), it.call(9, 16),
				{"n": "a box of cogs, for a contraption", "price": 24, "left": 3, "give": "cogs"}]
		"armourer":
			for a in [[1, 24], [2, 24], [3, 30], [19, 18], [22, 36], [25, 24]] + ([[5, 48], [14, 60]] if w >= 3 else []):
				wares.append(it.call(a[0], a[1]))
		"brewer":
			wares = [{"n": "5 food", "price": 8, "left": 6, "give": "food"}, {"n": "a barrel of ale for the Thorny Rose (5 tankards)", "price": 10, "left": 4, "give": "ale"}]
		"pedlar":
			var left_ := D.RELICS.filter(func(id): return not relics.has(id))
			var real: int = left_[randi() % left_.size()] if left_.size() else -1
			var names := D.FAKES.duplicate()
			names.shuffle()
			var at := randi() % 3
			for i in 3:
				wares.append({"n": names[i], "price": 36, "left": 1, "give": "relic", "real": real if i == at else -1})
		"bookseller":
			wares = [{"n": "a loose page", "price": 18, "left": 8, "give": "page"}, {"n": "An Index of Further Reading", "price": 72, "left": 2, "give": "index"}]

func job_spot() -> Dictionary:   # where today's job is done: {x, z, r}
	if merchant < 0: return {}
	var wh: String = D.MERCHANTS[merchant].where
	if wh == "stone": return {"x": QUARRY.x, "z": QUARRY.z, "r": 5.5}
	var st := D.station("cart" if wh == "cart" else wh)
	return {"x": st.x, "z": st.z, "r": st.r + 2.5}

func near_job(p: E.Player) -> bool:
	var j := job_spot()
	return not j.is_empty() and D.d2(p.x, p.z, j.x, j.z) < j.r * j.r

## The job is done: the one who did most gets the merchant's best; anyone who helped gets a shilling for their trouble.
func finish_job() -> void:
	job.done = true
	var workers := players.filter(func(p): return p.jobT > 0)
	workers.sort_custom(func(a, b): return a.jobT > b.jobT)
	for p in players: p.job = false
	if workers.is_empty(): return
	var p: E.Player = workers[0]
	var w := week_of(mday())
	var got := ""
	match D.MERCHANTS[merchant].id:
		"tinker":
			var n := 4 if w >= 3 else 2
			p.cogs += n; p.iron = mini(cap(p), p.iron + 10); got = "%d boxes of cogs and some iron" % n
		"armourer":
			gain(p, 5); got = "a warhammer"
			if w >= 3:
				gain(p, 22); got += " and a chain shirt"
		"brewer":
			reserve = true; ale += 10; p.food = mini(cap(p), p.food + 10)
			got = "a cask of the Brewer’s Reserve for the inn: tonight every tankard counts double"
		"pedlar":
			var real := -1
			for wv in wares:
				if wv.give == "relic" and wv.real >= 0 and wv.left > 0 and not relics.has(wv.real):
					real = wv.real; wv.left = 0
			if real >= 0:
				relics.append(real); gain(p, real); got = D.IT[real].n
				ev.append(["found", p.id, D.IT[real].n, r1(p.x), r1(p.z), 1, 1])
			else:
				p.coin += 60; got = "five shillings (he had no real relic left, and was quite upset about it)"
		"bookseller":
			if not p.xslot:
				p.xslot = true; got = "An Index of Further Reading: a fourth book"
			else:
				var best := -1
				for b in p.books.size():
					if p.books[b] > 0 and p.books[b] < 7 and (best < 0 or p.books[b] < p.books[best]): best = b
				if best >= 0:
					var t0 := title_of(p)
					p.books[best] += 1; p.xp[best] = maxf(p.xp[best], need_xp(best, p.books[best] - 1)); got = "a whole chapter of " + D.BOOKS[best].name
					retitle(p, t0)
				else:
					p.coin += 72; got = "six shillings"
	say("The job is done. %s gets %s." % [p.dn, got])
	for o in workers.slice(1):
		o.coin += 12; say("%s gets a shilling for helping." % o.dn)

func site_line() -> String:
	return "Today the stone is %s, the iron %s, and the fish are biting %s." % [D.SITES[0][sites[0]].n, D.SITES[1][sites[1]].n, D.SITES[2][sites[2]].n] \
		+ (" The outer ruins have wandered off again in the night, as ruins do. Nobody knows where." if day > 1 else " Somewhere out there are two older ruins. Nobody remembers where.")

func start_day(lines: Array) -> void:
	phase = "day"; timeLeft = D.DAY_LEN; undead = []; boss = null; night = null; left = 0; wave = 0; rage = 1.0
	for p in players:
		p.ready = false
	dawn = {"seq": dawn.seq + 1, "day": day, "lines": lines}
	if save_hook.is_valid():
		save_hook.call(save_data())


# --- saving: the host keeps the morning of the current day
const P_SAVE := ["card_rank", "rune", "etch", "name", "dn", "col", "slot", "hp", "wood", "stone", "iron", "food", "coin", "bodies", "wpn", "head", "body", "off", "trk", "holy", "holyT", "gab", "coward", "deaths", "spare", "xslot", "cogs", "steel"]

func save_data() -> Dictionary:
	var tree_codes := []
	for t in trees:
		if t.st or t.par:
			tree_codes.append([t.i, t.st, t.par, t.gd])
	var ss := []
	for s in structs:
		ss.append({"k": s.k, "x": s.x, "z": s.z, "rot": s.rot, "built": s.built, "hp": s.hp, "max": s.mhp, "slot": s.slot, "re": s.re, "bl": s.bl, "nr": s.nr, "age": s.age})
	var ps := []
	for p in players:
		var o := {"inv": p.inv.duplicate(), "books": p.books.duplicate(), "xp": p.xp.duplicate()}
		for k in P_SAVE:
			o[k] = p.get(k)
		ps.append(o)
	var qs := []
	for q in peasants:
		var own := player_by_id(q.owner)
		qs.append({"ni": q.ni, "x": q.x, "z": q.z, "hx": q.hx, "hz": q.hz, "hp": q.hp, "armed": q.armed, "body": q.state == "body", "os": own.slot if own else -1, "kind": q.kind})
	var ds := []
	for d in drops:
		ds.append({"it": d.it, "x": d.x, "z": d.z, "day": d.day})
	return {"v": 3, "day": day, "last": last_day, "pm": pm, "seed": gseed, "keepHp": keepHp, "store": store.duplicate(), "items": items.duplicate(), "relics": relics.duplicate(),
		"sites": sites.duplicate(), "stats": stats.duplicate(), "letters": letters.duplicate(true), "letter_new": letter_new, "seen": seen.duplicate(), "chest": chest.duplicate(), "lines": dawn.lines, "drops": ds, "trees": tree_codes, "structs": ss, "players": ps, "peasants": qs}

# infos: the people playing now. Each takes over a saved peasant, by name where possible.
func load_game(d: Dictionary, infos: Array) -> void:
	clear_world(); day = int(d.day); pm = int(d.pm); gseed = int(d.get("seed", 1)); keepHp = float(d.keepHp); last_day = int(d.get("last", D.MONTH))
	for k in store:
		store[k] = int(d.store.get(k, 0))
	for k in stats:
		stats[k] = int(d.stats.get(k, 0))
	for l in d.get("letters", []): letters.append([int(l[0]), int(l[1])])
	letter_new = bool(d.get("letter_new", false))
	var ch: Dictionary = d.get("chest", {})
	if not ch.is_empty(): chest = {"x": float(ch.x), "z": float(ch.z), "from": int(ch.from), "road": int(ch.road), "seen": bool(ch.seen), "open": bool(ch.open), "rot": float(ch.get("rot", 0.0))}
	var sn: Dictionary = d.get("seen", {})
	for k in sn: seen[k] = int(sn[k])
	items = []
	for v in d.get("items", []): items.append(int(v))
	relics = []
	for v in d.get("relics", []): relics.append(int(v))
	drops = []
	for e in d.get("drops", []):
		var dr := E.Drop.new(); dr.id = nid; nid += 1; dr.it = int(e.it); dr.x = e.x; dr.z = e.z; dr.day = int(e.get("day", day))
		drops.append(dr)
	for a in d.get("trees", []):
		if a[0] < trees.size():
			var t: E.Trunk = trees[a[0]]
			t.set_state(int(a[1]), int(a[2])); t.gd = int(a[3])
	tv += 1
	structs = []
	for s in d.structs:
		var st := mk_struct(s.k, s.x, s.z, s.rot, s.built, s.hp, s.max, int(s.slot))
		st.re = s.re; st.bl = s.bl; st.nr = s.get("nr", false); st.age = int(s.get("age", 0))
		structs.append(st)
	var left_: Array = d.players.duplicate()
	var used := {}
	players = []
	for info in infos:
		var k := -1
		for i in left_.size():
			if left_[i].name == info.name:
				k = i
				break
		if k < 0 and left_.size():
			k = 0
		var sp = left_.pop_at(k) if k >= 0 else null
		var slot: int = int(sp.slot) if sp else 0
		if not sp:
			while used.has(slot) or d.players.any(func(o): return int(o.slot) == slot):
				slot += 1
		used[slot] = true
		var p := mk_player(info.id, info.name, info.get("col", 0), slot % 8)
		p.remote = info.get("remote", false)
		if sp:
			for f in P_SAVE:
				if f != "name" and f != "col" and f != "slot" and sp.has(f):
					var v = sp[f]
					if typeof(p.get(f)) == TYPE_INT: v = int(v)
					p.set(f, v)
			p.inv = []
			for v in sp.inv: p.inv.append(int(v))
			p.books = []
			for v in sp.books: p.books.append(int(v))
			p.xp = sp.xp.duplicate()
			while p.books.size() < D.BOOKS.size(): p.books.append(0)   # a save from before the Holy Book
			while p.xp.size() < D.BOOKS.size(): p.xp.append(0.0)
			p.dn = D.rel_name(info.name, p.deaths)
		else:
			add_villagers(p.slot, 3)
		players.append(p)
	for q in d.peasants:
		var own: E.Player = null
		for p in players:
			if p.slot == int(q.os):
				own = p
		var at_home: bool = own == null and not q.body
		var e := mk_peasant(int(q.ni), q.hx if at_home else q.x, q.hz if at_home else q.z, q.hx, q.hz, own.id if own else 0)
		e.hp = q.hp; e.armed = int(q.armed); e.kind = int(q.get("kind", 0))
		if q.body:
			e.state = "body"; e.owner = 0
		peasants.append(e)
	var s_ := []
	for v in d.get("sites", [0, 0, 0]): s_.append(int(v))
	roll_day(true); sites = s_; set_sites(sites)
	phase = "day"; timeLeft = D.DAY_LEN; dawn = {"seq": dawn.seq + 1, "day": day, "lines": d.get("lines", [])}


# --- collisions
# anything with x, z (and a box with x, z, hw, hd, rot). axis 0 or 1 forces the push along x or z (after a move along that axis)
static func push_out(e, r: float, c, axis: int = -1) -> bool:
	var dx: float = e.x - c.x
	var dz: float = e.z - c.z
	var lx := dx
	var lz := dz
	var cs := 1.0
	var sn := 0.0
	if c.rot:
		cs = cos(c.rot); sn = sin(c.rot); lx = dx * cs - dz * sn; lz = dx * sn + dz * cs; axis = -1
	var px: float = c.hw + r - absf(lx)
	var pz: float = c.hd + r - absf(lz)
	if px <= 1e-9 or pz <= 1e-9:
		return false
	if axis == 0 or (axis == -1 and px < pz):
		lx += px * (-1.0 if lx < 0 else 1.0)
	else:
		lz += pz * (-1.0 if lz < 0 else 1.0)
	if c.rot:
		e.x = c.x + lx * cs + lz * sn; e.z = c.z - lx * sn + lz * cs
	else:
		e.x = c.x + lx; e.z = c.z + lz
	return true

static func in_box(x: float, z: float, r: float, c) -> bool:
	var dx: float = x - c.x
	var dz: float = z - c.z
	var lx := dx
	var lz := dz
	if c.rot:
		var cs: float = cos(c.rot)
		var sn: float = sin(c.rot)
		lx = dx * cs - dz * sn; lz = dx * sn + dz * cs
	return absf(lx) < c.hw + r and absf(lz) < c.hd + r

static func box_point(x: float, z: float, c) -> Vector2:   # nearest point of an unrotated box
	return Vector2(clampf(x, c.x - c.hw, c.x + c.hw), clampf(z, c.z - c.hd, c.z + c.hd))

## Going in: to where the room really is, far off to the south.
func enter_room(p: E.Player, k: String) -> void:
	var M: Dictionary = D.ROOMS[k]
	p.room = k; p.x = M.at[0]; p.z = M.at[1] - 1.2; p.tx = p.x; p.tz = p.z; p.r = PI; p.goal_r = p.r; p.tp = tpc; tpc += 1; p.gk = 0; p.prog = 0; p.eLock = true
	ev.append(["door", r1(M.door[0]), r1(M.door[1])])

func leave_room(p: E.Player) -> void:
	if p.room == "": return
	var M: Dictionary = D.ROOMS[p.room]
	p.room = ""; p.x = M.door[0] + rnd2(-0.4, 0.4); p.z = M.door[1] + 1.2; p.tx = p.x; p.tz = p.z; p.tp = tpc; tpc += 1; p.gk = 0; p.prog = 0; p.eLock = true
	ev.append(["door", r1(p.x), r1(p.z)])

## What holding E would do, indoors.
func room_interact(p: E.Player):
	var M: Dictionary = D.ROOMS[p.room]
	if p.room == "mine":
		for i in D.RUNE_VEINS.size():
			var v: Array = D.RUNE_VEINS[i]
			if D.d2(p.x, p.z, v[0], v[1]) < 5.3:
				var lit := p.wpn == D.I_TORCH
				var left: int = rune_left[i]
				var full := p.rune >= cap(p)
				return {"type": "rune", "i": i, "key": "rune%d" % i, "ok": lit and left > 0 and not full, "dur": D.RUNE_TIME * (0.8 if rk(p, 0) >= 3 else 1.0), "x": v[0], "z": v[1], "rad": 1.0,
					"label": "It is too dark to work. You need a burning torch in your hand" if not lit else "This vein is worked out until tomorrow" if left <= 0 else "You can carry no more runes" if full else "Hold {interact} to prise out a rune"}
	for st in D.STATIONS:
		if st.get("room", "") == p.room and D.d2(p.x, p.z, st.x, st.z) < st.r * st.r:
			return {"type": "station", "st": st, "key": "st" + st.id, "ok": true, "dur": 0.12, "x": st.x, "z": st.z, "rad": 1.1, "label": "Hold {interact} to " + st.verb}
	if D.d2(p.x, p.z, M.at[0], M.at[1]) < 4.0:
		return {"type": "leave", "key": "leave", "ok": true, "dur": 0.6, "x": M.at[0], "z": M.at[1], "rad": 1.1, "label": "Hold {interact} to " + M.out}
	return null

func collide_friend(e, r: float, axis: int = -1) -> void:   # villagers: buildings, built walls, trees, the edge of the map
	if e is E.Player and e.room != "":                 # indoors: the room's own walls and furniture
		var M: Dictionary = D.ROOMS[e.room]
		for b in M.box:
			push_out(e, r, E.Box.new(b[0], b[1], b[2], b[3]), axis)
		e.x = clampf(e.x, M.x - M.hw + r, M.x + M.hw - r); e.z = clampf(e.z, M.z - M.hd + r, M.z + M.hd - r)
		return
	for c in near_colliders(e.x, e.z):
		push_out(e, r, c, axis)
	for s in structs:
		if s.built and s.k == "wall":
			push_out(e, r, s, axis)
	for t in near_trees(e.x, e.z):
		if t.alive:
			var dx: float = e.x - t.x
			var dz: float = e.z - t.z
			var rr: float = r + 0.42 * t.s
			var d := dx * dx + dz * dz
			if d < rr * rr and d > 1e-6:
				var l := sqrt(d)
				e.x = t.x + dx / l * rr; e.z = t.z + dz / l * rr
	e.x = clampf(e.x, D.X0, D.X1); e.z = clampf(e.z, D.Z0, D.Z1)

# a standing palisade or gate stops blows both ways: nobody can be hit through it (arrows, stones and buckets go over)
func wall_between(ax: float, az: float, bx: float, bz: float) -> bool:
	if (az - D.VN) * (bz - D.VN) >= 0:
		return false
	var x := ax + (bx - ax) * (D.VN - az) / (bz - az)
	for s in structs:
		if s.slot >= 0 and s.built and absf(x - s.x) <= 3:
			return true
	return false

func blocking_struct(x: float, z: float, r: float) -> E.Struct:
	for s in structs:
		if s.built and D.BLOCKERS.has(s.k) and in_box(x, z, r, s):
			return s
	return null


# --- what holding E would do for this player right now (shared by host and clients, so prompts match)
# The labels say "E"; the view swaps in the player's own key.
func find_interact(p: E.Player):
	if p == null:
		return null
	if p.state == "hide":
		return {"type": "unhide", "key": "unhide", "ok": true, "dur": 0.6, "x": p.x, "z": p.z, "rad": 1.0, "label": "Hold {interact} to come out of your cottage"}
	if p.room != "": return room_interact(p) if p.state == "ok" else null
	if p.state == "ok":
		for k in D.ROOMS:
			var M: Dictionary = D.ROOMS[k]
			if D.d2(p.x, p.z, M.door[0], M.door[1]) < 4.0:
				var shut: bool = k == "inn" and innHp <= 0
				return {"type": "enter", "room": k, "key": "enter" + k, "ok": not shut, "dur": 0.6, "x": M.door[0], "z": M.door[1], "rad": 1.1,
					"label": "The door of the Rose is in pieces. It is shut until morning" if shut else "Hold {interact} to " + M["in"]}
	if p.state == "ok" and not chest.is_empty() and not chest.open and D.d2(p.x, p.z, chest.x, chest.z) < 7.0:
		return {"type": "chest", "key": "chest", "ok": true, "dur": 1.5, "x": chest.x, "z": chest.z, "rad": 1.1, "label": "Hold {interact} to open the chest"}
	if p.state != "ok":
		return null
	var rvT := 1.5 if rk(p, 9) >= 2 else 3.0
	for o in players:
		if o != p and o.state == "down" and D.d2(p.x, p.z, o.x, o.z) < 7:
			return {"type": "revive", "target": o, "key": "r%d" % o.id, "ok": true, "dur": rvT, "x": o.x, "z": o.z, "rad": 1.0, "label": "Hold {interact} to revive " + o.dn}
	if phase != "day":
		var c := D.cottage(p.slot)
		var hx: float = c.sx
		var hz: float = c.z + c.dir * 2.3
		if D.d2(p.x, p.z, hx, hz) < 2.6:
			return {"type": "hide", "key": "hide", "ok": true, "dur": 1.2, "x": hx, "z": hz, "rad": 1.0, "label": "Hold {interact} to hide in your cottage. The village will call you a coward."}
	var best = null
	var bd := 3.6
	for d in drops:
		var dd := D.d2(p.x, p.z, d.x, d.z)
		if dd < bd:
			bd = dd; best = d
	if best:
		var full: bool = p.inv.size() >= D.PACK_MAX and not wears_now(p, best.it)
		return {"type": "pick", "target": best, "key": "d%d" % best.id, "ok": not full, "dur": 0.4, "x": best.x, "z": best.z, "rad": 0.7,
			"label": "Your backpack is full ({pack} opens it)" if full else "Hold {interact} to pick up " + D.it_a(best.it)}
	best = null; bd = 8.0
	for q in peasants:
		if q.state == "idle":
			var d := D.d2(p.x, p.z, q.x, q.z)
			if d < bd:
				bd = d; best = q
	if best:
		var full := p.posse >= posse_max(p)
		return {"type": "rally", "target": best, "key": "q%d" % best.id, "ok": not full, "dur": 0.35, "x": best.x, "z": best.z, "rad": 0.8,
			"label": ("Your posse is full. Nobody else will follow a coward today." if p.coward else "Your posse is full") if full else "Hold {interact} to rally " + D.PNAMES[best.ni]}
	best = null; bd = 6.5
	for q in peasants:
		if q.state == "body":
			var d := D.d2(p.x, p.z, q.x, q.z)
			if d < bd:
				bd = d; best = q
	if best:
		var full := p.bodies >= D.MAX_BODIES
		return {"type": "body", "target": best, "key": "b%d" % best.id, "ok": not full, "dur": 0.7, "x": best.x, "z": best.z, "rad": 0.9,
			"label": "You can carry no more bodies" if full else "Hold {interact} to pick up what is left of " + D.qname(best)}
	for s in structs:
		if not s.built and s.slot >= 0:
			var dx := clampf(p.x, s.x - 3, s.x + 3) - p.x
			var dz: float = s.z - p.z
			if dx * dx + dz * dz < 9:
				var c := cost_of(p, s.k)
				var ok := has(p, c)
				return {"type": "found", "target": s, "key": "s%d" % s.id, "ok": ok, "dur": 1.1, "x": s.x, "z": s.z, "rad": 3.2, "wide": true,
					"label": ("Hold {interact} to build a %s (%s)" if ok else "A %s needs %s") % [D.SNAME[s.k], D.cost_text(c)]}
	best = null; bd = 1e9
	for s in structs:
		if s.built and in_box(p.x, p.z, 1.7, s):
			var d := D.d2(p.x, p.z, s.x, s.z)
			if d < bd:
				bd = d; best = s
	if best:
		var s: E.Struct = best
		var o := {"target": s, "x": s.x, "z": s.z, "rad": D.SDIM[s.k].x + 0.2, "wide": true, "rot": s.rot}
		if s.hp < s.mhp - 0.5:
			var c := repair_cost(p, s)
			var ok := has(p, c)
			o.merge({"type": "repair", "key": "p%d" % s.id, "ok": ok, "dur": 0.6 if rk(p, 2) >= 2 else 1.2,
				"label": ("Hold {interact} to repair the %s (%s)" if ok else "Repairing the %s needs %s") % [D.SNAME[s.k], D.cost_text(c)]})
			return o
		if D.REINF.has(s.k) and not s.re:
			var rf: Dictionary = D.REINF[s.k]
			var some := false
			for k in rf.cost:
				if p.get(k) > 0: some = true
			if some:
				var c := reinf_cost(p, s.k)
				var smith: bool = not rf.smith or rk(p, 3) >= rf.smith
				var ok := smith and has(p, c)
				o.merge({"type": "reinf", "key": "f%d" % s.id, "ok": ok, "dur": 1.4,
					"label": "Iron tips need rank 2 of Hammer and Tongs" if not smith else ("Hold {interact} to %s (%s)" if ok else "To %s needs %s") % [rf.name, D.cost_text(c)]})
				return o
		if p.bbod > 0 and not s.bl and s.k != "decoy" and s.k != "spikes":
			o.merge({"type": "blessre", "key": "h%d" % s.id, "ok": true, "dur": 1.4, "label": "Hold {interact} to build a blessed body into the %s. It is what they would have wanted." % D.SNAME[s.k]})
			return o
	var kb := E.Box.new(D.KEEP_X, D.KEEP_Z, D.KEEP_H, D.KEEP_H)
	if keepHp < D.KEEP_HP and in_box(p.x, p.z, 1.6, kb):
		var c := {"wood": 1, "stone": 1}
		var ok := has(p, c)
		var pt := box_point(p.x, p.z, kb)
		return {"type": "keep", "key": "keep", "ok": ok, "dur": 0.9, "x": pt.x, "z": pt.y, "rad": 1.2,
			"label": "Hold {interact} to mend the keep (1 wood and 1 stone a time)" if ok else "Mending the keep needs wood and stone"}
	var sps: Array = Map.ruin_layout(gseed, day).spots
	for i in sps.size():
		var sp: Dictionary = sps[i]
		if D.d2(p.x, p.z, sp.x, sp.z) < 4.6:
			var n: int = spots[i]
			return {"type": "search", "i": i, "key": "x%d" % i, "ok": n > 0, "dur": search_time(p), "x": sp.x, "z": sp.z, "rad": 1.1,
				"label": ("Hold {interact} to search the rubble" + (". It is noisy work." if sp.ruin else "")) if n > 0 else "Nothing more under here until tomorrow"}
	for st in D.STATIONS:
		if st.id == "cart" and (merchant < 0 or phase != "day"): continue     # the cart is only there on a merchant's day
		if st.id == "letter" and letters.is_empty(): continue                 # and the gatepost is bare until the Lord writes
		if st.id == "bell" and D.d2(p.x, p.z, st.x, st.z) < st.r * st.r:
			return {"type": "bell", "key": "bell", "ok": bell_t <= 0, "dur": 0.4, "x": st.x, "z": st.z, "rad": 1.0, "label": "Hold {interact} to ring the village bell. It does nothing at all."}
		if st.has("room"): continue                                           # indoors: room_interact sees to those
		if D.d2(p.x, p.z, st.x, st.z) < st.r * st.r:
			return {"type": "station", "st": st, "key": "st" + st.id, "ok": true, "dur": 0.12, "x": st.x, "z": st.z, "rad": 1.3, "label": "Hold {interact} to " + st.verb}
	if rk(p, 9) >= 1:
		best = null; bd = 5.0
		var isP := false
		for o in players:
			if o != p and o.state == "ok" and o.hp < max_hp(o) - 5:
				var d := D.d2(p.x, p.z, o.x, o.z)
				if d < bd:
					bd = d; best = o; isP = true
		for q in peasants:
			if active(q) and q.hp < q_max(q) - 5:
				var d := D.d2(p.x, p.z, q.x, q.z)
				if d < bd:
					bd = d; best = q; isP = false
		if best:
			return {"type": "bandage", "target": best, "isP": isP, "key": "n%d" % best.id, "ok": true, "dur": 1.6, "x": best.x, "z": best.z, "rad": 0.8,
				"label": "Hold {interact} to bandage " + (best.dn if isP else D.qname(best))}
	var kind := ""
	var gx := p.x
	var gz := p.z
	var tgt: E.Trunk = null
	var rad := 1.1
	bd = 7.5
	for t in near_trees(p.x, p.z):
		if t.alive:
			var d := D.d2(p.x, p.z, t.x, t.z)
			if d < bd:
				bd = d; tgt = t
	if tgt:
		kind = "tree"; gx = tgt.x; gz = tgt.z; rad = 1.2 * tgt.s
	elif in_box(p.x, p.z, 1.9, QUARRY):
		kind = "stone"
		var pt := box_point(p.x, p.z, QUARRY)
		gx = pt.x; gz = pt.y
	elif D.d2(p.x, p.z, MINE.x, MINE.z) < 8:
		kind = "iron"; gx = MINE.x + MINE.dir * 0.6; gz = MINE.z
	elif D.d2(p.x, p.z, STEELM.x, STEELM.z) < 8:
		kind = "steel"; gx = STEELM.x - 0.6; gz = STEELM.z
	elif p.x > D.FARM.x0 and p.x < D.FARM.x1 and p.z > D.FARM.z0 and p.z < D.FARM.z1:
		kind = "food"
	elif D.d2(p.x, p.z, JETTY.x, JETTY.z) < 11:
		kind = "fish"; gx = JETTY.x; gz = JETTY.z + 1.4
	if kind != "":
		var g: Dictionary = D.GATHER[kind]
		var full: bool = p.get(g.res) >= cap(p)
		return {"type": "gather", "kind": kind, "target": tgt, "key": "g" + kind + (str(tgt.i) if tgt else ""), "ok": not full, "dur": gather_time(p, kind), "x": gx, "z": gz, "rad": rad,
			"label": "You can carry no more " + g.res if full else "A bite! Press {attack}" if kind == "fish" and p.bite > 0 else "Hold {interact} to " + g.verb}
	return null

func valid_place(k: String, x: float, z: float, rot: float) -> bool:
	if x < D.X0 + 2 or x > D.X1 - 2 or z < D.Z0 + 2 or z > D.Z1 - 2: return false
	if absf(z - D.VN) < 1.7 and absf(x) < 21.5: return false                          # keep the foundations clear
	if (k == "bodywall" or k == "decoy") and D.inside_village(x, z): return false     # the fallen go outside the wall
	if k == "logs" and (z > D.VN - 4 or absf(x) > 30): return false                  # the log roller goes up the road, north of the wall
	var c := E.Box.new(x, z, D.SDIM[k].x, D.SDIM[k].y, rot)
	for o in colliders:
		if in_box(o.x, o.z, maxf(o.hw, o.hd) * 0.2, c) or in_box(x, z, 0.9, o): return false
	for s in structs:
		if s.slot < 0 and D.d2(x, z, s.x, s.z) < 2.3 * 2.3: return false
	for t in trees:
		if t.alive and in_box(t.x, t.z, 0.3, c): return false
	return true

func aim_assist(p: E.Player) -> void:   # turn to the nearest undead in reach
	var I: Dictionary = D.IT[p.wpn]
	var best: E.Undead = null
	var bd: float = I.rng * I.rng if I.rng else pow(I.reach + 1.5, 2)
	for u in undead:
		if u.state == "rise":
			continue
		var d := D.d2(p.x, p.z, u.x, u.z)
		if d < bd:
			bd = d; best = u
	if best:
		p.r = atan2(best.x - p.x, best.z - p.z)


# --- things held and worn
func drop_item(id: int, x: float, z: float) -> void:
	var d := E.Drop.new()
	d.id = nid; nid += 1; d.it = id; d.day = day
	d.x = clampf(x + rnd2(-0.9, 0.9), D.X0, D.X1); d.z = clampf(z + rnd2(-0.9, 0.9), D.Z0, D.Z1)
	drops.append(d)

func stow(p: E.Player, id: int) -> void:
	if p.inv.size() < D.PACK_MAX: p.inv.append(id)
	else: drop_item(id, p.x, p.z)

func wear(p: E.Player, id: int) -> void:
	var k: String = D.SLOTK[D.IT[id].s]
	var old: int = p.get(k)
	p.set(k, id)
	if k == "wpn":
		p.bless &= ~1; p.abCd = maxf(p.abCd, 1.5)
	if k == "trk":
		p.bless &= ~2
	if old > 0:
		stow(p, old)

static func wears_now(p: E.Player, id: int) -> bool:   # would go straight on, not into the backpack
	if not D.SLOTK.has(D.IT[id].s): return false           # a paper: it is kept, not worn
	var k: String = D.SLOTK[D.IT[id].s]
	return can_use(p, id) and (p.wpn == 0 if k == "wpn" else p.get(k) < 0)

func gain(p: E.Player, id: int) -> void:
	if wears_now(p, id): wear(p, id)
	else: stow(p, id)

func take_off(p: E.Player, slot: String) -> void:   # empties a slot (a peasant always has a pitchfork to fall back on)
	p.set(slot, 0 if slot == "wpn" else -1)
	if slot == "wpn": p.bless &= ~1
	if slot == "trk": p.bless &= ~2


# --- actions
func gather_one(kind: String, t: E.Trunk, p: E.Player) -> bool:
	var g: Dictionary = D.GATHER[kind]
	if p.get(g.res) >= cap(p) or p.job:
		return false
	if kind == "tree":
		if t == null or not t.alive:
			return false
		t.wood -= 1; stats.wood += 1
		if t.wood <= 0:
			t.set_state(1, t.par); tv += 1
	p.set(g.res, mini(cap(p), p.get(g.res) + (2 if g.book == 0 and rk(p, 0) >= 6 and randf() < 0.2 else 1)))
	add_xp(p, g.book, 1)
	return true

func try_place(p: E.Player, k: String, x: float, z: float, rot: float) -> bool:
	if not (D.BUILDS.has(k) or D.CONTR.has(k)) or p.state != "ok" or not live() or not can_contr(p, k):
		return false
	var c := cost_of(p, k)
	var r := rk(p, 2)
	if not has(p, c) or D.d2(p.x, p.z, x, z) > 144 or not valid_place(k, x, z, rot):   # generous on distance, to allow for a laggy connection
		return false
	pay(p, c); stats.built += 1; add_xp(p, 2, 1); note("b_" + k)
	if D.CONTR.has(k) and r < D.CONTR[k].rank: p.cogs -= 1     # built from a box of cogs
	if D.CONTR.has(k):
		var s := mk_struct(k, x, z, rot, true, D.SHP[k], D.SHP[k], -1)
		s.tick = 1.0 if k == "logs" else 0.0                     # the log roller is stacked and ready
		structs.append(s)
		sv += 1
		say("%s has built %s." % [p.dn, ("the " if k == "thresher" else "a ") + D.SNAME[k]])
		return true
	var mul := (2.0 if r >= 5 else 1.0) if k == "spikes" else 1.0 if k == "decoy" else 1.5 if r >= 6 else 1.25 if r >= 3 else 1.0
	var mx := float(roundi(D.SHP[k] * mul))
	var s := mk_struct(k, x, z, rot, true, mx, mx, -1)
	s.nr = k == "barricade" and r >= 4
	structs.append(s)
	sv += 1
	return true

func destroy_struct(s: E.Struct) -> void:
	if s.slot >= 0:
		s.built = false; s.hp = 0; s.re = false; s.bl = false; s.mhp = D.SHP[s.k]
	else:
		structs.erase(s)
	sv += 1

func kill_undead(u: E.Undead) -> void:
	if u.dead:
		return
	u.dead = true; stats.kills += 1
	if night: night.kills += 1
	var U: Dictionary = D.UN[u.k]
	if not big(u) and not U.fly and not U.ghost:
		graves.append({"x": u.x, "z": u.z, "k": u.k})
		if graves.size() > 40: graves.pop_front()
	if U.ram:                                       # what was carrying it gets up and carries on
		for i in 4:
			var a := TAU * i / 4.0
			var b := spawn_undead(1, u.x + cos(a) * 1.3, u.z + sin(a) * 1.3)
			b.state = "walk"; b.t = 0
		say("The coffin ram has fallen apart. The six skeletons carrying it turn out to have been four.")
	if U.tenant:                                    # evicted: whoever saw to it goes through his pockets
		var who := player_by_id(u.last)
		if who == null and players.size(): who = players[0]
		if who:
			var rent := 36 + 12 * (week_of(mday()) - 1)
			who.coin += rent
			var extra := ""
			var left_ := D.RELICS.filter(func(id): return not relics.has(id))
			if left_.size() and randf() < 0.2:
				var id: int = pick(left_)
				relics.append(id); gain(who, id); extra = ", and " + D.IT[id].n
			elif randf() < 0.5:
				var id: int = pick(D.FOUND_W + D.FOUND_A)
				gain(who, id); extra = ", and " + D.it_a(id)
			say("%s has evicted the Previous Tenant. In his pockets: %s in back rent%s." % [who.dn, D.coins(rent), extra])
			ev.append(["found", who.id, "the Previous Tenant’s back rent: " + D.coins(rent) + extra, r1(u.x), r1(u.z), 1, 1 if extra != "" else 0])
	if u == boss:
		boss = null
		say({D.U_STEWARD: "The Steward has been dismissed.", D.U_COACH: "The hearse has lost a wheel, and the Coachman his head (again). He will not be driving tonight.",
			D.U_CAPTAIN: "The Captain of the Guard is down, and his guard has lost its enthusiasm.", D.U_LORD: "The Lord of Ashhollow has been put back in his box. He has not been asked to stay."}.get(u.k, "%s has fallen." % U.name.capitalize()))

# s: where the blow came from and whose it was: {x, z, p (a player), q (a peasant), blunt, holy (a multiplier), kb (extra knock-back), ranged}
func hit_u(u: E.Undead, d: float, s: Dictionary = {}) -> void:
	u.hc += 1
	if u.dead:
		return
	if u.state == "pile":
		if s.get("p"): kill_undead(u)
		return
	var U: Dictionary = D.UN[u.k]
	var bony: bool = U.bony
	var holy: float = s.get("holy", 0)
	if s.get("p"): u.last = s.p.id
	elif s.get("q"): u.last = s.q.owner
	if U.ghost and not holy and not s.get("rune", false):   # ordinary weapons pass straight through a wraith (rune-cut ones do not)
		ev.append(["miss", r1(u.x), r1(u.z)])
		return
	if holy: d *= holy
	if u.vuln > 0: d *= 1.5
	if bony and s.get("blunt", false): d *= 2
	if U.armour:                                     # armour: farm tools and pitchforks barely dent it; a mace or a hammer does
		d *= 1.3 if s.get("blunt", false) else 1.0 if holy else 0.35 if s.get("farm", true) else 0.75
	if U.fly and not s.get("ranged", false) and not s.get("ring", false): d *= 0.35   # bats are hard to hit with anything you swing
	if U.ram and s.get("heavy", false): d *= 2
	if U.lord and not holy: d *= 0.6
	u.hp -= d
	if not s.get("dot", false): u.cd = minf(U.cd, u.cd + 0.25)   # a hit delays its next swing a little; it does not stop it
	if U.lord: lord_stage(u)
	if s.has("x") and not big(u):
		var dx: float = u.x - s.x
		var dz: float = u.z - s.z
		var l := Vector2(dx, dz).length()
		if l == 0: l = 1
		var k: float = (0.25 if u.k == 0 else 0.7) * (1.6 if s.get("blunt", false) else 1.0) + s.get("kb", 0.0)
		u.x += dx / l * k; u.z += dz / l * k
	if s.get("p") and not s.get("smite", false) and not s.get("dot", false):
		add_xp(s.p, 5 if s.get("ranged", false) else 4, 1)
	elif s.get("q"):
		var own := player_by_id(s.q.owner)
		if own: add_xp(own, 6, 0.5)
	if u.hp <= 0:
		if bony and not u.revived and not s.get("blunt", false) and not s.get("holy", 0):
			u.state = "pile"; u.t = 3.6; u.revived = true; u.hp = 0; u.stun = 0; u.pin = 0; u.fear = 0
		else:
			kill_undead(u)

func nerve_hit(q: E.Peasant, n: float) -> void:   # a fright. At no nerve left, a peasant runs for the keep until dawn.
	var own := player_by_id(q.owner)
	if q.kind != 0 or own == null or (q.state != "follow" and q.state != "fight" and q.state != "chop"):
		return
	if own.head == 20 or rk(own, 6) >= 7 or own.charge > 0:
		return
	q.nv -= n * (1 - 0.1 * rk(own, 6))
	if q.nv <= 0:
		q.nv = 0; q.state = "hide"; q.tree = null; say("%s has lost their nerve and run for the keep." % D.PNAMES[q.ni]); bark(q, D.BARK_RUN)

func hurt_friend(e, d: float, is_player: bool, u: E.Undead, ranged: bool) -> void:
	if is_player:
		if e.state != "ok":
			return
		if not ranged and u and e.parry > 0:
			e.parry = 0; u.stun = maxf(u.stun, 2); hit_u(u, dmg_of(e, D.IT[e.wpn], 1), src_of(e, D.IT[e.wpn])); ev.append(["parry", r1(e.x), r1(e.z)])
			return
		if rk(e, 4) >= 2 and randf() < 0.125:
			ev.append(["miss", r1(e.x), r1(e.z)])
			return
		d *= gear_cut(e) * (0.5 if e.charge > 0 else 1.0) * (0.67 if e.prot > 0 else 1.0)
		if u and not ranged and e.body == 23:
			hit_u(u, 6, {"holy": 1.5})
			if lore(e, 23): e.hp = minf(max_hp(e), e.hp + 2)
	else:
		d *= (0.6 if e.kind == 1 else 0.7 if e.kind == 2 else 0.8 if e.armed else 1.0) * (0.67 if e.prot > 0 else 1.0)
	e.hp -= d; e.hc += 1; e.hurtT = 0
	if not is_player:
		nerve_hit(e, 3)
	if e.hp > 0:
		return
	e.hp = 0
	if is_player:
		if rk(e, 9) >= 7 and not e.upOnce:
			e.upOnce = true; e.hp = 35; say("%s went down, thought better of it, and got up again." % e.dn)
			return
		e.state = "down"; e.downT = 30.0 if rk(e, 9) >= 5 else 15.0; e.gk = 0; e.prog = 0; e.study = false
		for q in peasants:
			if q.owner == e.id: nerve_hit(q, 30)
	else:
		var own := player_by_id(e.owner)
		if own and rk(own, 9) >= 3 and not e.saved:
			e.saved = true; e.hp = 18
			return
		e.state = "body"; e.owner = 0; e.tree = null; fallen.append(D.qname(e)); stats.lost += 1; say("%s has fallen." % D.qname(e))
		for q in peasants:
			if q != e and D.d2(q.x, q.z, e.x, e.z) < 144: nerve_hit(q, 22)


# --- fighting
static func dmg_of(p: E.Player, I: Dictionary, mul: float = 1.0) -> float:
	var d: float = I.dmg * mul * (1 + (0.08 * rk(p, 5) if I.rng else 0.06 * rk(p, 4)))
	if (I.tier == "forged" or I.tier == "steel") and rk(p, 3) >= 4: d *= 1.1
	if p.charge > 0: d *= 2.0 if rk(p, 7) >= 7 else 1.6
	if p.wpn == 17 and I.n == D.IT[17].n and lore(p, 17): d *= 1.25
	if p.etch == p.wpn and I.n == D.IT[p.wpn].n: d *= 1.2      # runes cut into it
	return d

static func src_of(p: E.Player, I: Dictionary, kb: float = 0.0) -> Dictionary:
	return {"x": p.x, "z": p.z, "p": p, "blunt": I.blunt, "holy": ((1.9 if rk(p, 8) >= 5 else 1.5) if I.holy or (p.bless & 1) or p.hb > 0 else 0.0),
		"kb": I.kb + kb, "ranged": I.rng > 0, "farm": I.tier == "found", "heavy": I.heavy, "rune": p.etch == p.wpn and I.n == D.IT[p.wpn].n}

## The Lord fights in three stages: he watches from the road and sends his bats, then he comes down himself, then
## he goes for the keep door.
func lord_stage(u: E.Undead) -> void:
	if u.stage == 0 and u.hp < u.mhp * 0.66:
		u.stage = 1; u.march = true; u.rt = 4.0
		say("The Lord has tired of watching. He is coming down, and walls do not seem to bother him.")
	elif u.stage == 1 and u.hp < u.mhp * 0.33:
		u.stage = 2
		say("The Lord is going for the keep door himself. Stop him!")

# the undead a blow from p would reach, nearest first. over: it goes over the wall. p is anything with x, z, r.
func targets(p, reach: float, arc: float, over: bool = false) -> Array:
	var fx := sin(p.r)
	var fz := cos(p.r)
	var out := []
	for u in undead:
		if u.state == "rise" or u.dead:
			continue
		var dx: float = u.x - p.x
		var dz: float = u.z - p.z
		var d := sqrt(dx * dx + dz * dz)
		if d > reach + D.UN[u.k].r: continue
		if d > 0.8 and (dx * fx + dz * fz) / d < arc: continue
		if not over and not D.UN[u.k].fly and not D.UN[u.k].ghost and wall_between(p.x, p.z, u.x, u.z): continue
		u.dd = d
		out.append(u)
	out.sort_custom(func(a, b): return a.dd < b.dd)
	return out

func shoot(p: E.Player, I: Dictionary, mul: float, o: Dictionary = {}) -> E.Undead:   # one shot at the nearest enemy ahead. Returns what it hit.
	var t: E.Undead = null
	for u in targets(p, I.rng, 0.3, true):
		if u.state != "pile":
			t = u
			break
	var fx := sin(p.r)
	var fz := cos(p.r)
	var tx: float = t.x if t else p.x + fx * I.rng * 0.7
	var tz: float = t.z if t else p.z + fz * I.rng * 0.7
	ev.append(["shot", r1(p.x), r1(p.z), r1(tx), r1(tz), I.shot])
	if t == null or (o.is_empty() and rk(p, 5) < 2 and randf() > 0.85):   # an aimed stone does not miss
		return null
	var src := src_of(p, I)
	src.erase("x")                                     # a shot does not shove anyone
	hit_u(t, dmg_of(p, I, mul), src)
	if o.has("stun"): t.stun = maxf(t.stun, o.stun * 0.4 if big(t) else o.stun)
	if rk(p, 5) >= 6:
		for u in undead:
			if u != t and not u.dead and u.state != "rise" and u.state != "pile" and D.d2(u.x, u.z, t.x, t.z) < 9:
				hit_u(u, dmg_of(p, I, mul * 0.6), src)
				break
	return t

func do_attack(p: E.Player) -> void:
	if p.state != "ok" or p.atkCd > 0:
		return
	var I: Dictionary = D.IT[p.wpn]
	if phase == "night": p.fought = true
	p.atkCd = I.cd * (0.8 if I.rng and rk(p, 5) >= 4 else 1.0); p.ac += 1
	var mul := 1.0
	if rk(p, 4) >= 7:
		p.combo += 1
		if p.combo % 5 == 0: mul = 2.0
	if I.rng:
		if shoot(p, I, mul) == null: drill(p, I.rng, 0.3, 5)
		return
	var src := src_of(p, I)
	var hit := false
	for u in targets(p, I.reach, I.arc - 0.35 if rk(p, 4) >= 4 else I.arc):
		hit_u(u, dmg_of(p, I, mul), src); hit = true
		if I.fire: ignite(u, p, D.BURN_TIME)
	if not hit: drill(p, I.reach + 0.5, I.arc, 4)

## Practice on a training dummy: a little of the fighting book (or the ranged one), up to a limit a day.
func drill(p: E.Player, reach: float, arc: float, b: int) -> void:
	var fx := sin(p.r)
	var fz := cos(p.r)
	for i in D.DUMMIES.size():
		var dmy: Array = D.DUMMIES[i]
		var dx: float = dmy[0] - p.x
		var dz: float = dmy[1] - p.z
		var d := sqrt(dx * dx + dz * dz)
		if d > reach + 0.4 or (d > 0.8 and (dx * fx + dz * fz) / d < arc): continue
		ev.append(["dummy", i, r1(dmy[0]), r1(dmy[1]), b == 5])
		if b == 5: ev.append(["shot", r1(p.x), r1(p.z), r1(dmy[0]), r1(dmy[1]), D.IT[p.wpn].shot])
		if p.drill < D.DRILL_MAX and rk(p, b) > 0:
			p.drill += 1; add_xp(p, b, 1)
			if p.drill >= D.DRILL_MAX: say("%s has had enough practice for one day. The dummies look relieved." % p.dn)
		return

## Set one of the dead alight. Wraiths have nothing to burn; rain puts it out in half the time.
func ignite(u: E.Undead, p: E.Player, t: float) -> void:
	if u.dead or D.UN[u.k].ghost or u.state == "pile": return
	if u.burn <= 0: u.bt = 0.5
	u.burn = maxf(u.burn, t * (0.5 if weather == "rain" else 1.0)); u.last = p.id

func stun_u(u: E.Undead, t: float) -> void:
	u.stun = maxf(u.stun, t * 0.4 if big(u) else t)

func do_ability(p: E.Player) -> void:   # the weapon's own trick
	if p.state != "ok" or p.abCd > 0 or not live():
		return
	var I: Dictionary = D.IT[p.wpn]
	var k: String = I.ab
	if not D.AB.has(k):
		return
	p.abCd = ab_wait(p); p.ac += 1; p.atkCd = maxf(p.atkCd, 0.35)
	var src := src_of(p, I)
	var fx := sin(p.r)
	var fz := cos(p.r)
	var D_ := func(m: float) -> float: return dmg_of(p, I, m)
	match k:
		"pin":
			var l: Array = targets(p, I.reach + 2.2, 0.9) if I.line else targets(p, I.reach + 0.4, I.arc).slice(0, 1)
			for u in l:
				hit_u(u, D_.call(1.5), src); u.pin = 1.5 if big(u) else 3.5
		"parry":
			p.parry = 1.8
		"brace":
			for u in targets(p, I.reach + 1.6, 0.93):
				hit_u(u, D_.call(2.0), src); stun_u(u, 1.2)
		"shatter":
			for u in targets(p, I.reach + 0.2, I.arc):
				hit_u(u, D_.call(1.5), src); u.vuln = 8
		"hook":
			var l := targets(p, 5.2, 0.3)
			if l.size():
				var u: E.Undead = l[-1]
				if not big(u):
					u.x = p.x + fx * 1.4; u.z = p.z + fz * 1.4
				var s2 := src.duplicate(); s2.erase("x")
				hit_u(u, D_.call(1.0), s2); stun_u(u, 1.6)
		"flare":                                    # the torch, swept all round: everything near catches, and backs off
			for u in targets(p, 3.4, -1.0):
				if not wall_between(p.x, p.z, u.x, u.z):
					hit_u(u, D_.call(1.0), src); ignite(u, p, D.BURN_TIME * 1.5); scare(u, p.x, p.z, 1.6)
		"smash":
			var c := {"x": p.x + fx * 1.6, "z": p.z + fz * 1.6, "r": 0.0}
			var s2 := src.duplicate(); s2.x = c.x; s2.z = c.z; s2.kb = 1.4
			for u in targets(c, 3.2, -1.0):
				if not wall_between(p.x, p.z, u.x, u.z):
					hit_u(u, D_.call(1.5), s2); stun_u(u, 1.5)
		"wallop":
			var l := targets(p, I.reach + 0.3, I.arc)
			if l.size():
				var s2 := src.duplicate(); s2.kb = 2.4
				hit_u(l[0], D_.call(2.2), s2); stun_u(l[0], 2.5)
		"bury":
			var piles := undead.filter(func(u): return u.state == "pile" and D.d2(u.x, u.z, p.x, p.z) < pow(I.reach + 0.8, 2))
			if piles.size():
				for u in piles: kill_undead(u)
				if lore(p, 15): p.hp = minf(max_hp(p), p.hp + 10)
			else:
				var l := targets(p, I.reach + 0.3, I.arc)
				if l.size():
					var u: E.Undead = l[0]
					if not big(u) and not D.UN[u.k].ghost and u.hp <= u.mhp * (0.6 if I.holy else 0.4):
						u.hc += 1; u.revived = true; kill_undead(u)
						if lore(p, 15): p.hp = minf(max_hp(p), p.hp + 10)
					else:
						var s2 := src.duplicate(); s2.kb = 1.5
						hit_u(u, D_.call(2.0), s2)
		"trip":
			for u in targets(p, I.reach + 0.5, -0.1):
				hit_u(u, D_.call(0.5), src); stun_u(u, 2.2)
		"reap":
			for u in targets(p, I.reach + 0.3, -1.0):
				hit_u(u, D_.call(1.6), src)
		"backstab":
			var l := targets(p, I.reach + 0.3, I.arc)
			if l.size():
				var u: E.Undead = l[0]
				hit_u(u, D_.call(3.0 if u.tg != p.id or u.stun > 0 or u.pin > 0 or u.fear > 0 else 1.5), src)
		"clang":
			p.guard = 6
			for u in undead:
				var d := D.d2(u.x, u.z, p.x, p.z)
				if d < 100 and not big(u) and not D.UN[u.k].fly:
					u.taunt = p.id; u.tauntT = 6
					if d < 9: stun_u(u, 0.8)
		"aimed":
			shoot(p, I, 3, {"stun": 1.5})
		"volley":
			var l := targets(p, I.rng, 0.0, true).filter(func(u): return u.state != "pile").slice(0, 3)
			var s2 := src.duplicate(); s2.erase("x")
			for u in l:
				ev.append(["shot", r1(p.x), r1(p.z), r1(u.x), r1(u.z), 1]); hit_u(u, D_.call(1.0), s2)
			if l.is_empty():
				ev.append(["shot", r1(p.x), r1(p.z), r1(p.x + fx * 10), r1(p.z + fz * 10), 1])
		"pierce":
			var s2 := src.duplicate(); s2.erase("x")
			for u in targets(p, I.rng, 0.985, true):
				hit_u(u, D_.call(1.5), s2)
			ev.append(["shot", r1(p.x), r1(p.z), r1(p.x + fx * I.rng), r1(p.z + fz * I.rng), 1])
	ev.append(["abl", k, r1(p.x), r1(p.z), r2(p.r)])

func scare(u: E.Undead, x: float, z: float, t: float) -> void:
	if big(u) or u.state == "rise" or u.state == "pile" or u.state == "dig":
		return
	u.fear = t; u.fx = x; u.fz = z

## A calling's power: i is 0 or 1. For the Holy Book, Smite and Pray.
func do_power(p: E.Player, i: int) -> void:
	if p.state != "ok" or not live():
		return
	var c := class_of(p)
	if c < 0 or i < 0 or i > 1:
		return
	var C: Dictionary = D.CLASSES[c]
	var r := rk(p, C.book)
	if r < C.powers[i].rank or (p.p1Cd if i == 0 else p.p2Cd) > 0:
		return
	if i == 0: p.p1Cd = power_wait(p, 0)
	else: p.p2Cd = power_wait(p, 1)
	p.ac += 1
	match c:
		0: priest_power(p, i, r)

func priest_power(p: E.Player, i: int, r: int) -> void:
	if i == 0:                                       # Smite: a bolt of holy light from on high
		var tl := targets(p, 14, 0.3, true).filter(func(u): return u.state != "pile")
		if tl.is_empty():
			var near := undead.filter(func(u): return not u.dead and u.state != "rise" and u.state != "pile" and u.state != "dig" and D.d2(u.x, u.z, p.x, p.z) < 100)
			near.sort_custom(func(a, b): return D.d2(a.x, a.z, p.x, p.z) < D.d2(b.x, b.z, p.x, p.z))
			tl = near
		var dmg := 16.0 + 4.0 * r
		var src := {"p": p, "holy": 1.5, "ranged": true, "smite": true}
		var hit := 0
		note("smite")
		for u in tl.slice(0, 3 if r >= 7 else 1):
			var U: Dictionary = D.UN[u.k]
			ev.append(["smite", r1(u.x), r1(u.z)])
			hit_u(u, dmg * (2.0 if r >= 7 and (U.ghost or U.boss) else 1.0), src)
			if r >= 4:                               # with feeling: it bursts
				for v in undead:
					if v != u and not v.dead and v.state != "rise" and D.d2(v.x, v.z, u.x, u.z) < 2.6 * 2.6:
						hit_u(v, dmg * 0.5, src)
			hit += 1
		if hit == 0:
			ev.append(["smite", r1(p.x + sin(p.r) * 6), r1(p.z + cos(p.r) * 6)])   # a smite at nothing in particular
		else:
			add_xp(p, D.B_HOLY, hit)
	else:                                            # Pray: protection (and at rank 3, holy weapons; at 6, mending)
		var n := 0
		for o in players:
			if o.state == "ok" and D.d2(o.x, o.z, p.x, p.z) < 49:
				o.prot = 10.0
				if r >= 3: o.hb = 10.0
				if r >= 6: o.hp = minf(max_hp(o), o.hp + 25)
				n += 1
		for q in peasants:
			if active(q) and D.d2(q.x, q.z, p.x, p.z) < 49:
				q.prot = 10.0
				if r >= 6:
					q.hp = minf(q_max(q), q.hp + 25); q.nv = 100
				n += 1
		ev.append(["pray", r1(p.x), r1(p.z)])
		add_xp(p, D.B_HOLY, 1 + n * 0.5)

func do_toilet(p: E.Player) -> void:   # emergency toilet break: the posse makes its own ammunition
	if p.state != "ok" or p.tbCd > 0 or not live():
		return
	var posse := peasants.filter(func(q): return q.owner == p.id and (q.state == "follow" or q.state == "fight" or q.state == "chop") and D.d2(q.x, q.z, p.x, p.z) < 200)
	if posse.is_empty():
		return
	p.tbCd = D.TOILET_CD * (0.67 if rk(p, 5) >= 5 else 1.0)
	var near := undead.filter(func(u): return not big(u) and u.state != "rise" and u.state != "pile" and D.d2(u.x, u.z, p.x, p.z) < 121)
	for i in posse.size():
		var q: E.Peasant = posse[i]
		var u: E.Undead = near[i % near.size()] if near.size() else null
		q.ac += 1
		ev.append(["shot", r1(q.x), r1(q.z), r1(u.x if u else q.x + sin(p.r) * 7), r1(u.z if u else q.z + cos(p.r) * 7), 2])
	for u in near:
		scare(u, p.x, p.z, 5); hit_u(u, 2)
	say("%s’s posse has taken an emergency toilet break. The dead did not care for it." % p.dn)

func do_use(p: E.Player) -> void:   # whatever you carry
	if p.state != "ok" or not live():
		return
	if p.trk == 28:                  # the slop bucket, lobbed once
		var l := targets(p, 9, 0.0, true)
		var t: E.Undead = l[0] if l.size() else null
		var x: float = t.x if t else p.x + sin(p.r) * 5
		var z: float = t.z if t else p.z + cos(p.r) * 5
		var holy := (p.bless & 2) != 0
		ev.append(["shot", r1(p.x), r1(p.z), r1(x), r1(z), 3]); ev.append(["splat", r1(x), r1(z), 1 if holy else 0])
		for u in undead:
			if D.d2(u.x, u.z, x, z) < 16:
				scare(u, x, z, 6)
				if holy: hit_u(u, 30, {"p": p, "holy": 1.9 if rk(p, 8) >= 5 else 1.5})
		p.trk = -1; p.bless &= ~2
	elif p.trk == 26 and p.useCd <= 0:   # the Chapel Handbell
		p.useCd = 40; ev.append(["ring", r1(p.x), r1(p.z)])
		for u in undead:
			if u.state != "rise" and D.d2(u.x, u.z, p.x, p.z) < 64:
				stun_u(u, 3.5)
				if D.UN[u.k].fly: hit_u(u, 40, {"p": p, "ring": true})   # bats cannot abide a bell
				if lore(p, 26): hit_u(u, 15, {"p": p, "holy": 1.5, "smite": true, "ring": true})

func do_order(p: E.Player) -> void:   # follow, hold here, charge
	if p.state != "ok" or rk(p, 6) < 3:
		return
	p.order = (p.order + 1) % 3
	if p.order == 1:
		for q in peasants:
			if q.owner == p.id:
				q.px = q.x; q.pz = q.z

func do_eat(p: E.Player) -> void:
	if p.state != "ok" or p.food < 1 or p.eatCd > 0:
		return
	var heal := meal_hp(p)
	var mine := peasants.filter(func(q): return q.owner == p.id and q.state != "body")
	var posse := mine.filter(func(q): return q.hp < q_max(q)) if rk(p, 1) >= 4 else []
	if p.hp >= max_hp(p) and posse.is_empty():
		return
	p.food -= 1; p.eatCd = 0.6; p.hp = minf(max_hp(p), p.hp + heal)
	for q in posse: q.hp = minf(q_max(q), q.hp + heal)
	if rk(p, 1) >= 7:
		for q in mine: q.nv = 100
	ev.append(["eat", r1(p.x), r1(p.z)])

func do_fish(p: E.Player) -> void:
	if p.state != "ok" or p.gk != 5:
		return
	if p.bite > 0:
		var n := mini(D.FISH_FOOD + (1 if rk(p, 1) >= 3 else 0), cap(p) - p.food)
		p.food += n; add_xp(p, 1, n); p.cc += 1; ev.append(["fish", r1(JETTY.x), r1(JETTY.z + 2.6)]); note("fish")
	p.bite = 0; p.fishT = fish_wait(p)   # pulling early scares the fish off

func do_search(p: E.Player, i: int) -> void:   # one rummage through a heap of rubble
	var sps: Array = Map.ruin_layout(gseed, day).spots
	if i < 0 or i >= sps.size() or spots[i] <= 0:
		return
	var sp: Dictionary = sps[i]
	spots[i] -= 1; add_xp(p, 8, 1)
	var is_night := phase != "day"
	var lore := rk(p, 8)
	var dbl := 2 if lore >= 4 else 1
	var left_ := D.RELICS.filter(func(id): return not relics.has(id))
	var inv0 := p.inv.size()
	var pr := (0.06 if is_night else 0.012) * (2.5 if lore >= 6 else 1.5 if lore >= 3 else 1.0) * (1 + 0.1 * (mday() - 1)) * (2.0 if weather == "moon" else 1.0)   # relics glow in moonlight
	var found := ""
	var big := 0
	if left_.size() and randf() < pr:
		var id: int = pick(left_)
		relics.append(id); gain(p, id); found = D.IT[id].n; big = 1
		say("%s has found %s in %s!" % [p.dn, D.IT[id].n, D.RUINS[sp.ruin].name])
	else:
		var r := randf()
		if r < 0.34:
			var res: String = D.RES[randi() % 3]
			var n := maxi(0, mini((3 + randi() % 4) * dbl, cap(p) - p.get(res)))
			p.set(res, p.get(res) + n)
			found = ("%d %s" % [n, res]) if n else res + ", and no room to carry it"
		elif r < 0.48:
			var n := (8 + randi() % 13) * dbl
			p.coin += n; found = "an old purse: " + D.coins(n)
		elif r < 0.60:
			var id: int = pick(D.FOUND_W); gain(p, id); found = D.it_a(id)
		elif r < 0.69:
			var id: int = pick(D.FOUND_A); gain(p, id); found = D.it_a(id)
		elif r < 0.75:
			gain(p, 28); found = "a full slop bucket"
		elif r < 0.81 and p.books.any(func(b): return b > 0 and b < 7):
			var l := []
			for j in p.books.size():
				if p.books[j] > 0 and p.books[j] < 7: l.append(j)
			var b: int = pick(l)
			var rr: int = p.books[b]
			add_xp(p, b, ceili((need_xp(b, rr) - (need_xp(b, rr - 1) if rr > 1 else 0)) * 0.25))   # a quarter of the way to the next rank
			found = "a loose page of " + D.BOOKS[b].name
		elif r < 0.81 + (0.012 if is_night else 0.006) and not p.xslot:
			p.xslot = true; big = 1; found = "a slim volume: An Index of Further Reading"
			say("%s has found An Index of Further Reading, and can now take up a fourth book." % p.dn)
		elif r < 0.835 and not p.gab:
			p.gab = true; big = 1; found = "a pamphlet: The Gift of the Gab"; say("%s has found The Gift of the Gab. The market will regret it." % p.dn)
		elif r < 0.90:
			p.food = mini(cap(p), p.food + 1); found = "a very old turnip. Still food."
		else:
			found = pick(D.JUNK)
	ev.append(["found", p.id, found, r1(sp.x), r1(sp.z), big, 1 if p.inv.size() > inv0 else 0])
	# by day, in the outer ruins, the rummaging now and then wakes something much worse than a shambler
	if sp.ruin and not is_night and day >= 2 and tenant_day != day and randf() < D.TENANT_CHANCE + 0.01 * (week_of(mday()) - 1):
		tenant_day = day
		var a := randf() * TAU
		var t := spawn_undead(D.U_TENANT, clampf(sp.x + cos(a) * 2.6, D.X0, D.X1), clampf(sp.z + sin(a) * 2.6, D.Z0, D.Z1))
		t.hp = roundf(D.UN[D.U_TENANT].hp * tough_of(mday()) * (1 + 0.4 * (players.size() - 1))); t.mhp = t.hp
		t.hx = sp.x; t.hz = sp.z; t.t = 1.8; t.taunt = p.id; t.tauntT = 12
		ev.append(["raise", r1(t.x), r1(t.z)]); ev.append(["tenant", r1(t.x), r1(t.z)])
		say("%s has disturbed the Previous Tenant of %s. He would like a word about the noise." % [p.dn, D.RUINS[sp.ruin].name])
		return
	var pl := (0.6 if is_night else 0.3) if sp.ruin else (0.25 if is_night else 0.0)   # the ruins are not empty, and searching is noisy
	if lore < 7 and randf() < pl:
		var n := 1 + (1 if mday() >= 4 else 0) + (1 if is_night and randf() < 0.5 else 0)
		for j in n:
			var a := randf() * TAU
			var u := spawn_undead(D.U_GHOUL if mday() >= 8 and randf() < 0.3 else 1 if mday() >= 3 and randf() < 0.35 else 0, clampf(sp.x + cos(a) * 3.6, D.X0, D.X1), clampf(sp.z + sin(a) * 3.6, D.Z0, D.Z1))
			u.taunt = p.id; u.tauntT = 30
		say("Something in %s heard %s rummaging." % [D.RUINS[sp.ruin].name, p.dn])

# --- the gambler in the Rose: twenty-one, higher or lower, and the pea under the cups. A card is 0 to 51: its rank is
# card % 13 (0 the ace, 12 the king), its suit card / 13.
static func pip(c: int) -> int:   # what a card counts at twenty-one (an ace as one)
	return mini(10, c % 13 + 1)

static func total21(cards: Array) -> int:
	var t := 0
	var ace := false
	for c in cards:
		t += pip(int(c))
		if int(c) % 13 == 0: ace = true
	return t + 10 if ace and t + 10 <= 21 else t

## What higher or lower pays on a card: [what a right "higher" returns, what a right "lower" returns] for this stake (0: cannot be).
static func hl_pays(c: int, bet: int) -> Array:
	var r := c % 13
	var hi := 12 - r
	var lo := r
	return [roundi(bet * 0.92 * 13.0 / hi) if hi > 0 else 0, roundi(bet * 0.92 * 13.0 / lo) if lo > 0 else 0]

## Where the pea ends up: the cups are swapped in pairs, and it goes with its cup.
static func cups_end(ball: int, swaps: Array) -> int:
	for s in swaps:
		if ball == int(s[0]): ball = int(s[1])
		elif ball == int(s[1]): ball = int(s[0])
	return ball

func settle(p: E.Player, back: int, msg: String) -> void:   # the game is over: what comes back (0 if lost), and what he says
	var G: Dictionary = p.game
	G.done = true; G.win = back; G.msg = msg
	p.coin += back; p.gwon += back - int(G.bet)
	ev.append(["gamble", p.id, 1 if back > int(G.bet) else 0, r1(p.x), r1(p.z)])
	if back > int(G.bet) * 3: say("%s has taken %s off the gambler in one go. He has stopped smiling." % [p.dn, D.coins(back)])

func gamble(p: E.Player, a: String, arg) -> void:
	if p.room != "inn" or p.state != "ok" or not near_station(p, "gambler"): return
	var G: Dictionary = p.game
	var live_game: bool = not G.is_empty() and not G.get("done", false)
	match a:
		"gend":
			if not live_game: p.game = {}
		"gstart":                                   # arg: "game:stake"
			var bits: PackedStringArray = str(arg).split(":")
			var bet := int(bits[1]) if bits.size() > 1 else 0
			if live_game or not D.BETS.has(bet) or p.coin < bet or p.gwon >= D.GAMBLE_DAY or not ["21", "hl", "cups"].has(bits[0]): return
			p.coin -= bet; note("gamble")
			match bits[0]:
				"21":
					p.game = {"g": "21", "bet": bet, "me": [randi() % 52, randi() % 52], "him": [randi() % 52], "done": false, "msg": "", "win": 0}
					if total21(p.game.me) == 21: settle(p, bet + roundi(bet * 1.5), "Twenty-one in two cards. He pays you half as much again, and looks at the cards as if they had let him down.")
				"hl":
					p.game = {"g": "hl", "bet": bet, "card": randi() % 52, "next": -1, "done": false, "msg": "", "win": 0}
				"cups":
					var n := 5 + mini(8, 2 * p.gstreak)
					var swaps := []
					for i in n:
						var x := randi() % 3
						swaps.append([x, (x + 1 + randi() % 2) % 3])
					var sp := maxf(0.26, 0.5 - 0.035 * p.gstreak)
					p.game = {"g": "cups", "bet": bet, "ball": randi() % 3, "swaps": swaps, "sp": sp, "t": 1.7 + n * sp, "pick": -1, "at": -1, "done": false, "msg": "", "win": 0}
		"ghit":
			if live_game and G.g == "21":
				G.me.append(randi() % 52)
				if total21(G.me) > 21: settle(p, 0, "%d. Too many. He sweeps the cards up without a word." % total21(G.me))
				elif total21(G.me) == 21: gamble(p, "gstand", null)
		"gstand":
			if live_game and G.g == "21":
				while total21(G.him) < 17: G.him.append(randi() % 52)
				var mine := total21(G.me)
				var his := total21(G.him)
				if his > 21: settle(p, int(G.bet) * 2, "He turns up %d and goes over. He pays, slowly." % his)
				elif mine > his: settle(p, int(G.bet) * 2, "Your %d beats his %d. He pays." % [mine, his])
				elif mine == his: settle(p, int(G.bet), "%d each. “Nobody’s money,” he says, and pushes yours back." % mine)
				else: settle(p, 0, "His %d beats your %d. He does not gloat. It is worse." % [his, mine])
		"ghi", "glo":
			if live_game and G.g == "hl":
				var pays := hl_pays(int(G.card), int(G.bet))
				var back: int = pays[0] if a == "ghi" else pays[1]
				if back <= 0: return
				G.next = randi() % 52
				var r0 := int(G.card) % 13
				var r1_ := int(G.next) % 13
				var right: bool = r1_ > r0 if a == "ghi" else r1_ < r0
				var nm := "the %s of %s" % [D.CARD_N[r1_], D.CARD_SUIT[int(G.next) / 13]]
				if right: settle(p, back, "He turns up %s. %s it is. He pays you %s." % [nm, "Higher" if a == "ghi" else "Lower", D.coins(back)])
				elif r1_ == r0: settle(p, 0, "He turns up %s. The same. “The house takes a pair,” he says. It would." % nm)
				else: settle(p, 0, "He turns up %s. Wrong way." % nm)
		"gcup":
			var i := int(arg) if arg != null else -1
			if live_game and G.g == "cups" and float(G.t) <= 0.0 and i >= 0 and i < 3:
				var at := cups_end(int(G.ball), G.swaps)
				G.pick = i; G.at = at
				if i == at:
					p.gstreak += 1
					settle(p, int(G.bet) * 2, "The pea is there. He pays, and moves the cups a little faster next time.")
				else:
					p.gstreak = 0
					settle(p, 0, "Nothing under it. He lifts the %s cup, and there it is." % ["left", "middle", "right"][at])

func leave_inn(p: E.Player, charging: bool) -> void:
	if p.state != "inn":
		return
	p.state = "ok"; p.room = ""; p.x = D.INN.dx; p.tx = p.x; p.z = D.INN.dz + rnd2(-0.8, 0.8); p.tz = p.z; p.r = PI / 2; p.goal_r = p.r; p.tp = tpc; tpc += 1; p.drinkT = 0
	for q in peasants:
		if q.owner == p.id and q.state == "inn":
			q.state = "follow"; q.x = p.x + rnd2(0.4, 2); q.z = p.z + rnd2(-2, 2)
			if charging: q.nv = 100
	if charging:
		p.cg = 0; p.charge = charge_len(p); ev.append(["burst", r1(p.x), r1(p.z)]); say("%s bursts out of the Thorny Rose Inn, full of Dutch courage." % p.dn)

func near_station(p: E.Player, id: String) -> bool:
	var st := D.station(id)
	return D.d2(p.x, p.z, st.x, st.z) < pow(st.r + 2.5, 2)

func do_act(p: E.Player, a: String, arg = null) -> void:   # things done from a notice. The host checks everything again.
	if not live():
		return
	if p.state == "inn":
		if a == "drink" and ale > 0 and p.drinkT <= 0 and p.cg < 100:
			ale -= 1; p.drinkT = D.DRINK_TIME
		elif a == "innout":
			leave_inn(p, false)
		return
	if a.begins_with("g") and ["gstart", "ghit", "gstand", "ghi", "glo", "gcup", "gend"].has(a):
		gamble(p, a, arg)
		return
	if p.state != "ok":
		return
	var spark := func(k: String) -> void: ev.append([k, r1(p.x), r1(p.z)])
	var ia: int = int(arg) if typeof(arg) == TYPE_INT or typeof(arg) == TYPE_FLOAT else -1
	var sa: String = arg if typeof(arg) == TYPE_STRING else ""
	match a:
		"sell":
			if near_station(p, "market") and D.RES.has(sa):
				var n := mini(5, p.get(sa))
				var each := D.STEEL_SELL if sa == "steel" else 1
				p.set(sa, p.get(sa) - n); p.coin += floori(n * each * 1.5) if p.gab else n * each
				if n: spark.call("coin")
		"buy":
			if near_station(p, "market") and D.RES.has(sa) and sa != "steel":     # nobody sells steel
				var n := mini(mini(5, cap(p) - p.get(sa)), floori(p.coin / 2.0))
				if n > 0:
					p.set(sa, p.get(sa) + n); p.coin -= n * 2; spark.call("coin")
		"put":
			if near_station(p, "store") and D.RES.has(sa):
				store[sa] += p.get(sa); p.set(sa, 0)
		"take":
			if near_station(p, "store") and D.RES.has(sa):
				var n := mini(mini(5, store[sa]), cap(p) - p.get(sa))
				if n > 0:
					store[sa] -= n; p.set(sa, p.get(sa) + n)
		"puti":
			if near_station(p, "store") and ia >= 0 and ia < p.inv.size() and items.size() < 60:
				items.append(p.inv.pop_at(ia))
		"pute":
			if near_station(p, "store") and D.SLOTS.has(sa) and p.get(sa) > 0 and items.size() < 60:
				items.append(p.get(sa)); take_off(p, sa)
		"takei":
			if near_station(p, "store") and ia >= 0 and ia < items.size() and (p.inv.size() < D.PACK_MAX or wears_now(p, items[ia])):
				gain(p, items.pop_at(ia))
		"eq":
			if ia >= 0 and ia < p.inv.size() and can_use(p, p.inv[ia]) and D.SLOTK.has(D.IT[p.inv[ia]].s):
				wear(p, p.inv.pop_at(ia))
		"uneq":
			if D.SLOTS.has(sa) and p.get(sa) > 0 and p.inv.size() < D.PACK_MAX:
				p.inv.append(p.get(sa)); take_off(p, sa)
		"dropi":
			if ia >= 0 and ia < p.inv.size():
				drop_item(p.inv.pop_at(ia), p.x, p.z)
		"destroy":                                  # broken up, burnt or thrown in the river: gone for good
			if ia >= 0 and ia < p.inv.size():
				var gone: int = p.inv.pop_at(ia)
				if D.IT[gone].tier == "relic": relics.erase(gone)   # (a relic finds its way back into the rubble, in time)
				ev.append(["smash", r1(p.x), r1(p.z)])
		"forge":
			if near_station(p, "smithy") and ia >= 0 and ia < D.IT.size() and not D.IT[ia].cost.is_empty():
				var I: Dictionary = D.IT[ia]
				var c := forge_cost(p, I.cost)
				if can_forge(p, ia) and has(p, c):
					pay(p, c)
					if can_use(p, ia): wear(p, ia)
					else: stow(p, ia)
					add_xp(p, 3, 1); spark.call("forge")
					if I.s == "w": say("%s has forged %s." % [p.dn, D.it_a(ia)])
		"armp":
			if near_station(p, "smithy"):
				var c := forge_cost(p, D.PEASANT_ARM)
				var n := 0
				for q in peasants:
					if q.owner == p.id and not q.armed and q.state != "body" and has(p, c):
						pay(p, c); q.armed = 1; add_xp(p, 3, 1); n += 1
						if rk(p, 3) < 3: break
				if n: spark.call("forge")
		"book":
			if near_station(p, "library") and ia >= 0 and ia < D.BOOKS.size() and not p.books[ia] and book_slots(p) > 0 and not (is_class_book(ia) and class_of(p) >= 0):
				var t0 := title_of(p)
				p.books[ia] = 1; say("%s has taken up %s." % [p.dn, D.BOOKS[ia].name])
				if p.card_rank > 1:                         # a library card was handed in: not quite from the beginning
					p.books[ia] = mini(7, p.card_rank); p.xp[ia] = need_xp(ia, p.books[ia] - 1)
					say("%s read ahead, and starts %s at rank %d." % [p.dn, D.BOOKS[ia].name, p.books[ia]])
				p.card_rank = 0
				if is_class_book(ia): say("%s is training as an %s. Heaven help us all." % [p.dn, D.CLASSES[class_of(p)].name])
				retitle(p, t0)
				if ia == 5:
					stow(p, 12); ev.append(["found", p.id, "a sling, tucked inside the cover", r1(p.x), r1(p.z), 0, 1])
		"recruit":
			if near_station(p, "slum"):
				var c := {"food": slum_food(p)}
				var pop := peasants.filter(func(q): return q.state != "body").size()
				if has(p, c) and p.posse < posse_max(p) and pop < pop_cap():
					pay(p, c)
					var used := {}
					for q in peasants: used[q.ni] = true
					var ni := randi() % D.PNAMES.size()
					for i in D.PNAMES.size():
						if not used.has(ni): break
						ni = (ni + 1) % D.PNAMES.size()
					var h := home_spot(p.slot, randi() % 5, 5)
					peasants.append(mk_peasant(ni, p.x - 1.2, p.z + 1.2, h.x, h.z, p.id)); add_xp(p, 6, 4)
					say("%s has left the slum to follow %s." % [D.PNAMES[ni], p.dn])
		"ale":
			if near_station(p, "inn"):
				var n := mini(5, p.food)
				if n > 0:
					p.food -= n; ale += n; spark.call("eat")
		"innin":
			if near_station(p, "inn") and phase != "day" and innHp > 0:
				p.state = "inn"; p.room = "inn"; p.x = D.INN.x - 3.2 + p.slot * 0.9; p.tx = p.x; p.z = D.INN.z; p.tz = p.z; p.r = PI; p.goal_r = PI; p.tp = tpc; tpc += 1; p.gk = 0; p.prog = 0; p.study = false; p.game = {}
				for q in peasants:
					if q.owner == p.id and (q.state == "follow" or q.state == "fight" or q.state == "chop"):
						q.state = "inn"; q.tree = null
				say("%s has gone into the Thorny Rose Inn and barred the door." % p.dn)
		"mbuy":                                     # buy from the merchant. arg: "i" or "i:book"
			var bits: PackedStringArray = str(arg).split(":")
			var i := int(bits[0])
			if near_station(p, "cart") and merchant >= 0 and phase == "day" and i >= 0 and i < wares.size():
				var wv: Dictionary = wares[i]
				if wv.left > 0 and p.coin >= wv.price:
					var done := true
					match wv.give:
						"iron":
							done = p.iron < cap(p); p.iron = mini(cap(p), p.iron + 5)
						"food":
							done = p.food < cap(p); p.food = mini(cap(p), p.food + 5)
						"ale":
							ale += 5
						"cogs":
							p.cogs += 1
						"it":
							done = p.inv.size() < D.PACK_MAX or wears_now(p, wv.it)
							if done: gain(p, wv.it)
						"index":
							done = not p.xslot; p.xslot = true
						"page":
							var b := int(bits[1]) if bits.size() > 1 else -1
							done = b >= 0 and rk(p, b) > 0 and rk(p, b) < 7 and p.jobT <= 0
							if done:
								var rr := rk(p, b)
								add_xp(p, b, ceili((need_xp(b, rr) - (need_xp(b, rr - 1) if rr > 1 else 0)) * 0.25))
						"relic":
							if wv.real >= 0 and not relics.has(wv.real):
								relics.append(wv.real); gain(p, wv.real)
								say("%s has bought %s from the relic pedlar. It is the real thing: %s!" % [p.dn, wv.n, D.IT[wv.real].n])
								ev.append(["found", p.id, D.IT[wv.real].n, r1(p.x), r1(p.z), 1, 1])
							else:
								say("%s has bought %s from the relic pedlar. It is, on closer inspection, rubbish." % [p.dn, wv.n])
					if done:
						p.coin -= wv.price; wv.left -= 1; spark.call("coin")
		"job":
			if near_station(p, "cart") and merchant >= 0 and phase == "day" and not job.done:
				p.job = not p.job
				if p.job: say("%s has agreed to %s." % [p.dn, D.MERCHANTS[merchant].job.to_lower()])
		"guard":
			if near_station(p, "bailiff") and guards < D.GUARDS and p.coin >= guard_fee():
				p.coin -= guard_fee()
				var post: Array = D.POSTS[guards % D.POSTS.size()]
				var q := mk_peasant(guards, post[0], post[1], post[0], post[1], 0)
				q.kind = 1; q.state = "post"; q.armed = 1; q.hp = q_max(q); q.px = post[0]; q.pz = post[1]
				peasants.append(q)
				say("Robert Bailiff opens the door a crack, takes %s’s money, and sends %s to %s for the night." % [p.dn, D.qname(q), D.POST_NAMES[guards % D.POSTS.size()]])
				guards += 1; spark.call("coin"); note("hired")
		"merc":
			if near_station(p, "inn") and not p.merc and p.coin >= D.MERC_FEE:
				p.coin -= D.MERC_FEE; p.merc = true
				var h := home_spot(p.slot, randi() % 5, 5)
				var q := mk_peasant(randi() % D.MERC_NAMES.size(), p.x - 1.2, p.z + 1.2, h.x, h.z, p.id)
				q.kind = 2; q.armed = 1; q.hp = q_max(q)
				peasants.append(q)
				say("%s has hired %s at the Thorny Rose Inn. What could possibly go wrong?" % [p.dn, D.qname(q)]); note("hired")
				spark.call("coin")
		"btalk", "bknock", "bjeer":                # Robert Bailiff, at his upstairs window
			if near_station(p, "window"):
				var w := week_of(mday())
				match a:
					"btalk": bail_line = pick(D.BAILIFF_TALK[w - 1])
					"bknock":
						bail_line = pick(D.BAILIFF_KNOCK); ev.append(["knock", r1(p.x), r1(p.z)])
					"bjeer":
						bail_line = pick(D.BAILIFF_JEER); bail_mood += 1; note("jeer"); ev.append(["jeer", r1(p.x), r1(p.z)])
						say("%s has jeered at Robert Bailiff. His guards are a shilling dearer today." % p.dn)
				bail_t = 6.0
		"card":                                     # a library card: give up a book, to take up another
			if near_station(p, "library") and p.inv.has(D.I_CARD) and ia >= 0 and ia < D.BOOKS.size() and p.books[ia] > 0:
				var t0 := title_of(p)
				p.inv.erase(D.I_CARD)
				p.card_rank = maxi(1, p.books[ia] - 1)
				say("%s has handed in a library card and given up %s (rank %d). The librarian has stamped something." % [p.dn, D.BOOKS[ia].name, p.books[ia]])
				p.books[ia] = 0; p.xp[ia] = 0.0
				retitle(p, t0); spark.call("page")
		"treat":                                    # a drink for one of the locals in the Rose: one good turn each, a day
			if ia >= 0 and ia < D.LOCALS.size() and p.room == "inn" and near_station(p, "local%d" % ia) and p.coin >= D.TREAT and not (p.treated & (1 << ia)):
				p.coin -= D.TREAT; p.treated |= 1 << ia; spark.call("coin")
				var tip := ""
				match ia:
					0:
						p.food = mini(cap(p), p.food + 3); tip = "Old Marge gives %s a pie out of her basket. It is still warm, which is a worry." % p.dn
					1:
						if not chest.is_empty() and not chest.open:
							chest.seen = true
							tip = "Tam the Carter tells %s: “I saw a man down, %s, and a box by him with a seal on. I did not stop. It is marked on your map now.”" % [p.dn, D.CHEST_ROADS[chest.road]]
						else:
							ruins_seen = [true, true, true]
							tip = "Tam the Carter tells %s where the outer ruins have got to today. They are on the map." % p.dn
					2:
						var nb := 0
						for d in D.BOSS_NIGHTS:
							if last_day >= D.MONTH and int(d) >= day and (nb == 0 or int(d) < nb): nb = int(d)
						var k: int = D.BOSS_NIGHTS[nb] if nb else D.U_LORD
						tip = "The stranger tells %s: “%s”" % [p.dn, D.BOSS_HINT[k]]
				say(tip); ev.append(["tip", p.id, D.LOCALS[ia].name, tip])
		"etch":                                     # three runes, cut into the weapon in your hand
			if near_station(p, "smithy") and p.rune >= D.ETCH_RUNES and p.etch != p.wpn:
				p.rune -= D.ETCH_RUNES; p.etch = p.wpn; spark.call("forge")
				say("%s has had runes cut into %s %s. It hums, slightly." % [p.dn, "their", D.IT[p.wpn].n])
		"lread":                                    # the letter on the gatepost has been read
			letter_new = false
		"study":
			if near_station(p, "priest") and p.holy < 2:
				p.study = not p.study
		"bless":
			var free := p.holy >= 2 if sa == "b" else p.holy >= 1
			var okW: bool = sa == "w" and not (p.bless & 1) and not D.IT[p.wpn].holy
			var okK := sa == "k" and p.trk == 28 and not (p.bless & 2)
			var okB := sa == "b" and p.bbod < p.bodies
			if (okW or okK or okB) and (free or (near_station(p, "priest") and p.coin >= D.BLESS_FEE)):
				if not free: p.coin -= D.BLESS_FEE
				if okW: p.bless |= 1
				elif okK: p.bless |= 2
				else: p.bbod += 1
				spark.call("holy")


# --- one step of the world
func step(dt: float) -> void:
	if not chest.is_empty() and not chest.seen:           # and the same for the chest that never arrived
		for p in players:
			if p.state == "ok" and D.d2(p.x, p.z, chest.x, chest.z) < 13 * 13:
				chest.seen = true
				ev.append(["chest", r1(chest.x), r1(chest.z)])
				say("%s has found a dead messenger, and a chest with %s’s seal on it." % [p.dn, D.CHEST_FROM[chest.from][0]])
	if not (ruins_seen[1] and ruins_seen[2]):             # anyone who comes near an outer ruin finds it, for everyone
		var cs: Array = Map.ruin_layout(gseed, day).centres
		for p in players:
			if p.state != "ok": continue
			for k in [1, 2]:
				if not ruins_seen[k] and D.d2(p.x, p.z, cs[k].x, cs[k].z) < 18 * 18:
					ruins_seen[k] = true
					ev.append(["ruin", k])
					say("%s has found one of the outer ruins." % p.dn)
	if phase == "day":
		nf = maxf(0, nf - dt / 6); timeLeft -= dt
		if timeLeft <= 0 or (players.size() and players.all(func(p): return p.ready)):
			dusk_falls()
	elif phase == "dusk":
		timeLeft -= dt; nf = clampf(1 - timeLeft / D.DUSK_LEN, 0, 1)
		if timeLeft <= 0: start_night()
	elif phase == "night":
		night_step(dt)
	elif phase == "won":
		nf = maxf(0, nf - dt / 6)
	if not live():
		return
	innIn = 0
	bell_t = maxf(0, bell_t - dt); bail_t = maxf(0, bail_t - dt)
	for p in players:
		if p.state == "inn": innIn += 1
		player_step(p, dt)
	for q in peasants:
		peasant_step(q, dt)
	undead_step(dt); spikes_step(dt); contraptions_step(dt)
	if undead.any(func(u): return u.dead):
		var keep := []
		for u in undead:
			if u.dead: ev.append(["gone", "u", u.id, r1(u.x), r1(u.z), u.k])
			else: keep.append(u)
		undead = keep

func dusk_falls() -> void:
	phase = "dusk"; timeLeft = D.DUSK_LEN
	for p in players:                              # someone in every posse has something to say about it
		var mine := peasants.filter(func(q): return q.owner == p.id and active(q))
		if mine.size(): bark(mine[randi() % mine.size()], D.BARK_DUSK)
	for q in peasants:
		if q.state == "idle": q.state = "hide"
	for p in players:
		p.ready = false; p.coward = false
	for s in structs:
		if s.k == "logs": s.tick = 1.0                 # the log roller is stacked again for the night
	var rot := 0
	var gone := 0                                  # every evening the damp takes half of what is left of an old barricade
	for s in structs.duplicate():
		if s.k == "barricade" and not s.re and not s.nr and s.age >= 1:
			s.mhp = float(roundi(s.mhp / 2)); s.hp = minf(s.mhp, ceilf(s.hp / 2)); rot += 1
			if s.mhp < 20:
				destroy_struct(s); gone += 1
	if rot:
		sv += 1
		say("The evening damp has rotted %d old barricade%s by half" % [rot, "s" if rot > 1 else ""] + (", and %d fell apart." % gone if gone else ".") + " Iron braces stop the rot.")

## How much bigger tonight's horde is than night 1's: a quarter more each night of the first week, then it eases
## off at the start of each new week and grows more slowly (the new kinds of dead make up the difference).
static func growth(d: int) -> float:
	var g := 1.0
	for i in range(2, d + 1):
		if i <= 7: g *= D.NIGHT_GROWTH
		elif i == 8 or i == 15 or i == 22: g *= 0.88
		elif i < 15: g *= 1.07
		elif i < 22: g *= 1.05
		else: g *= 1.04
	return g

## What share of tonight's horde each kind makes up, on night md of the month (before dividing by what each is worth).
static func mix(md: int, newk: Array) -> Array:
	var w := []
	w.resize(D.UN.size()); w.fill(0.0)
	w[0] = 1.0
	if md >= 2: w[1] = 0.15 if md == 2 else 0.2
	if md >= 4: w[2] = 0.06 if md == 4 else 0.1
	if md >= 8: w[D.U_GHOUL] = 0.22
	if md >= 10: w[D.U_DIGGER] = 0.14
	if md >= 12: w[D.U_BATS] = 0.14
	if md >= 15: w[D.U_GUARD] = 0.18
	if md >= 18: w[D.U_WRAITH] = 0.12
	if md >= 20: w[D.U_RAM] = 0.12
	for k in newk: w[k] *= 1.5                      # the night they first come, there are rather a lot of them
	return w

## The kinds of dead coming down for the first time on night d.
static func new_kinds(d: int, last: int) -> Array:
	var md := month_day(d, last)
	var before := month_day(d - 1, last) if d > 1 else 0
	var out := []
	for k in D.UN.size():
		if not D.UN[k].boss and D.UN[k].first <= md and D.UN[k].first > before: out.append(k)
	return out

## Who comes down from the graveyard tonight, and over how long. c: how many of each kind (bosses apart).
static func night_plan(d: int, n: int, last: int = D.MONTH) -> Dictionary:
	var md := month_day(d, last)
	var g := growth(d) if last >= D.MONTH else pow(D.NIGHT_GROWTH, d - 1)
	var budget := D.NIGHT_BASE * (1 + D.NIGHT_PER_PLAYER * (n - 1)) * g
	var newk := new_kinds(d, last)
	var w := mix(md, newk)
	var sum := 0.0
	for v in w: sum += v
	var c := []
	c.resize(D.UN.size()); c.fill(0)
	for k in w.size():
		if w[k] > 0:
			c[k] = maxi(1 if newk.has(k) else 0, roundi(budget * w[k] / sum / D.UN[k].cost))
	c[D.U_RAM] = mini(c[D.U_RAM], 1 + floori(n / 3.0))
	var heads := 0
	for v in c: heads += v
	var crowd_ := 1.0
	if heads > D.NIGHT_HEADS:                       # too many to show: fewer of them, and tougher (so eight players still face eight hordes' worth)
		var keep := 0
		for k in c.size():
			if c[k] > 0:
				c[k] = maxi(1, roundi(c[k] * float(D.NIGHT_HEADS) / heads)); keep += c[k]
		crowd_ = float(heads) / keep
	var dur := D.NIGHT_RISE + D.NIGHT_RISE_DAY * mini(d - 1, 6) + 4.0 * maxi(0, d - 7)
	return {"c": c, "dur": dur, "boss": boss_of(d, last), "crowd": crowd_}

# The dead do not come in waves. They rise one after another all night, slowly at first and faster as it goes on:
# the last of them come up a little over twice as fast as the first.
func night_queue(plan: Dictionary) -> Array:
	var kinds := []
	for k in plan.c.size():
		for i in plan.c[k]: kinds.append(k)
	for i in range(kinds.size() - 1, 0, -1):
		var j := randi() % (i + 1)
		var t = kinds[i]; kinds[i] = kinds[j]; kinds[j] = t
	var late := func(k: int) -> bool: return k == 2 or D.UN[k].ram or k == D.U_WRAITH
	var first := mini(6, kinds.size())
	for i in first:                                 # no archers, rams or wraiths among the very first
		if late.call(kinds[i]):
			for j in range(first, kinds.size()):
				if not late.call(kinds[j]):
					var t = kinds[i]; kinds[i] = kinds[j]; kinds[j] = t
					break
	var half := kinds.size() / 2                    # a coffin ram takes a while to get organised
	for i in half:
		if D.UN[kinds[i]].ram:
			for j in range(kinds.size() - 1, half, -1):
				if not D.UN[kinds[j]].ram:
					var t = kinds[i]; kinds[i] = kinds[j]; kinds[j] = t
					break
	var out := []
	for i in kinds.size():
		var f := (i + 0.5) / kinds.size()
		var x := (-0.6 + sqrt(0.36 + 1.6 * f)) / 0.8
		out.append({"k": kinds[i], "t": 4 + plan.dur * x})
	return out

func spawn_undead(k: int, x = null, z = null) -> E.Undead:
	var U: Dictionary = D.UN[k]
	var sx: float = (randf() * 2 - 1) * D.SPAWN_W if x == null else x
	var u := E.Undead.new()
	u.id = nid; nid += 1
	u.k = k; u.x = sx; u.z = D.SPAWN_Z + (randf() * 2 - 1) * 4.5 if z == null else z
	u.hp = U.hp * tough * crowd; u.cd = randf(); u.lane = clampf(sx * 0.62 + (randf() * 2 - 1) * 3.5, -20, 20); u.jit = (randf() * 2 - 1) * 1.7
	if U.ram:                                       # a coffin ram goes for the gate
		u.lane = 0; u.jit = 0
	if U.boss:
		u.hp = roundf(U.hp * (1 + 0.5 * (players.size() - 1))); u.lane = 0; boss = u
		for q in peasants: nerve_hit(q, 25)
	u.mhp = u.hp
	undead.append(u)
	return u

## A boss comes down. The Captain of the Guard brings his guard with him, against one gate.
func spawn_boss(k: int) -> void:
	var u := spawn_undead(k, 0.0, D.SPAWN_Z)
	match k:
		D.U_STEWARD:
			say("The Steward has come down to supervise.")
		D.U_COACH:
			u.march = true; u.lane = rnd2(-1.5, 1.5)
			say("Hooves on the castle road. The Coachman is driving the hearse down, and he is not stopping for anything made of wood.")
		D.U_CAPTAIN:
			u.side = [-1, 0, 1][randi() % 3]
			var gate: String = ["the west gateway", "the north gate", "the east gateway"][u.side + 1]
			for i in 5 + players.size():
				var g := spawn_undead(D.U_GUARD, u.x + rnd2(-4, 4), u.z + rnd2(-3, 3))
				g.side = u.side; g.lane = rnd2(-2, 2)
			say("The Captain of the Guard has come down with the Lord’s guard behind him. They are making for %s." % gate)
		D.U_LORD:
			say("The Lord of Ashhollow has come down from his castle in person. He has brought his bats.")

func start_night() -> void:
	phase = "night"; nf = 1; timeLeft = 0; graves = []; fallen = []
	tough = tough_of(mday())
	var plan := night_plan(day, players.size(), last_day)
	crowd = plan.crowd; crowd_d = 1.0 + 0.6 * (crowd - 1.0)
	var q := night_queue(plan)
	night = {"t": 0.0, "q": q, "total": q.size(), "c": plan.c, "dur": plan.dur, "kills": 0, "boss": plan.boss, "idle": 0.0}
	waves = q.size()
	for p in players: p.ready = false

func night_step(dt: float) -> void:
	var N: Dictionary = night
	N.t += dt
	while N.q.size() and N.q[0].t <= N.t and undead.size() < D.ALIVE_CAP:
		spawn_undead(N.q.pop_front().k)
	# a boss arrives once the night is well under way (the Coachman sooner, the Lord later)
	var when := 0.8 if N.boss == D.U_COACH else 0.45 if N.boss == D.U_LORD else 0.6
	if N.boss >= 0 and N.q.size() <= N.total * when:
		var k: int = N.boss
		N.boss = -1; spawn_boss(k)
	# with nobody left standing (all dead, or under their beds) the dead make short work of what is in their way, so the night is not dragged out
	N.idle = 0.0 if players.any(func(p): return (p.state == "ok" and p.room != "mine") or p.state == "down" or p.state == "inn") else N.idle + dt
	rage = minf(40, 6 + (N.idle - 12) * 0.4) if N.idle > 12 else 1.0
	wave = N.q.size(); left = undead.size() + N.q.size() + (1 if N.boss >= 0 else 0)   # wave: how many have still to rise
	if keepHp <= 0:
		keepHp = 0; phase = "lost"
		return
	if left == 0: end_night()

## What the dawn notice says about tonight: new kinds of dead, a boss, the weather.
func tonight_lines() -> Array:
	var out := []
	const WHAT := {1: "skeletons, which get up again unless you hit the bones", 2: "skeleton archers, who shoot from the road",
		D.U_GHOUL: "ghouls, which are fast and climb straight over barricades (not walls)",
		D.U_DIGGER: "gravediggers, which tunnel under the north wall and come up inside it",
		D.U_BATS: "bat swarms, which fly over everything straight for the keep. Slings, bows and the handbell bring them down",
		D.U_GUARD: "the Lord’s guard: armoured, hard on walls, and barely dented by farm tools. Maces and hammers",
		D.U_WRAITH: "wraiths, which drift through walls. Ordinary weapons pass straight through them: only holy things hurt them",
		D.U_RAM: "a coffin ram, carried down the road at the north gate. A warhammer, or a very strong gate"}
	var nk := new_kinds(day, last_day)
	if nk.size():
		var bits := []
		for k in nk: if WHAT.has(k): bits.append(WHAT[k])
		if bits.size(): out.append("Word from the graveyard: tonight there will be " + "; and ".join(bits) + ".")
	var b := boss_of(day, last_day)
	if b >= 0:
		out.append({D.U_STEWARD: "Tonight the Steward himself will come down to supervise.", D.U_COACH: "Tonight the Coachman drives the hearse down the castle road. Wood will not stop him; stone and iron might.",
			D.U_CAPTAIN: "Tonight the Captain of the Guard leads the Lord’s guard against one of the gates.", D.U_LORD: "Tonight is the last night. The Lord of Ashhollow is coming down in person."}[b])
	return out

func grow_trees() -> void:   # dawn in the forest: saplings that are old enough become trees, and yesterday's stumps rot into saplings
	for t in trees:
		if t.st == 2 and day >= t.gd:
			t.wood = D.TREE_WOOD; t.set_state(0, t.par)
		elif t.st == 1:
			t.set_state(2, 1 - t.par if t.dx or t.dz else t.par); t.gd = day + 1 + (t.i % 2)
	tv += 1

func end_night() -> void:   # dawn: count the cost, bring people home, start the next day
	var N: Dictionary = night
	var lines := ["Night %d is over. %d of the dead were put back down." % [day, N.kills]]
	if fallen.size():
		lines.append("Fallen: %s. What is left lies where it fell, and could still be useful." % ", ".join(fallen))
	var share: int = 6 + floori(N.kills / 5.0)
	var paid := 0
	for p in players:
		if p.state == "inn": leave_inn(p, false)
		if p.state == "dead":
			var was: String = p.dn
			var kept := []
			for id in [p.wpn, p.head, p.body, p.off, p.trk] + p.inv:
				if id > 0 and D.IT[id].tier == "relic": kept.append(id)
			p.deaths += 1; p.dn = D.rel_name(p.name, p.deaths)
			for id in kept: drop_item(id, p.x, p.z)
			p.wood = 0; p.stone = 0; p.iron = 0; p.food = 0; p.bodies = 0; p.bbod = 0; p.wpn = 0; p.head = -1; p.body = -1; p.off = -1; p.trk = -1
			p.inv = []; p.hp = D.PLAYER_HP; p.state = "ok"; p.coward = false
			var kn := []
			for id in kept: kn.append(D.it_cap(id))
			lines.append("%s did not see the dawn. %s has taken up the pitchfork, and the cottage." % [was, p.dn[0].to_upper() + p.dn.substr(1)]
				+ (" %s still %s where %s fell." % [" and ".join(kn), "lie" if kept.size() > 1 else "lies", was] if kept.size() else ""))
		else:
			if p.state == "down": p.hp = 30
			if p.fought and D.IT[p.wpn].tier == "crude":    # a crude weapon wears: chipped after one night's fighting, gone after two
				var I: Dictionary = D.IT[p.wpn]
				if I.wear == 1:
					p.wpn += 1; lines.append("%s’s %s is chipped after the night’s work." % [p.dn, I.n])
				else:
					lines.append("%s’s %s has fallen to bits. The smithy can make another, or Hammer and Tongs a better one." % [p.dn, I.n])
					p.wpn = 0; p.bless &= ~1
			p.fought = false
			var hid: bool = p.coward
			p.state = "ok"; p.hp = minf(max_hp(p), p.hp + 25)
			if hid: lines.append("%s spent the night under the bed. The village has noticed, and will remember until dusk." % p.dn)
			else:
				p.coin += share; paid += 1
		var c := D.cottage(p.slot)
		p.x = c.sx; p.tx = p.x; p.z = c.sz; p.tz = p.z; p.tp = tpc; tpc += 1; p.gk = 0; p.prog = 0; p.bite = 0; p.room = ""
		# blessings and Dutch courage both wear off by morning
		p.bless = 0; p.bbod = 0; p.cg = 0; p.charge = 0; p.hang = 0; p.drinkT = 0; p.parry = 0; p.guard = 0; p.upOnce = false; p.study = false; p.order = 0; p.abCd = 0; p.useCd = 0; p.tbCd = 0; p.p1Cd = 0; p.p2Cd = 0; p.prot = 0; p.hb = 0
	if paid: lines.append("The village passed the hat: %s for everyone who stood and fought." % D.coins(share))
	if ale > 0: lines.append("The innkeeper finished the last %d tankard%s himself." % [ale, "s" if ale > 1 else ""])
	var hired := peasants.filter(func(q): return q.kind != 0 and q.state != "body")
	for q in hired:                                 # the hired help goes home at dawn (and the odd mercenary turns on his employer)
		peasants.erase(q)
		if q.kind != 2: continue
		var own := player_by_id(q.owner)
		if own and randf() < 1.0 / 7.0:
			if own.coin >= 24:
				own.coin -= 24; lines.append("%s turned on %s at dawn and demanded another two shillings. %s paid up." % [D.qname(q), own.dn, own.dn])
			else:
				var things: Array = own.inv.duplicate()
				for k in ["wpn", "head", "body", "off", "trk"]:
					if own.get(k) > 0: things.append(own.get(k))
				if things.is_empty():
					lines.append("%s turned on %s at dawn for two more shillings, found nothing worth taking, and left in disgust." % [D.qname(q), own.dn])
				else:
					var id: int = things[randi() % things.size()]
					if own.inv.has(id): own.inv.erase(id)
					else:
						for k in ["wpn", "head", "body", "off", "trk"]:
							if own.get(k) == id:
								take_off(own, k)
								break
					if D.IT[id].tier == "relic": relics.erase(id)
					lines.append("%s turned on %s at dawn and demanded two more shillings. %s could not pay, was given a good hiding, and lost %s." % [D.qname(q), own.dn, own.dn, D.it_a(id)])
	if guards > 0: lines.append("The village guards have gone back inside Robert Bailiff’s house for their breakfast.")
	guards = 0
	var row := {}
	for q in peasants:                              # the living come home, and line up outside their leader's door
		if q.state == "body": continue
		var own := player_by_id(q.owner)
		q.hp = D.PEASANT_HP; q.tree = null; q.nv = 100; q.saved = false
		if own:
			row[own.id] = row.get(own.id, 0) + 1
			var h := home_spot(own.slot, row[own.id], 7)
			q.x = h.x; q.z = h.z; q.state = "follow"
		else:
			q.owner = 0; q.state = "idle"; q.x = q.hx; q.z = q.hz
	for p in players:
		if p.coward:                                # nobody new follows a coward, and one of the posse walks off
			var mine := peasants.filter(func(q): return q.owner == p.id and q.state != "body")
			while mine.size() > posse_max(p):
				var q: E.Peasant = mine.pop_back()
				q.owner = 0; q.state = "idle"; q.x = q.hx; q.z = q.hz
	for s in structs: s.age += 1
	undead = []; boss = null
	var up := peasants.filter(func(q): return q.state == "follow")
	if up.size(): bark(up[randi() % up.size()], D.BARK_DAWN)
	if day >= last_day:
		phase = "won"; dawn = {"seq": dawn.seq + 1, "day": day, "lines": lines}
		if save_hook.is_valid(): save_hook.call({})
		return
	crowd = 1.0; crowd_d = 1.0
	day += 1; grow_trees(); roll_day(false); lines.append(site_line())
	tough = tough_of(mday())
	if new_chest(): lines.append("Word has come, late and by pigeon, that %s sent a chest of help to Thornhallow. The messenger set off %s and has not been seen since." % [D.CHEST_FROM[chest.from][0], D.CHEST_ROADS[chest.road]])
	var stale := drops.filter(func(d): return day - d.day >= D.DROP_DAYS)       # things left lying about: after two days nobody cares
	if stale.size():
		for d in stale:
			drops.erase(d)
			if D.IT[d.it].tier == "relic": relics.erase(d.it)
		lines.append("%s left lying on the ground for two days %s gone. Nobody knows where, and nobody is asking." % [D.it_a(stale[0].it).capitalize().substr(0, 1) + D.it_a(stale[0].it).substr(1) if stale.size() == 1 else "%d things" % stale.size(), "has" if stale.size() == 1 else "have"])
	lines.append_array(tonight_lines())
	var li := next_letter()
	if li >= 0:
		letters.append([li, day]); letter_new = true; ev.append(["rider"])
		lines.append("A headless rider came down from the castle at first light and nailed a letter to the gatepost by the north gate. It is from the Lord of Ashhollow, and it is a complaint.")
	if merchant >= 0:
		var M: Dictionary = D.MERCHANTS[merchant]
		lines.append("A merchant has come: %s, parked by the market, selling %s. He has a job going, too." % [M.name, M.sells])
	start_day(lines)


func player_step(p: E.Player, dt: float) -> void:
	p.atkCd = maxf(0, p.atkCd - dt); p.eatCd = maxf(0, p.eatCd - dt); p.hurtT += dt; p.workT = maxf(0, p.workT - dt)
	p.p1Cd = maxf(0, p.p1Cd - dt); p.p2Cd = maxf(0, p.p2Cd - dt); p.prot = maxf(0, p.prot - dt); p.hb = maxf(0, p.hb - dt)
	p.abCd = maxf(0, p.abCd - dt); p.useCd = maxf(0, p.useCd - dt); p.tbCd = maxf(0, p.tbCd - dt); p.parry = maxf(0, p.parry - dt); p.guard = maxf(0, p.guard - dt); p.hang = maxf(0, p.hang - dt)
	if p.charge > 0:
		p.charge -= dt
		if p.charge <= 0:
			p.charge = 0
			var r := rk(p, 7)
			p.hang = 0.0 if r >= 4 else 5.0 if r >= 3 else 10.0
	if p.remote:
		var k := minf(1, dt * 16)
		p.x = lerpf(p.x, p.tx, k); p.z = lerpf(p.z, p.tz, k); p.r = D.ang_lerp(p.r, p.goal_r, k)
	if p.state == "down":
		p.downT -= dt
		if p.downT <= 0:
			p.state = "dead"; say("%s is dead." % p.dn)
		return
	if p.state == "dead":
		return
	var n := 0
	for q in peasants:
		if q.owner == p.id and q.state != "body": n += 1
	p.posse = n
	if not p.game.is_empty():                      # a game with the gambler: the cups take their time, and walking off forfeits the stake
		if p.room != "inn" or p.state != "ok" or not near_station(p, "gambler"): p.game = {}
		elif p.game.g == "cups" and float(p.game.t) > 0: p.game.t = maxf(0.0, float(p.game.t) - dt)
	if p.state == "inn":                           # drinking: each tankard takes a few seconds and fills the courage meter
		p.gk = 0; p.prog = 0
		if phase == "day":
			leave_inn(p, false)
			return
		if p.drinkT > 0:
			p.drinkT -= dt
			if p.drinkT <= 0:
				p.drinkT = 0; p.cg = minf(100, p.cg + (D.TANKARD + 4 * rk(p, 7)) * (2.0 if reserve else 1.0)); add_xp(p, 7, 1); p.cc += 1
				if rk(p, 7) >= 5:
					for o in players:
						if o != p and o.state == "inn": o.cg = minf(100, o.cg + 10)
				if p.cg >= 100: leave_inn(p, true)
		for o in players:
			if o.state == "inn" and o.cg >= 100: leave_inn(o, true)
		return
	if rk(p, 9) >= 4 and p.hp < max_hp(p):
		p.hp = minf(max_hp(p), p.hp + dt)
	if p.study:                                    # a class in holy studies: stay by the priest until it is over
		var st: Dictionary = D.STATIONS[6]
		if p.state != "ok" or p.holy >= 2 or D.d2(p.x, p.z, st.x, st.z) > pow(st.r + 1.5, 2):
			p.study = false
		else:
			p.holyT += dt
			if p.holyT >= D.HOLY_TIME:
				p.holyT = 0; p.holy += 1; p.study = false; ev.append(["holy", r1(p.x), r1(p.z)])
				say(("%s has sat through a class in holy studies, and can now bless a weapon or a bucket." if p.holy == 1 else "%s has finished holy studies, and can now bless the departed.") % p.dn)
	if p.job:                                      # working on the merchant's job: stay where the job is
		if merchant < 0 or job.done or phase != "day":
			p.job = false
		elif near_job(p):
			job.work += dt; p.jobT += dt
			if job.work >= D.JOB_WORK: finish_job()
	if not p.eHold: p.eLock = false                # going in or out of the cottage needs a fresh press of E
	var it = find_interact(p) if p.eHold and not p.eLock else null
	if it == null or it.key != p.itKey:
		p.itT = 0; p.itKey = it.key if it else ""; p.bite = 0; p.fishT = fish_wait(p)
	p.gk = 0; p.prog = 0
	if it and it.ok and it.type == "gather" and it.kind == "fish":   # fishing: wait for the bite
		p.gk = 5
		if p.bite > 0:
			p.bite -= dt
			if p.bite <= 0: p.fishT = fish_wait(p)
		else:
			p.fishT -= dt
			if p.fishT <= 0:
				p.bite = 1.2; ev.append(["bite", p.id])
	elif it and it.ok:
		p.itT += dt; p.prog = minf(1, p.itT / it.dur)
		if it.type == "gather":
			p.gk = D.GK.find(it.kind); p.workT = maxf(p.workT, 20.0 if rk(p, 0) >= 4 else 0.8); p.workK = it.kind; p.workX = it.x; p.workZ = it.z
			if not p.remote: p.r = D.ang_lerp(p.r, atan2(it.x - p.x, it.z - p.z), minf(1, dt * 12))
		elif it.type == "search":
			p.gk = 6
		elif it.type == "rune":
			p.gk = 3
			if not p.remote: p.r = D.ang_lerp(p.r, atan2(it.x - p.x, it.z - p.z), minf(1, dt * 12))
		if p.itT >= it.dur:
			p.itT = 0
			match it.type:
				"unhide":
					p.state = "ok"; p.eLock = true
				"bell":
					if bell_t <= 0:
						bell_t = 2.5; ev.append(["bellring", r1(it.x), r1(it.z)]); note("bell")
						if randf() < 0.4: say(pick(D.BELL_LINE))
				"hide":
					p.state = "hide"; p.coward = true; p.gk = 0; p.eLock = true; say("%s has gone to hide under the bed." % p.dn)
				"revive":
					var o: E.Player = it.target
					o.state = "ok"; o.hp = 70.0 if rk(p, 9) >= 2 else 40.0; o.hurtT = 0; add_xp(p, 9, 3)
				"bandage":
					var o = it.target
					var mx: float = max_hp(o) if it.isP else q_max(o)
					o.hp = mx if rk(p, 9) >= 6 else minf(mx, o.hp + 25 + 5 * rk(p, 9)); add_xp(p, 9, 1); ev.append(["eat", r1(o.x), r1(o.z)])
				"pick":
					var d: E.Drop = it.target
					if drops.has(d):
						drops.erase(d); gain(p, d.it); ev.append(["coin", r1(p.x), r1(p.z)])
				"rally":
					it.target.owner = p.id; it.target.state = "follow"; add_xp(p, 6, 2)
					if randf() < 0.6: bark(it.target, D.BARK_RALLY)
				"body":
					peasants.erase(it.target); p.bodies += 1
				"found":
					var s: E.Struct = it.target
					pay(p, cost_of(p, s.k)); s.built = true; s.mhp = D.SHP[s.k]; s.hp = s.mhp; s.re = false; s.bl = false; stats.built += 1; sv += 1; add_xp(p, 2, 1)
				"repair":
					var s: E.Struct = it.target
					pay(p, repair_cost(p, s)); s.hp = s.mhp; s.hc += 1; sv += 1; add_xp(p, 2, 0.5); ev.append(["build", r1(s.x), r1(s.z)])
				"reinf":
					var s: E.Struct = it.target
					pay(p, reinf_cost(p, s.k)); s.re = true; s.mhp = float(roundi(s.mhp * D.REINF[s.k].mul)); s.hp = s.mhp; s.hc += 1; sv += 1; add_xp(p, 2, 1); ev.append(["build", r1(s.x), r1(s.z)])
				"blessre":
					var s: E.Struct = it.target
					p.bodies -= 1; p.bbod -= 1; s.bl = true
					var add := float(roundi(s.mhp * 0.5))
					s.mhp += add; s.hp += add; s.hc += 1; sv += 1; add_xp(p, 2, 1); ev.append(["holy", r1(s.x), r1(s.z)])
				"keep":
					pay(p, {"wood": 1, "stone": 1}); keepHp = minf(D.KEEP_HP, keepHp + 40); ev.append(["build", r1(it.x), r1(it.z)])
				"chest":
					open_chest(p)
				"enter":
					enter_room(p, it.room)
				"leave":
					leave_room(p)
				"rune":
					if rune_left[it.i] > 0 and p.rune < cap(p):
						rune_left[it.i] -= 1; p.rune += 1; p.cc += 1; add_xp(p, 0, 3)
						ev.append(["found", p.id, "a rune, cold to the touch" if p.rune > 1 else "a rune: a small cold stone with a mark cut in it that hurts to look at. The smithy can etch a weapon with three", r1(p.x), r1(p.z), 0, 0])
				"search":
					p.cc += 1; do_search(p, it.i); note("search")
				"gather":
					p.cc += 1; gather_one(it.kind, it.target, p)
		elif it.type == "search" and fmod(p.itT, 0.7) < dt:
			p.cc += 1


const FOLLOW := [[-1.2, -1.7], [1.2, -1.7], [0, -2.8], [-2.3, -3.1], [2.3, -3.1], [0, -4.1], [-1.2, -4.6], [1.2, -4.6]]

func step_to(e, x: float, z: float, spd: float, dt: float, stop: float = 0.0) -> float:
	var dx: float = x - e.x
	var dz: float = z - e.z
	var d := sqrt(dx * dx + dz * dz)
	if d > 0.05: e.r = D.ang_lerp(e.r, atan2(dx, dz), minf(1, dt * 10))
	if d <= (stop if stop else 0.15):
		return d
	var s := minf(spd * (0.85 if weather == "snow" else 1.0) * dt, d - stop)
	e.x += dx / d * s; collide_friend(e, 0.35, 0)
	e.z += dz / d * s; collide_friend(e, 0.35, 1)     # one axis at a time, so corners do not snag
	return d

## Does the straight line from a to b pass through this box (x0..x1, z0..z1)?
static func seg_hits(ax: float, az: float, bx: float, bz: float, x0: float, z0: float, x1: float, z1: float) -> bool:
	var t0 := 0.0
	var t1 := 1.0
	var dx := bx - ax
	var dz := bz - az
	for e in [[-dx, ax - x0], [dx, x1 - ax], [-dz, az - z0], [dz, z1 - az]]:
		var p: float = e[0]
		var q: float = e[1]
		if absf(p) < 1e-9:
			if q < 0: return false
			continue
		var r := q / p
		if p < 0: t0 = maxf(t0, r)
		else: t1 = minf(t1, r)
		if t0 > t1: return false
	return true

## Where a villager should walk next to reach (tx, tz). Straight there, unless the village wall is in the way: then to the
## gateway that makes the shortest way through it (the north gate opens for friends), or round the corner of it.
func way_to(x: float, z: float, tx: float, tz: float) -> Vector2:
	var a := D.inside_village(x, z)
	var b := D.inside_village(tx, tz)
	var goal := Vector2(tx, tz)
	var here := Vector2(x, z)
	if a != b:
		# [where the gateway is, the way out through it]
		var gates := [[Vector2(0, D.VN), Vector2(0, -1)], [Vector2(-D.VW, D.GATE_Z), Vector2(-1, 0)], [Vector2(D.VW, D.GATE_Z), Vector2(1, 0)]]
		var best: Array = gates[0]
		var bd := 1e9
		for g in gates:
			var d: float = here.distance_to(g[0]) + goal.distance_to(g[0])
			if d < bd:
				bd = d; best = g
		var out: Vector2 = best[1] * (-1.0 if a else 1.0)      # from the gateway towards the side this villager is on
		var gate: Vector2 = best[0]
		var off: Vector2 = here - gate
		var side := absf(off.x * out.y - off.y * out.x)        # how far off the line through the gateway
		if side > 0.9 and off.dot(out) > -0.5: return gate + out * 2.2     # line up in front of it first
		return gate - out * 2.4                                             # then through, and out the other side
	if not a:                                                  # both outside: is the village itself in the way?
		var m := 1.2
		var x0 := -D.VW - m; var x1 := D.VW + m; var z0 := D.VN - m; var z1 := D.VS + m
		if seg_hits(x, z, tx, tz, x0, z0, x1, z1):
			var cs := [Vector2(x0 - 1.5, z0 - 1.5), Vector2(x1 + 1.5, z0 - 1.5), Vector2(x1 + 1.5, z1 + 1.5), Vector2(x0 - 1.5, z1 + 1.5)]   # going round, clockwise
			var best := goal
			var bd := 1e9
			for i in 4:
				var c: Vector2 = cs[i]
				if here.distance_to(c) < 1.2 or seg_hits(x, z, c.x, c.y, x0, z0, x1, z1): continue
				var rest := 1e9
				if not seg_hits(c.x, c.y, tx, tz, x0, z0, x1, z1): rest = c.distance_to(goal)
				else:
					for j in [(i + 1) % 4, (i + 3) % 4]:
						var c2: Vector2 = cs[j]
						if not seg_hits(c2.x, c2.y, tx, tz, x0, z0, x1, z1): rest = minf(rest, c.distance_to(c2) + c2.distance_to(goal))
				if here.distance_to(c) + rest < bd:
					bd = here.distance_to(c) + rest; best = c
			return best
	return goal

func peasant_step(q: E.Peasant, dt: float) -> void:
	q.cd = maxf(0, q.cd - dt); q.hurtT += dt; q.prot = maxf(0, q.prot - dt)
	if q.state == "body" or q.state == "idle" or q.state == "gone" or q.state == "inn":
		return
	if q.kind == 1:
		guard_step(q, dt)
		return
	if q.state == "hide":
		if step_to(q, D.KEEP_X + 0.6, -D.KEEP_H - 0.6, 3.6, dt) < 0.5: q.state = "gone"
		return
	var Ld := player_by_id(q.owner)
	if Ld == null or Ld.state == "dead":
		q.owner = 0; q.state = "idle" if phase == "day" else "hide"
		return
	if Ld.state == "hide":
		q.state = "hide"
		return
	if Ld.state == "inn":
		q.state = "inn"
		return
	var order := Ld.order                              # 0 follow, 1 hold here, 2 charge
	var tgt: E.Undead = null
	var bd := 900.0 if order == 2 else 81.0
	var near := false
	for u in undead:
		if u.state == "pile" or u.state == "rise": continue
		var d := D.d2(q.x, q.z, u.x, u.z)
		if d < 144: near = true
		if d < bd and (order == 2 or (D.d2(q.px, q.pz, u.x, u.z) < 36 if order == 1 else D.d2(q.x if Ld.room != "" else Ld.x, q.z if Ld.room != "" else Ld.z, u.x, u.z) < 64)) and not wall_between(q.x, q.z, u.x, u.z):
			bd = d; tgt = u
	if not near and q.nv < 100: q.nv = minf(100, q.nv + dt * 3)
	if tgt:
		q.state = "fight"; q.tree = null
		var reach: float = (2.2 if q.armed else 1.7) + D.UN[tgt.k].r
		var d := step_to(q, tgt.x, tgt.z, 6.0 if order == 2 else 5.2, dt, reach - 0.45)
		if d < reach and q.cd <= 0:
			q.cd = 0.9; q.ac += 1
			var qs := {"x": q.x, "z": q.z, "q": q, "farm": q.kind == 0}
			if lore(Ld, 16): qs.holy = 1.5
			hit_u(tgt, ((20.0 if q.kind == 2 else 10.0 if q.armed else 6.0) + (3.0 if q.armed and rk(Ld, 3) >= 6 else 0.0)) * (1.25 if rk(Ld, 6) >= 5 else 1.0) * (1.3 if Ld.charge > 0 else 1.0), qs)
	elif order == 1:
		q.state = "follow"; q.tree = null; q.ct = 0
		if Vector2(q.px - q.x, q.pz - q.z).length() > 0.5: step_to(q, q.px, q.pz, 5.4, dt, 0.3)
	elif Ld.workT > 0 and Ld.workK != "fish" and Ld.get(D.GATHER[Ld.workK].res) < cap(Ld) and D.d2(q.x, q.z, Ld.x, Ld.z) < 400:
		q.state = "chop"
		var wt := D.PEASANT_WORK_TIME * (0.65 if rk(Ld, 0) >= 3 else 1.0)
		if Ld.workK == "tree":
			if q.tree == null or not q.tree.alive or D.d2(q.tree.x, q.tree.z, Ld.x, Ld.z) > 196:
				q.tree = null
				var b := 100.0
				var spare: E.Trunk = null                 # a tree somebody else is on already: better to share it than to wander off
				var sb := 1e9
				for t in trees:
					if not t.alive or D.d2(t.x, t.z, Ld.x, Ld.z) > 49: continue     # close by the leader: within seven paces
					var d := D.d2(t.x, t.z, q.x, q.z)
					if peasants.any(func(o): return o != q and o.tree == t):
						var dl := D.d2(t.x, t.z, Ld.x, Ld.z)
						if dl < sb:
							sb = dl; spare = t
						continue
					if d < b:
						b = d; q.tree = t
				if q.tree == null: q.tree = spare
			if q.tree:
				var d := step_to(q, q.tree.x, q.tree.z, 5, dt, 1.25 * q.tree.s + 0.3)
				if d < 1.25 * q.tree.s + 0.7:
					q.ct += dt
					if q.ct >= wt:
						q.ct = 0; q.ac += 1; gather_one("tree", q.tree, Ld)
		else:
			q.tree = null
			var a := (q.id % 7) * 0.9
			var wx := Ld.workX + cos(a) * 1.6 + (Ld.x - Ld.workX) * 0.6
			var wz := Ld.workZ + sin(a) * 1.6 + (Ld.z - Ld.workZ) * 0.6
			var d := step_to(q, wx, wz, 5, dt, 0.4)
			if d < 1.2:
				q.r = D.ang_lerp(q.r, atan2(Ld.workX - q.x, Ld.workZ - q.z), 0.2); q.ct += dt
				if q.ct >= wt:
					q.ct = 0; q.ac += 1; gather_one(Ld.workK, null, Ld)
	else:
		q.state = "follow"; q.tree = null; q.ct = 0
		var idx := 0
		for o in peasants:
			if o == q: break
			if o.owner == q.owner and o.state != "body": idx += 1
		var f: Array = FOLLOW[idx % FOLLOW.size()]
		var cs := cos(Ld.r)
		var sn := sin(Ld.r)
		var tx: float = Ld.x + f[0] * cs + f[1] * sn
		var tz: float = Ld.z - f[0] * sn + f[1] * cs
		if Ld.room != "":                                # the leader has gone in somewhere: wait by the door
			var dr: Array = D.ROOMS[Ld.room].door
			tx = dr[0] + f[0]; tz = dr[1] + 2.2 - f[1] * 0.7
		var d := Vector2(tx - q.x, tz - q.z).length()
		if d > 40:
			q.x = tx; q.z = tz
		elif d > 0.45:
			var wp := way_to(q.x, q.z, tx, tz)
			step_to(q, wp.x, wp.y, (10.5 if Ld.charge > 0 else 8.2) if d > 4 else 5.4, dt, 0.3 if wp.x == tx and wp.y == tz else 0.0)
			q.st += dt
			if q.st >= 2.5:                              # wedged behind something for a while, and the leader well away: catch up at a run
				if d > 6 and D.d2(q.x, q.z, q.sx, q.sz) < 1.0:
					ev.append(["hop", r1(q.x), r1(q.z)])
					q.x = tx; q.z = tz; collide_friend(q, 0.35)
					ev.append(["hop", r1(q.x), r1(q.z)])
				q.st = 0.0; q.sx = q.x; q.sz = q.z
	collide_friend(q, 0.35)
	for o in peasants:
		if o != q and o.state != "body" and o.state != "gone" and o.state != "inn":
			var dx: float = q.x - o.x
			var dz: float = q.z - o.z
			var d := dx * dx + dz * dz
			if d < 0.5 and d > 1e-6:
				var l := sqrt(d)
				var k := (0.71 - l) * 0.5
				q.x += dx / l * k; q.z += dz / l * k


## A village guard holds his gate: he fights whatever comes near it, and goes back to his post.
func guard_step(q: E.Peasant, dt: float) -> void:
	var tgt: E.Undead = null
	var bd := 1e9
	for u in undead:
		if u.state == "pile" or u.state == "rise" or u.state == "dig" or u.dead: continue
		if D.d2(u.x, u.z, q.px, q.pz) > 64: continue
		var U: Dictionary = D.UN[u.k]
		if not (U.fly or U.ghost) and wall_between(q.x, q.z, u.x, u.z): continue
		var d := D.d2(u.x, u.z, q.x, q.z)
		if d < bd:
			bd = d; tgt = u
	if tgt:
		q.state = "fight"
		var reach: float = 2.5 + D.UN[tgt.k].r
		var d := step_to(q, tgt.x, tgt.z, 5.4, dt, reach - 0.45)
		if d < reach and q.cd <= 0:
			q.cd = 0.8; q.ac += 1
			hit_u(tgt, 16.0, {"x": q.x, "z": q.z, "q": q, "farm": false})
	else:
		q.state = "post"
		if Vector2(q.px - q.x, q.pz - q.z).length() > 0.5: step_to(q, q.px, q.pz, 5.0, dt, 0.3)
		else: q.r = D.ang_lerp(q.r, PI if q.pz < -10 else (-PI / 2 if q.px < 0 else PI / 2), minf(1, dt * 4))
	collide_friend(q, 0.35)

func undead_goal(u: E.Undead) -> Vector2:
	var U: Dictionary = D.UN[u.k]
	if U.tenant and phase == "day": return Vector2(u.hx, u.hz)   # by day he keeps to his ruin; after dark he goes down with the rest
	if U.fly or (U.ghost and not U.lord) or (U.lord and u.stage >= 1):   # over the wall, or through it: straight for the keep
		return Vector2(clampf(u.lane * 0.3, -D.KEEP_H + 0.6, D.KEEP_H - 0.6), -D.KEEP_H - 0.2)
	if u.side != 0 and not D.inside_village(u.x, u.z):   # the Captain's guard: round to a side gateway
		var sx := float(u.side)
		if absf(u.z - D.GATE_Z) <= 1.4 and signf(u.x) == sx and absf(u.x) > D.VW - 1: return Vector2(sx * (D.VW - 3), D.GATE_Z)   # level with the gateway: in
		if absf(u.x) < D.VW + 3.5 or signf(u.x) != sx: return Vector2(sx * (D.VW + 5.5), minf(u.z + 4, D.GATE_Z))
		return Vector2(sx * (D.VW + 4.5), D.GATE_Z)
	if u.z < D.VN - 0.3:                          # outside, to the north: look for a way through the wall
		if U.ram or U.hearse: return Vector2(u.lane, D.VN + 2.5)   # straight down the road at the gate
		u.gt -= 1
		if u.gt <= 0:
			u.gt = 30; u.gap = -1
			var b := 16.0
			for s in structs:
				if s.slot >= 0 and not s.built:
					var d := absf(s.x - (u.x if u.z > D.VN - 12 else u.lane))
					if d < b:
						b = d; u.gap = s.slot
		if u.gap >= 0:
			var gx: float = D.SLOTX[u.gap] + u.jit
			if absf(u.x - gx) > 1.2 and u.z > D.VN - 5: return Vector2(gx, D.VN - 5.2)
			return Vector2(gx, D.VN - 4.6) if absf(u.x - gx) > 1.2 else Vector2(gx, D.VN + 2.5)
		return Vector2(clampf(u.lane, -20, 20), D.VN + 2)
	if not D.inside_village(u.x, u.z):            # outside to the west, east or south: round to a side gateway
		var sx := -1.0 if u.x < 0 else 1.0
		if u.z > D.VS - 0.5 and absf(u.x) < D.VW + 2.5: return Vector2(sx * (D.VW + 4.5), D.VS + 3)   # south of the wall: along it to the corner
		return Vector2(sx * (D.VW + 4.5), D.GATE_Z) if absf(u.z - D.GATE_Z) > 1.4 else Vector2(sx * (D.VW - 3), D.GATE_Z)
	if u.z < -18.6 and absf(u.x) > 6.5: return Vector2(signf(u.x) * 5.5, -19.9)   # sidle along the inside of the wall to the avenue
	return Vector2(clampf(u.lane * 0.3, -D.KEEP_H + 0.6, D.KEEP_H - 0.6), -D.KEEP_H - 0.2)   # somewhere along the keep's north face

func hit_struct(u: E.Undead, U: Dictionary, blk: E.Struct, dmul: float = 1.0) -> void:
	u.state = "atk"
	if u.cd <= 0:
		u.cd = U.cd; u.ac += 1; blk.hp -= U.sdmg * rage * dmul / stout(); blk.hc += 1; sv += 1
		if blk.bl: hit_u(u, 5, {"holy": 1.5})
		if blk.hp <= 0: destroy_struct(blk)

## The Coachman drives the hearse down the road at the keep, turns, goes back up for another run, and comes again.
## Anything made of wood in the way goes under the wheels; stone and iron stop him, and he batters at them.
func hearse_step(u: E.Undead, U: Dictionary, dt: float, keep_box: E.Box) -> void:
	var gx := u.lane
	var gz := -D.KEEP_H + 0.5 if u.march else -46.0
	var dx := gx - u.x
	var dz := gz - u.z
	var d := sqrt(dx * dx + dz * dz)
	u.r = D.ang_lerp(u.r, atan2(dx, dz), minf(1, dt * 4))
	if u.march and in_box(u.x, u.z, U.r + 0.5, keep_box):
		if u.cd <= 0:
			u.cd = U.cd * 2; u.ac += 1; keepHp -= U.kdmg * rage / stout(); keepHc += 1; ev.append(["build", r1(u.x), r1(u.z + 1)])
			u.march = false                           # turn round for another run
		u.state = "atk"
		return
	if d < 1.5:
		if not u.march:
			u.march = true; u.lane = rnd2(-1.5, 1.5)
		return
	var sp: float = U.spd * wspeed() * (0.5 if u.slow > 0 else 1.0) * (1.0 if u.march else 0.7)
	var nx: float = u.x + dx / d * sp * dt
	var nz: float = u.z + dz / d * sp * dt
	for s in structs.duplicate():
		if s.built and in_box(nx, nz, U.r, s) and not (s.slot >= 0 and u.z > D.VN + 0.5):
			if s.re:                                   # stone and iron hold
				hit_struct(u, {"cd": U.cd, "sdmg": 25.0}, s)
				return
			destroy_struct(s); ev.append(["smash", r1(s.x), r1(s.z)])
	u.state = "walk"; u.x = nx; u.z = nz
	for c in colliders: push_out(u, U.r, c)
	for p in players:                                  # and anyone in the road is run over
		if p.state == "ok" and D.d2(p.x, p.z, u.x, u.z) < pow(U.r + 0.6, 2) and p.hurtT > 0.8:
			hurt_friend(p, U.dmg * tough * crowd_d, true, u, false); p.x += signf(p.x - u.x + 0.01) * 1.5; p.tp = tpc; tpc += 1
	for q in peasants:
		if active(q) and D.d2(q.x, q.z, u.x, u.z) < pow(U.r + 0.5, 2) and q.hurtT > 0.8:
			hurt_friend(q, U.dmg * tough * crowd_d, false, u, false); q.x += signf(q.x - u.x + 0.01) * 1.5

func undead_step(dt: float) -> void:
	var keep_box := E.Box.new(D.KEEP_X, D.KEEP_Z, D.KEEP_H, D.KEEP_H)
	var decoys := structs.filter(func(s): return s.k == "decoy")
	var chickens := structs.filter(func(s): return s.k == "chicken" and s.built)
	var censers := players.filter(func(p): return p.trk == 27 and p.state == "ok")
	var captain: E.Undead = boss if boss and boss.k == D.U_CAPTAIN else null
	var ws := wspeed()
	for u in undead:
		var U: Dictionary = D.UN[u.k]
		u.cd = maxf(0, u.cd - dt); u.t -= dt; u.slow = maxf(0, u.slow - dt)
		u.stun = maxf(0, u.stun - dt); u.pin = maxf(0, u.pin - dt); u.vuln = maxf(0, u.vuln - dt); u.fear = maxf(0, u.fear - dt); u.tauntT = maxf(0, u.tauntT - dt)
		if u.dead: continue
		if u.burn > 0:                                # alight: a scorch every half second, until it goes out
			u.burn -= dt; u.bt -= dt
			if u.bt <= 0:
				u.bt = 0.5
				hit_u(u, D.BURN_DMG * (0.5 if U.bony else 1.0), {"dot": true, "farm": false})
				ev.append(["burn", r1(u.x), r1(u.z)])
				if u.dead: continue
		if u.state == "rise":
			if u.t <= 0: u.state = "walk"
			continue
		if u.state == "pile":
			if u.t <= 0:
				u.state = "walk"; u.hp = U.hp * tough * crowd
			continue
		if u.state == "dig":                      # a gravedigger, tunnelling under the north wall
			if u.t <= 0:
				u.dug = true; u.state = "rise"; u.t = 1.4
				u.x = clampf(u.x + rnd2(-5, 5), -8.5, 7.5); u.z = D.VN + rnd2(3, 10)   # on the green, clear of the houses
				for c in colliders: push_out(u, U.r + 0.3, c)
				ev.append(["dig", r1(u.x), r1(u.z)])
			continue
		if u.stun > 0:
			u.state = "stun"
			continue
		if u.state == "stun": u.state = "walk"
		var dmul := tough * crowd_d * (1.3 if captain and u.k == D.U_GUARD and D.d2(u.x, u.z, captain.x, captain.z) < 100 else 1.0)
		if U.hearse:
			hearse_step(u, U, dt, keep_box)
			continue
		for p in censers:
			if D.d2(u.x, u.z, p.x, p.z) < 30:
				u.slow = maxf(u.slow, 0.3)
				if lore(p, 27) and randf() < dt: hit_u(u, 3, {"holy": 1.5})   # smouldering
		var sp: float = U.spd * (0.5 if u.slow > 0 else 1.0) * ws
		if U.lord and u.stage == 2: sp *= 1.6
		if u.fear > 0:                            # running from the smell
			var dx: float = u.x - u.fx
			var dz: float = u.z - u.fz
			var d := sqrt(dx * dx + dz * dz)
			if d == 0: d = 1
			u.state = "walk"; u.r = D.ang_lerp(u.r, atan2(dx, dz), minf(1, dt * 8))
			if u.pin <= 0:
				u.x += dx / d * sp * 1.5 * dt
				for c in near_colliders(u.x, u.z): push_out(u, U.r, c, 0)
				u.z += dz / d * sp * 1.5 * dt
				for c in near_colliders(u.x, u.z): push_out(u, U.r, c, 1)
				u.z = maxf(u.z, D.SPAWN_Z - 6)
			continue
		# a gravedigger that reaches the north wall goes under it
		if U.dig and not u.dug and u.z < D.VN - 0.5 and u.z > D.VN - 7 and u.pin <= 0:
			u.state = "dig"; u.t = 5.0
			continue
		var sight := 64.0 if u.k == 2 and weather == "fog" else 169.0 if u.k == 2 else 30.0 if U.boss else 196.0 if U.tenant else 49.0
		var tgt = null
		var tp := false
		var bd := sight
		if not U.fly:                             # bats do not stop for anyone: they want the keep
			for p in players:
				if p.state == "ok" and p.room == "":
					var d := D.d2(u.x, u.z, p.x, p.z)
					if d < bd:
						bd = d; tgt = p; tp = true
			if not U.boss:
				for q in peasants:
					if active(q):
						var d := D.d2(u.x, u.z, q.x, q.z)
						if d < bd:
							bd = d; tgt = q; tp = false
			if u.tauntT > 0:
				var t := player_by_id(u.taunt)
				if t and t.state == "ok" and D.d2(u.x, u.z, t.x, t.z) < 625:
					tgt = t; tp = true; bd = D.d2(u.x, u.z, t.x, t.z)
		if U.lord and u.stage == 2 and tgt and bd > 4: tgt = null   # at the end he only has eyes for the keep door
		u.tg = tgt.id if tgt and tp else 0
		var gx := 0.0
		var gz := 0.0
		var door := false
		var raiser: bool = u.k == D.U_STEWARD or (U.lord and u.stage == 0)
		if raiser:                                # the Steward (and the Lord, at first): stands back and raises the fallen, until a player gets close
			var alone: bool = graves.is_empty() and undead.size() == 1 and night and night.q.is_empty()
			if U.lord: alone = night != null and night.q.is_empty() and night.t > night.dur + 60   # the Lord waits to be fetched, but not for ever
			if tgt == null:
				if alone or u.march:              # nobody left to raise: he sees to the keep himself
					u.march = true
					if U.lord: u.stage = maxi(u.stage, 1)
					var g := undead_goal(u)
					gx = g.x; gz = g.y
				elif D.d2(u.x, u.z, 0, -35) > 2:
					gx = 0; gz = -35
				else:
					u.state = "atk"; u.r = D.ang_lerp(u.r, 0, 0.1); u.rt -= dt
					if u.rt <= 0:
						u.rt = 6 if not U.lord else 8; u.ac += 1
						var n := mini(graves.size(), 2 + floori(players.size() / 2.0))
						for i in n:
							var g: Dictionary = graves.pop_at(randi() % graves.size())
							spawn_undead(g.k, g.x, g.z); ev.append(["raise", r1(g.x), r1(g.z)])
						if U.lord:                  # and the Lord calls down his bats
							for i in 2 + floori(players.size() / 2.0):
								var b := spawn_undead(D.U_BATS, u.x + rnd2(-3, 3), u.z + rnd2(-2, 2))
								b.state = "walk"; b.t = 0
							ev.append(["raise", r1(u.x), r1(u.z)])
					continue
			else:
				gx = tgt.x; gz = tgt.z; u.rt = maxf(u.rt, 2.5)
		elif u.k == 2 and tgt and bd <= U.rng * U.rng:   # archers stop and shoot
			u.state = "atk"; u.r = D.ang_lerp(u.r, atan2(tgt.x - u.x, tgt.z - u.z), minf(1, dt * 8))
			if u.cd <= 0:
				u.cd = U.cd; u.ac += 1
				var hit: bool = randf() < 0.7 and not (tp and (tgt.guard > 0 or (tgt.off >= 0 and randf() < D.IT[tgt.off].arrow)))
				ev.append(["arrow", r1(u.x), r1(u.z), r1(tgt.x), r1(tgt.z)])
				if hit: hurt_friend(tgt, U.dmg * dmul, tp, u, true)
			continue
		else:
			var dc: E.Struct = null
			var dd := 64.0
			if (u.k < 2 or u.k == D.U_GHOUL) and bd > 12 and u.tauntT <= 0:
				for s in decoys:
					var d := D.d2(u.x, u.z, s.x, s.z)
					if d < dd:
						dd = d; dc = s
			if not U.boss and not U.fly and not U.ghost and not U.ram and u.tauntT <= 0:   # nobody can ignore a chicken
				var cd := 100.0
				for s in chickens:
					var d := D.d2(u.x, u.z, s.x, s.z)
					if d < cd:
						cd = d; dc = s
			if dc:                                # a propped-up body is more interesting than anyone further off
				gx = dc.x; gz = dc.z; tgt = null
			elif tgt:
				gx = tgt.x; gz = tgt.z
			elif innIn and innHp > 0 and not U.fly and D.inside_village(u.x, u.z) and D.d2(u.x, u.z, D.INN.dx, D.INN.dz) < 260:   # they can hear the singing
				gx = D.INN.dx - 0.6; gz = D.INN.dz; door = true
			else:
				var g := undead_goal(u)
				gx = g.x; gz = g.y
		if U.lord and u.stage == 1:               # coming down: now and then he turns to mist and is suddenly somewhere nearer
			u.rt -= dt
			if u.rt <= 0 and tgt == null:
				u.rt = 8.0
				var mx: float = gx - u.x
				var mz: float = gz - u.z
				var ml := maxf(0.1, sqrt(mx * mx + mz * mz))
				var j := minf(7.0, ml - 1.0)
				if j > 1:
					ev.append(["mist", r1(u.x), r1(u.z)])
					u.x += mx / ml * j; u.z += mz / ml * j
					ev.append(["mist", r1(u.x), r1(u.z)])
		var gdx: float = gx - u.x
		var gdz: float = gz - u.z
		var gd := sqrt(gdx * gdx + gdz * gdz)
		if gd == 0: gd = 1
		u.r = D.ang_lerp(u.r, atan2(gdx, gdz), minf(1, dt * 6))
		var through: bool = U.ghost or U.fly or (U.lord and u.stage >= 1)
		if tgt and gd < U.r + 1.05 and (through or not wall_between(u.x, u.z, tgt.x, tgt.z)):
			if u.state != "atk" and u.t < -1: u.cd = maxf(u.cd, 0.45)
			u.state = "atk"; u.t = 0
			if u.cd <= 0:
				u.cd = U.cd; u.ac += 1; hurt_friend(tgt, U.dmg * dmul, tp, u, false)
			continue
		if door and gd < U.r + 1.3:
			u.state = "atk"
			if u.cd <= 0:
				u.cd = U.cd; u.ac += 1; innHp -= maxf(U.sdmg, 3.0) * dmul; ev.append(["build", r1(D.INN.dx - 0.8), r1(D.INN.dz)])
				if innHp <= 0:
					innHp = 0; say("The dead have broken into the Thorny Rose Inn. Drinking-up time.")
					for p in players:
						leave_inn(p, p.cg >= 100)
						if p.room == "inn": leave_room(p)     # and anyone else who was in there, talking
			continue
		if tgt == null and not door and (not raiser or u.march) and in_box(u.x, u.z, U.r + 0.45, keep_box):
			u.state = "atk"; u.r = D.ang_lerp(u.r, atan2(D.KEEP_X - u.x, D.KEEP_Z - u.z), 0.3)
			if u.cd <= 0:
				u.cd = U.cd; u.ac += 1; keepHp -= U.kdmg * rage * dmul / stout(); keepHc += 1
			continue
		if u.pin > 0:
			u.state = "stun"
			continue
		var nx: float = u.x + gdx / gd * sp * dt
		var nz: float = u.z + gdz / gd * sp * dt
		if through:                                # bats fly over everything; wraiths and the Lord drift through it
			u.state = "walk"; u.x = nx; u.z = nz
			continue
		var blk := blocking_struct(nx, nz, U.r)
		if blk and blk.slot >= 0 and u.z > D.VN:   # already inside: the north wall is just in the way, not something to break
			blk = null
		if blk and U.climb and (blk.k == "barricade" or blk.k == "bodywall" or blk.k == "decoy"):   # ghouls go over barricades
			blk = null; u.slow = maxf(u.slow, 0.25)
		if blk:
			hit_struct(u, U, blk, dmul)
			continue
		u.state = "walk"
		u.lt += dt
		if u.lt >= 3.0:                               # walking for three seconds and nowhere to show for it: wedged in a corner. Shuffle sideways.
			if D.d2(u.x, u.z, u.lx, u.lz) < 0.3:
				var a := randf() * TAU
				if blocking_struct(u.x + cos(a) * 1.4, u.z + sin(a) * 1.4, U.r) == null:
					nx = u.x + cos(a) * 1.4; nz = u.z + sin(a) * 1.4
			u.lt = 0.0; u.lx = u.x; u.lz = u.z
		u.x = nx
		var nc := near_colliders(nx, nz)
		for c in nc: push_out(u, U.r, c, 0)
		u.z = nz
		for c in nc: push_out(u, U.r, c, 1)
		if u.z > D.VN:                                # inside, the north wall is solid like any other
			for s in structs:
				if s.slot >= 0 and s.built: push_out(u, U.r, s)
	# keep them from standing inside each other (a grid, so a big horde stays cheap). Bats and wraiths drift through.
	var grid := {}
	for u in undead:
		if u.state == "rise" or u.state == "pile" or u.state == "dig" or D.UN[u.k].fly or D.UN[u.k].ghost: continue
		var key := Vector2i(floori(u.x / 1.6), floori(u.z / 1.6))
		if grid.has(key): grid[key].append(u)
		else: grid[key] = [u]
	for u in undead:
		if u.state == "rise" or u.state == "pile" or u.state == "dig" or D.UN[u.k].fly or D.UN[u.k].ghost: continue
		var cx := floori(u.x / 1.6)
		var cz := floori(u.z / 1.6)
		var ru: float = D.UN[u.k].r
		for gx in range(cx - 1, cx + 2):
			for gz in range(cz - 1, cz + 2):
				var cell = grid.get(Vector2i(gx, gz))
				if cell == null: continue
				for v in cell:
					if v.id <= u.id: continue      # each pair once
					var dx: float = u.x - v.x
					var dz: float = u.z - v.z
					var d := dx * dx + dz * dz
					var rr: float = ru + D.UN[v.k].r
					if d < rr * rr and d > 1e-6:
						var l := sqrt(d)
						var k := (rr - l) * 0.5 / l
						u.x += dx * k; u.z += dz * k; v.x -= dx * k; v.z -= dz * k

## The contraptions at work. (The chicken decoy works through the dead's own minds: see undead_step.)
func contraptions_step(dt: float) -> void:
	for s in structs.duplicate():
		if not s.built: continue
		match s.k:
			"tar":                                     # the dead wade; so do the living, a little
				for u in undead:
					if u.dead or u.state == "rise" or u.state == "dig" or D.UN[u.k].fly or D.UN[u.k].ghost: continue
					if in_box(u.x, u.z, D.UN[u.k].r * 0.5, s):
						u.slow = maxf(u.slow, 0.3); s.hp -= 0.25 * dt
				if s.hp <= 0:
					destroy_struct(s); say("A tar pit has been trodden flat.")
			"pitfall":                                 # the first four in go down for good
				for u in undead:
					if u.dead or u.state != "walk" and u.state != "atk": continue
					var U: Dictionary = D.UN[u.k]
					if U.boss or U.fly or U.ghost or U.ram: continue
					if in_box(u.x, u.z, 0.0, s):
						u.revived = true; kill_undead(u); ev.append(["pit", r1(s.x), r1(s.z)])
						s.hp -= 1; s.hc += 1; sv += 1
						if s.hp <= 0:
							destroy_struct(s)
							break
			"trough", "thresher":
				s.tick -= dt
				if s.tick > 0: continue
				s.tick = 0.5 if s.k == "trough" else 0.4
				if s.k == "thresher":                  # it only turns while someone turns the handle
					var crank := players.any(func(p): return p.state == "ok" and D.d2(p.x, p.z, s.x, s.z) < 9) or peasants.any(func(q): return active(q) and D.d2(q.x, q.z, s.x, s.z) < 9)
					if not crank: continue
					var any := false
					for u in undead:
						if u.dead or u.state == "rise" or u.state == "pile" or u.state == "dig" or D.UN[u.k].fly: continue
						if D.d2(u.x, u.z, s.x, s.z) < 2.6 * 2.6:
							hit_u(u, 7, {"x": s.x, "z": s.z, "blunt": true, "farm": false}); any = true
					if any: s.hc += 1; sv += 1
				else:
					for u in undead:
						if u.dead or u.state == "rise" or u.state == "dig" or D.UN[u.k].fly: continue
						if in_box(u.x, u.z, D.UN[u.k].r * 0.5, s):
							hit_u(u, 8, {"holy": 1.5}); s.hp -= 1; ev.append(["holy", r1(u.x), r1(u.z)])
					if s.hp <= 0:
						destroy_struct(s); say("A holy water trough has run dry.")
			"logs":                                    # once a night: when a crowd (or a ram) has come down the road past it, roll
				if phase != "night" or s.tick <= 0: continue
				var lane := undead.filter(func(u): return not u.dead and u.state != "rise" and u.state != "dig" and not D.UN[u.k].fly and absf(u.x - s.x) < 2.2 and u.z > s.z and u.z < s.z + 24)
				if lane.size() >= 5 or lane.any(func(u): return D.UN[u.k].ram):
					s.tick = 0.0; s.hc += 1; sv += 1
					ev.append(["logs", r1(s.x), r1(s.z), r1(s.x), r1(minf(s.z + 24, D.VN - 1))])
					for u in lane:
						hit_u(u, 120, {"x": s.x, "z": s.z - 1, "kb": 3.0, "blunt": true, "heavy": true, "farm": false}); stun_u(u, 2)
					say("The log roller has gone, and taken %d of the dead with it." % lane.size())

func spikes_step(dt: float) -> void:
	for s in structs.duplicate():
		if s.k != "spikes": continue
		s.tick -= dt
		if s.tick > 0: continue
		s.tick = 0.5
		for u in undead:
			var UK: Dictionary = D.UN[u.k]
			if u.state == "rise" or u.state == "pile" or u.state == "dig" or u.dead or UK.boss or UK.fly or UK.ghost or not in_box(u.x, u.z, D.UN[u.k].r * 0.6, s): continue
			hit_u(u, 10 if s.re else 5); u.slow = 0.8; s.hp -= 1; s.hc += 1; sv += 1
			if s.hp <= 0:
				destroy_struct(s)
				break


# --- moving a local player (the web version did this in the page; here it is a rule so tests and bots can use it)
# mx, mz: the direction held, each -1..1. t: seconds since the start, for the hangover wobble.
func move_player(p: E.Player, mx: float, mz: float, dt: float, t: float = 0.0) -> String:
	if p.state != "ok" or not live():
		return ""
	var l := sqrt(mx * mx + mz * mz)
	if l <= 0:
		return ""
	var sp: float = D.PLAYER_SPEED * (1 - D.IT[p.body].slow if p.body >= 0 else 1.0) * (1 - 0.05 * p.bodies) * (1.35 if p.charge > 0 else 0.6 if p.hang > 0 else 1.0) * (0.85 if weather == "snow" else 1.0)
	mx /= l; mz /= l
	if p.hang > 0:                                 # the hangover wobble
		var w := sin(t / 0.26) * 0.6
		var ax := mx - mz * w
		var az := mz + mx * w
		var al := sqrt(ax * ax + az * az)
		mx = ax / al; mz = az / al
	p.r = D.ang_lerp(p.r, atan2(mx, mz), minf(1, dt * 14))
	p.x += mx * sp * dt; collide_friend(p, 0.45, 0)
	p.z += mz * sp * dt; collide_friend(p, 0.45, 1)   # one axis at a time, so corners do not snag
	if p.room != "": return ""
	if p.x >= D.X1 - 0.01 or p.x <= D.X0 + 0.01: return "hedge"
	if p.z <= D.Z0 + 0.01: return "stakes"
	if p.z >= D.Z1 - 0.01: return "river"
	return ""
