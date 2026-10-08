# Defend the Village! build log

The design lives in the doc "Defend the Village! — Game Design". This log records what each build actually contains and how it was made, so the next build can start from it.

## Moving to Godot, stage 2: the map and models (8 Oct 2026)

### What moved
- **Every model from the web version**, shape for shape (`godot/scripts/view/models.gd`): peasants, their weapons, armour and buckets, the shambler, skeleton, skeleton archer and the Steward, every defence, the outcrop, mine, jetty, rubble, trees and stumps, and the priest outside his chapel. Each model is one mesh, flat-shaded like the web version, and the dead are drawn two hundred at a time with one draw per kind.
- **The see-through keep:** it fades when the dead are close to it or a friend, a body or a dropped thing is just north of it.
- **Effects:** wood chips, stone and ore, splashes, coins, sparks, bones and rot when the dead are hit and put down, ghosts when the Steward raises the fallen, rings for Smash, Clang, Reap, Trip, the handbell and the slop bucket, arrows, stones and buckets in flight, felled trees toppling and chopped ones shivering, defences popping up and shuddering when struck, the gate opening for friends when none of the dead are near, health bars, sweating peasants who are losing their nerve, a glow on holy things.
- **The map in the corner, the signs over places, and other players' names.**
- The 25 script warnings Godot showed are gone.

### Tested
- Rule checks 107 of 107; the careful bot holds all seven nights; screenshots by day and night with everything on show. Seen running on Forward+ with Direct3D 12 on Matt's computer (stage 1).

## Moving to Godot, stage 1: the rules (8 Oct 2026)

**Where:** the `godot/` folder of the repository, and the Peasant Defence project on Matt's computer. The web version stays live at https://wijji551.github.io/Peasant/ until the Godot one has caught up.

### What moved
- **All the rules**, function for function from `src/05-sim.js`, with the same numbers: `godot/scripts/rules/` (data, map, things, rules). Nothing in them draws anything, so the host can run them for co-op later, as in the web version.
- **A playable game on top**, plainer than the web version for now: the village, the moving outcrop, mine and jetty, the outer ruins rebuilt each dawn, the north wall's foundations and everything built, trees felled and growing back, peasants holding and wearing their gear, the dead (shambler, skeleton, archer, the Steward), the notices for every place and the pack as plain parchment boxes, the dawn notice, a line of news, and saving each morning.

### Changes from the web version
- The dead push each other apart using a grid rather than checking every pair, so a big horde stays cheap. Same result.
- Walking into the outcrop only pushes you clear once you move (as in the web version, where the test for it was always true).

### Tested
- `godot/tests/rules_test.gd`: the web version's 107 rule checks, all passing.
- `godot/tests/bot_week.gd`: the careful bot held all seven nights (410 of the dead put down, no peasants lost); the walls-only bot fell on night 3, as in the web version.
- A bot night played in the game itself, headless, and screenshots by day and night (Compatibility renderer, software graphics on Linux).
- **Not tested:** the look on Forward+ with Direct3D 12 on Matt's computer.

### Still to move
2. (Done in stage 2.)
3. Menus: the scroll look, the slot inventory, the handbook, changing keys, the home screen and the change log.
4. Sound.
5. Co-op.

## Build 3: the inn and the ruins (8 Oct 2026)

**The game file:** `defend-the-village.html` in this project (it replaced Build 2). Saves from Build 2 do not load, and Build 2 and Build 3 players cannot join each other.

