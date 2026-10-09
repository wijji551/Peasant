class_name E
extends RefCounted
## The things the rules move about: boxes to bump into, trees, players, peasants, the dead, defences and dropped items.


class Box:
	var x := 0.0
	var z := 0.0
	var hw := 0.0
	var hd := 0.0
	var rot := 0.0

	func _init(x_: float = 0, z_: float = 0, hw_: float = 0, hd_: float = 0, rot_: float = 0) -> void:
		x = x_; z = z_; hw = hw_; hd = hd_; rot = rot_


class Trunk:   # a tree ("Tree" is taken by Godot)
	var i := 0
	var x := 0.0
	var z := 0.0
	var ox := 0.0          # its first spot
	var oz := 0.0
	var dx := 0.0          # where its sapling comes up, beside the stump
	var dz := 0.0
	var st := 0            # 0 standing, 1 a stump, 2 a sapling
	var par := 0           # 1 when it stands on the spot beside its first one
	var gd := 0            # the day a sapling becomes a tree
	var s := 1.0           # size
	var rot := 0.0
	var kind := 0          # 0 pine, 1 broadleaf
	var tint := Color.WHITE
	var wood := 6
	var alive := true

	func set_state(st_: int, par_: int) -> void:
		st = st_; par = par_; alive = st == 0
		x = ox + (dx if par else 0.0)
		z = oz + (dz if par else 0.0)
		if st == 0 and wood <= 0:
			wood = D.TREE_WOOD


class Player:
	var id := 0
	var name := ""
	var dn := ""            # the name shown: after a death, a relative takes over
	var col := 0
	var slot := 0
	var remote := false
	var x := 0.0
	var z := 0.0
	var r := 0.0
	var tx := 0.0
	var tz := 0.0
	var goal_r := 0.0
	var hp := 100.0
	var wood := 0
	var stone := 0
	var iron := 0
	var food := 0
	var steel := 0
	var fought := false     # swung at the dead tonight: crude weapons wear
	var coin := 0
	var bodies := 0
	var bbod := 0           # blessed bodies
	var wpn := 0
	var head := -1
	var body := -1
	var off := -1
	var trk := -1
	var inv: Array = []
	var bless := 0          # 1 the weapon is blessed, 2 the bucket
	var holy := 0
	var holyT := 0.0
	var study := false
	var gab := false
	var books: Array = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	var xp: Array = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	var xslot := false      # read An Index of Further Reading: a fourth book
	var p1Cd := 0.0         # a calling's two powers (the Holy Book: Smite and Pray)
	var p2Cd := 0.0
	var prot := 0.0         # prayed over: a third less harm
	var hb := 0.0           # prayed over at rank 3: the weapon is holy
	var spare := 0.0        # learning past rank VII, in points; sold for coin in the skills window
	var cogs := 0           # boxes of cogs, from the tinker: for contraptions
	var job := false        # working on today's merchant's job
	var jobT := 0.0         # how much of it they have done
	var merc := false       # has hired a mercenary today
	var drill := 0.0        # practice on the training dummies today
	var coward := false
	var deaths := 0
	var cg := 0.0           # courage, from the inn
	var charge := 0.0
	var hang := 0.0
	var drinkT := 0.0
	var abCd := 0.0
	var useCd := 0.0
	var tbCd := 0.0
	var order := 0            # 0 follow, 1 hold, 2 charge
	var parry := 0.0
	var guard := 0.0
	var combo := 0
	var upOnce := false
	var state := "ok"       # ok, down, dead, hide, inn
	var ready := false
	var posse := 0
	var ac := 0             # counters the view watches: attacks, hits taken, chops
	var hc := 0
	var cc := 0
	var gk := 0
	var prog := 0.0
	var tp := 0             # bumped when the rules move a player somewhere (so the view snaps)
	var bite := 0.0
	var fishT := 3.0
	var atkCd := 0.0
	var eatCd := 0.0
	var hurtT := 99.0
	var eHold := false
	var eLock := false
	var itT := 0.0
	var itKey := ""
	var workT := 0.0
	var workK := "tree"
	var workX := 0.0
	var workZ := 0.0
	var downT := 0.0


class Peasant:
	var id := 0
	var ni := 0             # their name, from D.PNAMES
	var x := 0.0
	var z := 0.0
	var r := 0.0
	var hx := 0.0           # home
	var hz := 0.0
	var hp := 75.0
	var owner := 0
	var state := "idle"     # idle, follow, fight, chop, hide, gone, inn, body
	var armed := 0
	var nv := 100.0         # nerve
	var saved := false
	var cd := 0.0
	var ac := 0
	var hc := 0
	var ct := 0.0
	var tree: Trunk = null
	var tx := 0.0           # in a joined game: where the host last said they were (the view eases towards it)
	var tz := 0.0
	var tr := 0.0
	var px := 0.0           # where they were told to hold (a guard: his post)
	var pz := 0.0
	var prot := 0.0         # prayed over: a third less harm
	var kind := 0           # 0 a villager, 1 a village guard (hired for the night), 2 a mercenary (in a posse until dawn)
	var hurtT := 99.0


class Undead:
	var id := 0
	var k := 0              # 0 shambler, 1 skeleton, 2 archer, 3 the Steward
	var x := 0.0
	var z := 0.0
	var r := 0.0
	var hp := 0.0
	var mhp := 0.0
	var state := "rise"     # rise, walk, atk, stun, pile
	var lx := 0.0           # where it was a few seconds ago, and how long since: one that is walking and getting nowhere is wedged
	var lz := 0.0
	var lt := 0.0
	var t := 1.2
	var cd := 0.0
	var lane := 0.0
	var jit := 0.0
	var gap := -1
	var gt := 0
	var ac := 0
	var hc := 0
	var slow := 0.0
	var rt := 5.0
	var stun := 0.0
	var pin := 0.0
	var vuln := 0.0
	var fear := 0.0
	var fx := 0.0
	var fz := 0.0
	var taunt := 0
	var tauntT := 0.0
	var tg := 0
	var dead := false
	var revived := false
	var march := false
	var side := 0           # the Captain's guard: -1 the west gateway, 1 the east, 0 the north gate
	var stage := 0          # the Lord: 0 watching, 1 coming down, 2 going for the keep door
	var dug := false        # a gravedigger that has already come up inside
	var dd := 0.0           # scratch: distance when sorting
	var tx := 0.0           # in a joined game: where the host last said it was
	var tz := 0.0
	var tr := 0.0


class Struct:
	var id := 0
	var k := "wall"
	var x := 0.0
	var z := 0.0
	var rot := 0.0
	var hw := 0.0
	var hd := 0.0
	var built := false
	var hp := 0.0
	var mhp := 0.0
	var slot := -1          # a north wall foundation (0-6), or -1 for something placed
	var hc := 0
	var re := false         # reinforced
	var bl := false         # a blessed body built in
	var nr := false         # never rots
	var age := 0
	var tick := 0.0


class Drop:
	var id := 0
	var it := 0
	var x := 0.0
	var z := 0.0
