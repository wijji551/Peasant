class_name D
extends RefCounted
## The fixed facts of the game: the map, the numbers, the items, the books.
## Every number is a starting value, to tune in play. Moved across unchanged from the web version.

# --- the map (x east, z south; north is -z)
const VW := 28.0
const VN := -22.0
const VS := 26.0
const GATE_Z := 2.0
const KEEP_X := 0.0
const KEEP_Z := 0.0
const KEEP_H := 3.3
const HILL := Vector2(0, -116)
const SPAWN_Z := -69.0
const SPAWN_W := 32.0                # the dead rise anywhere along the graveyard, 32 either side of the road
const X0 := -124.0
const X1 := 124.0
const Z0 := -62.0
const Z1 := 53.0
const SLOTX := [-18.0, -12.0, -6.0, 0.0, 6.0, 12.0, 18.0]   # north wall foundations; the middle one is the gate

const GAME := "Thornhallow Thirty Nights"      # what the game is called
# --- rules
const DAY_LEN := 360.0
const DUSK_LEN := 20.0
const NIGHT_BASE := 28.0
const NIGHT_PER_PLAYER := 1.0
const NIGHT_GROWTH := 1.24
const ALIVE_CAP := 220
const NIGHT_HEADS := 420             # the most that rise in one night. A bigger horde than that comes as fewer, tougher dead instead
const NIGHT_RISE := 80.0             # seconds the dead keep rising on night 1
const NIGHT_RISE_DAY := 10.0         # and how much longer each night after
const CARRY := 20
const POSSE_MAX := 3
const POSSE_SOLO := 5
const POSSE_PAIR := 4                # two players start with four followers each: a pair is short-handed for two hordes
const POP_PER_PLAYER := 6
const MAX_BODIES := 3
const PACK_MAX := 6
const DROP_DAYS := 2                 # a thing left on the ground is gone on the second morning after
const PLAYER_HP := 100.0
const PEASANT_HP := 75.0
const KEEP_HP := 1000.0
const INN_HP := 160.0
const PLAYER_SPEED := 7.0
const PEASANT_WORK_TIME := 4.0
const TREE_WOOD := 6
const RES := ["wood", "stone", "iron", "food", "steel"]
const GATHER := {
	"tree": {"res": "wood", "time": 1.5, "verb": "chop", "book": 0},
	"stone": {"res": "stone", "time": 1.9, "verb": "quarry stone", "book": 0},
	"iron": {"res": "iron", "time": 2.3, "verb": "mine iron", "book": 0},
	"food": {"res": "food", "time": 1.6, "verb": "forage", "book": 1},
	"fish": {"res": "food", "time": 0.0, "verb": "fish", "book": 1},
	"steel": {"res": "steel", "time": 3.2, "verb": "mine steel ore", "book": 0},
}
const GK := ["", "tree", "stone", "iron", "food", "fish", "search", "steel"]
const STEEL_MINE := {"x": -108.0, "z": -44.0}      # the old steel mine, at the top of the forest. It does not move.
const MILL := {"x": 104.0, "z": 30.0}              # the old mill, on the eastern downs: a landmark, and something to walk round
const COST := {"barricade": {"wood": 5}, "spikes": {"wood": 8}, "wall": {"wood": 15}, "gate": {"wood": 20}, "bodywall": {"bodies": 3}, "decoy": {"bodies": 1},
	"chicken": {"wood": 3, "food": 2}, "pitfall": {"wood": 6, "stone": 4}, "tar": {"wood": 6, "stone": 3}, "trough": {"wood": 8, "iron": 2}, "logs": {"wood": 25, "iron": 4}, "thresher": {"wood": 15, "iron": 6}}
const REINF := {
	"wall": {"cost": {"stone": 10}, "mul": 3.0, "name": "face it with stone", "smith": 0},
	"gate": {"cost": {"iron": 8}, "mul": 2.0, "name": "band it with iron", "smith": 0},
	"barricade": {"cost": {"iron": 3}, "mul": 2.0, "name": "brace it with iron", "smith": 0},
	"spikes": {"cost": {"iron": 4}, "mul": 1.0, "name": "tip them with iron", "smith": 2},
}
const SHP := {"barricade": 90.0, "spikes": 40.0, "wall": 260.0, "gate": 220.0, "bodywall": 110.0, "decoy": 70.0,
	"chicken": 40.0, "pitfall": 4.0, "tar": 100.0, "trough": 60.0, "logs": 1.0, "thresher": 160.0}   # a pitfall: how many it swallows; tar and the trough wear out with use
const SDIM := {"barricade": Vector2(1.7, 0.45), "spikes": Vector2(1.7, 0.8), "wall": Vector2(3, 0.45), "gate": Vector2(3, 0.45), "bodywall": Vector2(1.7, 0.5), "decoy": Vector2(0.45, 0.45),
	"chicken": Vector2(0.5, 0.5), "pitfall": Vector2(1.2, 1.2), "tar": Vector2(1.8, 1.2), "trough": Vector2(1.7, 0.5), "logs": Vector2(1.6, 1.0), "thresher": Vector2(0.9, 0.9)}
const SNAME := {"barricade": "barricade", "spikes": "spike row", "wall": "palisade wall", "gate": "gate", "bodywall": "body wall", "decoy": "decoy",
	"chicken": "chicken decoy", "pitfall": "pitfall", "tar": "tar pit", "trough": "holy water trough", "logs": "log roller", "thresher": "Thresher"}
const SKINDS := ["wall", "gate", "barricade", "spikes", "bodywall", "decoy", "chicken", "pitfall", "tar", "trough", "logs", "thresher"]
const BLOCKERS := ["wall", "gate", "barricade", "bodywall", "decoy", "chicken"]   # what the dead have to break, or go round
## Contraptions: the peasant community's inventions, learned from Barricades for Beginners (or built with a box of cogs).
const CONTRAPTIONS := ["chicken", "pitfall", "tar", "trough", "logs", "thresher"]
const CONTR := {
	"chicken": {"rank": 1, "d": "A caged chicken. The dead nearby cannot leave it alone, and it does not last long"},
	"pitfall": {"rank": 3, "d": "Swallows the first four of the dead to cross it, for good. Good inside the wall, for gravediggers"},
	"tar": {"rank": 4, "d": "Everything that wades through it is slowed, the dead most of all"},
	"trough": {"rank": 5, "d": "Holy water: burns the dead that cross it, wraiths too. Needs water blessed at the chapel (a class of holy studies, or the Holy Book)"},
	"logs": {"rank": 6, "d": "A stack of logs north of the wall. Once a night, when a crowd or a coffin ram comes down the road past it, it rolls them flat"},
	"thresher": {"rank": 7, "d": "A spinning flail. Hits everything round it, as long as someone is near enough to turn the handle"},
}
const BUILDS := ["barricade", "spikes", "bodywall", "decoy"]