### What is in
- **The Thorny Rose.** Bring the innkeeper food by day (one piece, one tankard; what is left at dawn he drinks). From dusk, go in and bar the door with your posse. A tankard takes 3 seconds and adds 25% courage. At 100% you burst out and charge for 20 seconds (a third faster, 60% more damage, half damage taken), then 10 seconds of hangover. The dead nearby attack the inn door; when it breaks everyone is thrown out and it stays broken until dawn.
- **Ruins.** Eight heaps of rubble: two in the old ruins by the chapel (always the same), three in each outer ruin. The outer ruins are rebuilt differently every dawn. Each heap gives two searches a round. Finds: materials, coins, the seven found weapons, three pieces of found armour, slop buckets, loose pages, the Gift of the Gab, and relics (1.2% a search by day, 6% at night, rising a tenth each day). Searching the outer ruins wakes something 3 times in 10 by day and 6 in 10 at night.
- **Seven relics**, each unique: the Slightly Blessed Spade, Saint Wilbur's Pitchfork, the Silvered Sword, the Helm of the Unbothered, the Vicar's Breastplate, the Chapel Handbell, the Smoking Censer. A dead player's relics lie where they fell.
- **A trick for every weapon**, on Shift or right-click: Pin, Parry, Brace, Shatter, Hook, Smash, Wallop, Bury, Trip, Reap, Backstab, Clang, Aimed stone, Volley, Pierce. Sling, bow and crossbow shoot over the wall.
- **A pack** of six (I), and an **arms rack** in the storehouse shared by the village. Forging puts the new thing on and the old one in the pack.
- **Ten books, seven ranks each.** A second book at rank 2 of the first; a third when two books are at rank 3. Each further rank takes 3, 7, 13, 21 and 32 times the first.
- **The priest.** Blesses a weapon, a slop bucket or a carried body for 2 shillings, until dawn. Holy damage is half as much again and stops skeletons reassembling. Two classes of holy studies (45 seconds each): after one you bless your own weapon and bucket free, anywhere; after two, bodies as well. A blessed body built into a wall, gate, barricade or body wall adds half its strength and burns whatever strikes it.
- **Posse.** Nerve (falls when friends die, the leader goes down or the Steward appears; at nothing the peasant runs to the keep until dawn). Orders with rank 3 of the leadership book: Q cycles follow, hold, charge. Emergency toilet break on T, once a minute: the dead near you run for 5 seconds.

### Changed after play (the designer's notes on Build 2)
- The dead rise anywhere along a graveyard 64 strides wide, and each keeps roughly to its own stretch of the north wall.
- Hordes: 28 for each player on night 1 (112 for four; Build 2 sent 74), and 24% bigger each night (407 for four on night 7; Build 2 sent 221). Three waves, four from night 3, five from night 6. They arrive closer together. Shamblers 46 health and 8 damage. The Steward 520 health. A few archers from night 4. At most 220 walk at once.
- The stone, the iron and the fishing each move between five places every dawn, and the dawn notice says where. The quarry is a rocky outcrop and the mine a small mound.
- Trees: a stump rots at the next dawn and a sapling comes up beside it; the sapling is a tree one or two dawns after that.
- Barricades: every dusk, a barricade that has already stood a night loses half its strength for good, and falls apart below 20. Iron braces stop it. So does rank 4 of Barricades for Beginners.
- The keep is two thirds the width. Everyone lines up outside their own door at dawn.
- The edge of the map: a thorn hedge west and east, a line of stakes north, the river south. Walking into one says why you cannot go on.
- Flags are half as tall again; name tags are small, and there is none over your own head.
- **No more waves.** The night's dead now rise one after another without a pause, slowly at first and a little over twice as fast by the end. They keep rising for 80 seconds on night 1 and 10 seconds longer each night after. The numbers are unchanged. The readout says how many are left and how many have still to rise. The Steward comes down once four in ten have risen.
- **A night with nobody left to fight is settled quickly.** If every player is dead or hiding, after 12 seconds the dead do six times the damage to defences and the keep, rising the longer it goes on. Before, one skeleton archer could spend a quarter of an hour on a stone-faced wall while everyone waited.
- **The handbook** (Esc, or the button top right, or on the home screen): a guide to the game, the controls, and options. Every key except Esc, the numbers and the mouse can be changed; prompts and readouts name whatever key is set. Options: sound volume, name tags, the see-through keep. Alone, the handbook pauses the game. It also has "Leave the village", which the game lacked.
- **The keep turns see-through** when the view is near it and an undead is at it, or a player, a body or a dropped thing is hidden behind it.
- **The pack is drawn as slots**: five for what is on you, six for spares. Click to use or put away, a small cross to drop, 1 to 6 to use, X to swap to the next weapon without opening it. A thing you cannot use yet says which book it needs.
- **Bows.** A bow needed rank 2 of the ranged book, and that book only ranks up by landing shots, so without a lucky sling from the ruins it could never be reached. Now the book itself lets you use a bow and comes with a sling; the crossbow needs rank 3. The book's later ranks moved down one, and rank 7 is new (ranged tricks ready in half the time).
- Notices are drawn as scrolls, after the designer's mock-up: rolled ends, a wax seal on each corner, knotwork corners, torn edges, stains. The frame is one SVG drawn by `tools/scroll.py` and used as a CSS border image, so it fits a notice of any size. Buttons, fields and the small readouts have the same thick brown outline.

