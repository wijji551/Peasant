extends SceneTree
## Tidy-ups after Build 5: steel can be mined by anyone, things can be destroyed, things left on the ground go after
## two days, and the posse finds its way round the village wall and chops close to its leader.
## Run:  godot --headless --path godot -s res://tests/tidy_test.gd

var R: Rules
var m: E.Player
var lines := []
const STEP := 1.0 / 30.0


func ok(name: String, cond: bool, extra = null) -> void:
	lines.append(("PASS " if cond else "FAIL ") + name + ("" if extra == null else "  [" + str(extra) + "]"))


func fast(sec: float, f: Callable = Callable()) -> float:
	var t := 0.0
	while t < sec:
		if f.is_valid() and f.call() == false: return t
		R.step(STEP); R.ev.clear(); t += STEP
	return t


func morning() -> void:
	R.dusk_falls(); R.timeLeft = 0.01; R.step(STEP)
	R.night.q = []; R.night.boss = -1; R.undead.clear()
	var t := 0.0
	while R.phase == "night" and t < 30:
		R.step(STEP); t += STEP
	R.ev.clear()


func _init() -> void:
	R = Rules.new()
	R.new_game([{"id": 1, "name": "Matt", "col": 0}])
	m = R.players[0]
	# steel: anyone, at the old mine
	m.x = R.STEELM.x - 0.6; m.z = R.STEELM.z
	var it = R.find_interact(m)
	ok("at the old mine, hold to mine steel ore (no book needed)", it != null and it.get("type") == "gather" and it.get("kind") == "steel" and it.ok, it)
	m.eHold = true
	fast(8.0)
	m.eHold = false
	ok("and steel comes out", m.steel >= 2, m.steel)
	# destroy
	m.inv = [6, 12]
	R.do_act(m, "destroy", 0)
	ok("a thing in the backpack can be destroyed for good", m.inv == [12] and R.drops.is_empty(), m.inv)
	# dropped things go after two days
	R.do_act(m, "dropi", 0)
	ok("dropped, it lies on the ground", R.drops.size() == 1 and R.drops[0].day == 1)
	morning()
	ok("still there the next morning", R.day == 2 and R.drops.size() == 1)
	var sv := R.save_data()
	ok("the day it was dropped is saved", sv.drops[0].day == 1)
	morning()
	ok("gone on the second morning", R.day == 3 and R.drops.is_empty() and R.dawn.lines.any(func(l): return "two days" in l), R.dawn.lines)
	# the posse and the wall
	for s in R.structs:
		if s.slot >= 0:
			s.built = true; s.hp = s.mhp
	var q: E.Peasant = R.peasants[0]
	q.owner = m.id; q.state = "follow"
	q.x = 12.0; q.z = D.VN + 3.0                        # inside, well along the wall from the gate
	m.x = 12.0; m.z = D.VN - 8.0; m.r = 0               # the leader outside, straight across the wall
	var wp := R.way_to(q.x, q.z, m.x, m.z)
	ok("with the wall between, a follower makes for the gate", absf(wp.x) < 1 and absf(wp.y - D.VN) < 3, wp)
	var t := fast(14.0, func(): return not (q.z < D.VN - 3 and D.d2(q.x, q.z, m.x, m.z) < 16))
	ok("and gets round to the leader", q.z < D.VN - 3 and D.d2(q.x, q.z, m.x, m.z) < 16 and t < 13.5, [q.x, q.z, t])
	q.x = -40.0; q.z = 10.0                             # outside to the west; the leader outside to the east
	m.x = 40.0; m.z = 12.0
	wp = R.way_to(q.x, q.z, m.x, m.z)
	ok("with the whole village between, round a corner of it", absf(wp.x) > D.VW and (wp.y < D.VN or wp.y > D.VS), wp)
	t = fast(40.0, func(): return D.d2(q.x, q.z, m.x, m.z) > 16)
	ok("and all the way round", D.d2(q.x, q.z, m.x, m.z) <= 16, [q.x, q.z, t])
	# wedged: the leader far off and no way to walk it
	q.x = 0.0; q.z = 0.0                                # inside the keep's walls, which nobody can walk out of
	m.x = -40.0; m.z = 30.0
	fast(6.0)
	ok("a follower who is wedged catches up in a hop", D.d2(q.x, q.z, m.x, m.z) < 25, [q.x, q.z])
	# woodcutting: close to the leader
	var tr: E.Trunk = null
	for tt in R.trees:
		if tt.alive and tt.x < -40 and tt.x > -60 and absf(tt.z) < 20:
			tr = tt; break
	m.x = tr.x + 1.4; m.z = tr.z
	for o in R.peasants:
		if o.owner == 0 and o.state == "idle":
			o.owner = m.id; o.state = "follow"
	for o in R.peasants:
		if o.owner == m.id:
			o.x = m.x + 1; o.z = m.z + 1
	m.eHold = true
	fast(6.0)
	var far := 0.0
	for o in R.peasants:
		if o.owner == m.id and o.state == "chop": far = maxf(far, sqrt(D.d2(o.x, o.z, m.x, m.z)))
	m.eHold = false
	var chopping := R.peasants.filter(func(o): return o.owner == m.id and o.state == "chop").size()
	ok("the posse chops beside its leader, not across the wood", chopping >= 3 and far < 9.5, [chopping, far])
	var fails := 0
	for l in lines:
		if l.begins_with("FAIL"): fails += 1
		print(l)
	print("%d passed, %d failed" % [lines.size() - fails, fails])
	quit()