# --- everything a peasant can hold or wear. s: w weapon, h head, b body, o off hand, t carried.
# arc is the smallest cosine of the angle a swing reaches: 0.5 is a third of a circle, 0 is half. rng marks a ranged weapon and how far it carries.
const _IT := [
	{"n": "pitchfork", "s": "w", "tier": "found", "dmg": 12, "cd": 0.42, "reach": 2.3, "arc": 0.5, "ab": "pin", "pool": "fork", "note": "Long and light"},
	{"n": "short sword", "s": "w", "tier": "forged", "dmg": 18, "cd": 0.36, "reach": 1.9, "arc": 0.5, "ab": "parry", "pool": "sword", "swing": 1, "cost": {"iron": 6, "wood": 2}, "note": "Quick and balanced"},
	{"n": "spear", "s": "w", "tier": "forged", "dmg": 20, "cd": 0.5, "reach": 2.9, "arc": 0.85, "ab": "brace", "pool": "spear", "cost": {"iron": 4, "wood": 4}, "note": "The longest reach, a narrow jab"},
	{"n": "mace", "s": "w", "tier": "forged", "dmg": 22, "cd": 0.6, "reach": 1.9, "arc": 0.5, "blunt": true, "ab": "shatter", "pool": "mace", "swing": 1, "cost": {"iron": 8, "wood": 2}, "note": "Skeletons it breaks stay broken"},
	{"n": "billhook", "s": "w", "tier": "forged", "dmg": 20, "cd": 0.6, "reach": 2.8, "arc": 0.0, "heavy": true, "ab": "hook", "pool": "bill", "swing": 1, "cost": {"iron": 8, "wood": 4}, "note": "Heavy. Long reach and a wide sweep"},
	{"n": "warhammer", "s": "w", "tier": "forged", "dmg": 45, "cd": 1.0, "reach": 2.0, "arc": 0.5, "blunt": true, "heavy": true, "ab": "smash", "pool": "hammer", "swing": 1, "cost": {"iron": 12, "wood": 4}, "note": "Heavy. Slow and devastating"},
	{"n": "club", "s": "w", "tier": "found", "dmg": 24, "cd": 0.75, "reach": 1.8, "arc": 0.5, "blunt": true, "ab": "wallop", "pool": "club", "swing": 1, "note": "Slow, heavy single hits"},
	{"n": "spade", "s": "w", "tier": "found", "dmg": 19, "cd": 0.7, "reach": 2.0, "arc": 0.4, "kb": 0.8, "ab": "bury", "pool": "spade", "swing": 1, "note": "A slow swing with a knock-back"},
	{"n": "rake", "s": "w", "tier": "found", "dmg": 11, "cd": 0.4, "reach": 2.6, "arc": 0.3, "ab": "trip", "pool": "rake", "swing": 1, "note": "Long and light"},
	{"n": "scythe", "s": "w", "tier": "found", "dmg": 17, "cd": 0.8, "reach": 2.5, "arc": -0.2, "ab": "reap", "pool": "scythe", "swing": 1, "note": "A wide sweep, slow to recover"},
	{"n": "kitchen dagger", "s": "w", "tier": "found", "dmg": 8, "cd": 0.24, "reach": 1.4, "arc": 0.5, "ab": "backstab", "pool": "dagger", "note": "Very fast, very short"},
	{"n": "frying pan", "s": "w", "tier": "found", "dmg": 8, "cd": 0.34, "reach": 1.6, "arc": 0.5, "blunt": true, "ab": "clang", "pool": "pan", "swing": 1, "note": "Weak and quick"},
	{"n": "sling", "s": "w", "tier": "found", "dmg": 9, "cd": 0.8, "rng": 12, "ab": "aimed", "pool": "sling", "shot": 0, "note": "A weak ranged attack, and no shortage of stones"},
	{"n": "bow", "s": "w", "tier": "forged", "dmg": 16, "cd": 0.9, "rng": 16, "ab": "volley", "pool": "bow", "shot": 1, "need": [5, 1], "cost": {"iron": 2, "wood": 8}, "note": "Solid ranged damage, over the wall"},
	{"n": "crossbow", "s": "w", "tier": "forged", "dmg": 34, "cd": 1.8, "rng": 18, "heavy": true, "ab": "pierce", "pool": "xbow", "shot": 1, "need": [5, 3], "cost": {"iron": 10, "wood": 8}, "note": "Heavy. Slow to load, hits very hard"},
	{"n": "the Slightly Blessed Spade", "s": "w", "tier": "relic", "dmg": 26, "cd": 0.6, "reach": 2.1, "arc": 0.4, "kb": 1.6, "holy": true, "ab": "bury", "pool": "spade", "swing": 1, "tint": [1.25, 1.1, 0.6], "note": "Holy, with a heavy knock-back"},
	{"n": "Saint Wilbur’s Pitchfork", "s": "w", "tier": "relic", "dmg": 20, "cd": 0.4, "reach": 2.7, "arc": 0.5, "holy": true, "line": true, "ab": "pin", "pool": "fork", "tint": [1.25, 1.1, 0.6], "note": "Holy. Its Pin goes through a whole line"},
	{"n": "the Silvered Sword", "s": "w", "tier": "relic", "dmg": 28, "cd": 0.34, "reach": 2.0, "arc": 0.5, "holy": true, "ab": "parry", "pool": "sword", "swing": 1, "tint": [1.2, 1.25, 1.35], "note": "Holy, quick and sharp"},
	{"n": "cooking pot", "s": "h", "tier": "found", "cut": 0.08, "pool": "helm", "tint": [0.42, 0.4, 0.42]},
	{"n": "iron cap", "s": "h", "tier": "forged", "cut": 0.15, "pool": "helm", "tint": [0.8, 0.83, 0.88], "cost": {"iron": 5}},
	{"n": "the Helm of the Unbothered", "s": "h", "tier": "relic", "cut": 0.2, "pool": "helm", "tint": [1.25, 1.05, 0.5], "note": "Your posse never loses its nerve"},
	{"n": "padded jerkin", "s": "b", "tier": "found", "cut": 0.15, "pool": "mail", "tint": [0.74, 0.55, 0.36]},
	{"n": "chain shirt", "s": "b", "tier": "forged", "cut": 0.3, "slow": 0.06, "pool": "mail", "tint": [0.68, 0.71, 0.76], "cost": {"iron": 10}},
	{"n": "the Vicar’s Breastplate", "s": "b", "tier": "relic", "cut": 0.4, "pool": "mail", "tint": [1.2, 1.05, 0.55], "note": "Burns any undead that strikes you"},
	{"n": "barrel lid", "s": "o", "tier": "found", "cut": 0.08, "arrow": 0.3, "pool": "shield", "tint": [0.8, 0.66, 0.46]},
	{"n": "iron-rimmed shield", "s": "o", "tier": "forged", "cut": 0.15, "arrow": 0.5, "pool": "shield", "tint": [1, 1, 1], "cost": {"iron": 4, "wood": 4}},
	{"n": "the Chapel Handbell", "s": "t", "tier": "relic", "pool": "bucket", "tint": [1.3, 1.0, 0.35], "note": "{carry} rings it: every undead nearby is stunned. A long wait between rings"},
	{"n": "the Smoking Censer", "s": "t", "tier": "relic", "pool": "bucket", "tint": [0.9, 0.9, 1.1], "note": "Undead near you are slowed"},
	{"n": "slop bucket", "s": "t", "tier": "found", "pool": "bucket", "tint": [0.6, 0.48, 0.3], "note": "{carry} lobs it, once: every undead it splashes runs from the smell"},
]
const _IT_DEF := {"dmg": 0.0, "cd": 0.0, "reach": 0.0, "arc": 0.0, "ab": "", "note": "", "swing": 0, "cost": {}, "blunt": false, "heavy": false,
	"fire": false, "runed": false, "kb": 0.0, "rng": 0.0, "shot": 0, "need": [], "holy": false, "line": false, "tint": [1, 1, 1], "cut": 0.0, "slow": 0.0, "arrow": 0.0, "base": -1, "wear": 0}
## The smithy makes three grades. Anyone can knock out a crude weapon, which wears out: after a night's fighting it is
## chipped, and after a second it falls apart. Hammer and Tongs (rank 1) makes the refined ones (the first list above);
## from rank 4, steel, from the old steel mine. Crude, chipped and steel things are made here from the refined ones,
## and given ids after the first 29, so saves keep working.
const CRUDE_W := [1, 2, 3, 4, 5]
const STEEL_W := [1, 2, 3, 4, 5]
const STEEL_A := [19, 22, 25]
static func _grades() -> Array:
	var out := []
	for base in CRUDE_W:                      # crude, then chipped
		var r: Dictionary = _IT[base]
		for w in [1, 2]:
			var o := r.duplicate(true)
			o.n = ("crude " if w == 1 else "chipped crude ") + r.n
			o.tier = "crude"; o.base = base; o.wear = w
			o.dmg = roundf(r.dmg * (0.8 if w == 1 else 0.68))
			o.cost = {"iron": maxi(1, ceili(r.cost.get("iron", 0) / 2.0)), "wood": r.cost.get("wood", 0)}
			o.note = "Crude: " + ("it will be chipped after a night’s fighting, and fall apart after a second" if w == 1 else "chipped, and will fall apart after another night’s fighting")
			o.tint = [0.75, 0.62, 0.5] if w == 1 else [0.62, 0.52, 0.44]
			out.append(o)
	for base in STEEL_W + STEEL_A:
		var r: Dictionary = _IT[base]
		var o := r.duplicate(true)
		o.n = "steel " + r.n
		o.tier = "steel"; o.base = base
		if r.s == "w": o.dmg = roundf(r.dmg * 1.35)
		else:
			o.cut = r.cut + (0.06 if r.s != "o" else 0.05)
			if r.has("arrow"): o.arrow = minf(0.7, r.get("arrow", 0.0) + 0.15)
		o.cost = {"steel": maxi(2, ceili(r.cost.get("iron", 0) * 0.75)), "wood": r.cost.get("wood", 0)}
		o.note = "Steel: " + (r.note.to_lower() if r.has("note") and r.s == "w" else "better than iron")
		o.tint = [1.12, 1.18, 1.3]
		out.append(o)
	return out