### Decisions made while building, for the designer to confirm
- "The village as well" was read as the keep being too big, not the village. The village is the same size.
- Barricade rot starts on a barricade's second evening, so one built today is whole tonight.
- The inn's ale does not keep overnight (the design says "that day").
- A slop bucket is used up when thrown (the design says "lobbed once").
- Relic odds are low in week 1 on purpose: the design puts the first relics in week 2.
- Anyone can use a sling. The ranged book is needed for the bow (rank 2) and the crossbow (rank 4).
- Posse members still carry only a pitchfork or a spear.
- The books' ranks 4 to 7 are new and were invented here; the design only described three.
- Dutch courage is not cowardice, but the keep is undefended while you drink.

### Tested
- Automated: a Build 3 rules test (99 checks: every trick, the inn, the ruins, the priest, nerve, orders, rot, regrowth, sites, saving), the Build 2 week test ported, page tests for the new keys and notices, two tabs in co-op (pack, arms rack, tricks, bucket, moving sites, stumps, the inn), and a bot playing the week alone.
- The bot that keeps up (food, spear, armour, stone facing) still wins alone, in some runs losing its whole posse on night 7. The bot that only builds walls and never eats dies between night 2 and night 4. In Build 2 those were "nobody lost" and "lost on night 6".
- With 220 undead walking, one step of the rules takes 0.4 ms and the horde is 8 KB a send.
- **Not tested:** four or more real players (the co-op numbers are a calculation, not a play-test), co-op over the real internet from the test machine, frame rate on a real graphics card, the new sounds.

### The source, ready for GitHub
The whole project is laid out as a repository (`defend-the-village-repo.zip`): the source in `src/`, `build.js` to join it into the one HTML file, the tests, this log, and a workflow that builds the game and publishes it with GitHub Pages on every push. It has not been pushed anywhere yet: no GitHub account is connected to Claude, and the publishing workflow could not be run from the test machine.

### Next: Build 4, the month
Nights 8 to 30, weather, travelling merchants and their jobs, hired guards and mercenaries, contraptions, the other bosses and the headless rider.

## Build 2: the first week (7 Oct 2026)

**The game file:** `defend-the-village.html` in this project (it replaced Build 1). It is the whole game and its source.

### What is in
- Seven days and nights. The horde is 24 on night 1 (alone) and a fifth bigger each night; skeletons from night 2, skeleton archers from night 5, the Steward on night 7. Each extra player adds 70%.
- Materials: wood (forest), stone (quarry), iron (mine), food (farms, and fishing at the jetty with a bite-and-pull timing). Carry 20 of each. F eats 1 food for 20 health.
- Coins: 12 pence to the shilling, 20 shillings to the gold piece. The market pays 1d a piece and charges 2d. The storehouse is shared.
- Smithy: short sword, spear, mace, and (with rank 2 of Hammer and Tongs) billhook and warhammer. Iron cap, chain shirt, shield. Spears for the posse.
- Books (3 ranks, earned by doing): The Woodcutter's Almanac, Field Hook and Pot, Barricades for Beginners, Hammer and Tongs. Second book at rank 2 of the first, third when two are at rank 2.
- Defences: repair for wood; stone facing triples a wall, iron bands double the gate, iron braces double a barricade, iron tips double spike damage (needs smithing rank 2).
- A standing wall or gate stops blows both ways. Fight by going out through the gate.
- Peasants die for good. Bodies can be carried (3 at most) and built into a body wall (3) or a decoy (1), outside the village wall only.
- A player down for 15 seconds dies and returns at dawn as a relative: books and cottage kept, carried materials and gear lost. Each death is a more distant relative.
- Hiding in your own cottage at night: safe, but a coward until the next dusk (posse one smaller, slum recruits cost double, books at half speed, no share of the hat).
- The slum: a new peasant for 5 food, up to 6 living peasants per player.
- Dawn: everyone starts at their cottage, a notice lists the night's cost, the village passes the hat, and the host's browser saves. "Carry on" on the notice board and in the lobby; losing offers that morning again.
- The Steward: stands back on the road and raises the fallen until a player gets within a few strides.

