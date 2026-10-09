extends SceneTree
## Build 5: the Lord of Ashhollow's letters, and the notice board in the square.
## Run:  godot --headless --path godot -s res://tests/letters_test.gd

var R: Rules
var m: E.Player
var lines := []
const STEP := 1.0 / 30.0


func ok(name: String, cond: bool, extra = null) -> void:
	lines.append(("PASS " if cond else "FAIL ") + name + ("" if extra == null else "  [" + str(extra) + "]"))


func morning() -> Array:   # straight to the next morning: an empty night, then dawn. Returns what happened at dawn.
	R.dusk_falls(); R.timeLeft = 0.01; R.step(STEP)
	R.night.q = []; R.night.boss = -1; R.undead.clear()
	R.ev.clear()
	var t := 0.0
	while R.phase == "night" and t < 30:
		R.step(STEP); t += STEP
	var ev := R.ev.duplicate()
	R.ev.clear()
	return ev


func id_of(i: int) -> String:
	return D.LETTERS[R.letters[i][0]].id


func _init() -> void:
	R = Rules.new()
	R.new_game([{"id": 1, "name": "Matt", "col": 0}])
	m = R.players[0]
	var post := D.station("letter")
	ok("no letters on the first day", R.letters.is_empty() and not R.letter_new)
	m.x = post.x; m.z = post.z
	var it = R.find_interact(m)
	ok("and nothing to read on the gatepost", it == null or it.get("type") != "station", it)
	var ev := morning()
	ok("the second morning: his first letter", R.day == 2 and R.letters.size() == 1 and id_of(0) == "intro" and R.letter_new, R.letters)
	ok("brought by the headless rider", ev.any(func(e): return e[0] == "rider"))
	ok("and the dawn notice says so", R.dawn.lines.any(func(l): return "headless rider" in l))
	m.x = post.x; m.z = post.z
	it = R.find_interact(m)
	ok("it can be read at the gatepost", it != null and it.get("type") == "station" and it.st.id == "letter", it)
	var d := Notices.data(R, "letter", m, "")
	ok("the notice is the letter", d.title.contains("letter") and d.o.any(func(o): return o.has("text") and "pitchfork" in o.text), d.title)
	R.do_act(m, "lread")
	ok("reading it takes the new off it", not R.letter_new and R.letters.size() == 1)
	morning()
	ok("no letter on the third morning", R.day == 3 and R.letters.size() == 1)
	R.note("b_tar")
	morning()
	ok("the fourth: he writes about what the village has newly done (the tar pit)", R.day == 4 and R.letters.size() == 2 and id_of(1) == "tar", R.letters)
	morning(); morning()
	ok("the sixth: with nothing new, he finds something else", R.day == 6 and R.letters.size() == 3 and not D.LETTERS[R.letters[2][0]].has("why"), R.letters)
	morning(); morning()
	ok("the morning after the Steward: about the Steward", R.day == 8 and id_of(R.letters.size() - 1) == "steward", R.letters)
	var sv := R.save_data()
	var R2 := Rules.new()
	R2.load_game(JSON.parse_string(JSON.stringify(sv)), [{"id": 1, "name": "Matt", "col": 0}])
	ok("letters are saved", R2.letters.size() == R.letters.size() and R2.letters[1][0] == R.letters[1][0] and R2.letter_new == R.letter_new and R2.seen.get("b_tar", 0) == 1, R2.letters)
	while R.day < 30 and R.phase == "day": morning()
	var ids := R.letters.map(func(l): return l[0])
	var uniq := {}
	for i in ids: uniq[i] = true
	ok("a month of letters, none twice", R.day == 30 and ids.size() == 16 and uniq.size() == ids.size(), ids)
	ok("after the Coachman and the Captain too", ids.has(Rules.letter_ix("coach")) and ids.has(Rules.letter_ix("captain")))
	ok("and on the last morning he says he is coming", id_of(R.letters.size() - 1) == "final" and R.letters[-1][1] == 30)
	# the notice board
	d = Notices.data(R, "board", m, "")
	var texts: Array = d.o.filter(func(o): return o.has("text"))
	ok("the notice board has the news and three notices", texts.size() >= 5 and texts.filter(func(o): return D.NOTICES.has(o.text)).size() == 3, texts.size())
	ok("and tonight's warning", texts.any(func(o): return "Lord of Ashhollow" in o.text))
	var opts: Array = d.o.filter(func(o): return o.has("label"))
	ok("and the Lord's letters", opts.size() == 1 and opts[0].page == "letters" and opts[0].ok)
	d = Notices.data(R, "board", m, "letters")
	ok("all sixteen, newest first", d.o.filter(func(o): return o.has("label") and str(o.get("page", "")).begins_with("l")).size() == 16 and d.o[1].label.begins_with("Day 30"), d.o[1])
	d = Notices.data(R, "board", m, "l0")
	ok("each can be read again", d.o.any(func(o): return o.has("text") and o.text == D.LETTERS[0].t))
	# the short game: a letter every morning
	var S := Rules.new()
	S.new_game([{"id": 1, "name": "Matt", "col": 0}], D.WEEK)
	R = S
	while R.day < 7 and R.phase == "day": morning()
	ok("the short game: a letter every morning, the last one last", R.letters.size() == 6 and id_of(0) == "intro" and id_of(5) == "final", R.letters)
	for L in D.LETTERS:
		if L.t.length() > 420 or not L.t.begins_with("Sirs, "): ok("letter %s is the right shape" % L.id, false, L.t.length())
	var fails := 0
	for l in lines:
		if l.begins_with("FAIL"): fails += 1
		print(l)
	print("%d passed, %d failed" % [lines.size() - fails, fails])
	quit()