## The top of the smithy: the five refined weapons again, made of steel with runes cut in. They go after everything
## else (see _MORE), so nothing earlier changes its number.
static func _runes() -> Array:
	var out := []
	for base in STEEL_W:
		var r: Dictionary = _IT[base]
		var o := r.duplicate(true)
		o.n = "rune " + r.n
		o.tier = "rune"; o.base = base; o.runed = true
		o.dmg = roundf(r.dmg * RUNE_DMG)
		o.cost = {"rune": RUNE_COST, "steel": maxi(2, ceili(r.cost.get("iron", 0) * 0.75)), "wood": r.cost.get("wood", 0)}
		o.note = "Rune-cut steel: " + (r.note.to_lower() if r.has("note") else "the best there is") + ". It bites wraiths"
		o.tint = [0.95, 0.78, 1.45]
		out.append(o)
	return out
## Things added later go on the end, so that every earlier thing keeps its number (saved games remember things by number).
## s "c": a paper, kept in the backpack and handed in somewhere, never worn.
const _MORE := [
	{"n": "library card", "s": "c", "tier": "paper", "pool": "card", "note": "Hand it in at the library to give up one of your books and take up another, a rank behind where you were"},
	{"n": "burning torch", "s": "w", "tier": "made", "dmg": 8, "cd": 0.46, "reach": 2.0, "arc": 0.35, "ab": "flare", "pool": "torch", "fire": true, "cost": {"wood": 3},
		"note": "Sets alight whatever it hits: they burn for a few seconds after. Lights the dark, too"},
]
static var IT: Array = _fill(_IT + _grades() + _MORE + _runes(), _IT_DEF)
const I_CARD := 47
const I_TORCH := 48
const BURN_TIME := 4.0               # how long a thing set alight burns, and what it takes every half second
const BURN_DMG := 3.0
const STUCK_WAIT := 20.0              # seconds between uses of "I'm a stuck little peasant"
const MUD := 0.92                    # how fast the living walk in the rain (the dead wade at 0.85)
const RUNE_COST := 4                 # runes in a rune weapon (with the steel a steel one takes)
const RUNE_DMG := 1.7                # a rune weapon's damage, against the refined one's (steel is 1.35)
const RUNE_RANK := 7                 # the rank of Hammer and Tongs that can make one
const RUNE_PER_VEIN := 2             # runes in each vein of the old workings, each morning
const RUNE_TIME := 4.0
const RUNE_VEINS := [[-6.0, 233.0], [6.0, 238.0], [-2.0, 229.9]]
## --- Inside the Thorny Rose: three locals, and what each will say. Each has three things to be asked about, and a set of
## answers for each week; and each will do you one small good turn a day for the price of a drink.
const LOCALS := [
	{"name": "Old Marge", "what": "knitting something long and grey by the fire", "ask": ["the castle", "Robert Bailiff", "the village"], "treat": "a pie from her basket: 3 food",
		"say": [
			["Foreign gentleman took it, from Transylvania they say. Paid Lord Aldred in gold, and nobody thought to ask whose.", "Nobody has seen him by day. Not once. I have seen his washing, mind. All black, and a great deal of it.", "They say he is a guest of Lord Aldred. I say a guest goes home."],
			["Robert? Bolted his door the first night and has been governing us through the letterbox ever since.", "He was a brave little boy. It did not last. His mother blamed the schooling.", "He keeps six guards in there with him. For the look of the thing, he says. They cost the earth, and he remembers a jeer."],
			["Four hundred years this village has stood, and the worst we ever had before was the sheep going wrong.", "Mind the maypole. It was put up for a wedding, and nobody will say whose.", "If you want anything known in Thornhallow, tell the priest in confidence."],
		]},
	{"name": "Tam the Carter", "what": "a big man with a tankard, and mud to the knee", "ask": ["the roads", "the smithy", "the dead"], "treat": "he tells you what he saw on the road today",
		"say": [
			["West road is all forest, right out to the thorn hedge. The old steel mine is at the top of it, and there is a hole beside it I would not go down without a light.", "East is the downs, and the old mill. Count the sheep if you like. I have stopped.", "Messengers come by the roads and the river. When one goes missing, look outside the wall. Look early, before the foxes."],
			["Anybody can knock out a crude blade, and it will see you through a night or two. For one that lasts you want Hammer and Tongs.", "Steel is the thing. Top of the forest. The smith wants rank four of his book before he will touch it.", "There are stones down the old workings with marks on. A smith who has read his book to the last page can work them into steel, and that blade will bite things a blade should not."],
			["Shamblers are slow. It is the standing still that kills you. Keep moving, and hit the one at the edge.", "Bones get up again unless you break them properly. A mace, or anything blessed.", "Something big sleeps under the outer ruins. Rummage if you must, but have your running legs on."],
		]},
	{"name": "the stranger in the corner", "what": "hooded, a long way from the fire, with a drink that has not gone down", "ask": ["what is coming", "the Lord", "himself"], "treat": "he tells you what the next of the Lord’s household cannot abide",
		"say": [
			["Every week he sends worse, and at the end of every week one of his own household comes down to see why you are not dead.", "The seventh night, the fourteenth, the twenty-first. And on the thirtieth, himself.", "Watch the castle as night falls. It will tell you how his temper is."],
			["He does not hate you. You are in the way, like a hedge.", "He writes letters. Read them. A man who complains can be annoyed, and a man who is annoyed makes mistakes.", "He has relatives. They all have relatives. Remember that, when you think you have won."],
			["I am waiting for someone. No, not you.", "I knew this inn when it had a different sign. A long time ago. Do not do the sums.", "Ask the gambler who I am. Then ask me who he is. We will both lie."],
		]},
]
const TREAT := 6                     # the price of a drink for a local: one good turn each, a day
const BOSS_HINT := {3: "The Steward keeps back and raises the fallen. He is no fighter: get to him early, and he stops.", 10: "The Coachman’s hearse goes through wood like paper. Stone on the walls and iron on the gate, and keep out of the road.",
	11: "The Captain does not come by the north gate unless he must. Watch which way his banner turns, and be at that gateway first.", 12: "Himself. Blessed things and rune-cut things hurt him properly. Nothing else does, much."}
## --- The gambler. Stakes, and his patience: when you have won this much in a day he packs up.
const BETS := [6, 12, 24, 48]
const GAMBLE_DAY := 120
const CARD_N := ["Ace", "2", "3", "4", "5", "6", "7", "8", "9", "10", "Knave", "Queen", "King"]
const CARD_SUIT := ["Cups", "Coins", "Swords", "Batons"]
const GAMBLER_SAYS := ["“Sit, friend. Three games, all honest. I have never been caught.”", "“The cards are old. They have opinions. Do not take it personally.”", "“Watch the cups, not my hands. Everybody watches my hands.”",
	"“I take coin from the living. The dead never have any change.”", "“I was here before the inn. They built it round me.”"]
## Rooms: places you walk into. They are built far off beyond the river, out of sight; going in or out moves you there and back.
## at: where you arrive inside (and leave from). door: the way in, outside. box: solid things inside, as [x, z, half width, half depth].
const ROOMS := {
	"mine": {"name": "the old workings", "x": 0.0, "z": 240.0, "hw": 7.0, "hd": 11.0, "at": [0.0, 249.4], "door": [-104.0, -40.2],
		"in": "climb down into the old workings", "out": "climb back up into the daylight",
		"box": [[-3.4, 243.0, 0.5, 0.5], [3.4, 243.0, 0.5, 0.5], [-3.4, 236.0, 0.5, 0.5], [3.4, 236.0, 0.5, 0.5], [1.6, 232.4, 1.0, 0.7]]},
	"inn": {"name": "the Thorny Rose Inn", "x": 60.0, "z": 240.0, "hw": 8.0, "hd": 6.0, "at": [60.0, 245.3], "door": [-13.2, -4.7],
		"in": "go into the Thorny Rose", "out": "go back out into the square",
		"box": [[60.0, 235.3, 4.6, 0.55], [55.4, 240.9, 0.85, 0.85], [64.4, 241.2, 0.85, 0.85], [66.6, 236.6, 0.9, 0.7], [52.35, 239.3, 0.35, 1.2], [52.5, 235.0, 0.9, 0.5]]},
}
## The chest that never arrived: who sent it, and the note inside.
const CHEST_FROM := [
	["the Mayor of Nether Wopping", "To the brave peasants of Thornhallow, with the Mayor’s admiration, from a safe distance."],
	["the Dowager Duchess of Hallowshire", "For the poor dear villagers. Do try not to be eaten. The Duchess."],
	["the Bishop of Mirewater", "A collection was taken. Some of it is here. Pray for the rest."],
	["the Guild of Master Thatchers", "From one roof to another. Do not spend it on the Bailiff."],
	["a clerk to Their Majesties", "Their Majesties have been informed of your situation and are appalled. Enclosed: the sum of what could be found in the coach."],
	["Lord Aldred’s second cousin, who feels responsible", "I told him not to let the castle to a foreigner. I am so sorry. Please accept this."],
]
const CHEST_ROADS := ["out to the west", "out to the east", "south, towards the river"]
## crude id -> chipped id, base -> crude id, base -> steel id
static func crude_of(base: int) -> int:
	return 29 + CRUDE_W.find(base) * 2