### Decisions made while building, for the designer to confirm
- Anyone may forge basic arms; Hammer and Tongs makes forging a third cheaper at rank 1 (the design could be read as needing the book to forge at all).
- Horde growth is 20% a night in week 1, not 12%: at 12% a competent player was never in danger.
- Rank 3 of Barricades for Beginners does nothing yet (contraptions are Build 4).
- No strays outside the village yet, no hand-to-hand trading between players (the storehouse does that job), no price drop when the market is flooded, no exporting a save to a file.

### Tested
- Automated: a week-long rules test (every system above), real-page tests (place notices, number keys, dawn notice, carry on from a save, losing and retrying, the Steward), two-tab co-op (book, market, eating, forging, hiding, losing and retrying together), and a time-limited bot playing all seven nights.
- The bot that only built walls on day 1 and then did nothing held four nights, died on the fifth and lost the keep on the sixth. The bot that kept up (food, a spear, armour, stone facing) won with nobody lost.
- **Still not tested:** co-op over the real internet from the test machine, frame rate on a real graphics card, the sounds.

## Build 1: the first night (7 Oct 2026)

**The game file:** `defend-the-village.html` in this project. It is the whole game and also its source: readable, unminified JavaScript in one `<script>`, in sections (core, renderer, world, models, rules, co-op, drawing, screens).

### What is in
- The map of Thornhallow in 3D: keep, eight cottages, Robert Bailiff's house, the old ruins and chapel, the Thorny Rose, smithy, training yard, storehouse, slum, market, library, the village wall with west and east gateways, Hallowshire Forest, farms, quarry, mine, outer ruins, river, the graveyard and Ashhollow Castle. Only the forest, the north wall and the keep have a job yet; the rest is scenery.
- One day (up to 6 minutes, ends when everyone presses R), 20 seconds of dusk, one night, then a win or lose notice.
- Wood: hold E at a tree. A posse chops alongside its leader. Carry limit 20.
- North side: seven foundations (six palisade walls at 15 wood, one gate at 20). Barricades (5) and spike rows (8) anywhere.
- Posse: rally neighbours with E. Three each, five when playing alone.
- Undead: shamblers and skeletons in three waves from the graveyard. Skeletons reassemble once unless a player hits the pile.
- Co-op for up to 8 by five-letter village code. The host's browser runs the game.
- Extras not in the design: a minimap, simple generated sound effects, a glide up to the castle at dusk, and slow health recovery out of combat (a stand-in until food exists).

### Differences from the design, to settle later
- A fallen peasant is only down for the night. Permanent death and bodies as defences are Build 2.
- A downed player who is not revived in 15 seconds sits out the night. Relatives are Build 2.
- No saving, no late joining, keyboard and mouse only.

### Starting values
Player 100 health, 7 speed, pitchfork 12 damage every 0.42 s. Peasant 75 health, 6 damage. Keep 1000. Wall 260, gate 220, barricade 90, spike row 40 uses. Shambler 40 health, 7 damage. Skeleton 16 health, 4 damage. Waves alone: 8, then 9 + 4 skeletons, then 11 + 7. Each extra player adds 70%.

A test bot gathering flat out collected 120 to 140 wood in a day, which is in line with the design's rough figure of 100.

### How it was made
- No game library. The file has its own small WebGL 2 renderer: flat-shaded coloured shapes, instancing, one shadow map, dark outlines, day and night lighting.
- Co-op uses the PeerJS library (version 1.5.4), loaded from a public CDN only when someone hosts or joins. Playing alone needs no internet.
- Adding `#local` to the file's address swaps the internet connection for a same-computer one between browser tabs. This is for testing.
- `window.__dtv` in the browser console exposes the game state and a fast-forward, also for testing.

### Tested
- Automated, in a headless browser: a bot playing whole solo days and nights (several play styles); real keyboard and mouse input; two tabs playing co-op through lobby, day, night, restart, a late joiner being refused and the host leaving.
- **Not tested:** co-op over the real internet (the test machine could not reach the connection service), frame rate on a real graphics card, and how the sound effects actually sound.