static func steel_of(base: int) -> int:
	return 29 + CRUDE_W.size() * 2 + (STEEL_W + STEEL_A).find(base)
static func rune_of(base: int) -> int:
	return 29 + CRUDE_W.size() * 2 + (STEEL_W + STEEL_A).size() + _MORE.size() + STEEL_W.find(base)
const SLOTK := {"w": "wpn", "h": "head", "b": "body", "o": "off", "t": "trk"}
const SLOTS := ["wpn", "head", "body", "off", "trk"]
const RELICS := [15, 16, 17, 20, 23, 26, 27]
const FOUND_W := [6, 7, 8, 9, 10, 11, 12]
const FOUND_A := [18, 21, 24]
const FORGE_W := [1, 2, 3, 4, 5, 13, 14]
const FORGE_A := [19, 22, 25]

# each weapon's own trick. cd is the wait between uses, in seconds.
const AB := {
	"pin": {"n": "Pin", "cd": 8.0, "d": "holds one enemy in place for a few seconds"},
	"parry": {"n": "Parry", "cd": 7.0, "d": "turns aside the next blow and staggers whoever swung it"},
	"brace": {"n": "Brace", "cd": 7.0, "d": "a thrust through everything in a line, stopping it dead"},
	"shatter": {"n": "Shatter", "cd": 9.0, "d": "cracks them open: everyone’s blows hurt them more for a while"},
	"hook": {"n": "Hook", "cd": 8.0, "d": "drags the farthest enemy in reach out of the crowd, off its feet"},
	"smash": {"n": "Smash", "cd": 11.0, "d": "a ground blow that flattens everything near it"},
	"flare": {"n": "Flare", "cd": 9.0, "d": "sweeps the flame all round you: everything near catches fire and backs off"},
	"wallop": {"n": "Wallop", "cd": 6.0, "d": "a wound-up blow that stuns and sends one enemy flying"},
	"bury": {"n": "Bury", "cd": 7.0, "d": "puts a wounded enemy, or a heap of bones, back in the ground for good"},
	"trip": {"n": "Trip", "cd": 8.0, "d": "sweeps a group off their feet"},
	"reap": {"n": "Reap", "cd": 8.0, "d": "one swing all the way round"},
	"backstab": {"n": "Backstab", "cd": 4.0, "d": "triple damage on an enemy that is busy with someone else"},
	"clang": {"n": "Clang", "cd": 10.0, "d": "the noise draws the undead to you, and the pan stops arrows for a while"},
	"aimed": {"n": "Aimed stone", "cd": 6.0, "d": "a careful shot that hits three times as hard and staggers"},
	"volley": {"n": "Volley", "cd": 9.0, "d": "three arrows at once"},
	"pierce": {"n": "Pierce", "cd": 10.0, "d": "a bolt that passes through everything in its way"},
}
const PEASANT_ARM := {"iron": 3, "wood": 2}
const STEEL_SELL := 3                # the market pays this much a piece for steel, and sells none
const SLUM_FOOD := 5
const FISH_FOOD := 3
const BLESS_FEE := 24
const HOLY_TIME := 45.0
const TANKARD := 25.0
const DRINK_TIME := 3.0
const SEARCHES := 2
const SEARCH_TIME := 3.5
const TOILET_CD := 60.0

# --- the ten books. Seven ranks each; a rank is earned by doing what the book teaches.
const XPM := [1, 3, 7, 13, 21, 32]   # how much doing each further rank takes, as a multiple of the book's first step
const SPARE_PAY := 12                # past rank VII, each further first step's worth of learning is a spare point, sold for this many pence
const BOOKS := [
	{"name": "The Woodcutter’s Almanac", "what": "Resource gathering", "base": 60, "by": "chopping, quarrying and mining", "ranks": ["Gather wood, stone and iron faster (and faster again with every rank)", "Carry 30 of each material", "Your posse works faster", "Your posse keeps gathering while you do something else nearby", "Carry 40 of each material", "One piece in five comes with a second", "Carry 50 of each material"]},
	{"name": "Field, Hook and Pot", "what": "Food", "base": 40, "by": "fishing and foraging", "ranks": ["Fish and forage faster (and faster again with every rank)", "Meals heal 35", "A catch is 4 fish", "Eating heals your whole posse too", "Meals heal 50", "Slum recruits cost 3 food", "Meals heal 65 and settle your posse’s nerves"]},
	{"name": "Barricades for Beginners", "what": "Defence making", "base": 8, "by": "building and repairing", "ranks": ["Building costs a fifth less (and a little less with every rank). Contraption: the chicken decoy", "Repairs are quicker and cost half", "Your barricades and body walls are a quarter stronger. Contraption: the pitfall", "Your barricades do not rot at dusk. Contraption: the tar pit", "Your spike rows last twice as long. Contraption: the holy water trough", "Your barricades and body walls are half as strong again. Contraption: the log roller", "Contraption: the Thresher, a spinning flail"]},
	{"name": "Hammer and Tongs", "what": "Blacksmithing", "base": 3, "by": "forging", "ranks": ["You can forge refined arms, not just crude ones, with a third less iron (and a little less with every rank)", "You can forge heavy arms (billhook, warhammer, crossbow) and iron tips for spike rows", "Arm your whole posse with spears in one go", "You can forge steel, from the old steel mine, and forged weapons hit a tenth harder in your hands", "Any armour you wear takes a further twentieth off every blow", "Your posse hit harder with their spears", "You can forge rune weapons, the best there are, from steel and the runes of the old workings. Facing, banding and bracing a defence costs half"]},
	{"name": "The Art of Hitting Things", "what": "Combat training", "base": 60, "by": "landing blows", "ranks": ["You hit harder up close (and harder again with every rank)", "One blow in eight against you misses", "Your weapon’s trick is ready a fifth sooner", "Your swings sweep wider", "Your weapon’s trick is ready a third sooner", "20 more health", "Every fifth blow you land is twice as hard"]},
	{"name": "Slings, Bows and Thrown Turnips", "what": "Ranged combat", "base": 40, "by": "landing shots", "ranks": ["You can use a bow, and a sling comes with the book (shots hit harder with every rank)", "Your shots never miss", "You can use a crossbow", "You shoot a fifth faster", "Emergency toilet breaks come round a third sooner", "Every shot also hits a second of the dead nearby", "Aimed stones, volleys and piercing bolts are ready in half the time"]},
	{"name": "How to Win Peasants and Lead Them", "what": "Peasant leadership", "base": 50, "by": "recruiting, and your posse’s blows", "ranks": ["Your posse keeps its nerve better (and better again with every rank)", "A posse one larger", "Orders: {orders} tells your posse to follow, hold or charge", "A posse two larger", "Your posse hits a quarter harder", "A posse three larger", "Your posse never runs away"]},
	{"name": "The Landlord’s Ledger", "what": "Dutch courage", "base": 4, "by": "drinking at the Thorny Rose Inn", "ranks": ["Every tankard gives more courage (and more again with every rank)", "A longer charge: 26 seconds", "Half the hangover", "No hangover", "When you drink, everyone else in the inn gets a little courage too", "A longer charge: 32 seconds", "The charge hits twice as hard"]},
	{"name": "Relics and Where They Were Left", "what": "Relic lore", "base": 4, "by": "searching the ruins", "ranks": ["You search rubble faster (and faster again with every rank)", "Your map marks the rubble that still hides something", "Relics turn up half as often again", "You find twice the materials and coin in rubble", "Holy weapons, blessings and holy slop hit harder in your hands", "Relics turn up far more often", "Nothing lurking in the ruins notices you searching"]},
	{"name": "Granny’s Remedies", "what": "Healing", "base": 4, "by": "bandaging and reviving", "ranks": ["Bandage a hurt ally: hold {interact} beside them (it heals more with every rank)", "Revive twice as fast, and to better health", "Each of your posse survives one fatal blow a night", "You heal slowly all the time, even in a fight", "Knocked down, you last twice as long before you die", "A bandage heals completely", "Once a night you get back up by yourself"]},
	{"name": "The Holy Book (Abridged)", "what": "Divine powers: the apprentice priest", "base": 30, "by": "smiting and praying", "class": 0, "ranks": [
		"Minor Smiting: {power1} calls down a bolt of holy light on the nearest of the dead (it hits harder with every rank)",
		"A Word of Protection: {power2} prays over you and everyone near you, your posse included: a third less harm for ten seconds",
		"The Blessing of Mild Improvement: the prayer also makes everyone’s weapons holy while it lasts",
		"Smiting, With Feeling: a smite bursts, and scorches everything near what it hits",
		"Smites and prayers come round a third sooner",
		"Hallowed Ground (Mostly): the prayer also mends 25 health and steadies your posse’s nerve",
		"Divine Intervention, Probably: a smite strikes three of the dead at once, and wraiths and bosses twice as hard"]},
]
## Callings: a book that makes you something more than a peasant, with two powers on their own keys. One calling at a
## time. The Holy Book is the first; more can follow (each needs its book, and its two powers in rules.gd).
const CLASSES := [
	{"name": "Apprentice Priest", "book": 10, "powers": [
		{"n": "Smite", "full": "Minor Smiting", "rank": 1, "icon": "smite", "d": "a bolt of holy light on the nearest of the dead"},
		{"n": "Pray", "full": "A Word of Protection", "rank": 2, "icon": "pray", "d": "a third less harm for you and everyone near you, for ten seconds"}]},
]
const B_HOLY := 10
## A title from the books you have read: the one you know best, and the next best.
const TITLE_NOUN := ["Woodcutter", "Cook", "Barricader", "Smith", "Brawler", "Turnip-Slinger", "Ringleader", "Regular", "Relic-Botherer", "Granny", "Apprentice Priest"]
const TITLE_ADJ := ["Splintery", "Well-Fed", "Over-Fortified", "Sooty", "Bruising", "Sharp-Eyed", "Bossy", "Merry", "Dusty", "Kindly", "Holy"]
## Each relic has a book it goes with. Carrying the relic with that book read does something more.
const RELIC_LORE := {
	15: [1, "Every Bury feeds you: 10 health"],
	16: [6, "Your posse’s blows are holy too"],
	17: [4, "It hits a quarter harder"],
	20: [7, "Your Dutch courage charge lasts half as long again"],
	23: [9, "Every burn it gives mends you a little"],
	26: [10, "Its ring smites everything it stuns"],
	27: [8, "The dead it slows smoulder"],
}
# --- the dead. first: the night of the month they first come down. cost: how much of a night's horde one of them is
# worth (a shambler is 1). Flags: bony (reassembles once), boss, climb (over barricades), dig (under the north wall),
# fly (over everything, for the keep), armour (shrugs off farm tools), ghost (through walls; only holy things hurt it),
# ram (goes for the gate), hearse (the Coachman), lord.
const _UN := [
	{"name": "shambler", "hp": 50.0, "spd": 1.5, "dmg": 9.0, "sdmg": 7.0, "kdmg": 3.0, "cd": 1.3, "r": 0.5, "first": 1},
	{"name": "skeleton", "hp": 16.0, "spd": 2.9, "dmg": 6.0, "sdmg": 3.0, "kdmg": 2.0, "cd": 0.9, "r": 0.4, "bony": true, "first": 2, "cost": 0.6},
	{"name": "skeleton archer", "hp": 14.0, "spd": 2.4, "dmg": 6.0, "sdmg": 2.0, "kdmg": 2.0, "cd": 2.4, "r": 0.4, "rng": 11.0, "bony": true, "first": 4, "cost": 0.8},
	{"name": "the Steward", "hp": 800.0, "spd": 1.3, "dmg": 10.0, "sdmg": 8.0, "kdmg": 5.0, "cd": 1.2, "r": 0.75, "boss": true, "first": 7},
	{"name": "ghoul", "hp": 34.0, "spd": 4.2, "dmg": 8.0, "sdmg": 5.0, "kdmg": 2.0, "cd": 0.8, "r": 0.45, "climb": true, "first": 8, "cost": 1.2},
	{"name": "gravedigger", "hp": 44.0, "spd": 1.8, "dmg": 9.0, "sdmg": 6.0, "kdmg": 3.0, "cd": 1.1, "r": 0.5, "dig": true, "first": 10, "cost": 1.5},
	{"name": "bat swarm", "hp": 18.0, "spd": 4.8, "dmg": 3.0, "sdmg": 0.0, "kdmg": 4.0, "cd": 0.7, "r": 0.6, "fly": true, "first": 12, "cost": 0.8},
	{"name": "the Lord’s guard", "hp": 130.0, "spd": 1.35, "dmg": 13.0, "sdmg": 24.0, "kdmg": 6.0, "cd": 1.4, "r": 0.55, "armour": true, "first": 15, "cost": 4.0},
	{"name": "wraith", "hp": 55.0, "spd": 2.0, "dmg": 10.0, "sdmg": 0.0, "kdmg": 5.0, "cd": 1.2, "r": 0.5, "ghost": true, "first": 18, "cost": 3.0},
	{"name": "coffin ram", "hp": 320.0, "spd": 1.25, "dmg": 12.0, "sdmg": 70.0, "kdmg": 30.0, "cd": 2.6, "r": 1.2, "ram": true, "first": 20, "cost": 10.0},
	{"name": "the Coachman", "hp": 1100.0, "spd": 6.0, "dmg": 22.0, "sdmg": 999.0, "kdmg": 40.0, "cd": 1.5, "r": 1.3, "boss": true, "hearse": true, "first": 14},
	{"name": "the Captain of the Guard", "hp": 1500.0, "spd": 1.45, "dmg": 24.0, "sdmg": 45.0, "kdmg": 10.0, "cd": 1.3, "r": 0.8, "boss": true, "armour": true, "first": 21},
	{"name": "the Lord", "hp": 2600.0, "spd": 1.6, "dmg": 30.0, "sdmg": 60.0, "kdmg": 25.0, "cd": 1.2, "r": 0.8, "boss": true, "lord": true, "first": 30},
	{"name": "the Previous Tenant", "hp": 260.0, "spd": 2.7, "dmg": 16.0, "sdmg": 14.0, "kdmg": 6.0, "cd": 1.15, "r": 0.6, "tenant": true, "first": 99, "cost": 6.0},
]
const _UN_DEF := {"rng": 0.0, "bony": false, "boss": false, "climb": false, "dig": false, "fly": false, "armour": false, "ghost": false,
	"ram": false, "hearse": false, "lord": false, "tenant": false, "first": 1, "cost": 1.0}
static var UN: Array = _fill(_UN, _UN_DEF)
const U_TENANT := 13                 # the Previous Tenant: what sometimes comes up when the outer ruins are searched by day
const TENANT_CHANCE := 0.05          # a search: one in twenty, and a little more each week
const U_STEWARD := 3
const U_GHOUL := 4
const U_DIGGER := 5
const U_BATS := 6
const U_GUARD := 7
const U_WRAITH := 8
const U_RAM := 9
const U_COACH := 10
const U_CAPTAIN := 11
const U_LORD := 12
const BOSS_NIGHTS := {7: 3, 14: 10, 21: 11, 30: 12}   # the night of the month: which boss comes down
const MONTH := 30
const WEEK := 7
const SHORT_NIGHTS := [1, 4, 8, 12, 18, 20, 30]     # the short game: which night of the month each of its 7 nights is like

# --- weather. Most nights are clear. Night 15 is always the full moon.
const WEATHER := ["clear", "clear", "clear", "overcast", "rain", "clear", "fog", "overcast", "rain", "clear", "snow", "clear"]
const WEATHER_LINE := {
	"clear": "",
	"overcast": "The sky is the colour of old porridge today.",
	"rain": "It is raining. Tonight the ground will be mud, and the dead will wade.",
	"fog": "A thick fog has come up off the river. Tonight you will hear the dead before you see them.",
	"snow": "It is snowing. Everyone will be slower tonight, the dead included.",
	"moon": "Tonight is the full moon. Relics glint in the rubble, and the dead are restless and quick.",
}
const RELS := ["{n}’s twin", "{n}’s cousin", "{n}’s second cousin", "{n}’s cousin’s lodger", "{n}’s great-aunt’s godchild", "someone who once met {n} at a fair", "a creditor of {n}’s", "a passer-by mistaken for {n}"]
const JUNK := ["a dead rat", "somebody else’s left shoe", "one button", "a rude carving of Robert Bailiff", "a jar of what used to be jam", "nothing but spiders", "a note reading “IOU one relic”"]

# places where pressing E opens a notice of things to do
const STATIONS := [
	{"id": "market", "x": 0.0, "z": 19.7, "r": 3.4, "name": "the market", "verb": "trade at the market"},
	{"id": "smithy", "x": 12.4, "z": -4.7, "r": 3.2, "name": "the smithy", "verb": "use the smithy"},
	{"id": "store", "x": 12.9, "z": 10.6, "r": 3.0, "name": "the storehouse", "verb": "open the storehouse"},
	{"id": "library", "x": 13.4, "z": 20.4, "r": 3.0, "name": "the library", "verb": "read in the library"},
	{"id": "slum", "x": -17.6, "z": 17.4, "r": 3.4, "name": "the slum", "verb": "recruit in the slum"},
	{"id": "inn", "x": 60.0, "z": 236.9, "r": 1.9, "room": "inn", "name": "the bar of the Thorny Rose", "verb": "have a word with the innkeeper"},
	{"id": "priest", "x": 13.6, "z": -10.6, "r": 2.3, "name": "the priest", "verb": "speak to the priest"},
	{"id": "cart", "x": 10.4, "z": 22.6, "r": 3.0, "name": "the merchant’s cart", "verb": "see what the merchant has"},
	{"id": "bailiff", "x": -14.5, "z": -16.6, "r": 2.4, "name": "Robert Bailiff’s back door", "verb": "knock at Robert Bailiff’s back door"},
	{"id": "window", "x": -14.5, "z": -8.2, "r": 2.6, "name": "Robert Bailiff’s front door", "verb": "call up to Robert Bailiff’s window"},
	{"id": "bell", "x": 5.5, "z": -8.6, "r": 1.8, "name": "the village bell", "verb": "ring the village bell"},
	{"id": "board", "x": -5.5, "z": -8.5, "r": 1.8, "name": "the notice board", "verb": "read the notice board"},
	{"id": "letter", "x": -4.2, "z": -18.4, "r": 1.6, "name": "the gatepost", "verb": "read the letter nailed to the gatepost"},
	{"id": "local0", "x": 55.4, "z": 242.3, "r": 1.7, "room": "inn", "name": "Old Marge", "verb": "talk to Old Marge"},
	{"id": "local1", "x": 64.4, "z": 242.6, "r": 1.7, "room": "inn", "name": "Tam the Carter", "verb": "talk to Tam the Carter"},
	{"id": "local2", "x": 53.6, "z": 235.9, "r": 1.6, "room": "inn", "name": "the stranger in the corner", "verb": "talk to the stranger in the corner"},
	{"id": "gambler", "x": 65.6, "z": 237.9, "r": 1.7, "room": "inn", "name": "the gambler", "verb": "sit down with the gambler"},
	{"id": "shelf", "x": 53.1, "z": 239.3, "r": 1.4, "room": "inn", "name": "the inn’s bookshelf", "verb": "look at the inn’s bookshelf"},
]
# --- The Lord of Ashhollow's letters of complaint. A headless rider nails one to the gatepost at first light.
# why: what must have happened first (a count in Rules.seen, or "kills"); the rest are sent when there is nothing new to complain of.
const LETTERS := [
	{"id": "intro", "sub": "An introduction", "t": "Sirs, I write as your neighbour at the Castle. Several of my household walked down last night to introduce themselves and were, I am told, struck repeatedly with a pitchfork. I am sure this was a misunderstanding. They will call again this evening, and every evening, until it is cleared up."},
	{"id": "steward", "sub": "My Steward", "t": "Sirs, You have broken my Steward. He had been with the family four hundred years, three hundred of them after his death, and never missed a day. I shall now have to do my own accounts, and I warn you that I round up."},
	{"id": "coach", "sub": "The hearse", "t": "Sirs, The hearse was an antique. It had carried eleven generations of my family to the vault, and nine of them back again. The Coachman is inconsolable, though with him it is hard to tell. I am informed that you used a wall."},
	{"id": "captain", "sub": "My Captain of the Guard", "t": "Sirs, My Captain of the Guard has returned without his guard, his standard, or the lower half of himself. He asks me to say that it was a fair fight. I have told him that is exactly what was wrong with it."},
	{"id": "final", "sub": "A visit", "t": "Sirs, I have enjoyed our correspondence, though I notice that I have done all of it. I shall call in person this evening, at about dusk, with everybody. Please do not go to any trouble."},
	{"id": "tar", "why": "b_tar", "n": 1, "sub": "The smell", "t": "Sirs, About the tar pit. The wind has been in the south for three days and the Castle smells like a shipyard. Two of my footmen are still in it. I should like them back when you have finished with them, and I should like the smell back never."},
	{"id": "chicken", "why": "b_chicken", "n": 1, "sub": "The chicken", "t": "Sirs, A chicken, in a cage. Six of my household spent the whole of last night trying to reason with it, and came home at dawn having achieved nothing, which I had thought was my Steward’s job. I do not consider this sporting."},
	{"id": "thresher", "why": "b_thresher", "n": 1, "sub": "Your machine", "t": "Sirs, The machine with the flails. I am told it is agricultural. It is not agriculture when it is done to a footman. I have had what was left of him swept up, and I am sending him back down tonight with the others, in a bucket, to make my point."},
	{"id": "pitfall", "why": "b_pitfall", "n": 1, "sub": "Holes", "t": "Sirs, I learn that you have been digging holes and covering them with twigs. My gravediggers are professionals, with four centuries in the trade, and are mortified to have fallen for it. Kindly fill them in. The holes, I mean."},
	{"id": "logs", "why": "b_logs", "n": 1, "sub": "Logs", "t": "Sirs, Logs. Rolled down the road. Into a funeral procession. I have looked through every book of etiquette in the Castle for the proper way to put this, and there is none."},
	{"id": "holy", "why": "smite", "n": 3, "sub": "Your clergyman", "t": "Sirs, I understand that one of you has taken holy orders, or at any rate taken a book. Shouting at the sky until something falls out of it is not theology. My chaplain agrees with me, or would, if he could be found, and if you had not hit him with it."},
	{"id": "bodies", "why": "b_bodywall", "n": 1, "sub": "Your walls", "t": "Sirs, It has come to my attention that you are building walls out of your neighbours. I had rather thought that sort of thing was my department. I do not object. I merely note that when I do it, people write letters."},
	{"id": "jeer", "why": "jeer", "n": 2, "sub": "Mr Bailiff", "t": "Sirs, Mr Bailiff has written to me to complain about your manners. I mention it only because he wrote to me, the besieging party, for sympathy, and I found that I had some. Please stop shouting at his window. He is the only thing in your village that is on my side."},
	{"id": "hired", "why": "hired", "n": 1, "sub": "Staff", "t": "Sirs, I see that you have begun paying men to stand about at night. I have never paid anyone, and my staff turnover is nil. I offer this as one employer to another."},
	{"id": "bell", "why": "bell", "n": 4, "sub": "The bell", "t": "Sirs, I must raise the matter of the bell. It has been rung a great many times, to no purpose that my staff could discover. Some of us sleep during the day, and have done for centuries. I should be obliged if it were rung only in an emergency, of which I shall give you notice."},
	{"id": "bones", "why": "kills", "n": 60, "sub": "Breakages", "t": "Sirs, A large number of my staff have now been returned to me in pieces. Skeletons do not grow on trees. They grow in the ground, slowly, at my expense. I enclose an invoice. I do not expect you to be able to read it."},
	{"id": "ruins", "why": "search", "n": 3, "sub": "My ruins", "t": "Sirs, The ruins on my estate are ruined on purpose. They are a feature. Your people have been seen carrying off the contents in sacks. If you should find a small brass handbell, it is mine, and I should much rather you did not ring it."},
	{"id": "fish", "why": "fish", "n": 3, "sub": "The river", "t": "Sirs, The river is mine as far as the far bank, and so, strictly, are the fish. I do not eat them. I do not eat anything, any more. It is the principle."},
	{"id": "trees", "sub": "The chopping", "t": "Sirs, The chopping. From first light. I had that forest planted in 1312 to keep the sound of the village out, and I now find that the village is carrying it away a log at a time."},
	{"id": "smoke", "sub": "Your smithy", "t": "Sirs, Your smithy. The smoke blows up the valley and has turned the washing on the east tower grey. It was grey before, but it was our grey."},
	{"id": "maypole", "sub": "The maypole", "t": "Sirs, A maypole. I can see it from my window. It is the most cheerful thing I have looked at in six hundred years, and I should be grateful if it were taken down."},
	{"id": "sheep", "sub": "The sheep", "t": "Sirs, My household passes the old mill on its way to you each evening, and each morning I am told there were seven sheep. One of my ghouls insists there were eight. He will not be talked out of it. If there is an eighth sheep, I should like it explained."},
	{"id": "ducks", "sub": "Your ducks", "t": "Sirs, Your ducks. There are two of them, on a pond, in the middle of a siege, doing nothing whatever about it. I find I cannot stop watching them. Please have them moved."},
	{"id": "singing", "sub": "The singing", "t": "Sirs, The singing from the Thorny Rose carries up the valley. My household knows all the words now, and has begun joining in on the road down, which spoils the effect I am going for."},
	{"id": "weather", "sub": "The weather", "t": "Sirs, You will have noticed the weather. I had arranged for fog throughout. I do not know what you have done to deserve sunshine, but I have complained to the proper authority, who is not answering."},
	{"id": "reply", "sub": "My letters", "t": "Sirs, I have had no reply to any of my letters. I am told that most of you cannot read and that the rest are busy. I shall therefore write more slowly."},
	{"id": "rent", "sub": "The neighbourhood", "t": "Sirs, I pay Lord Aldred a very fair rent for the Castle, on the understanding that the neighbourhood was quiet. It was described to me as “a sleepy village”. I have asked for some of it back."},
	{"id": "dummies", "sub": "The straw men", "t": "Sirs, The straw men in your training yard. Several of my newer staff took them for villagers last night, attacked, and were, I am sorry to say, held to a draw."},
	{"id": "door", "sub": "Mr Bailiff’s door", "t": "Sirs, My household has knocked at Mr Bailiff’s door every night this week, to serve him with a notice. It does not open. I begin to understand you a little."},
	{"id": "pitchfork", "sub": "Weapons", "t": "Sirs, A point of order. A pitchfork is a tool. A lady or gentleman who has gone to the trouble of dying and getting up again is entitled to be put down by something with a proper name. I enclose a catalogue."},
]
const LETTER_SIGN := "I remain, &c.,\nAshhollow"
# --- The notice board in the square. Three of these are pinned up each day, between the news.
const NOTICES := [
	"LOST: one husband, answers to Gerald. Last seen walking slowly towards the graveyard. If found, do not return.",
	"BY ORDER of R. Bailiff: the dead are not to be fed, argued with, or let in.",
	"FOR SALE: coffin, hardly used. Owner got out. Apply at the chapel.",
	"WANTED: night watchman. Previous applicants need not reapply, and have not.",
	"FINES. Ringing the bell without cause: 2d. Ringing the bell with cause: 2d.",
	"The duck pond is not the well. The well is not the duck pond. This is the last time. R.B.",
	"Would whoever has been drinking the holy water please stop. It is for the trough. (The Priest.)",
	"CURFEW at dusk. This is advice, not a rule. The rule is: run.",
	"Thornhallow in Bloom is postponed, for the four hundredth year running.",
	"Choir practice is cancelled until further notice, owing to what happened to the tenors.",
	"The stocks are closed for repair. Offenders are asked to wait their turn standing up.",
	"FOUND: one arm. The owner may collect it from the Thorny Rose, where it is holding a tankard.",
	"Rent is due on the first of the month, siege or no siege. R.B.",
	"MAYPOLE DANCING, weather and the dead permitting. Bring your own ribbon.",
	"LESSONS in the pitchfork: the pointy end, and what to do if you find you are holding the other one. Training yard, daily.",
	"It is forbidden to bury relatives in the turnip field. The turnips have started coming up wrong.",
	"The Thorny Rose regrets that tabs cannot be passed on to the next of kin.",
	"REWARD of 3d for the Lord of Ashhollow, dead. (He is dead already. The reward has been claimed by Mr Bailiff.)",
	"Sheep at the old mill are to be counted every morning. If there are more than seven, tell the priest.",
	"Complaints about the Bailiff may be put in the box provided. The box is in the Bailiff’s house. The door is bolted.",
	"PARISH COUNCIL: the next meeting will be held under the table at the Thorny Rose.",
	"The smithy asks that crude swords be brought back for mending BEFORE they fall apart, and not in a bag.",
	"Whoever chalked “HELP” on the keep door: it is spelt correctly. Well done. (The Library.)",
	"Bodies left in the square after dawn will be assumed to be volunteering for the wall.",
]
# --- Robert Bailiff, at his upstairs window. Talk, knock, or jeer; he remembers jeering, and his guards cost more.
const BAILIFF_TALK := [
	["Ah. A peasant. Is it about the dead? It is always about the dead.", "I have every confidence in you. From up here.", "The Lord of Hallowshire sends his regards, and no soldiers.",
	"Keep the noise down at night, would you? Some of us are trying to hide."],
	["You will be pleased to hear I have drawn up a plan. It is in a drawer.", "I have written to Lord Aldred about the castle. He says the rent is very good.",
	"Do be careful with my guards. They are hired by the night, and I have to fill in a form if one dies.", "If you see the Coachman, tell him he still owes for the gate."],
	["I have been thinking about coming down to help. I have decided not to.", "The Lord's guard? Nobody told me he had a guard. Nobody tells me anything.",
	"I am told the merchants are cheating you. Good. It keeps the economy moving.", "I could open the door, but then the door would be open."],
	["Nearly done now. I have had a commemorative plate made, with my face on it.", "When this is over I shall make a speech. You are all invited to listen from outside.",
	"Courage, peasants! I shall be watching from a safe distance, which I have measured.", "Is he coming? The Lord? Tonight? I shall be under the bed. In a supervisory capacity."],
]
const BAILIFF_KNOCK := ["“Nobody is in!” calls a voice that sounds exactly like Robert Bailiff.", "“Go away! The door is load-bearing!”",
	"You knock. Something heavy is pushed against the other side of the door.", "“If it is about the guards, use the back door. If it is about anything else, also use the back door.”",
	"You knock. A note is slid under the door. It reads: NO."]
const BAILIFF_JEER := ["“I heard that!” He slams the shutters, then opens them again to say “I heard that” once more.", "“Peasant! I shall remember your face!” He clearly will not.",
	"A chamber pot sails out of the window. It misses, mostly.", "“Insolence! Guards! … Guards? Oh. They are on the gates. Very well, insolence noted.”",
	"He ducks out of sight, and can be heard writing something down."]
const BELL_LINE := ["The bell rings out over Thornhallow. Nothing happens, but it is very satisfying.", "BONG.", "Somebody rings the bell. A dog barks back.",
	"The bell rings. From an upstairs window, Robert Bailiff shouts “Is it them? Is it them?”"]
# --- the training yard: three straw dummies. Practising on them teaches a little of the fighting books, by day.
const DUMMIES := [[-20.0, 10.8], [-17.0, 10.8], [-14.0, 10.8]]
const DRILL_MAX := 30.0             # the most a day's practice teaches, in the book's own steps
# --- things peasants say
const BARK_RALLY := ["Right behind you!", "If you say so.", "I've got a pitchfork and I'm not afraid to point it.", "Is there food?", "Lead on. Slowly.", "My mother said this would happen."]
const BARK_DUSK := ["Here they come…", "I left the pot on.", "Smells like graveyard.", "Nobody panic. Except me.", "Is it too late to be a coward?", "Stay close, everyone. Not that close."]
const BARK_RUN := ["Nope!", "I've remembered an appointment!", "Every peasant for themselves!", "Tell my pig I loved him!"]
const BARK_DAWN := ["We lived!", "Is it over? It's over.", "Same again tonight, then.", "I'd like to lodge a complaint with the Bailiff."]
# --- travelling merchants. One comes on about six days of the month, parks by the market, and leaves at dusk.
# The best thing on the cart is not for sale: it is the pay for a job, which takes the whole day (half each with help).
# where: the job is done standing near there ("cart", "stone" (the outcrop), or a station's id).
const MERCHANTS := [
	{"id": "tinker", "name": "the tinker", "sells": "tools and contraption parts", "job": "Fetch a new cart wheel from the quarry road", "where": "stone",
		"doing": "searching the quarry road for a cart wheel", "pay": "boxes of cogs, for contraptions, and iron"},
	{"id": "armourer", "name": "the armourer", "sells": "forged arms, without the smithy", "job": "Guard the cart while he sleeps", "where": "cart",
		"doing": "guarding the cart. He snores", "pay": "his best piece: a warhammer"},
	{"id": "brewer", "name": "the brewer", "sells": "ale for the inn, and food", "job": "Unload and stack forty barrels", "where": "cart",
		"doing": "stacking barrels", "pay": "the Brewer’s Reserve: tonight every tankard at the inn counts double"},
	{"id": "pedlar", "name": "the relic pedlar", "sells": "one real relic among several fakes", "job": "Carry a very heavy crate to the old chapel", "where": "priest",
		"doing": "carrying the crate to the chapel, a step at a time", "pay": "the real relic"},
	{"id": "bookseller", "name": "the bookseller", "sells": "loose pages that advance a book", "job": "Copy out his ledger by hand", "where": "library",
		"doing": "copying out the ledger", "pay": "An Index of Further Reading, or a whole chapter of one of your books"},
]
const JOB_WORK := 240.0              # seconds of work: most of a day alone, half each with a team-mate
const FAKES := ["a Splinter of the True Fence", "Saint Bob’s Left Toenail", "a Feather from the Holy Goose", "the Jawbone of a Very Small Martyr",
	"a Vial of Saint Agatha’s Tears (water)", "a Genuine Halo, Slightly Bent", "the Shroud of Saint Nobody", "a Tooth of Saint Unknown (a horse’s)"]
# --- hired help
const GUARD_FEE := 96                # 8 shillings, at Robert Bailiff's back door: a guard holds a gate for the night
const MERC_FEE := 96                 # 8 shillings, at the Thorny Rose: a mercenary in your posse until dawn
const GUARDS := 6
const POSTS := [[0.0, -19.4], [-25.4, 2.0], [25.4, 2.0]]   # the north gate, the west gateway, the east gateway
const POST_NAMES := ["the north gate", "the west gateway", "the east gateway"]
const GUARD_NAMES := ["Sergeant Pike", "Corporal Dunn", "Old Gerald", "Watchman Hobb", "Halbert", "Young Gerald"]
const MERC_NAMES := ["Gunter the Unreliable", "Big Margery", "Swiss Hans", "Ulf (no surname)", "Sir Reginald (allegedly)", "Mad Agnes", "Two-Swords Tom", "the Bastard of Bruges"]
const INN := {"x": 60.0, "z": 237.6, "dx": -13.6, "dz": -4.7}   # at the bar (inside, which is a room far off), and the door on the square
const FARM := {"x0": -70.0, "x1": -46.5, "z0": 20.4, "z1": 41.6}
# --- the stone, the iron and the fish are somewhere new every morning
const SITES := [
	[{"x": 60.0, "z": -8.0, "n": "east of the village"}, {"x": 44.0, "z": -38.0, "n": "in the north-east field"}, {"x": 72.0, "z": 26.0, "n": "far to the east"}, {"x": -40.0, "z": -54.0, "n": "north of the forest"}, {"x": 38.0, "z": 40.0, "n": "south-east, towards the river"}, {"x": -110.0, "z": 16.0, "n": "out past the forest, in the far west"}, {"x": 106.0, "z": -10.0, "n": "up on the eastern downs"}],
	[{"x": 58.0, "z": 24.0, "n": "east, beyond the gate"}, {"x": 78.0, "z": -30.0, "n": "far to the north-east"}, {"x": -78.0, "z": -55.0, "n": "at the top of the forest"}, {"x": -34.0, "z": 46.0, "n": "south-west, by the river"}, {"x": 82.0, "z": 46.0, "n": "in the far south-east corner"}, {"x": 112.0, "z": 8.0, "n": "under the eastern downs"}, {"x": -112.0, "z": -16.0, "n": "deep in the far west"}],
	[{"x": 12.0, "z": 53.4, "n": "south of the village"}, {"x": -28.0, "z": 53.4, "n": "on the west reach"}, {"x": 34.0, "z": 53.4, "n": "on the east reach"}, {"x": -80.0, "z": 53.4, "n": "far downstream, to the west"}, {"x": 76.0, "z": 53.4, "n": "far upstream, to the east"}, {"x": -112.0, "z": 53.4, "n": "right down past the forest"}, {"x": 110.0, "z": 53.4, "n": "below the old mill"}],
]
# --- the ruins. The old ruins by the chapel never change; the two outer ruins fall down differently every night.
const RUINS := [{"x": 11.0, "z": -13.4, "name": "the old ruins"}, {"x": -58.0, "z": 47.6, "name": "the outer ruins"}, {"x": 58.0, "z": 47.6, "name": "the outer ruins"}]
# the clearings where the two outer ruins can be. Every night they wander off to two of them; nobody is told which.
const RUIN_SITES := [
	{"x": -58.0, "z": 47.6}, {"x": 58.0, "z": 47.6}, {"x": -62.0, "z": -22.0}, {"x": -81.0, "z": -4.0},
	{"x": 70.0, "z": -47.0}, {"x": 46.0, "z": 13.0}, {"x": -18.0, "z": 40.0}, {"x": 21.0, "z": 40.0}, {"x": -104.0, "z": 36.0}, {"x": 100.0, "z": -34.0},
]

const PCOL := ["#c8443a", "#3f77c4", "#e0a526", "#4f9d57", "#8e55b5", "#e07a2f", "#3aa6a0", "#d46a9a"]
const PCOLN := ["Red", "Blue", "Gold", "Green", "Purple", "Orange", "Teal", "Rose"]
const PNAMES := ["Aldith", "Wat", "Hob", "Maud", "Gib", "Cecily", "Dunstan", "Agnes", "Odo", "Mabel", "Tibb", "Edith", "Hugh the Lesser", "Joan", "Perkin", "Alys", "Godwin", "Rohese", "Ham", "Isolde", "Bartholomew", "Emmot", "Diggory", "Sibyl", "Old Ned", "Young Ned", "Marjory", "Pip", "Gunnora", "Wilkin", "Bet", "Lambert", "Tilda", "Jankin", "Avice", "Sim", "Parnell", "Colin", "Hawise", "Noll"]


static func _fill(raw: Array, def: Dictionary) -> Array:
	var out := []
	for r in raw:
		var o: Dictionary = def.duplicate(true)
		for k in r:
			o[k] = r[k]
		out.append(o)
	return out


# --- small helpers
static func d2(ax: float, az: float, bx: float, bz: float) -> float:
	var dx := ax - bx
	var dz := az - bz
	return dx * dx + dz * dz


static func ang_lerp(a: float, b: float, t: float) -> float:
	var d := fposmod(b - a + PI, TAU) - PI
	return a + d * t


static func it_a(id: int) -> String:   # "a club", "an iron cap", "the Silvered Sword"
	var I: Dictionary = IT[id]
	if I.tier == "relic":
		return I.n
	return ("an " if "aeiou".contains(I.n[0]) else "a ") + I.n


static func it_cap(id: int) -> String:
	var n: String = IT[id].n
	return n[0].to_upper() + n.substr(1)


## A book as it is shown everywhere: its title, and in a word or two what it is about.
static func book_title(b: int) -> String:
	return "%s (%s)" % [BOOKS[b].name, BOOKS[b].what]


static func rel_name(n: String, k: int) -> String:   # who takes over the cottage after a death
	if k <= 0:
		return n
	if k <= RELS.size():
		return RELS[k - 1].replace("{n}", n)
	return "a stranger claiming to be %s (no. %d)" % [n, k - RELS.size() + 1]


# money: 12 bronze pence to the silver shilling, 20 shillings to the gold piece
static func coins(d: float) -> String:
	var n := maxi(0, roundi(d))
	var g := floori(n / 240.0)
	var s := floori((n % 240) / 12.0)
	var p := n % 12
	return (str(g) + " gold " if g else "") + (str(s) + "s " if g or s else "") + str(p) + "d"


static func cost_text(c: Dictionary) -> String:
	var a := []
	for k in c:
		a.append(str(c[k]) + " " + (("body" if c[k] == 1 else "bodies") if k == "bodies" else ("rune" if c[k] == 1 else "runes") if k == "rune" else k))
	return " and ".join(a)


# each player's cottage: two rows of four, south of the keep
static func cottage(i: int) -> Dictionary:
	var col := i % 4
	var row := i >> 2
	var x := -7.5 + col * 5
	var z := 15.2 if row else 9.0
	var dir := 1 if row else -1
	return {"x": x, "z": z, "dir": dir, "sx": x, "sz": z + dir * 3.1}


static func inside_village(x: float, z: float) -> bool:
	return absf(x) < VW and z > VN and z < VS


## A peasant's name: villagers from D.PNAMES, guards and mercenaries from their own lists.
static func qname(q) -> String:
	if q.kind == 1: return GUARD_NAMES[q.ni % GUARD_NAMES.size()]
	if q.kind == 2: return MERC_NAMES[q.ni % MERC_NAMES.size()]
	return PNAMES[q.ni % PNAMES.size()]


static func station(id: String) -> Dictionary:
	for s in STATIONS:
		if s.id == id:
			return s
	return {}
