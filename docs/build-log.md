# Defend the Village! build log

The design lives in the doc "Defend the Village! — Game Design". This log records what each build actually contains and how it was made, so the next build can start from it.

## Moving to Godot, stage 3: the menus (8 Oct 2026)

Matt's note: the menus should be more intuitive and not overlap.

### What changed
- **One window.** Every notice (a place, your pack, the dawn, the handbook, the home screen, the end of the week) opens in one window in the middle of the screen, framed by the web version's scroll (rolled ends, wax seals, knots, torn edge). Only one is ever open. Esc or the cross closes it; walking away closes a place's notice; inside the Thorny Rose it stays until you go out.
- **Fixed places for the readouts:** the day, time and "ready" line top left; the keep (and the Steward) top middle; the map and a Handbook button top right; what you carry and your books on the left; your health bottom left with the news above it; a bar along the bottom with your weapon's trick, your bucket, your posse, your pack and the toilet break, each with its key; the four things you can place bottom right with their costs (click one, or press 1 to 4). What holding E would do shows just above the bottom bar.
- **Nothing on top of anything:** a place's notice and the pack sit between the top readouts and the bottom bar. The handbook, the dawn and the end take the whole screen and the readouts step aside. Big announcements wait while one of those is open. Signs and names over the world hide rather than sit on a readout, the window or the prompt.
- **The pack as slots with pictures** (the web version's drawings): click a thing to use it or put it away, the cross drops it, pointing at one says what it is.
- **The handbook on Esc:** the guide (with a new section, "Reading the screen"), the controls (change any key; a key does one thing) and options (names over players, the see-through keep, sound for later). The game waits while it is open, playing alone.
- **A home screen:** name and colour, Carry on from the saved day, New village, and the change log.
- **The end of the week:** as in the web version; losing keeps that morning's save, so you can try the day again.
- Typefaces: the web version's (Pirata One and Alegreya) could not be fetched here, so the game asks Windows for Palatino Linotype (or Book Antiqua, or Georgia).

### Tested
- `godot/tests/ui_test.gd`: 26 checks, driving the menus with key presses (home, handbook from home and back, New village, dawn, Esc, the pack and 1 to 6, the handbook pausing the game, changing keys and a key moving between actions, a place's notice opening by holding E, choosing by number, closing by walking away, the end of the week), and that the notice and the pack do not cover the bottom bar. Rule checks 107 of 107. Screenshots of each window.

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


## Godot stage 3 patch: the click crash

- Clicking in the game crashed it: `main.gd` still asked the HUD `notice_open()`, which went when the menus were rewritten. It now asks whether the window is open. Found from the log Godot keeps in `%APPDATA%\Godot\app_userdata\Peasant Defence\logs`.
- New `godot/tests/click_test.gd` clicks the home screen and the game with real mouse presses (holding the button down as the game starts), which is how this got past `ui_test.gd`.

## Godot: the look of the place

The web version is no longer updated; from here on, changes are made in Godot only.

- Fonts: Pirata One (titles, numbers) and IM Fell English (text), from Google's open-licence font collection, in `godot/fonts/` with their licences. Loaded through Godot's importer so they go with an exported game.
- Look: `Look.card()` and buttons are now drawn parchment (torn, burnt edges, made with noise when the game starts) instead of flat boxes; the wax-red button for the main choice. Resource pictures are full colour (logs, stones, an ingot, a loaf and a fish, a coin, a backpack, a book).
- Readouts: "What you carry" lists Wood, Stone, Iron, Food and Coin by name with the carry limit. The books card is gone; a Skills chip (K) opens a covering Skills window: the ten books on the left, the chosen one as a ladder of seven ranks with what each does and the progress to the next.
- Rules: past rank VII, learning becomes `spare` points (one per first step's worth of the book), saved, and sold for `D.SPARE_PAY` = 12d each from the Skills window. Starting value to tune.
- "Pack" is "Backpack" in everything the player reads (the key action is still called `pack` inside).
- Window: 1600 by 900 to start (the UI is laid out at 1280 by 720 and scaled). Home screen 800 by 510.
- Fixed: a window opened after a bigger one kept the bigger one's size and sat off to the right and down (the frame's smallest size has to be set before its size); the frame now recentres whenever its size changes. Fixed: scenery trees beyond the hedge and the stakes were drawn on the map.
- Names: Bailiff's House; the Thorny Rose Inn.
- Models: a new chapel (nave, buttresses, coloured lancet windows, round window, rounded north end, bell tower with spire and gilded cross, churchyard, lantern); a new priest (white alb, gold-trimmed vestment with a cross, purple stole, processional cross, book, faint halo and glow); round haybales lying on their sides and a stack of square ones.
- Ruins: `D.RUIN_SITES` has eight clearings (no trees grow in them); each night the two outer ruins move to two of them, chosen from the game's seed and the day. `R.ruins_seen` hides them from the map and signs until a player comes within 18 of one, which tells everyone.
- Atmosphere (`scripts/view/atmos.gd`, only for looking at): two sheets of drifting mist (a shader on large planes), light by day, thicker at night, always lingering at the castle; weather per day from the seed (clear, overcast, rain, mist) with a line in the dawn notice; rain; chimney smoke; will-o'-wisps over the graveyard and the castle at night; crows round the towers; lightning at night. Night is darker and colder. Around the castle: dead trees, a gibbet, broken railings, green braziers at the gate, purple-glowing windows.
- Anti-aliasing: MSAA 4x, with debanding.
- Tests: rules 115 (spare learning, wandering ruins), UI 26, clicks 14 (new: the dawn after the home screen is centred). The careful bot still holds all seven nights.

## Godot stage 4: sound

- `tools/make_sounds.py` (numpy and scipy) makes every sound as a WAV in `godot/sounds/`: 46 effects (the web version's 29 recipes, one for one: same tones, slides, noise bursts and timings; plus won, page, knock, door, jeer, stone, iron, eat, rally, the Steward, three groans, a rattle, two thunders, two crows, an owl), four ambient loops (day, night, rain, castle) and two tunes (day: a Karplus-Strong lute in D Dorian at 96 bpm over a drone and a frame drum, 40 seconds; night: a harp in D minor at 62 bpm with a heartbeat, a drone and a whistle, 62 seconds). Nothing is downloaded. About 10 MB.
- `scripts/audio/sound.gd`: three buses under Master (Effects, Ambience, Music), a pool of 20 players for effects, the six loops always playing and faded by the time of day, the weather and how near the camera is to the castle. An effect with a place is quieter with distance and not heard beyond 34. The same effect is not started twice within 55 ms (as in the web version). Owls, crows and the groans of nearby dead come by themselves; thunder follows atmos.gd's lightning.
- Hooked to: every event from the rules (arrows, shots, raising, coins, forging, building, eating, fishing, the weapons' tricks, parries, slop, rings, holy, the inn, finds, the dead put down, the Steward), the figures (swings, blows, working each kind of material, drinking, rallying), the defences (built, struck, knocked down), the keep being hit, dusk, dawn, the end, windows opening, and every refusal.
- Settings: `vol`, `fx_vol`, `amb_vol`, `music_vol`, `muted`. The options have four sliders and a mute box; M mutes anywhere.
- Checked by recording a run with Godot's movie writer and measuring the audio: sound throughout, no clipping. UI tests 31 (channels, M, sliders, loops), rules 115, clicks 14; the bot still holds the week.

## Godot stage 5: playing together (the move is finished)

- `scripts/net/net.gd` (class `Net`, one node under the scene tree's root so it survives the game scene starting again). ENet over UDP port 24565, range-coder compression. Hosting starts a server and, in a thread, asks the router to open the port (UPnP) and for the internet address. The village code is the IPv4 address as 7 letters from a 32-letter alphabet without I, O, 0 or 1 (`ABCD-EFG`); Join also takes a plain address. If UPnP fails, the lobby says so and shows the code for the home network.
- Lobby: the host's list of players (name, colour; colours kept apart), "Start a new week", "Carry on from day N", "Close the village". Joining after the week has begun, or past eight, is refused with a reason. The host's game keeps the save.
- In play, as in the web version: the joined game sends its player's position (15 times a second, with the rules' teleport counter so a move by the rules wins), each swing, trick, use, toilet break, order, placement, ready, notice choice, eating, fishing and selling spare learning (`Net.apply()` does these to the rules, the same path the host uses for its own player through `main.cmd()`). The host sends, 12 times a second: the phase, clocks, keep, stores, sites, ruins, drops, every player, peasants and the dead (packed floats; a horde over 120 goes every other time), and what happened (events, for sounds and effects); the defences and the trees when they change; the dawn notice. The joined game eases everything toward it.
- Leaving: a player who goes (or is silent for 12 seconds) is taken out of the rules (`Rules.remove_player`): relics dropped where they stood, the posse sent home. The host leaving sends everyone home with a message. A new week or a retried day restarts the scene on every computer, and the joined games wait for the host.
- Also fixed on the way: a window could stay wider than asked (old buttons were only queued for freeing when it refilled, so for a moment there were two sets); windows now drop them at once and settle to their proper size every frame.
- Tests: `tests/net_test.sh` runs `net_host.gd` and `net_client.gd` together: 23 checks (hosting, the code, joining with name and colour, starting, the defences and peasants arriving, walking, swinging, ready, night and the dead arriving, the host closing the village). Rules 115, UI 31, clicks 14; the bot holds the week.

## The village server (relay)

- `relay/`: a separate tiny Godot project, `relay.gd` (a SceneTree script): an ENet server on UDP 24566 (3 channels, range-coder compression, up to 400 connections, 200 villages, 8 to a village, messages over 256 KB dropped). `host` gives a five-letter code (no I or O); `join` puts a player in that village and tells its host; `to` passes a message on, host to everyone or one, anyone else to the host, reliable or not as sent; `kick` for the host; a host leaving closes the village and tells everyone. Logs each village opening, joining, leaving and closing.
- `relay/setup.sh` for a fresh Ubuntu machine (x86_64 or arm64): fetches Godot 4.7.2 from its GitHub release, the relay from this repository, makes a systemd service that restarts itself, and opens UDP 24566 in iptables (Oracle's Ubuntu blocks everything but SSH). `relay/README.md` walks through Oracle Cloud's free tier, step by step.
- The game (`net.gd`): with a village server address (Settings `relay`, or `Net.DEFAULT_RELAY`), hosting and joining go through it: the same game messages, wrapped (`{r: "to", to, u, d}`) and unwrapped (`{r: "from", from, d}`); the host's player numbers are the server's numbers for the joiners. Five-letter codes go to the server, dashed codes straight to a host as before. If the server gives no code within 8 seconds, hosting falls back to direct, and says so.
- Tests: `tests/net_test.sh godot relay` runs the relay, a host and a friend together: 23 checks pass through it, as directly.

## Build 4, stage 1: the month

- **Thirty nights.** `Rules.last_day` (30, or 7 for the short game; saved as `last`, old saves carry on into the month). The short game maps its seven nights onto nights 1, 4, 8, 12, 18, 20 and 30 of the month (`D.SHORT_NIGHTS`) for which dead come down, keeps the first week's growth for the horde's size, and ends with the Lord. The home screen and the lobby offer both.
- **The horde** is a budget in shamblers' worth (`D.UN[k].cost`): 24% more a night in week 1, then ×0.88 at the start of each week and +7%, +5%, +4% a night in weeks 2, 3 and 4 (`Rules.growth`). It is shared between the kinds by `Rules.mix` (a kind's first night has half as many again). Rising lasts 80 s plus 10 a night to night 7, then 4 more a night (232 s on night 30). A night-30 horde for four players is worth about 740 shamblers (night 7: 407); at most 220 walk at once, as before.
- **Tougher dead:** shamblers 50 health and 9 damage (were 46 and 8), skeletons 6 damage (5). Each week after the first, everything has a tenth more health and does a tenth more damage (`Rules.tough`).
- **New kinds** (`D.UN`, with flags): ghoul (night 8; fast, climbs over barricades, body walls and decoys, not walls), gravedigger (10; stops at the north wall, digs for 5 s and comes up 4 to 13 strides inside), bat swarm (12; flies over everything for the keep, ignores people; a third damage from anything swung, full from shots, and the handbell knocks them out of the air), the Lord's guard (15; 130 health, armour: farm tools and peasants do 35%, forged blades 75%, blunt 130%, holy 100%; 24 damage to defences), wraith (18; through walls and buildings, only holy damage counts), coffin ram (20; 320 health, at most 1 + players/3 a night, goes straight for the north gate, 70 damage a blow; a heavy weapon does double; breaks into four skeletons).
- **Bosses** (`D.BOSS_NIGHTS`; health ×1.5 per extra player): the Coachman (14; the hearse drives at the keep, turns, goes back up the road and comes again; anything wooden in the way is smashed, stone-faced or iron-banded things stop him and he batters them; runs people over), the Captain of the Guard (21; armoured, brings 5 + players guards, all making for one gate, the west gateway, the north gate or the east gateway; guards near him hit 30% harder), the Lord (30; three stages by health: at first he stands on the road raising the fallen and calling down bats; below two thirds he walks through walls for the keep, turning to mist and jumping forward now and then; below a third he goes for the keep door, faster, ignoring anyone not in his way. Non-holy blows do 60%. Alone in the field, he comes down a minute after the last of the horde has risen).
- **Weather is the rules'** (`Rules.weather_of`, from the seed; `R.weather`, sent to joined games): clear, overcast, rain (the dead at 85% pace), fog (archers see a third as far; at night the fog closes in on the screen), snow (from week 2; everyone at 85%), and the full moon on night 15 (the dead at 115%, relics twice as likely). The view draws snow and the moon.
- **The dawn notice** says which new kinds come tonight and whether a boss does. The dusk bell has a line for each boss and the full moon. The readout names whichever boss is out.
- **Models** for all nine. Wraiths are see-through. The bats flutter at head height.
- Options: typing `none` as the village server hosts straight from your own computer.
- Tests: new `tests/month_test.gd` (41 checks: arrivals, bosses, growth, toughness, every kind's behaviour, weather, the whole month and the short game). Rules 115, UI 31, clicks 14, co-op 23 directly and through a local village server. The careful bot still holds the first week with nobody lost.

## Build 4, stage 2: the Holy Book

- **The Holy Book (Abridged)**, book 10 (`D.B_HOLY`; base 30, learned by smiting and praying), the first of `D.CLASSES` ("callings": a book with two powers on keys of their own, `power1` Z and `power2` C; one calling at a time; `Rules.class_of`). The apprentice priest: Smite (rank 1; 5 s wait, a third less from rank 5; 16 + 4 × rank holy damage on the nearest of the dead ahead within 14, or any within 10; rank 4 bursts for half over 2.6 strides; rank 7 strikes three and does double to wraiths and bosses) and Pray (rank 2; 30 s, a third less from rank 5; everyone within 7, players and posse: a third less harm for 10 s; rank 3 also makes their weapons holy for 10 s (`hb`); rank 6 also mends 25 and steadies nerve). The rank lines are in the book; the comic names are its own: Minor Smiting, A Word of Protection, The Blessing of Mild Improvement, Smiting With Feeling, Hallowed Ground (Mostly), Divine Intervention, Probably.
- **Titles** (`Rules.title_of`): "the" + the adjective of the second-best book + the noun of the best (a calling is always the noun), "Master" at rank VII. Said in the news when it changes; shown top left and in the skills window.
- **A fourth book**: An Index of Further Reading, in the ruins (0.6% a search by day, 1.2% at night, once each); `p.xslot`, saved.
- **Relics and books** (`D.RELIC_LORE`, `Rules.lore`): the Slightly Blessed Spade with Field, Hook and Pot (each Bury mends 10), Saint Wilbur's Pitchfork with How to Win Peasants (the posse's blows are holy), the Silvered Sword with The Art of Hitting Things (a quarter harder), the Helm of the Unbothered with the Landlord's Ledger (charges half as long again), the Vicar's Breastplate with Granny's Remedies (each burn mends 2), the Chapel Handbell with the Holy Book (its ring smites 15 holy), the Smoking Censer with Relics and Where They Were Left (the dead it slows smoulder). Shown in item descriptions.
- View: a column of gold light and a glow on the ground for a smite, a ring for a prayer, a shimmer on anyone prayed over, a faint glow over apprentice priests. The two powers have their own small bar above your health.
- Saves from before the Holy Book get the eleventh book on loading.
- Tests: new `tests/holy_test.gd` (32 checks). Rules 115, month 41, UI 31, clicks 14, co-op 23.

## Build 4, stage 3: merchants and hired help

- **Merchants** (`D.MERCHANTS`, `Rules.merchant_on`): one in each of six stretches of the month (days 2–5, 6–9, 11–13, 16–19, 22–24, 26–28; days 2, 4 and 6 in the short game), all five at least once, from the seed. The cart stands at `D.station("cart")` (east of the market) from dawn to dusk; its station only works on a merchant's day. Goods (`Rules.make_wares`, in pence, stock shared by the village): the tinker (5 iron 9d, spade, rake, scythe, boxes of cogs 2s for contraptions, `p.cogs`, saved), the armourer (short sword, spear, mace, iron cap, chain shirt, shield; warhammer and crossbow from week 3), the brewer (5 food 8d; 5 tankards straight into the inn 10d), the relic pedlar (three "relics" at 3s, one real if any are left; rank 2 of relic lore says which), the bookseller (a loose page of any of your books, a quarter rank, 1s 6d; An Index of Further Reading 6s).
- **Jobs**: take it at the cart (`p.job`), then stay near where it is done (the outcrop, the cart, the chapel, the library): 240 s of work (`D.JOB_WORK`), shared by everyone on it. A player who has worked on a job learns nothing from books for the rest of that day, and cannot gather while on it. The one who did most is paid: cogs and iron; a warhammer (and a chain shirt from week 3); the Brewer's Reserve (tonight every tankard counts double, and 10 more ale) and food; the real relic (or 5s); An Index of Further Reading, or a whole rank of your least-read book. Helpers get a shilling.
- **Village guards** (`D.station("bailiff")`, the back door north of Bailiff's House): 8s each, six a night, two to each of the north gate and the west and east gateways (`D.POSTS`). Peasants of `kind` 1: 200 health, take 60% of blows, 16 damage, no nerve to lose; they fight within 8 of their post and walk back to it. Gone at dawn.
- **Mercenaries** (the Thorny Rose): 8s, one a day each, `kind` 2 in your posse: 160 health, take 70%, 20 damage. At dawn each goes; one in seven first demands 2s more, and a player who cannot pay loses a random thing they carry.
- Guards wear Robert Bailiff's green with a cap, mail and a spear; mercenaries mail, a shield and a mace. A fallen guard or mercenary leaves a body like anyone else (its kind is saved).
- Tests: new `tests/merchant_test.gd` (38 checks). Rules 115, month 41, Holy Book 32, UI 31, clicks 14, co-op 23.

## Build 4, stage 4: contraptions (Build 4 finished)

- Six contraptions (`D.CONTRAPTIONS`, `D.CONTR`), placed like barricades. Learned from Barricades for Beginners (the ranks say which: chicken decoy 1, pitfall 3, tar pit 4, holy water trough 5, log roller 6, Thresher 7, replacing rank VII's "contraptions in a later build"), or built with a box of cogs (`p.cogs`, used up when the rank is missing). The trough also needs a class of holy studies or the Holy Book. Costs (before the book's discount): chicken 3 wood 2 food, pitfall 6 wood 4 stone, tar 6 wood 3 stone, trough 8 wood 2 iron, log roller 25 wood 4 iron, Thresher 15 wood 6 iron.
- `Rules.contraptions_step`: the chicken decoy (40 health, `D.BLOCKERS`) draws every ordinary dead thing within 10 (not bosses, bats, wraiths or rams), which then attack it. The pitfall kills the first four to walk or fight on it (not bosses, bats, wraiths or rams; no reassembling), then it is full and gone. Tar slows the dead wading through (not bats or wraiths) and is trodden flat after 400 wading-seconds. The trough burns 8 holy every half second to whatever is in it (wraiths included), 60 burns. The log roller, only north of the wall (`valid_place`), is stacked at dusk and, at night, rolls once when 5 of the dead or a coffin ram are in its lane (2.2 either side, 24 south): 120 heavy, blunt damage each and a stun. The Thresher hits everything within 2.6 for 7 every 0.4 s while a player or posse member stands within 3.
- Only walls, gates, barricades, body walls, decoys and the chicken stop the dead now (`D.BLOCKERS`); the rest are walked over. The hearse still smashes anything wooden.
- View: a model for each (the Thresher's arm spins while it works), effects for the pitfall and the logs. One build card for all contraptions, key 5, stepping through the ones you can build; the build cards are narrower and the bottom bar sits a little left of centre to make room.
- Tests: new `tests/contr_test.gd` (21 checks). Rules 115, month 41, Holy Book 32, merchants 38, UI 31, clicks 14, co-op 23.

### Build 4, for the designer to confirm
- The month's numbers (horde growth, toughness, boss health, prices, the job's length, guard and mercenary strength) are starting values from the design, not yet play-tested. The careful bot still holds week 1 with nobody lost; nothing has played weeks 2 to 4 yet.
- Contraptions were spread over Barricades for Beginners' ranks; the design only said they come from that book.
- The bookseller's job pays An Index of Further Reading, or a rank of your least-read book; the brewer's pays the Brewer's Reserve. Not in the design.
- Mercenaries take one of your posse places.

## Build 5, stage 1: the village

- **Robert Bailiff at his window** (`D.station("window")`, his front door): talk (`D.BAILIFF_TALK`, a set of lines for each week), knock (`D.BAILIFF_KNOCK`, with a knock), jeer (`D.BAILIFF_JEER`, with a jeer). What he says shows in a bubble over his window and in the notice (`R.bail_line`, `R.bail_t`). Each jeer that day makes his guards a shilling dearer (`R.bail_mood`, `Rules.guard_fee()`); he forgets by morning. He pops up at the window when someone stands at his door by day, or when he has something to say.
- **The village bell** (in the square): hold E to ring it. It swings, rings for everyone, and sometimes the news has a line about it. Nothing else happens. 2.5 s between rings.
- **Training dummies**: a melee swing that hits none of the dead but a dummy in reach, or a shot with nothing to shoot at but a dummy ahead, is practice: one step of The Art of Hitting Things (or the ranged book) per hit, up to `D.DRILL_MAX` (30) a day (`p.drill`). The dummies wobble.
- **Peasants talk** (`D.BARK_*`, event `bark`, a bubble over their heads): when rallied, at dusk (one of each posse), when they lose their nerve, at dawn.
- Clearer wording in many skill-tree ranks.
- Tests: new `tests/village_test.gd` (11). All earlier tests pass.

## Build 5, stage 2: the smithy

- **Three grades** (`D._grades()`, ids from 29 so saves keep working): crude versions of the short sword, spear, mace, billhook and warhammer (`D.crude_of`): 80% damage, half the iron, anyone can forge them (heavy ones too). A crude weapon in hand on a night its owner fought (`p.fought`, set by any attack at night) becomes chipped at dawn (68% damage), and a chipped one falls apart at the next such dawn (back to the pitchfork). Refined (the old forged list) weapons now need rank 1 of Hammer and Tongs; armour can still be forged by anyone. Steel (`D.steel_of`) weapons (135% damage) and armour (cap, chain shirt and shield, a little more protection) need rank 4 and steel (three quarters of the iron as steel). `Rules.can_forge` and `forge_why` decide; heavy arms still need rank 2 unless crude. Hammer and Tongs ranks 1 and 4 say so.
- **Steel**: a fifth material (`D.RES`), mined at the old steel mine (`D.STEEL_MINE`, -82, -44, at the top of the forest; it does not move; 3.2 s a piece; the gathering book). The market pays 3d a piece and sells none. Shown in what you carry when you have some; saved; in the storehouse.
- The careful bot now reads Hammer and Tongs second (and Barricades for Beginners third) and holds the week, one peasant lost. Without it (crude spears only) it fell on night 5.
- Tests: new `tests/smithy_test.gd` (18). Rules 117 (forging checks updated).

## Build 5, stage 3: a bigger map

- **Wider**: the playable land runs x -124 to 124 (was ±92; `D.X0`, `D.X1`). North (the stakes) and south (the river) are unchanged, so the castle, the graveyard and where the dead rise are the same. The hedge, the stakes, the tree scatter (`Map.trees`, now -165..165 with more tries, the forest out to -118), and `tree_ok` follow the new edge.
- **New places** in the new land: stone (far west, -110 16; the eastern downs, 106 -10), iron (under the downs, 112 8; deep west, -112 -16), fish (-112 and 110 on the river), and two more clearings for the outer ruins (-104 36, 100 -34). Appended to `D.SITES` and `D.RUIN_SITES`, so saves keep their indices.
- **The old steel mine** moved to -108, -44 (still the top of the forest). **The old mill** (`D.MILL`, 104 30) on the eastern downs: a collider and a sign, sails that turn, a sheepfold with seven sheep, a worn track from the east gate. Scenery only.
- **The river**: a shader that runs west (deeper in the middle, streaks of foam, a lighter edge), a ragged sandy bank, reeds in clumps on both banks, lily pads, stones, and bushes on the far side.
- **The village green** north of the keep (x -9..8, z -21..-10): a maypole with ribbons (turns slowly), the well, a duck pond with two ducks, the stocks and a bench by Robert Bailiff's. The well, maypole and stocks are colliders (`Map.colliders`).
- **Half-timbering**: houses with walls 1.9 or taller get a middle rail and braces. Cottages have cabbage patches and a wattle fence between the two rows.
- The minimap is wider than tall now (x ±130, 227 by 174 pixels) and the top-right corner grew to fit.
- Tests: rules 117 (the hedge check uses `D.X1`), month 41, Holy Book 32, merchants 38, contraptions 21, village 11, smithy 18, UI 31, clicks, co-op 23. The bot holds week 1 with nobody lost.

## Build 5, stage 4: letters, notices, and one to eight players (Build 5 finished)

- **The Lord's letters** (`D.LETTERS`, 28 of them; `Rules.next_letter`, `R.letters`, `R.letter_new`, `R.seen`). He writes on the second morning, then every other morning (every morning in the short game), the morning after the Steward, the Coachman or the Captain is beaten, and on the last morning: 16 in a month. He complains first of whatever the village has newly done (`Rules.note`: a tar pit, a chicken decoy, the Thresher, a pitfall, the log roller, a body wall, smiting, jeering at the Bailiff, hiring guards or a mercenary, ringing the bell, searching the ruins, fishing, 60 kills), and otherwise of something else (the chopping, the smithy's smoke, the maypole, the ducks, the sheep). Event `rider`: a headless rider (in `world.gd`) gallops down the castle road to the gate and back, with hooves and hammering (two new sounds, `hooves` and `nail`; `tools/make_sounds.py hooves nail` makes just those). The letter is nailed to a gatepost inside the north gate (station `letter`, a sign while it is unread); reading it clears the sign for everyone (`lread`). Saved, and sent to joined games.
- **The notice board** in the square (station `board`): the weather, what is expected tonight (`tonight_lines`), the next boss night, three of the village's own notices (`D.NOTICES`, 24, picked by the day), and every letter so far. Notices can now carry plain text between the choices (`{"text": ...}`).
- **One to eight players.** A measuring tool, `tests/balance.gd`: the same night fought by 1, 2, 4 and 8 test players with the same kit and a full posse each, nobody repairing. What it showed, and what changed:
  - A night's horde is capped at `D.NIGHT_HEADS` (420). Past that fewer rise, each `crowd` times as hard to put down and hitting `1 + 0.6 (crowd - 1)` times as hard (`Rules.night_plan` returns `crowd`). Eight players on night 30 would have been 1,375 of the dead; now 420, each 3.3 times as tough. This is the design's "past that, undead get tougher instead of more numerous".
  - The rules were slow with many players: every villager checked every tree (the bigger map has many more) and every building three times a moment. Now trees and buildings are looked up by 8-unit square (`near_trees`, `near_colliders`). Eight players, 24 followers and 200 of the dead: about 60 ms a moment before, 17 ms after, on the slow test machine.
  - Two players start with four followers each (`D.POSSE_PAIR`), not three. A pair had 8 bodies for two hordes where a lone player has 6 for one; the test pair lost night 7 outright while the lone player held without a scratch. With four each they hold.
  - Shared defences are stouter with company (`Rules.stout()`, the square root of the number of players): a blow from the dead does that much less to a wall, gate, barricade or the keep. Seven foundations and one keep were taking eight hordes' worth of blows.
  - The Steward has 800 health (was 520): a lone player's posse was putting him down in about five seconds.
  - Gravediggers come up on the green (they could surface wedged between Robert Bailiff's and the inn, and the night never ended), and any of the dead that walks for three seconds without getting anywhere shuffles sideways.
- Not changed: each extra player still adds a whole solo horde, and three or more players still start with three followers each. The test players hold night 7 as one or two and lose it as four or eight; but test players do not repair, build or work together, and four real players found the first week too gentle at the old growth. To make big games gentler, lower `D.NIGHT_PER_PLAYER` (0.8 would be the next thing to try) or raise `D.POSSE_MAX`.
- **The Captain of the Guard was not getting in.** Two nights in three he picks a side gateway, and his party then dithered outside it for ever (the rule that sends them round the corner kept pulling them back from the gateway itself). Fixed in `Rules.undead_goal`; `month_test` now marches him in by both gateways.
- The bot can play the month (`bot_week.gd -- month`): after the first week it also mends the keep, bands the gate, sits holy studies and forges steel. Three runs alone: it holds the first week with nobody lost, loses followers and walls through the second (ghouls, gravediggers, bats), and falls on night 13 or 14, twice to the Coachman. It uses no contraptions, guards, mercenaries or barricades, so a person should do better; but weeks 3 and 4 have still not been played by anything.
- The measuring tool's last run (held or lost; nobody repairs, so later nights are harsh on everyone):

  | Night | 1 player | 2 | 4 | 8 |
  |---|---|---|---|---|
  | 1 | held | held | held | held |
  | 4 | held | held | held | held |
  | 7 (the Steward) | held | held | lost | lost |
  | 14 (the Coachman) | held | lost | lost | lost |
  | 21 (the Captain; steel and blessed weapons) | held | held | held | held |
- Tests: new `tests/letters_test.gd` (22). Month 50 (nine new, for the cap, the pair's posse, stout walls, the Steward and the Captain's march). Rules 117, Holy Book 32, merchants 38, contraptions 21, village 11, smithy 18, UI 31, clicks 14, co-op 23.

## After Build 5: a camera you can turn

- The view orbits the player. `,` and `.` turn it, holding `V` (or the middle mouse button) and moving the mouse looks round, the wheel zooms, `N` puts it back (`cam_left`, `cam_right`, `look`, `cam_reset` in `ui/keys.gd`). State in `main.gd`: `_cam_yaw`, `_cam_pitch`, `_cam_zoom` with goal values they ease towards.
- Movement is relative to the view: `mx = ix*cos(yaw) + iz*sin(yaw)`, `mz = iz*cos(yaw) - ix*sin(yaw)`. The key labels say "Move up the screen" and so on. The minimap shows a fan for which way the view faces (`minimap.view`).

## A new name: Thornhallow, Thirty Nights

- The name is one constant, `D.GAME`. The designer's message said "Thornvale 30 Nights" and the three pictures he sent all say "Thornhallow, Thirty Nights"; he has since settled it: **Thornhallow Thirty Nights**.
- The title screen is his key art (`art/title.jpg`) on its own canvas layer under the HUD, with a small scroll pinned on the left under the title (`window.pin`): name and colour, Thirty nights, Seven nights, Host and Join, What is new, Handbook.
- The Lord is remodelled after the lore sheet: white, beaked, a tall hat with a gold band, a chain and a goblet.
- Place-name signs no longer overlap each other, and fade to about half when the player is near, so what is under them can be seen.

## Tidying up

- Steel is listed under Iron in what you carry.
- Things dropped on the ground go after two days (`D.DROP_DAYS`; a drop is stamped with its day). A backpack slot has a flame: press it twice to destroy what is in it (action `destroy`).
- **The posse**: followers find their way round walls and through gateways (`Rules.way_to`, `seg_hits`), hop a fence they are wedged against (event `hop`), and when their leader is cutting wood they work within 7 of the leader and share trees rather than wandering off.

## The castle

- As night falls the view lifts to the castle and comes back (`_pan_t` in `main._camera`: 2.6 s up, 3.4 s held, 2.2 s down; Space or Esc skips it; `Settings.castle_pan` turns it off). Thunder as it comes into view.
- The castle grows more evil through the month (`world.set_evil(level)`): green fires and banners in week 2, thorns in week 3, a spire, red windows and a turning storm in week 4.

## Days with something in them

- **The Previous Tenant** (`D.U_TENANT`, kind 13): searching one of the outer ruins by day, from day 2, has a 5% chance a search (`D.TENANT_CHANCE`, once a day) of bringing him up out of the rubble. 260 health, hits for 16, does not follow far. Beating him pays his back rent.
- **The chest that never arrived** (`R.chest`, `Rules.chest_day`, `new_chest`, `open_chest`): once a week a chest sent to the village by a neighbouring mayor or noble lies beside a dead messenger somewhere outside the walls. It holds a good sum of money, and sometimes a relic or a library card. It goes to whoever opens it, who can drop it for a friend.
- **The library card** (item 47, `D.I_CARD`): hand it in at the library to give up one of your three books and choose another, which starts one rank behind the old one (`p.card_rank`).

## Fire, and what is under the mine

- **The burning torch** (item 48, `D.I_TORCH`): three wood at the smithy, anyone can make one. 8 damage, but what it hits burns for `D.BURN_TIME` (4 s) at `D.BURN_DMG` (3) every half second (`Rules.ignite`, the burn tick in `undead_step`). Its trick, Flare, lights everything round you. Rain halves the burning; wraiths do not burn. It is a light at night (an `OmniLight3D` on the figure).
- **Rooms** (`D.ROOMS`, `p.room`, `enter_room`, `leave_room`, `room_interact`): interiors are built far to the south (z about 240) and the player is moved there through a door. `collide_friend` keeps them inside the room's box and off its furniture. Stations with a `room` are only offered indoors.
- **The old workings**: the mine is a room. It is dark without a torch. Three rune veins (`D.RUNE_VEINS`, two runes each, `R.rune_left`) can be worked only with a torch in hand.
- **Runes** are a new thing to carry. (At first three could be cut into any weapon for 20% more damage. That was a stopgap and is gone: see Rune weapons, below.)

## Inside the Thorny Rose

- The inn is a room. The innkeeper keeps his old trade at the bar (food for ale, a mercenary, a seat after dark).
- **Three locals** (`D.LOCALS`: Old Marge, Tam the Carter, the stranger): each can be asked three things, and stood a drink once a day (`D.TREAT`, 6d; action `treat`) for a good turn: a pie, word of where the chest or the ruins are, or how to deal with the next boss (`D.BOSS_HINT`).
- **The gambler** (`Rules.gamble`, stakes `D.BETS`): twenty-one (`total21`), higher or lower (`hl_pays`: the bolder the guess the more it pays, 8% to the house), and the pea under the cups (`cups_end`; `ui/cups.gd` draws and shuffles them). The cups are skill, not luck, and he gets quicker each time you win. He packs up when he has lost ten shillings to a player in a day (`D.GAMBLE_DAY`). Walking away forfeits a game in progress.
- The bookshelf has one book on it, for the Jester, in the next big update.
- Tests: new `tests/inn_test.gd` (30).

## One file, and updates from GitHub

- The game exports to a single Windows file, `Thornhallow.exe` (about 113 MB; `export_presets.cfg`, the pack embedded, the icon from the logo).
- **A release is made by putting `godot/version.json` up by one and pushing.** `.github/workflows/release.yml` then runs two tests, exports the file and a pack of the same build, and publishes a GitHub release `build-N` with `Thornhallow.exe`, `thornhallow.pck` (about 4 MB) and `version.json` (build, a line saying what is in it, the engine, the pack's size and SHA-256; written by `tools/release_info.py`).
- **The game updates itself** (`scripts/update.gd`). Only the exported game does this. At the title screen it reads `releases/latest/download/version.json`; if that build is newer it downloads the pack to `user://update/build-N.pck`, checks its size and hash, and the corner of the title screen offers to restart into it.
- **`scripts/boot.gd` is the first scene.** It loads the newest good pack over the game the file was born with (`ProjectSettings.load_resource_pack`) and then opens `main.tscn`. It stays as it was in the file people were first given, so it is small, names no other script, and should not need to change.
- **Safety**: a pack that does not reach the title screen (`Update.mark_ok`) is marked bad the next time the game starts, the game goes back to the last pack that worked, and the bad one is not fetched again. A newer engine (`"engine"` in the note differs) cannot be loaded as a pack, so the corner offers the download page instead.
- Co-op: the host sends its build with the welcome; a joining game on another build is told which of the two is behind.
- Found on the way: Godot's official export templates refuse `--main-pack`, so starting the game again from a pack is not possible; loading the pack over the top is, and a pack that adds new named classes loads correctly (tested).
- Tested here with the Linux export: fetch, restart, new build, a pack that failed last time, a corrupt pack. **Not tested: the Windows file itself**, which cannot be run here.

## Blows that feel like something

- **The rules report each blow** (`Rules.hit_u`): event `["hit", x, z, how much, how it told, whose, what kind, did it finish them, was it a shot]`. How it told: 0 ordinary, 1 telling (the damage came to 1.45 times the blow or more: the right tool), 2 feeble (0.8 or less: the wrong one), 3 a lucky double, 4 burning. Reported for players, the posse and fire; not for spikes and the like.
- **Sweeps** (`Fx.slash`): a crescent where the blade went, as wide as the weapon's arc; a dart for a thrusting weapon. Coloured for the torch, holy things, a rune-cut blade and Dutch courage. The posse and the dead have small ones. **Shockwaves** (`Fx.shock`): a ring racing out along the ground for Smash, Clang, Flare, prayers, the bell and smites. Both come from a pool of 72 meshes.
- **Numbers** (`ui/pops.gd`): gold and big for a telling blow, grey and small for a feeble one, orange with a mark for a double, small orange for burning. A shot's number waits for the shot to arrive.
- **Noises** (`tools/make_sounds.py`): `thwack`, `tink` (off armour), `crit`, and `whoosh` for heavy weapons and sweeping tricks.
- The view is knocked a little along your own blows and jolted when you are hit (`main._kick`). Whatever is hit leans back for a moment; figures lunge into a blow.
- Options: "Numbers when a blow lands" and "Your own blows knock the view a little".
- Tests: new `tests/blow_test.gd` (14). Rules 117, month 50, Holy Book 32, merchants 38, contraptions 21, village 11, smithy 18, letters 22, tidy 13, ruins 23, torch 27, inn 30, UI 31, clicks 18, co-op 23.

## Rune weapons (build 3)

- The designer's ruling: runes make the top tier of weapons, and making them needs rank 7 of Hammer and Tongs.
- **Five rune weapons** (`D._runes()`, tier `rune`, `D.rune_of(base)`): the rune sword, spear, mace, billhook and warhammer. Damage is `D.RUNE_DMG` (1.7) times the refined weapon's, where steel is 1.35: about a quarter more than steel. Cost: `D.RUNE_COST` (4) runes, the steel a steel one takes, and the wood. They are marked `runed`, which is what lets a blow hurt a wraith.
- They are added after everything else in `D.IT`, so no earlier item changes its number and old saves load.
- `Rules.can_forge` and `forge_why`: rank `D.RUNE_RANK` (7). The smithy lists the five at rank 7, and below that says what runes are for and what rank is needed. The last rank of Hammer and Tongs now reads that it makes rune weapons, as well as halving the cost of facing, banding and bracing.
- Removed: the action `etch`, `p.etch` (from the player, the save and the co-op snapshot) and `D.ETCH_RUNES`.
- Six runes a day come out of the old workings (three veins of two), so a village can make about one rune weapon a day once it has a master smith.
- The name: `D.GAME` is "Thornhallow Thirty Nights", and so are the window, the exported file's details, the release title and the READMEs.
- Tests: torch 35 (the rune section rewritten: thirteen checks on rune weapons). The rest unchanged.

## Fixes from the first long game (build 4)

Three players reached day 25 and sent back a list. The breakages first.

- **Black nights.** Fog is measured from the camera, which is about 120 from the player. A foggy night began at 20 and ended at 60, so the whole screen was solid fog (`main._apply_light`). Now 78 to 154: it closes in just past the player. Reproduced as a black screen before the fix, and checked after.
- **Joined players indoors.** `Net.apply` clamped a joined player's position to the map, and the rooms are far outside the map (z about 240). So the host held them at the map's edge: they could not reach the ladder or the door, and the host could not see them. Now clamped to the room when `p.room` is set.
- **Joining late, dropping out, coming back** (`Rules.away`, `leave_player`, `join_player`, `player_record`, `restore_player`).
  - A village can be joined after its week has begun. A newcomer takes an empty cottage and its three villagers.
  - A player who leaves or loses their connection is not thrown away: their record goes into `away` (relics excepted: those are dropped for the village). Joining again under the same name gives it back.
  - The save keeps `away`. Carrying on with some people missing puts their saved peasants there too. One unmatched name and one unclaimed peasant is treated as a change of name; the host always keeps the save's first peasant.
  - The host dropped a joined game that was quiet for 12 seconds, which a slow computer exceeds while building the village. Now 50 seconds (`QUIET_MS`), and joined games send a word every two seconds, in the lobby as well.
  - One of the three players could not get in at all. Which of these it was is not known; all are fixed.
- **The steel mine** was drawn with its mouth to the west and worked from the east (`sites.gd`: the model was never turned). Turned, and the reach widened a little.
- **"I'm a stuck little peasant"**: a button at the foot of the handbook (action `unstick`, `D.STUCK_WAIT` 20 s). You and your posse are put outside your own front door, from anywhere, including a room.
- **Health bars** were two billboards, each turning on its own centre, so the fill slid out of its frame as the view turned. The bar now turns as one piece (`figure._process`) and slides to a new value.
- Hold E to get up from the bar. Rain is half as many drops, shorter and fainter. Rain slows the living to 0.92 (`D.MUD`); the dead wade at 0.85.
- Standing by a training dummy says what it is for and how much practice is left today.
- Tests: new `tests/away_test.gd` (32). The co-op test has a third player, `tests/net_late.gd`, who joins a week already going, drops out and joins again (9 checks; host 15, client 12), direct and through the village server.

## The storehouse, relics, leading and fishing (build 5)

- **The storehouse is a bank** (`menus.store`). Materials tab: one row a material, take out 1, 5 or 20, put in 1, 5 or all (actions `take` and `put` now take `"wood:5"`). Things tab: the village's spare things in a grid, yours below; click to move. Runes can be stored (`D.STORE_RES`).
- **A relic for every book.** Four new relics (`D._RELICS2`, ids 54 to 57), added after the rune weapons:
  - the Thunderer's Bow (Slings, Bows and Thrown Turnips): holy; each arrow jumps as lightning to two more of the dead within 4.5, at half strength (`Rules.lightning`, event `zap`, `Fx.zap`). With the book: three, and half as far again.
  - Saint Walstan's Scythe (the Woodcutter's Almanac): holy, a very wide sweep. With the book: gathering takes a fifth less time.
  - the Mason's Blessed Trowel (Barricades for Beginners): defences within 9 mend 3 a second. With the book: 6, and your own repairs are free.
  - Saint Dunstan's Tongs (Hammer and Tongs): forging costs a quarter less. With the book: forged, steel and rune weapons hit a tenth harder.
- **Leading is learned by leading.** Orders come at rank 1 of How to Win Peasants and Lead Them (follow, hold); charge at rank 3. The book's first step is 40, not 50, and it is taught by: the first ten orders of a day (3 each), a follower's work (0.5 a piece), a follower's blow (1, was 0.5), and each follower standing at dawn after a night you fought (4). Reaching rank 3 took about 400 posse blows before.
- **Fishing.** A catch is 5 fish (7 at rank 3 of Field, Hook and Pot); it was 3, no better than foraging, and a posse cannot help. A catch has a 15% chance of a few coins, 3.5% of a rune and 1.5% of a found weapon or piece of armour (`D.FISH_FINDS`).
- **Books are shown as title and gist** (`D.book_title`): "Hammer and Tongs (Blacksmithing)", in the skills window, the library and the messages.
- **The log roller rolls** (`Fx.roll_logs`): five logs down the road, bouncing, with dust and a knock to the view.
- **House braces** were turned about a point on the corner post, so one end stuck out into the air. They now lie flat against the wall, from the foot of the post up to the rail.
- Tests: new `tests/relics_test.gd` (38, with the tougher dead and the bells below).
- **Tougher dead** (`D.DEAD_HP`, `Rules.hp_of`, `R.tough_hp`): the ordinary dead have 1.0, 1.5, 2.1 and 2.8 times their health in weeks one to four. It was 1.0 to 1.3, while a peasant's blows grow three- or four-fold over the month, so by week three everything died to one blow. What they hit for still grows a tenth a week. Bosses are unchanged.
- **The nights of the bells** (`Rules.bells_night`, `D.BELLS`): one night in each of weeks two, three and four, from the seed, never a boss's night or the full moon (the short game: its fourth night). The congregation rings till dawn and the dead are enraged: speed 1.12, damage 1.25, health 1.25. Warned of on the notice board and in the morning's news; the hat goes round twice the morning after. The dead are tinted red, and the chapel bell tolls all night.
- **Relics glow** (`Figure.glow_of`, `Figure.halo`): emissive metal, a halo and a small light, in the hand, worn, and on the ground. Rune weapons glow violet.
- The farm is a marked field on the map.
- Still to decide with the designer: what the windmill does.

## Moons, the watch platform, and Robert Bailiff at dusk (build 6)

- **Five moons a month** (`D.MOONS`, `Rules.moon_of`, thirty-night game only), on fixed nights, none on a boss's night:
  - night 9, harvest: the dead get back 1.5% of their health a second (`D.HARVEST_MEND`), not while alight;
  - nights 15 and 28, full: the old full moon (weather `moon`: the dead 15% quicker, relics twice as often);
  - night 19, frost: the weather is snow;
  - night 23, blood: the night's horde is 2.5 times the size (`D.BLOOD_MOON`, in `night_plan`), and the hat goes round 2.5 times.
  The designer named the kinds and nights 23 and 28; nights 9 and 19 and the mending rate are mine. Each has its own moon in the sky, its own light, a line on the notice board and at dawn, and a dusk line. The nights of the bells now avoid every moon.
- **The watch platform** was in the design's Building table from the start and had never been built. Now: `platform`, 20 wood, in `D.BUILDS`. Hold E to post one of your posse (`q.plat`); from dusk they climb it and throw stones (`D.PLAT`: reach 13, every 1.5 s, 8 damage plus the leader's rank in the ranged book). Melee dead cannot target them; archers can unless it is roofed (reinforce: 10 wood, `s.re`). Saved (`pl`), and sent to joined games (the peasant record is 15 numbers now).
- **Robert Bailiff at dusk** (`D.BAILIFF_DUSK`, event `bshout`, sound `shout`): every dusk he shouts at everybody to defend his village, with lines of his own for a boss's night, the bells and the blood moon. His window was at the middle of his front wall, 0.7 from the back of the inn, and hidden by it from the square: it is now the east window (`D.BAILIFF_AT`), larger, with shutters and a sill.
- Structure health bars turn with the view as one piece (the same fault the posse's bars had).
- Tests: new `tests/platform_test.gd` (35).

## The blood moon, corrected (build 7)

- The designer's "2.5x difficulty" had been built as 2.5 times as many of the dead. He meant the difficulty. Now `night_plan` leaves the horde its usual size and multiplies `crowd` by `D.BLOOD_MOON` (2.5): each of the dead has 2.5 times the health and, by the rule the game already uses for one of the dead worth several, hits `1 + 0.6 x 1.5 = 1.9` times as hard. The dead are tinted red that night. The hat still goes round 2.5 times.
- Tests: platform 37.

## Design only: the second long game (no build)

Nothing was built. The designer asked for the design document to be brought up to date first, and for a yes before any further update.

- **Written into the design document:** the next big update in three parts (three more books and boots; the Jester, taught by Prospero at the Thorny Rose in three lessons; the raft to the Riverside); everything from the second long game (three times the health for the dead, new kinds, harder bosses and three new ones with a werewolf on night 28, the Lord's fight in two parts at 10,000 health, watch towers behind the wall, the side gates, five smithy tiers with today's rune renamed mithril and a new rune tier above it, the Rune Cave, posse kits, ten ranks to every book with honing, a power for every book on an action bar, a building wheel, relics for every player); a table of where the three lists ask for the same thing; a proposed order of building (updates A to J); and the open questions.
- **Review of the old design against the game:** thirty-seven things are in the design and not in the game (or there in another form). They are listed in the document under "Designed but not in the game", each awaiting build, drop or leave.
- **Found while reading the code, not yet mended:**
  - The Smoking Censer's rule runs (`undead_step`: dead within about 5.5 of a player with `trk == 27` get `slow`, which halves walking speed only). It does not slow their blows and shows nothing, so in play it appears to do nothing.
  - Relics are one of each for the whole village (`Rules.relics`), not one per player.
  - Steel has no bow or crossbow, and the rune tier has neither those nor armour.

## Design only: the list gone through (no build)

Still nothing built. The designer went through the open questions one by one; the design document holds every answer. The main decisions, for whoever builds next:

- **Dead:** twice today's health in week one, three times from week two; horde size unchanged; three new kinds (bloated dead, pallbearers, grave hound); a mild evil glow on all but bosses.
- **Bosses:** Chaplain night 11, Cook night 18, werewolf night 28 (one blow breaks barricades, a few swipes a wall or gate; howl freezes players unless braced, in the prayer or wearing the Helm). Coachman stampedes. Lord: a shadow with health of its own that teleports, shuns fire and throws the dead; the Lord comes when it is beaten and half the horde is; 10,000 health; organ music.
- **Controls:** space bar jumps (jump away from a sweep), left mouse attacks; action bar on 1 to 9 with health above it; building wheel.
- **Towers:** four sites behind a wall moved forward, six peasants each from anybody's posse, rocks do 5, upkeep 4 wood and 1 iron a dawn. Side gates: one a night alternating in weeks one and two, both from week three; players may build gates there.
- **Smithy:** crude, iron (was refined), steel, mithril (today's rune), rune (new, from the Rune Cave across the river). Bows, crossbows and armour in every tier. Posse kits: crude at rank I, iron III, steel VI; scavenged from fallen peasants.
- **Books:** fourteen and two classes; four to a peasant (fourth when three are at rank 4), fifth from the Index; a class counts as one and nobody has two; ten ranks; a power for every book at rank III; honing 2 in the hundred a page, five pages.
- **Relics:** one of each for every player holding its book, findable by anybody, tradable. Relic boots: no book, one of each per player. The Tithe Collector (a holy, burning flail): its own cave across the river, a minute a search, a shilling a search rising weekly, never traded.
- **Riverside:** raft 100 wood, by day only; swimming (20 seconds, half health, 45 seconds exhausted, no posse); two merchants; the druid brews Granny's potions for a player with Granny's Remedies, price set daily.
- **Jester:** note in the library, Prospero at the inn, three lessons with questions and a tankard each, homework of twenty dead between them.
- **After the Lord:** a new relative each month, each month adding half the first month's strength, twelve months at most. Hallowshire Town teased.
- **Village life:** windmill banquet (10 food a posse), riding sheep from the Herder, stray peasants who may desert, fishing by hoik, a cockerel at dawn.

## Version 7.1: mends (build counter 8)

**Version numbers from here.** The designer asked that the game stop looking as though it has had eight versions. Small additions are now x.1, x.2 and so on; a big update, which he names as such, takes the next whole number. So this is **version 7.1**.

- The copies of the game already handed out compare `build` in `version.json` as a whole number (`int(d.get("build"))` in the `update.gd` they carry), so `build` must go on counting up by one: it is 8 here, and is never shown. `"version": "7.1"` beside it is what the players see. `Update.version()` and `Update.their()` give the name of this build and of the one on offer; `tools/release_info.py` copies `version` into the published note; the release is still tagged `build-N` and is titled with the version. The co-op check still compares builds and names versions (`"v"` in the `you` message).
- **To release:** put `build` up by one, set `version` and `what`, push.

**The mends**

- **The Smoking Censer** (`D.CENSER`: reach 8, was about 5.5). The rule ran before, but only halved walking speed and showed nothing. Now the dead in the smoke also strike half as often (`u.smoke`: their cooldown runs at `D.CENSER.strike`), they are tinted grey with wisps coming off them (flag 256 in the co-op snapshot), and smoke rises round the carrier out to the reach (`figure.gd`). Bosses are slowed on their feet as before, not in their blows.
- **The Thunderer's Bow is the Thunderer's Crossbow** (same item number, 54, so saved bows become crossbows): 40 damage every 1.9 s, reach 18, heavy, the piercing bolt for its trick, the lightning unchanged. It was 20 every 0.85 s. About a tenth less harm a second in all, in fewer and bigger blows.
- **The ordinary crossbow** loads in 1.35 s, not 1.8.
- **Watch platform stones** do 5, not 8 (`D.PLAT.dmg`).
- **The storehouse** shows things that are the same once, with a count; clicking takes one.
- **Rain** ambience at 0.34, not 0.8.
- **A cockerel at dawn** (`sfx_cockerel`, made in `tools/make_sounds.py`).
- Tests: relics 45 (seven new: the censer's smoke, reach, bosses, strike rate and clearing; the crossbow; the stones). Everything else as before; co-op host 15, friend 12, latecomer 9.

## Version 7.2: the harder dead (build counter 9)

- **Health** (`D.DEAD_HP`): `[2.0, 4.5, 6.3, 8.4]`, was `[1, 1.5, 2.1, 2.8]`: twice in the first week, three times after, the weekly rise kept. Bosses take their own health and are not touched (that is 7.3).
- **Three new kinds, from night 1** (appended to `D.UN`, so the old numbers stand): the bloated dead (14, `burst`: on death `burst()` does `D.BURST.living` × the week's harm to players and peasants within 2.8, and 60 to the dead, other bloated ones included, so they go off in chains); the pallbearer (15, `lid`: in `hit_u`, a blow whose source is in front of it, within about 72 degrees of where it faces, does `D.LID` = a quarter, unless it is heavy or a burn); the grave hound (16, `hound`: quick and frail; it counts a player as six times further off than a peasant when choosing whom to go for, and sees further). Each has its own shape in `models.gd`, a lines in the dusk notice, and the handbook.
- **The mix by week** (`Rules.mix`): the old weights are kept within each class, then each class is scaled to `D.MIX_SHARE` for the week: easy (shamblers, skeletons, hounds), middling (everything else), hard (the guard, wraiths, coffin rams). A class with nobody in it yet passes its share down. One consequence: on the last night with eight players the horde is still 420 heads, but each is about 2.1 times as tough where it was 3 to 3.6, because the hard kinds are dearer.
- **The glow**: every one of the dead but the bosses (and the wraith, which has its own) is drawn with a shader that gives a faint green-white rim (`dead.gd` `_evil()`).
- Picture hook `DTV_KINDS=14,15,16` lines up the named kinds in front of the player.
- Tests: new `dead_test` (18); the old tests that had the health numbers written into them now read `D.DEAD_HP`; month 50, rules 117, relics 45, platform 37; co-op host 15, friend 12, latecomer 9.

## Version 7.3: the bosses (build counter 10)

- **Health:** the Steward 3,000 (was 800), the Coachman 4,500 (1,100), the Captain 6,000 (1,500); still multiplied by 1 + half a boss for every player after the first. The Lord is left at 2,600 for version 7.4, which rebuilds his fight.
- **Three new bosses** (`D.UN` 17, 18, 19; `D.BOSS_NIGHTS` now 7, 11, 14, 18, 21, 28, 30): the Lord's Chaplain (night 11), the Castle Cook (18), the Gamekeeper, a werewolf (28, the second full moon; `D.WOLF_NIGHT`: a quarter of the usual horde comes with him). Each has a shape, a line when he comes down and when he falls, a dawn warning, and a letter from the Lord the morning after (kept out of the ordinary letters so it is there on its morning).
- **What they do** (`boss_trick`, numbers in `D.SLAM`, `SERMON`, `STAMPEDE`, `STEW`, `SWING`, `SHIELD`, `HOWL`). Every trick that lands is shown first: a red ring that grows over the wind-up (`warn`), or a trail of rings along the Captain's line (`line`).
  - The Steward: a player within 4.5 → 0.9 s → thrown 5 and hurt.
  - The Chaplain: the sermon, 8 s in every 15: players within 14 are tugged 0.45 towards him every half second; the dead within 8 mend 1.5% a second. A single blow of 40 or more, or a stun, stops it (`lostplace`).
  - The Coachman: every 12 s on a run, a 3 s stampede at 2.2 times the speed; whoever he hits is thrown 6 to the side (3 otherwise).
  - The Cook: a pool of stew where a player stands every 7 s (`R.pools`, sent to joined games as `po`), hot after 1 s for 6 s, 8 a second; and the cauldron, within 3.5, every 11 s: thrown 6.
  - The Captain: every 10 s, at a player between 3 and 12 paces with no wall between: 1 s to aim, then 9 paces a second along the line; whoever is near the line is thrown 4 aside. He charges at where you were.
  - The Gamekeeper: every 14 s a howl: players within 18 are frozen 2.5 s (`p.frozen`, sent as a player field; `move_player`, attacks, tricks and powers all refuse), unless prayed over (`p.prot`) or wearing the Helm of the Unbothered; peasants lose nerve. In `hit_struct` a barricade or anything else off the wall goes at a blow; a wall or gate loses a quarter.
- **Thrown** (`shove`): moved in small steps through the usual collisions and stamped (`p.tp`) so that a joined player's game takes the host's word for where they landed.
- Sounds made in `tools/make_sounds.py`: howl, whip, sermon.
- Tests: new `boss_test` (27). Letters 22 (a month now brings 18 letters); platform 37 (the one moon on a boss's night is the werewolf's).

## Version 7.4: the Lord (build counter 11)

- **Health:** the Lord 10,000 (was 2,600), still multiplied for the number of players; his old ×0.6 against anything not holy and the three-stage walk to the keep are gone (`lord_stage` is no longer called).
- **His shadow** (`D.UN` 20, `D.U_SHADOW`, 2,500, `shadow`): comes down six seconds into the Lord's night. Fire (`src_of` now says `"fire"`) does it no harm and makes it blink elsewhere (`shadow_blink`); a holy blow drives it back 3; `ignite` skips it and burning things near it go out. In `boss_trick`, numbers in `D.SHADOW`: it blinks every 6 s, raises a fallen one every 7 s, and every 8 s picks up one of the dead and lobs it (`lob`, `lob_step`, numbers in `D.LOB`) at a player or a building, shown first with a ring.
- **The wait:** the Lord comes when the shadow is down (`night.shadow_down`, set in `kill_undead`) and at least half the night's horde is killed.
- **The entrance:** every other one of the dead, every lob and every pool is cleared, the queue emptied, and he stands at the north gate (0, `D.VN` − 7). The view cuts to him for 4.5 s (fov 38, then back to 20) under a banner, with thunder, and `music_boss` (an organ in D minor with a pedal and timpani, made by `organ()` and `boss_music()` in `tools/make_sounds.py`) replaces the night music while he is on the field.
- **His fight** (`lord_trick`, numbers in `D.LORD`), one thing every 3 s: the cloak sweep (a cone 5 deep, ±1.2 radians, 0.6 s to land, 30 and thrown 4); bats down a line 16 long and 1.3 wide (0.9 s, 20); the goblet slam (within 4, 0.9 s, 22 and thrown 5); every 12 s he vanishes and comes back behind the player furthest from him, and sweeps; every 10 s he throws a fresh shambler. Close enough, he simply hits you. Each is shown on the ground first (`F.fan` for the cone, a ring or a line otherwise). The Lord is now his own figure in `dead.gd` (body, cloak, two arms, goblet) with poses for each wind-up and blow.
- **Jump:** Space (`keys.gd` action `jump`; attack's default is now the left mouse only, and an old bind of Space to attack is taken off). `Rules.jump`: 0.35 s, 3.2 paces the way you are moving, 1.1 s between jumps (`D.JUMP`). Dodging is by distance; there is no immunity in the air. Sent as `j` in a joined player's input and `jumpT` in the player fields so the hop shows. Space or a left click lands a fish; the intro pan can be skipped with it.
- Tests: new `lord_test` (21); month's Lord section now checks his entrance at the north gate with the field cleared. Everything else as before; co-op host 15, friend 12, latecomer 9.

## Version 7.5: walls, towers and the side gates (build counter 12)

- **The wall moved forward:** `D.VN` is −25, was −22 (`world.gd` now takes it from `D`). Things placed against the wall moved with it: the braziers (`VN − 2.6`), the headless rider's stopping place, the gate guard's post (`VN + 2.6`), and the line the dead sidle along inside the wall (`VN + 3.4` / `VN + 2.1`). A save from before has its seven north foundations moved to the new line when loaded.
- **Sites** (`E.Struct.site`): 0–3 are the watch tower sites (`D.TOWER_SITES`: the two corners at x ±24.5, either side of the gate at ±10, all at `VN + 5`); 4 and 5 are the west and east gateways (`D.SIDE_SITES`, a `gate` turned a quarter round). `add_sites()` makes them on a new game and adds them to an old save. Like the north foundations, a site survives its building being knocked down (`destroy_struct`).
- **Watch towers** (`tower`: 25 wood and 8 stone, 320 health, in `BLOCKERS`, so the dead that get inside will break one; people bump into them as into walls). Beside a built one, `find_interact` offers its notice (`D.station("towerN")`, `Notices.tower_page`), with `tup` (the nearest free one of your posse is given it, six at most from anybody's posse), `tdown` (one of your own comes down), `tkeep` (the upkeep, `D.TOWER.upkeep` 4 wood and 1 iron), `troof` (10 wood, stops arrows), `trep` and `tdis` (taken down: half the cost back, capped by what you can carry). The crew stand in a 3 × 2 grid on the deck, 2.9 up in the view, and throw stones as the platform did, out to 15 (`D.TOWER.reach`). At dawn every built tower is marked not seen to (`s.kept`); a tower nobody has seen to by dusk is not climbed. A fresh one counts as seen to on the day it goes up.
- **The watch platform** is no longer in `D.BUILDS`; old ones still stand and work.
- **Side gates:** `side_gates()`: `[1]` (east) on odd days and `[-1]` (west) on even ones until `D.SIDE.both` (week 3), then both; none on the Lord's night. Each queued one of the dead, unless it flies, drifts, rams, drives, digs or is a boss, takes a side gate with chance `D.SIDE.share` (0.2) for each in use, and goes round by the Captain's old route (`u.side`). The dawn notice says which. The werewolf takes a quarter of a side gate at a blow, not all of it.
- **Jumping:** `Rules.jump` now goes whichever way is pressed and leaves the facing alone; nothing pressed is a jump on the spot.
- Sent to joined games: `site` and `kept` on the end of each structure in `st`. Saved: `site`, `kept`.
- Models: `tower`, `tower_roof`, `foundTower`. Picture hook `DTV_TOWER` builds every site and mans the towers.
- Tests: new `tower_test` (34); `platform_test` keeps the moons (its platform half is now in `tower_test`); `lord_test` 25 (sideways, backwards and on-the-spot jumps). Co-op host 15, friend 12, latecomer 9.

## Version 7.6: the smithy (build counter 13)

- **Mithril and runes:** what were runes are mithril (player field `mith`, storehouse `mith`, `D.RES_NAME` "Mithril", a purple icon). The veins of the old workings and the odd fish give mithril. `rune` is now the new material, blue, from the Rune Cave across the river (version I builds the way there; until then nobody has any). Save version 4; a save of version 3 has its players' and the storehouse's runes moved to mithril (`restore_player`, `load_game`), and `main.read_save` takes 3 or 4.
- **Five tiers** (`D.TIERS`, shown as `D.TIER_NAME`: crude, iron (the old "forged"), steel, mithril, rune), each with the five weapons, bow, crossbow, cap, chain shirt and shield. Item ids are unchanged up to 57; 49–53 (the old rune weapons) are mithril now, at `TIER_DMG.mithril` 1.5 times iron where rune was 1.7. New, from 58 (`D._more_tiers`): crude armour (58–60); the crude bow and crossbow, each with a chipped one after it (61–64), no book needed; steel bow and crossbow (65–66); mithril armour, bow and crossbow (67–71); rune everything (72–81, 1.65 times iron); blessed rune armour (82–84); six kits (85–90). `D.tier_item(base, tier)` finds any of them; `TIER_CUT` / `TIER_ARROW` give armour its strength. Item icons are drawn in their tier's colour (`Look.TIER_INK`), and mithril and rune armour glow when worn.
- **Who forges what** (`can_forge`, `forge_why`): crude, anyone; iron weapons, Hammer and Tongs; steel, rank 4; mithril, rank 7 (`D.MITHRIL_RANK`); rune, rank 10 (`D.RUNE_RANK`, a rank version G writes), so not yet.
- **The smithy's window** (`menus.smithy`): tabs for the five tiers and the posse; each a wall of item cards (`_slot`, wider here, `_slot_w`), the price under each, the details on pointing at one. The number keys do nothing there; `Notices.data("smithy", page = tier)` keeps a list of the same for the tests.
- **Blessed rune armour:** the priest's notice offers it for each piece of rune armour worn (`rbless`): both holy classes (`p.holy >= 2`) and `D.RUNE_BLESS` (240d, a gold piece). The piece becomes its blessed twin. `hurt_friend`: with any blessed piece on, a wraith does half; each piece scorches whatever strikes you in reach for 3 holy.
- **Kits** (`s "k"`, `I.kit` "ranger" or "watch"; 10 iron or steel and 5 wood; `D.KIT_RANK` crude 1, iron 3, steel 6). Forged, a kit goes to the nearest of your posse with none (`give_kit`), or the backpack; from the backpack, clicking it hands it on (`kit`); from rank 3, `kitall` does the lot. `Rules.kit_gear(kit, ni)`: a ranger has the tier's bow and cap; a watchman a weapon (by the peasant's name, of the five), cap and shield. A ranger stays back and shoots at 0.8 of the bow's range, 0.55 of its damage, 1.7 times its wait, over walls; a watchman hits with half the weapon's damage (no longer a farm tool against armour, heavy and blunt where the weapon is). The cap and shield take their share off blows. A fallen peasant drops the kit (`drop_item`). A crude kit comes apart after its second dawn (`q.kw`). Sent as the sixteenth peasant field; saved as `kit`, `kw`. The spear (`armp`) is still there for anyone.
- **The old ruins** inside the village are smaller: six slabs, lower, closer together; the two heaps to search moved in with them.
- Tests: new `forge_test` (34); `torch_test`, `away_test` and `relics_test` say mithril now; `rules_test` expects save version 4. Co-op host 15, friend 12, latecomer 9.

## Version 7.7: ten ranks, honing, more books (build counter 14)

The first of three updates for stage G (7.8: a power for every book, the action bar, the building wheel; 7.9: the new books, boots, relics for every player).

- **Ten ranks** (`D.MAX_RANK` 10; `D.XPM` grows 45, 60, 78 for ranks VIII to X). Every place that grew with each rank (`0.04 * (r - 1)` and the like) stops growing at rank VII (`mini(r, 7)`), so the new ranks add what they say and nothing more. Titles: "Grand Master" at X.
- **The 33 new ranks:** Woodcutter (carry 60; a tree gives a third more before it is spent; past full, the posse takes what it gathers to the storehouse); Field, Hook and Pot (9 fish; a meal cures a hangover and a fright; meals heal 80 and the posse has 20 more health until dawn, `q.fed`); Barricades (half tower upkeep, `Rules.upkeep`; what you repair a quarter stronger until dawn, `shore`, `s.bo`; contraptions set themselves up again once a night, `s.rs`); Hammer and Tongs (armour stops a tenth more; kits you hand out never wear; rune at X); Art of Hitting (20 more health again; every fourth blow double; a killing blow carries its spare harm into the nearest one within 2.6); Slings (a third faster; a shot goes on to the one behind; a free volley of three every tenth shot, `p.shots`); Leader (posse four larger; tower peasants throw a third faster; X waits for the war cry in 7.8); Ledger (38 s charge; the hip flask, `p.flask`, filled from the barrel at dusk and drunk from the backpack; charging, no throw moves you); Relics (relics a tenth better; search twice as fast at night; one certain find a day, `p.sure`); Granny (a bandage settles a fright; the posse survives two fatal blows a night, `q.saved2`; the bandage reaches seven paces); Holy Book (So Help Me Lord, Please?: `help_me`, two times in three against a boss's throw, pull or freeze, with a small rising cross, `fx.cross`, and rune armour blessed for half, `rune_bless`; the prayer lasts 15 s; X's Consecrate waits for 7.8).
- **Honing:** at rank X, `hone` turns ten spare points (`D.HONE_COST`) into a page of a book (`p.pages`, five at most, `D.HONE_MAX`); `hn(p, b)` is 1 + 0.02 a page, applied to the book's damage, healing, courage, gathering and searching speed, costs, nerve and prayer. A button for it in the skills window. Spare points still sell.
- **Books to a peasant:** a fourth once three are at rank 4; a fifth with An Index of Further Reading (it was the fourth).
- **A fix:** the bloated dead going off now sends `bloat`, not `burst`, which a charge out of the inn also sent (since 7.2 the two looked and sounded alike).
- Saved: `pages`, `flask`. Sent to joined games: `pages`, `flask`.
- Tests: new `ranks_test` (28); `rules_test` expects ten ranks; `dead_test` listens for `bloat`. Co-op host 15, friend 12, latecomer 9.

## Version 7.8: powers, the action bar, the building wheel (build counter 15)

- **A power for every book** (`D.POWERS`, by book; the Holy Book's are its calling's), from rank I, each with its own wait (`p.pwCd`) and, where it lasts, a length (`t`) that honed pages stretch. `Rules.book_power(p, b)`, sent as `bp`. Many Hands (`p.many`: gathering and the posse's work at half the time); Pot Luck (one food: `meal_hp` for everyone and every peasant within `D.POWER_NEAR`, 8); Shore It Up (defences within 10 mended by a third of their health); The Whetstone (`p.whet` on everyone near: a fifth harder); Red Mist (`p.mist`: a third quicker, and `shove` does nothing); The Marked Man (`u.mark`, `R.marked`: the nearest ahead within 22, or the nearest; a quarter more harm in `hit_u`; `shoot`, tower peasants and rangers all take it first if it is in reach, `marked_in`); War Cry (`p.cry`: the posse's blows ×1.3 and no lost nerve, `crying`, everybody's posse at rank X); A Round on Me (30 courage for everyone near, and a charge for anyone it fills); Hone (`p.hone_i`, `p.hone_t`: the nearest heap with searches left, while any relic is still to find; the next search of it finds one); Smelling Salts (everyone down within 8 is up with at least 30).
- **Consecrate**, the apprentice priest's third power at rank X (`p3Cd`, 45 s): `R.holy_ground` [x, z, 3.5, 8 s]; the dead, bosses aside, will not step on to it (`on_holy`). Cleared at dawn, with every power's timers.
- **The action bar** (main: `bar_all`, `bar_slots`, `bar_info`, `bar_do`; hud: `bar`): the weapon's trick, each book power, the calling's powers, what you carry, orders, the toilet break; 1 to 9 for the first nine; every one clickable, with its wait shown. `Settings.bar_order` and `bar_off` (kept in the settings file) put it in order and take things off, from the skills window. The default keys for trick, carry, orders, toilet and the two calling powers are gone (Keys.name says "its button on the action bar", or "right-click" for the trick); they can be bound again.
- **The bottom of the screen** (`hud._bottom`): health over the bar, posse, backpack, skills and courage beside it, all scaled down together to fit the window; the prompt sits above it, the news bottom left.
- **The building wheel** (`hud.open_wheel`, `close_wheel`; main `_wheel_step`): the build key held for a fifth of a second opens a ring of everything you can build round the middle of the screen; let go over one to take it up, or click one. A tap steps through as before. The cards bottom right are gone.
- Views: a ring and a word when a power is used; a red marker over the Marked Man (`_mark_step`); a pillar of gold light for Hone (`fx.pillar`); a disc of light for consecrated ground.
- Tests: new `powers_test` (23); `ui_test` checks the bar's visibility in the tree. Co-op host 15, friend 12, latecomer 9.

## Version 7.9: four more books, boots, relics for everybody (build counter 16)

The last of stage G's three updates.

- **Four books** after the Holy Book (`D.B_FIRE` 11, `B_WATCH` 12, `B_SHIELD` 13, `B_DOG` 14), ten ranks each, with titles; a player's book lists are fifteen long, and older saves are made up to fifteen. Powers in `D.POWERS[11..14]` (with a `rank`: three of them come at rank 3), and the fire-raiser's second, burning oil, in `D.POWERS2` (bar id `o11`, sent as `oil`).
- **Fire** (`D.FIRE`): `ignite` burns a tenth longer a rank (to VII), ignores the rain from rank 2, frightens from 7 (`u.fear`), remembers who lit it (`u.burnby`; the burning take a quarter more from rank 9) and teaches the book. The fire stick (`p.fs` to hand, two at rank 8; `p.fsT` until the next; half the wait with the Everlasting Match) at the marked one, the nearest ahead, or the nearest; bursts on all within 2.6 from rank 4; lights a tar pit near where it lands from rank 3 (`light_tar`, `s.fire`, `s.lit`, four at most), as does a torch swung at one. The burning pot (`firepot`, built from rank 5): a bow or crossbow shot within 4.5 burns (`near_pot`). Burning oil (`oil_power`, rank 6): only from a north foundation, a tower, or a side gate; a patch outside it (`R.fires`) sets alight what is on it every half second for eight seconds; twice the ground at rank 10.
- **The night watchman:** `stride` (faster outside, and boots half as good again from rank 8); the haze thinner (`atmos.see`) from rank 2, cleared, with the night's dark lifted a little, near the Unblinking Lantern; the chest and the outer ruins on the map from rank 4; `unseen` (half the notice outside the wall at rank 6, the posse too at 7, three times less with the Lantern and its book); the dark lantern (`p.dark`: not looked for, and forgotten by anything that had noticed you; the posse hidden at rank 9) ends with your next blow; `u.nt` (a bit for each player's slot) for the dead that have noticed someone, and a blow on one that has not is three times as hard from rank 5, five at 10. Learned by searching the outer ruins, opening the chest, and blows outside the wall.
- **Shield-work:** a shield stops more (`gear_cut`); throws half as far behind one from rank 2 (the rank's text now says so: "not knocked back" would have made rank 10 pointless); Brace (`p.braced`: no harm from the front, the striker shoved back, no howl; `covered`, `bracer_of`, `faces`, `behind`); the posse behind a shield a quarter safer (rank 4); Brace a third sooner (5); a braced block staggers (6); a Brace covers those behind (7); arrows stopped outright (8); six seconds (9); no boss moves you braced (10). Saint Wilbur's Pot Lid sends a stopped arrow back. Learned by taking blows on a shield.
- **The dog:** a peasant of kind 3 (not posse, not saved, not counted in the village), one per player with the book and two with Saint Wilbur's Dog Lead (`ensure_dogs`, names from `D.DOG_NAMES`). `dog_step`: That One (`q.dt`: pulled down and held, `u.held`, `u.heldby`, four seconds, six at rank 9, and a boss for two only from rank 9; a quarter more harm while held from rank 6); dragging a fallen player away from the dead towards the keep (rank 7); biting what is near you or it; fetching drops within 14 (rank 4, `q.fetch`, `q.carry`); otherwise at your side. Knocked down (`state "down"`, sent as a new peasant state), up at dawn, or in a minute from rank 5, or after five seconds at rank 10. At night, a bark at a gate with the dead at it and nobody within 12 (rank 2, every 20 s at most). Rank 8 marks the rubble on the map, as the relic book's second rank does. A model with moving legs and tail; a bark and a growl, made in `tools/make_sounds.py`.
- **Boots:** a sixth slot, `feet` (`s "f"`): Somebody Else's Turnshoes (found in rubble, `D.FOUND_A`), hobnailed boots (forged, iron), sabatons (forged, steel, a twentieth off blows), and three relics in `D.BOOT_RELICS`: Brother Fleet's (a quarter faster), the Sandals of the Extremely Devout (`R.hallows`: footprints every 0.4 s that scorch for 2.5 s), Brother Cinder's Hot-Foot Boots (what strikes you is set alight). Saved, sent, drawn.
- **Relics for every player:** `relic_wanted(id)` is the number of players who hold the relic's book (at least one), and for the relic boots the number of players; `relics` keeps every copy; `relics_left()` is what may still turn up, everywhere a relic is handed out.
- **Fixes:** the iron page of the smithy listed its bow and crossbow twice (`FORGE_W` already has them), in the window and in the list; a check in `forge_test` now looks for doubles on every page. The news moved up, clear of the action bar.
- Tests: new `newbooks_test` (46); `rules_test`, `holy_test` expect fifteen books; `merchant_test` lets the pedlar's real relic be a pair of boots; `forge_test` 35. Co-op host 15, friend 12, latecomer 9.

## Version 7.10: village life (build counter 17)

Stage G2. Every update is now a .1 step, so after 7.9 comes 7.10.

- **The windmill's banquet** (`D.BANQUET`): two new places, `mill` at the windmill's door and `plate` (the offering plate, a dish on a post inside the east gate, drawn in `world._downs`). By day, 10 food at the mill sets `p.banq` to today; 13 food and 5d on the plate sends the nearest free one of the posse off (`q.errand`, walking by `way_to` to `D.MILL_DOOR`; `p.banqP` while he goes), and the banquet counts when he gets there, after which he rejoins. All night (`village_step`), every peasant of kind 0 whose leader's `banq` is today mends at 1.2 a second, to their most. Players are not healed. Paid afresh each day; `banqP` is cleared at dawn.
- **The Herder** (`D.HERDER`, by the sheepfold; an NPC with a crook in `world._downs`): the place `herder`. His lesson (`hlisten`: `p.herdL`, `p.herdT` up to `D.HERD_TIME`, 36 s, stood beside him; walking off pauses it), his patter shown line by line (`D.HERD_TALK`), then two of his three questions (`D.HERD_Q`, chosen and shuffled by player; `p.herdQ`, `hans`; a wrong answer sets `p.herdW` for his remark and another go). Learned, `p.herd`; `tame` gives `p.sheep` for one food.
- **Riding sheep:** a sheep is a peasant of kind 4 (not posse, not saved, not counted in the village; names in `D.SHEEP_NAMES`; peasant states `graze` and `ride` sent to joined games). By day it follows its player (`village_step`); `Rules.ride(p, on)` (sent as `ride`; the action bar's `sheep` button, and a `ride` key with none set) mounts if fed today, feeding it one carried food if not (`p.sheepFed`), and refuses at night, indoors or hungry (an `no` event with a title). Mounted (`p.ride`): speed `PLAYER_SPEED × 1.25` (mud aside; boots and armour make no odds); `find_interact` offers only "get off" (`dismount`); attack, the trick, carrying, the toilet break and every power are refused. `village_dusk` puts the sheep away under the stairs; it comes out again in the morning. The rider sits higher, on a sheep model under the figure (`figure._sheep_node`; one in four is black), with a bleat (`baa`, in `tools/make_sounds.py`).
- **Strays** (`D.STRAY`): `q.stray`. Each morning (`strays_morning`), for each player who has not had one this week (`p.strayW`, `week_i`), a chance by week (`D.STRAY_FIND`, 55 in the hundred falling to 12) that one hides at one of `D.STRAY_SPOTS` (round the farms first, deeper in the forest as the weeks go on), while the village is under its cap and no more are hiding than there are players. Talked round by holding interact for two seconds; over and above the posse (`posse_max` adds `strays_of`), two at a time at most. 60 health, a smaller figure in a faded, patched tunic (`patches`). At dusk the unfound ones go; each found one runs off with a chance of 1 in 100 per player in the game (`village_dusk`), taking his kit and up to a shilling of his leader's coin (`deserted` event). Saved (`stray`); sent to joined games as the peasant's kind plus 100.
- Saved: `herd`, `sheep`, `sheepFed`, `strayW`, `banq`. Sent to joined games: those and `banqP`, `herdT`, `herdL`, `herdQ`, `herdW`, `ride`.
- Tests: new `life_test` (49). Co-op host 15, friend 12, latecomer 9.

## Version 7.11: the Jester (build counter 18)

Stage H.

- **The book:** `D.BOOKS[15]`, Jester the Faux Magician (`D.B_JEST`, `"class": 1`), ten ranks; `TITLE_NOUN` Jester, `TITLE_ADJ` Motley; `D.POWERS[15]` is empty, as the Holy Book's is. Player book lists are sixteen long. At the library, taking it gives `p.jnote` and the note (`D.I_NOTE`, 101, paper) instead; the library entry says so.
- **Prospero** (place `prospero` in the inn, by the fire; an NPC with a jester's cap on a stool, with a collider; the inn's shelf is now empty and he says why). `jest_why(p)` gives the reason he will not teach: a priest (one calling), all three done, after dark, a question waiting, no free book slot for the first, homework short (`p.jhw` < `D.JEST.hw`, 20, the newest trick's dead since the last lesson), or no ale in the barrel. `jlisten` pays one tankard from `R.ale` (`p.jlPaid`) and starts or pauses `p.jlL`; `player_step` counts `p.jlT` to `D.JEST.time` (45 s) while by his stool in the inn by day; then two questions (`D.JEST_LESSONS[n].q`, `p.jlQ`, `jans`, `p.jlW` for his remark). Passing raises `p.jl`; the first sets the book to rank 1 (a stamped library card counts), takes the note and makes a jester. Giving the book up with a library card resets the lessons.
- **Callings' powers:** `Rules.has_cpower(p, c, i)` (the priest's by rank, the jester's by `lesson`), used by the bar and `do_power`; the jester's waits are `trick_wait` (`D.JEST.cd` 6, 20, 40 s; a third less at rank 4), in `p1Cd`..`p3Cd`.
- **The tricks** (`jester_power`), each through `trick_luck`: 0 fails (1 in 6, 1 in 12 from rank 2), 2 lucky (1 in 6), 3 the Big Finish (1 in 10 from rank 7); after a fail (`p.jfail`) the next cannot at rank 10 or with the Marotte. `R.jest_force` sets the next for tests. Strength ×(1 + 0.08 a rank past I) and honing. Is This Your Card? (20 harm at the nearest ahead within 14, or the nearest; through to the one behind at rank 3; one in three back in the hand at rank 8; event `card`, a spinning playing card, `pcard`). Abracadabra, Roughly (14 harm and a 1.4 s stagger within 4.5, or 7 when lucky; at rank 5 `R.smokes` linger 6 s and slow the dead in them; event `abra`). A Jape at Their Expense (within 9: `u.conf` 6 s, 9 at rank 6 with `u.confH` harder blows; doubled when lucky; bosses get `taunt`/`tauntT` instead, and `u.astray` at rank 9, which makes half their blows in `hurt_friend` miss; event `jape`). Confused dead (`undead_step`) wander (`u.cw`, `u.cr`) and hit any of the dead next to them; sent to joined games as undead flag 512, shown as coloured stars.
- **The relic:** Prospero's Marotte (102, carried, its own model), in `D.RELICS`, lore with book 15: japes a third longer.
- Views: `F.C_MOTLEY`; the cap and bells on a jester with no helm (`jhat`); `motley` on a lesson learned.
- Saved: `jl`, `jhw`, `jnote`. Sent: those and `jlT`, `jlL`, `jlQ`, `jlW`, `jlPaid`, `jfail`.
- Tests: new `jester_test` (58); `rules_test`, `holy_test`, `newbooks_test` expect sixteen books; `inn_test` an empty shelf. Co-op host 15, friend 12, latecomer 9.

## Version 7.12: the raft to the Riverside (build counter 19)

Stage I.

- **The Riverside** is a room (`D.ROOMS.riverside`, centred at -160, 320, 72 by 48), marked `"open"`: the sky over it (no indoor zoom or haze), jumping allowed, and peasants can be in it (`Rules.room_at`, used by `collide_friend` for peasants). Its door is the raft at the village bank (-30, 51); the landing is on its north edge, the river beyond. Scenery in `world._riverside` (three houses, two stalls, the druid's hut and campfire, the far ruin, the Rune Cave, the relic's cave, rocks, trees, the river); `world.set_riverside` shows the raft (or its woodpile), the cave's props and how bright the seams are.
- **The raft:** `R.raftW` to `D.RAFT.wood` (100), put in by holding interact at the bank (`raftw`), then `R.raft`. By day, `enter`/`leave` take the raft (`p.rafted`; the posse follows across and, on leaving, is brought back). After dusk, `swim` (`start_swim`/`end_swim`, player state `swim`, `p.swimT` 20 s): the swimmer arrives with half their health and `p.tired` 45 s (speed ×0.6, every blow ×0.75 in `hit_u`); the posse stays where it is (`peasant_step`: a peasant on the far bank whose leader is not stays put). Only once there is a raft. Dawn brings everyone home.
- **The far ruin:** ten heaps (`D.RIVER_SPOTS`, `R.spots2`, two searches each a day), searched with `do_search(p, 100 + k)`; same finds, no noise, nothing wakes.
- **The merchants:** the one who never leaves (`rmerch`, `rbuy`; `D.RESIDENT`: five of a material for 30d, steel 45d, one mithril 60d, one rune 120d, a rune weapon 480d, rune armour 360d); the travelling one (`tmerch`; `R.merch2`, never the village's that day; `R.wares2` from `wares_of`, ×1.5; bought with `mbuy` and a `t:` prefix). `make_wares` now uses `wares_of`; the notices share `Notices.wares_list`.
- **The Rune Cave:** `rcfix` (20 wood, once, `R.rcave`), then three seams (`D.RUNE_SEAMS`, `R.runes2`, two each a day, `rune2`) give runes. The smithy's rune message points there.
- **The druid** (`druid`): recipes (`p.recipes`, a bit each; 60d; readers of Granny's Remedies only) and brewing (`brew`) for the day's price (`R.brew`, from `druid_price`: one to three kinds; common 5–10, rare 1–2; the Last Warning always a fire rock, `frock`). Fire rocks from the campfire (`ember`, four in ten). Potions are counts on the player (`pot_a`, `pot_s`, `pot_d`, `pot_i`), in `D.STORE_RES` for the storehouse, on the action bar (`pot0`..`pot3`, sent as `pot`), drunk with `drink`: two minutes of ×1.25 harm dealt, ×1.2 walking and swinging, ×0.75 harm taken; or 15–20 s (half in the rain) of setting alight the dead within 2.6, twice a second.
- **The Tithe Collector** (103): a flail, holy and burning, arc -0.2, trick `quake` (everything within reach + 1: ×1.5, frightened 4 s, alight). The cave's owner (`keeper`, `tpay`, `tithe_fee`: 12d × the week) sells one search (`p.tpaid`); the rubble (`tithe`, 60 s, `do_tithe`) finds it 1 in 20 by day and 1 in 8 after dark. Untradeable: not dropped, racked, destroyed, stolen by a mercenary, left behind by a player who goes home, or lost on death; `stow` takes it even into a full pack. The day's piece of ore (`tore`, `R.tore_day`), rune or mithril.
- Saved: `raft` [raftW, raft, rcave, tore_day]; players' potions, `frock`, `recipes`, `tithe`. Sent: those, `rafted`, `swimT`, `tired`, the potions' timers, `tpaid`; the world's in `rv2`.
- Tests: new `river_test` (55). Co-op host 15, friend 12, latecomer 9.

## Version 7.13: a tidier corner (build counter 20)

The first of the polish updates, from Matt's review.

- **Top left** is one scroll (`hud.gd`): the day (24pt, down from 30), the time, the title and the ready line, a thin rule, then a two-column grid of what you carry as 22px icons with a number (`_carry_grid`, `_res[r + "_row"]`): coin always, and each material, potion and the fire rocks only while there is any; a full load in rose. The separate "What you carry" card is gone.
- **The map** is a fifth smaller (`Minimap.SC` 0.93; the slot 182 by 140) and sits in its own parchment frame (`Look.card`, 2px padding) in the top right; the map's own paper is lighter and lightly mottled, the river a touch softer, and the heavy brown border is a thin ink line.
- The handbook's "Reading the screen" says so.

## Version 7.14: the Riverside redrawn (build counter 21)

From Matt's review, with two pictures of a druid's cottage to go by.

- **Layout** (`D.ROOMS.riverside`, now 100 by 72): a small hamlet inside a fence (x -178 to -142, z 296 to 326) with four gates, north to the landing, south to the road, west and east to the two caves. Inside: the market round the bonfire (`D.CAMPFIRE`, now -160, 310), the merchant's stall and the traveller's cart along its north side, the druid's table and cottage on the west, three houses, the well, a pen. Outside: Garrick's Cave in a hill to the west (`TITHE_RUBBLE`, `TITHE_ORE`, the `keeper` station, now named Garrick) and the Rune Cave in a hill to the east (`RUNE_SEAMS` in its mouth); the far ruin in the fields to the south-west (`RIVER_SPOTS`); the road south to Hallowshire Town with a broken cart (collider) and a signpost (`hsign`, `D.HALLOWSHIRE_SIGN`). Colliders for the hills, the fence (with its gaps), stalls, houses, pen, bonfire, well and cart. Every station and work point was moved to match.
- **Folk:** Widow Thrupp (`hv0`) by the well and Young Ned (`hv1`) by the pen, with three things each to be asked about (`D.HAMLET_FOLK`, notice like the inn's locals).
- **Labels** (`labels.gd`) for the Riverside: the raft back, the market, the druid, the bonfire, "The Rune Cave: runes", "Garrick's Cave: the Tithe Collector", the far ruin, the road, the two folk.
- **Scenery** (`world._riverside` rewritten): softer, mottled grass; fields with furrows, hedgerows, trees, hay bales; the river now uses the village's running-water shader (`world._water`, shared, with uniforms for its middle and width), with sandy banks, reeds and lily pads; a jetty at the landing; dirt paths and the road's ruts; a cobbled market; the bonfire (`_bonfire`: a ring of stones, a cone of logs, five dancing flames and a flickering light, stronger at night); the striped stall and canvas-covered cart; the druid's cottage (`_druid_cottage`: stone walls, a turf roof, a great tree up through the middle with roots over the walls, ivy with flowers, flowers and red toadstools all round, herbs under the eaves, a lantern, a lit window) and the druid himself (`_druid`: green robe and hood, a white beard, antlers, a staff with a glowing green stone), his table of glowing potions; houses with window boxes, barrels and a washing line; the well with its little roof; the pen (`_pen`) with Dorothy the cow and the Donkey (`_beast`: heads that graze and look about, tails that swish); seven hens (`_chicken`) wandering and pecking round the market; fourteen torches (`_torch`) at the gates, the market and the cave mouths, lit after dusk (their lights are among `lanterns`); the two hills (`_hill`: layered turf with rocks and trees, a dark cave mouth framed in timber, and a sign: Garrick's says PAY HERE beside a money box; the Rune Cave's has a blue rune and a blue light inside).
- **Sounds:** `moo`, `bray`, `cluck` (in `tools/make_sounds.py`), played now and then at the animals (`world._hamlet_step`), heard only nearby.
- Tests: `river_test` checks that every station, heap, seam, the rubble, the ore and the bonfire can be walked to from the landing (56). All suites and co-op pass.

## Version 7.15: the dead's colours, the raft site, the test copy (build counter 22)

- **The dead** (`dead.gd`, `models.gd`): their flesh is corpse-grey again (the greenish skin colours in the dead's models, 0x8bab86 and nine others, swapped for greys and browns; the eyes still glow). The edge glow (`_evil`) is far fainter and only at the very edges (fresnel power 5, ×0.2, from power 2.4, ×0.5, which on flat-faced boxes turned whole sides green). And each of the dead but the bosses, bats, wraiths and shadows has a soft green light on the ground about it (`_aura`, one MultiMesh of flat quads, additive, fading out from the middle; gone in a heap, rising with it).
- **The raft site** (`world._riverside`, the village bank): a sandy slipway with planks and trestles, stakes with rope, a sign facing the village, a red flag on a tall pole that stirs (`_raft_flag`); a label (`labels.gd`, "Build the raft here: n of 100 wood", then "The raft: across to the Riverside"); and a red mark on the map (brown once built).
- **The test copy** (`scripts/dev.gd`, class `Dev`): on when the game file's name has "test" in it (not "godot…") or `DTV_DEV` is set. The release now publishes `Thornhallow-Test.exe` (a copy of `Thornhallow.exe`; it updates itself like the other). It saves to `user://dtv-save-test.json`. `Dev.step` (on the host, every moment) keeps every player's materials at their most, 40 gold, three of each potion and three fire rocks, and, with `Dev.safe`, unhurt. The handbook gets a Developer tab (`menus.dev_page`, only in the test copy, in a game, and not for a joined player): go to the morning of any day (`Rules.dev_day`) or straight to its dusk, with the boss and moon for that night shown; dusk now; clear the dead; end the night; always full and cannot be hurt; every book (but the callings) at rank 1, 4, 7 or 10, or none; a priest or a jester at rank X; every relic, the relic boots and a set of rune arms and armour on the rack (`Dev.rack`); the raft and the Rune Cave built; to the Riverside and home; a sheep.
- Tests: all suites and co-op pass.

## Version 7.16: things underfoot, and moles (build counter 23)

- **Ground detail** (`world._ground_detail`): shared meshes drawn many times each (`_multi`), with nothing to bump into. Over the main map (in bounds, off the roads, the farm, the castle hill, the mill and anything built; in the village only three in ten, and not on its main street) and across the river (fewer, a third as many; fewer again inside the hamlet's fence; not on the road, the fields or anything with a collider): about 1,700 clumps of three grass tufts, 650 pebbles, 380 little clumps of one colour of flower, 140 round patches of bare earth, 150 small bushes; and 110 groups of toadstools, red or brown, beside trees in the forest to the west.
- **Mole hills** (`R.moles`, `D.MOLES`): seven each morning on the main map (outside the village, off the roads, the farm, the castle hill, colliders and trees) and three across the river (outside the hamlet, off the road and the colliders), made in `roll_day` (`make_moles`). `moles_step`: a player who comes within 1.6 of a hill in the same place gets 3 to 12 pence, once a day per hill (event `mole`). Sent to joined games (`mo`). Drawn by `world.set_moles` (a mound of earth with clods; flattened once it has popped) and `mole_pop` (a mole with a pink nose and hands rises, looks about and goes down, 1.8 s), with a puff of earth and coins.
- Tests: new `mole_test` (8). All suites and co-op pass.

## Version 7.17: fish, and the posse's cook (build counter 24)

From Matt's play: Field, Hook and Pot did not add much (food is never short, and anyone can eat). He chose: fish to heal at once, and the angler's and the cook's ideas folded into the book's existing ranks.

- **Fish** are their own resource (`p.fish`; `D.GATHER.fish.res`, `D.RES`, `D.STORE_RES`, `RES_NAME`, the scroll, saved, sent, the storehouse). Fishing gives fish, not food. `Rules.eat_fish` (the action bar's `fish`, sent as `efish`): back to full health and unfrozen; then `p.fishCd` (`D.FISH.wait` 20 s, 12 s from rank IX); not eaten at full health (unless rank X has someone near to heal). The market buys fish at 2d (4d from rank V) and sells none.
- **Field, Hook and Pot**, new rank texts and what they add: I the posse's cook (`posse_cook`, from `peasant_step`: at night a villager of yours below half health eats one of your food and mends by your `meal_hp`, then waits `D.FISH.cook` 8 s; nerve too from rank VII); III the river's finds twice as often; V fish sell double; VI the posse eats below three quarters; VIII a prize fish one catch in ten (12d on the spot); IX the shorter wait; X a fish heals every player within 7 and your posse as well. The rest (faster fishing and foraging, meals 35/50/65/80, catches of 7 and 9, the posse healed by your meals, cheaper slum recruits, cures, twenty more health until dawn) is as it was. It is learned by fishing, foraging and feeding the posse.
- Handbook ("Fishing, and the farms") rewritten. Tests: new `fish_test` (16); `relics_test` counts fish. All suites and co-op pass.

## Version 7.18: boots, dogs, the Dog Lead, blessed armour (build counter 25)

Fixes from Matt's play.

- **Boots** were drawn with the rest of the gear on the body, so they stood still while the legs swung. Now each boot (`boot` mesh) is put on its own leg (`figure._boots`), and walks with it.
- **The dog walked backwards:** the figure turns to face the dog's way, and `_dog_show` turned the dog's model by the same angle again inside it. It no longer does. **Circling:** `dog_step` now waits until its place at the player's side is 1.6 away before it sets off (and goes on until within 0.35, `q.dmv`), and standing it turns to face the way its player faces; each dog's side comes from the order its player got them (by id), not from its place in the list of peasants, which changed and swapped them about.
- **Saint Wilbur's Dog Lead** had the bucket's model. It has its own (`lead`: a coil of leather and a brass clip at the hip); while it is carried a leather strap is drawn from the player's hand to each dog's collar, sagging a little (`main._leads_view`, seven short pieces, let go of beyond nine paces); and every dog now has a collar (`dog_collar`), red, or gold and faintly glowing on a dog led by the Lead.
- **Blessed rune armour:** a little paler blue; its own golden emission that swells and fades (`figure._blessed`), a soft golden halo and a small warm light about the wearer, and motes of holy light rising off them. `glow_of` gives blessed things gold.
- All suites and co-op pass.

## Version 7.19: banners in the wind, the Tithe Collector, the ground (build counter 26)

- **Banners ripple.** The `banner` model is now only the pole and its gold knob; the cloth is its own model, `banner_flag` (eight upright strips and a swallowtail), drawn with a small shader (`figure._flag_shader`) that waves it along its length, more towards the free end, and droops it a little. Each figure's flag starts at a different point in the wave, and it flaps harder when its owner is moving (`gust`). The pole is now wood-coloured; the flag carries the player's colour.
- **The Tithe Collector** hits for 50 (was 40).
- **Ground detail** cut by a quarter: grass tufts 1275, pebbles 490, flowers 285, earth patches 105, bushes 112, toadstool groups 82.
- All suites and co-op pass.

## Version 7.20: halos, building in loads, the posse sent home, and small mends (build counter 27)

From Matt's play.

- **Blessed rune armour** back to the rune blue (tint [0.85, 1.05, 1.7]), steady like other rune armour; no more pulsing golden emission, which washed it out white. Instead, wearing any blessed piece (helm, top or shield) puts a ring over the head (`figure._holy_halo`, a torus like the priest's, at 2.08), whose colour breathes slowly between gold and white, with a small warm light and the odd mote. `glow_of` no longer gives blessed things gold.
- **Building in loads.** Every foundation, tower site and side gate keeps what has been put into it (`Struct.dep`, saved, and sent to clients as the 17th field of a struct). Holding {interact} there puts in whatever you carry that it still wants (`still_owed`, `can_put`, `found_label`); anybody can add; once nothing is owed it is built, as before. Knocked down, it starts from nothing. The tower's 25 wood was more than a peasant can carry (20).
- **The posse sent home, or whistled for.** The Posse slot on the bar can be clicked: a small menu, "Send them home to your cottage" (`posse_home`, net "phome") or "Whistle them to you" (`posse_whistle`, "pwhis"). Sent home (`Peasant.sent`), they hold at their leader's cottage door (`D.cottage(slot)`), fighting what comes, walking there round things (`walk_round`: straight on, and if blocked, of the open sidesteps the one ending nearest). A whistle, or any order, brings back those on the same side of the river (`same_side`); one across the river is not heard. Those on the far bank with you are not sent home (the raft does not run errands). They stay your posse throughout. A whistle sound (`sfx_whistle`).
- **Saint Wilbur's Dog Lead** has an icon (`lead`: a coil and a clip).
- **Long item names** fit their cards: "the " dropped from names over 24 letters, smaller type for long names, a smaller picture for very long ones.
- **Riding a sheep**: the rider's legs sit forward either side of the fleece and no longer walk; a small jog instead of the walking bob (`figure._riding`).
- New `loads_test` (20). All suites and co-op pass.

## Version 7.21: the caves across the river, the Old Mine, the Riverside's river (build counter 28)

From Matt's play.

- **Two caves to walk into.** `D.ROOMS` has `tcave` (Garrick's Cave, at -40, 240) and `rcave` (the Rune Cave, at -80, 240): small rooms built far off like the Old Mine, entered from their hill's mouth at the Riverside (`door`), with `parent: "riverside"`: leaving one puts you back at the Riverside by its mouth, not home (`leave_room`), and dawn still brings everyone home. `Rules.far_bank(p)` counts the caves as the far bank (the whistle uses it). The posse waits outside the mouth (`wait`); a swimmer's posse, this side, waits by the raft. The main map's doors skip rooms with a parent.
- **Garrick's Cave**: the rubble heap (`TITHE_RUBBLE` now inside), the day's ore beside it, a boulder, a broken shovel, two wall torches (`_cave_torch`, always lit). Garrick stands at the mouth (his notice moved there).
- **The Rune Cave**: the three seams (`RUNE_SEAMS`) along its back wall, three torches, a statue of Saint Wilbur, the Dog Lord, with his dog and a halo, a prop, and a little heap of gold glinting over a rock in the corner where nobody can reach it (`_twinkle`). Its mouth is boarded (`_rcave_boards`) until a shady fellow (the `rcave` station, moved beside the mouth, hooded, leaning on a post) is given the 20 wood. The cave's door says so until then.
- Cave lighting in `main.gd` (dark, warm ambient, torches); figures carry their own light in them as in the mine. The minimap shows someone in a cave at the raft.
- **The Old Mine**: "the old workings" renamed everywhere it is not history (the room, its sign, the handbook, the smith's lines, Hammer and Tongs). The hole by the steel mine glows faintly purple and breathes (`_mine_glow`). "The Rune Cave: runes" is now just "The Rune Cave".
- **The Riverside's river**: the countryside's ground box reached right over the river, so only a thin strip showed. It now stops at the bank; the near bank's sand is raised above the grass.
- **Banners**: the wave's speed no longer changes with the wind (that jolted it whenever you stopped); only its size does.
- `river_test` (62) now goes in and out of the caves, checks the boarded door, reaches everything inside each cave, and the posse waiting outside. All suites and co-op pass.

## Version 7.22: tower crews, dogs across the river, the stranger's table (build counter 29)

From Matt's play.

- **Tower crews.** Sent up a watch tower (`tup`, or `post` for the old platform), a peasant now goes straight there and stays, day or night, until coaxed down; only a tower nobody has seen to today sends its crew back to their leader. The walk there uses `way_to` and `walk_round`, so they no longer catch on houses (it took half a minute from the market). Hired swords (kind 2) can be sent too, and the notice counts them as free. In testing a kitted peasant went up the same as any; the trouble was the dusk-only climb and the slow walk, and hired swords not counting.
- **Dogs across the river.** `dog_step`: if its player has crossed on the raft (or the dog is already over), the dog goes too (teleported over at the crossing, as the posse is), waits at a cave's `wait` spot while its player is inside, and comes back on the raft. A dog left over there when its player swims back stays put.
- **The stranger** in the Thorny Rose had been drawn inside the barrels behind the bar. He now has his own small table, with his drink and a candle stub, and a chair, in the front corner by the door (the room's box, his notice and his sign moved with him).
- Tests: `river_test` (67) takes two dogs across, into a cave's mouth and home; `tower_test` (35) sends a hired sword up, and counts the side-gate share over 90 seconds instead of 40 (it was on a knife-edge). All suites and co-op pass.

## Version 7.23: relic boots in three colours, the Bailiff's back door (build counter 30)

From Matt's play.

- **Relic boots.** All three glowed the same relic gold (`glow_of` gave every relic gold unless it was bluish), so they looked alike, and swapping one pair for another hardly changed anything you could see; their icons were the same gold too. Each now has a darker tint and a `glow` of its own: Brother Fleet's deep green, the Sandals of the Extremely Devout deep blue, Brother Cinder's deep red. The boots' emission is that colour at a lower strength (0.45), so it reads as colour rather than white; a small light at the feet casts it on the ground (`figure._feet_light`); `Look.icon` draws them in their colour instead of relic gold.
- **Robert Bailiff's back door**: there was a notice for it, a sign and a knock, but no door on the back wall of his house. Now there is: frame, planks, iron hinges, knocker, lintel and step.
- All suites and co-op pass.

## Version 7.24: balance pass, haunted hilltop, villagers' variety, see-through player (build counter 31)

Before the test groups. Agreed with Matt as a set.

- **Balance.**
  - Blow from the dark (`hit_u`): only when the player is outside the wall or the lantern is shut, never a boss, x2 (rank V) / x3 (rank X). It had applied to every first blow on every undead, x3/x5, which a sweeping weapon spread across the front row.
  - Armour: `gear_cut` never below `D.ARMOUR_FLOOR` 0.35 (65% off at most; full rune with the books was 78%, 85% praying). Vicar's Breastplate cut 0.4 to 0.3.
  - Fish: heal `D.FISH.heal` 60, fully at rank X; wait 30 s (20 at IX).
  - Holy: 1.35 (1.6 at relic rank V), was 1.5/1.9, in `src_of`, the Thunderer's chain and the blessed handbell. Charge 1.35 / 1.6 at Ledger VII (was 1.6 / 2). Burning (fire IX) and held (dog VI) no longer multiply together: a quarter more, whichever.
  - Silvered Sword cd 0.42 (was 0.34). Warhammer base 52 (was 45), so every tier up about a sixth. `cap` stops at 50; Woodcutter VIII is now the posse gathering a quarter faster.
  - New `balance_test` (11).
- **Towers** back to climbing at dusk (7.22 had them go straight up; Matt had forgotten the morning upkeep). The walk round obstacles and hired swords are kept. `tower_test` as before.
- **Posse card**: the Posse slot now opens a parchment card with the theme's buttons (`hud.posse_menu`) instead of a system `PopupMenu`; it closes on a choice, a second click, Esc, or after eight seconds. "Send home" from your own doorstep, and "whistle" with nobody away, now say so; that was the "first time it does nothing" report (tested with real simulated clicks: the commands themselves worked).
- **The castle hilltop** (`world._hilltop`): grey turf, a ruined curtain wall in a ring with a gateway and skull-topped gateposts, the Lord's graveyard (twelve leaning stones, railings, a mausoleum with a green light), a dry fountain with glowing green water, gargoyles and green-flame lanterns up the road, dead trees with crows round the back, stacked and standing coffins, bones, a faint mist. The hill's sides are duller.
- **Villagers** (`figure.peasant`): the straw hat is no longer part of the head for non-players (`torso_bare`, `tunic_bare`); each villager gets a hat or hair from ten (`HATS`: straw, cap, hood, headscarf, felt, bald fringe, mop, ginger), a skin tone (`SKINS`) and an unowned tunic colour (`TUNICS`) from their name; a posse's tunics vary a little in shade of their leader's colour. A helmet replaces the hat.
- **See-through player**: players' materials use Godot's stencil X-ray (`STENCIL_MODE_XRAY`), so behind a roof or a tree you show as a pale shape, and not through yourself.
- **Small touches**: running dust, swimming splashes, a puff when a dog bites; the Out signs moved to the side of each doorway.
- All 32 suites and co-op pass.

## Version 7.25: lights and lanterns, and the texts brought up to date (build counter 32)

From a review with Matt (his own look at the north wall's dashed foundations is pending).

- **Lights.** Windows: albedo to amber `e8953e` and emission `ff9a3c` at 1.5 (it was a pale cream at 2.6, which went white). `world.lantern()` is an iron-framed lantern with warm glass instead of a plain glowing box. The north-gate braziers have flames (`_brazier_fire`, flickering). Eight `_lantern_post`s along the north road, the west-east road, by the side gates and by the cottages. Interior lamps in the inn and at the Riverside warmed too.
- **Texts**, checked by a read-through of every rank, relic note and handbook page against the code (`menus.gd` GUIDE, `data.gd` books, lore lines and the talk, `main.gd` messages): the fish banner; the night watchman's numbers and conditions (handbook and rank V); the smithy's rune tab; the lobby's late joining; the outer ruins' places; contraptions on the wheel (and the unused `_next_contraption` removed); the Scythe (you a quarter faster, not your posse); Tam on mithril and runes; the stranger's boss nights; "(up to rank VII)" on the eleven books whose per-rank bonus stops there, and the fire book's burn time; armour's 65% in Hammer V and VIII and the handbook; relic book VII (the Previous Tenant) and VIII (relic weapons and armour); the Helm (the howl); the Dog Lead; hobnailed boots; wraiths and mithril/rune. Carrying limits in the handbook.
- Removed: the watch platform's picture hook, `MOON_NAME`, `SKINDS`, `FORGE_A`, none used.
- Not changed, noted for Matt: Prospero's Marotte duplicates Jester X; Dogs VIII duplicates Relics II; the Dog Lead's second dog never holds, and That One only sends the first.
- All 32 suites and co-op pass.

## Version 7.26: the country beyond the edges (build counter 33)

- `world._wilds()`: everything outside the playable ground, in batches (`_multi`), from new vertex-coloured shapes in `models.gd` (`wild_pine`, `wild_oak`, `wild_dead`, `wild_bush`, `wild_rock`, `wild_tuft`, `wild_flowers`, `wild_cottage`, `wild_barn`, `wild_hay`), each instance tinted a little differently. A `clear` test keeps all of it off the main map (and 3-4 paces round it), its river, the Riverside and its own fields, and the road south to Hallowshire Town.
- The west and east thorn hedge: bushes of mixed sizes in a ragged double row (the row of `Build.box` hedge blocks is gone). Woods behind it, thickest nearest the hedge, out to about 80 paces; dead trees where the dead ground runs.
- The river's far bank: fourteen fields with hedgerows and haystacks, about 2,600 tufts, flowers and small bushes, worn patches, reeds along the bank, 420 trees, rocks, and three farmsteads (cottage, barn, hay).
- Beyond the castle: the dead ground carries on to z -467; 700 dead trees; a ridge of 34 grey hills on the horizon.
- The Riverside: one ground colour under all of it, and about 4,200 tries at woods round it, open at first and thick further out, with the road south left clear; woods on the far side of its river too.
- All suites and co-op pass.

## Version 7.27: wind, crows, things in the dark, the roads out (build counter 34)

- **Wind**: `world._multi` takes `sway` and `base`; with sway it uses a small shader (`SWAY_SHADER`) that moves each vertex by its height above the instance's foot, with a breeze whose phase rolls across the land and a slow gust. Used for the wild pines, oaks, dead trees, bushes, tufts and flowers, and the main map's grass tufts.
- **Crows** (`_crows_step`): every 18-40 s by day, a flock of seven lifts out of somewhere outside the walls, 16-32 paces from the view and ahead of or beside it (the view looks north), rises, circles about nine seconds, and flies off; a caw when they go up. `world.view_at` is the view's focus, set by `main.gd`. `DTV_CROWS` holds a flock mid-circle, for pictures.
- **Eyes and wisps** (`_haunts_step`): at night (`night` > 0.45), on the dead ground beyond the north wall within 10-34 paces of the view: six pairs of red or green eyes that open for a few seconds, blink, close, and open somewhere else; three will-o'-the-wisps, pale glowing lights that drift and bob, with a faint light of their own.
- **Roads**: the west and east roads run on from 46 to about 246 paces, with cart ruts and stones, through a gap in the hedge and a lane through the woods (`clear` keeps 4 paces either side), with a milestone just past the hedge. The ground detail keeps off the whole length.
- All suites and co-op pass.

## Version 7.28: the weather has a wind (build counter 35)

- **Wind by weather** (`main.gd`): clear 1.0, overcast 1.5, rain 2.8, fog 0.3, snow 0.9, moon 1.0, eased towards at 0.35 a second, and handed to `world.set_wind` (every sway material's `wind`), `Figure.wind` (banners' gust), `atmos.wind` and `Sound.wind`.
- **Sway shader**: amount scales with the wind; above 1.2 the wind also bends things over downwind and adds a fast thrash, and the breeze itself quickens.
- **Storms** (`atmos.gd`): the rain slants more the harder it blows; splashes on the ground round the view (`_make_splash`); leaves and bits blowing past when the wind is over 1.8 (`_make_leaves`); snow drifts with the wind; rain's gloom 0.66 (was 0.55). Lightning in rain by day as well as at night: every 10-28 s a visible fork (`_fork`, a jagged run of bright pieces) somewhere 35-70 paces off, ahead or to the side, with the flash and thunder.
- **Sound**: a storm-wind loop (`amb_wind`, from `tools/make_sounds.py storm_wind()`, a gusting roar and a whistle that slides with the gusts), faded in with the wind above 1.2.
- `DTV_WEATHER=rain` forces the weather and a bolt, for pictures.
- All suites and co-op pass.

## Version 7.29: townsfolk (build counter 36)

- `scripts/view/folk.gd` (added by `main.gd` as `folk`): seven townsfolk, not in the rules. Each day's plan for each is worked out from the day number (seeded), and where they are from the day's clock (`DAY_LEN - timeLeft`, which co-op already sends), so every player sees the same without anything new on the network.
- Ways: a 1-pace grid over the village and round it, the buildings and walls blocked (from `Map.colliders()`, with a little room), one walk out from the keep's door to everywhere, and each path pulled straight where the line is clear.
- Their day: out from the keep's door to a place and back, again and again; each has a favourite (the farm, the mill, fishing from the bank at three spots, a standing tree at the edge of the west wood, the market, square and notice board, the Rose, the library and smithy). At the farm they stoop to work; at a tree they swing at it, with the sound; fishing they face the river; at the Rose they are inside, out of sight.
- At dusk they run (6.5 a second) back along the way they came to the keep's door, and are gone until morning; the furthest is home in under 17 of dusk's 20 seconds. At night, and when you are indoors, nobody is about.
- Hello: come within about three paces and one says something (a bubble, `labels.bark_at`), from a list of seventeen, at most once in 25 seconds each.
- They look like the rest of the village (`Figure.peasant` with a peasant record that is never in the rules), with their own hats and tunics.
- New `folk_test` (5). All 33 suites and co-op pass.

## Version 7.30: the Knight's Squire (build counter 37)

- **The library is a room** (`D.ROOMS.library`, at 110, 240; door 14.0, 20.4, and a new `exit` field, 13.0, 20.4, for doors that do not face south; `day`: shut at night, and anyone inside is shown out when night falls, `start_night`). Stations inside: `library` (the Peasants' Section: the book notice, now titled so), `librarian`, `knight` (Sir Aldous), `rope`. A rope collider across the room at z 239 keeps peasants out of the rest of the library. `D.STATIONS[6]` (the priest, by number) was used in two places: now `D.station("priest")`.
- **The lane and the clearing**: `D.ROOMS.woods` (open, at 130, 420; door at the west hedge, -122.4, 2.0; `face` for which way you face coming in), thickets either side of the lane as colliders. `D.ROOMS.cabin` (parent `woods`), entered from the clearing: rooms with a parent other than the Riverside now have their doors offered inside the parent (`room_interact`). Stations: `sqnote`, `sqtrail`, `sqsign`; `paint0`-`paint2` and `sqchest` in the cabin.
- **The errand** (`Player.sq`: 0 a sword wanted, 1 the notebook wanted, 2 notebook in hand, 3 read; saved and sent). `Rules.sq_want(p)` = (slot + seed) mod 4, a tier of short sword: crude, iron, steel, mithril. `sqsword` (arg `w` or `i<n>`): the wrong tier is handed back with a hint (finer, or humbler), the right one kept; a rune sword is confiscated with the speech; the Silvered Sword is refused. `sqsay` holds what he said last, for his notice. The lock: `Rules.sq_code(seed)`, three counts of 2-9, painted in the cabin (`squire.gd set_code`); `sqdial` (`0+`, `2-`) and `sqopen`. `sqbook`: rank I, and a crude greatsword.
- **Book 16, the Knight's Squire** (`D.B_SQUIRE`, base 40; learned by greatsword blows, a point each, and Challenges, three). `D.FREE_BOOKS` = [10, 15, 16]: not counted by `book_slots`, and taken without a slot. The Jester's first lesson no longer needs one. Books and xp arrays are 17 long.
- **Greatswords** (items 104-109: iron, crude, chipped, steel, mithril, rune; `two: true`, need rank I, trick Parry; iron 34 damage, 0.85 s, reach 2.5, arc 0, knock-back 0.6, heavy) and the relic, Sir Aldous's Grandfather's Greatsword (110: holy, 44, 0.9 s, reach 2.7, arc -0.15, knock-back 1.4). `wear` puts the shield away for a greatsword and the greatsword away for a shield; `wears_now` agrees. The smithy forges them from rank III (`can_forge`, `forge_why`, both smithy lists).
- **Challenge!** (`POWERS[16]`, 25 s): the undead with the most health within 10 paces (bosses from rank IX, for half as long) gets `chal`/`chalby` and is taunted for 8 s; `hit_u` makes it take 1.2x from the challenger, or from everybody if the challenger wears the relic with the book. A gold mark over it (`main._chal`).
- **Ranks**: II nerve loss x0.7 near you (8 paces); IV greatsword arc -0.3; V Second Wind (below a quarter, a third back, once a night, `swind` reset at dusk); VI `price_for` x0.9 at the merchants; VII `sqx`, set by a parry or a brace block, doubles the next blow; VIII posse x1.1 near you; X posse +1, players within 8 take x0.9, and the dubbing (`sqdub`, `kn` 1 Sir / 2 Dame; `knight_name` is used for the name after loading and after a death).
- **View** (`scripts/view/squire.gd`, added by `world.gd`): the library (bookcases full of books as one multimesh, the red carpet, a ladder, a globe, a lectern, a chandelier, Sir Aldous at his desk with his helm, sword and shield, the librarian and her desk, the rope and its sign, the Peasants' Section on bricks with its sign, a reading table, candles that flicker); the lane, woods and clearing (the cabin with a shield over the door and a pennant, the empty stable and saddle, a hacked dummy, the weapon rack with gaps, the cold fire, the woodpile, the washing, a trail of boot, gauntlet and helmet, hoofprints, the sign); the cabin inside (the paintings, beds, chest with dials, hearth, table, empty armour stand); and a fingerpost by the west road. Greatsword model (`great`), held in both hands; icons `great` and `challenge`. Library and cabin lighting in `main.gd`.
- New `squire_test` (60). All 34 suites and co-op pass.

## Version 7.31: the road, the trees, the Old Mine (build counter 38)

- **Roads**: `Map.trees()` moves any tree standing in the west or east road beyond the village (|x| ≥ 50, within 4.6 of the road's middle) out to its verge, the side it was nearer, and turns its sapling spot off the road. Same trees in the same order, so saves keep their stumps. 46 had been in the road.
- **The village's trees sway**: `world.sway_mat(amount)` makes a sway material that follows `set_wind`; `trees.gd sway(world)` puts it on the pine and round multimeshes (not the stumps).
- **The Old Mine's way down** (`world._mine_room`, at the door): it was a roof on four posts over a purple square. Now a round shaft in a collar of stones with the purple glow down it, a headframe of two A-frames with a beam, winding wheel, rope, bucket and winch handle, the ladder's top, a spoil heap, rails and a mine cart of rubble with a glowing lump, a lantern on a post (lit with the village's lanterns), and a sign.
- **No X-ray**: the player figure no longer draws through what is in front of it (the call to `_xray` in `figure.player` is gone).
- **Underground sound**: `Sound.under` (main: in the mine or either cave across the river) fades out the day, night, rain, wind, castle and above-ground music, stops the owl, the crows and thunder, and fades in `amb_cave` (drips with echo, a rumble, pebbles, creaking timber) and `music_mine` (a low E drone, a glass-like bell a few notes far apart, soft bowed chords, a distant pick tapping), both from `tools/make_sounds.py underground()` (`python3 tools/make_sounds.py amb_cave`).
- All 34 suites and co-op pass.

## Version 7.32: the posse, the torch, the caves (build counter 39)

- **Posse home**: driven for real (a mouse click on the card's button, in a window), it works: the posse is marked sent and walks home. Three things fixed round it. `posse_home`/`posse_whistle` messages are a new `posse` event, a banner titled "Your posse" (they were "found" events, titled "You found", and the main one was only in the log). The card is `move_to_front()` and `z_index` 10 when opened. And a covering window closing (`hud._process`: every zone made visible again) no longer turns the card back on by itself.
- **Torch flame** (`figure.gd`): the cones are gone from the `torch` model; a lit torch gets `_flame` on the hand, seven unshaded additive tongues (deep orange to near white) that each leap and die back on their own beat, sway, lean back as you move, and are kept upright.
- **Trees in the caves**: the woods on the far side of the Riverside's river (`_wilds`) covered the cave rooms at -40 and -80, 240. `clear()` now keeps 14 paces round every room but the Riverside; the Riverside's own ring of woods checks it too.
- All 34 suites and co-op pass.

## Version 7.33: the Lord, as he should look (build counter 40)

- From Matt's asset sheet ("The Lord: game asset reference"). `models.gd`: the Lord's parts are now static builders drawn at an offset (`lord_body`, `lord_cloak`, `lord_arm`, `lord_goblet`), so the whole (`lord`) and the pieces are the same. Pale square face, red glowing eyes (`lord_eyes`, unlit), frowning brows, a thin mouth and two teeth, black hair at the sides and back, top hat with gold band and red ribbon, a stand-up collar black outside and red inside wrapping round the head, black tailcoat with tails and lapels, red waistcoat with gold buttons, white cravat, gold jabot with a red stone, cuffs, pale hands, a cloak black outside and red inside that comes forward round his sides, and a gold goblet of something red.
- `Models.lord_figure()`: a moving figure (body and eyes, and "Cloak", "ArmL", "ArmR" on pivots, the goblet on a "Goblet" node at the hand). `Models.keep_goblet` keeps the goblet upright however the arm swings. `dead.gd` uses it for the Lord on the field (idle: goblet held up, raised now and then).
- The castle (`world.gd`): a small balcony under the one lit window, and the Lord on it (0.62 scale) from day one, turning a little; in the last week (evil level 3) a full-size Lord on the wall over the gate, behind the merlons, turning and raising his goblet. `world.set_lord_out` (main, from the undead list) hides both while he is on the field.
- The Lord's shadow has his hat and collar.
- All 34 suites and co-op pass.

## Version 7.34: one Lord (build counter 41)

- In the last week both castle figures showed (the window and the wall), so the dusk look up at the castle had two Lords. `world.set_lord_out` and `set_evil` now show the window Lord only before the last week, and the wall Lord only in it; neither while he is on the field.

## Version 7.35: more ore for a bigger village (build counter 42)

- `Rules.ore_extra()` = floor((players - 3) / 2), never below 0: 1 with five or six players, 2 with seven or eight. Each morning's refill gives every vein of the Old Mine `RUNE_PER_VEIN + ore_extra()` mithril and every seam of the Rune Cave `RUNE_PER_SEAM + ore_extra()` runes (so 6 a day each up to four players, 9 with five or six, 12 with seven or eight). Garrick's one piece of ore a day is unchanged.
- The handbook and the shady fellow's notice say so. New check in `balance_test`. All suites and co-op pass.

## Version 7.36: the bosses, with company (build counter 43)

- `D.BOSS_N` = {hp 0.35, pace 0.07, reach 0.04} for each player past the first. Boss health ×(1 + 0.35(n−1)) (was 0.5: eight players 3.45×, was 4.5×). `Rules.bpace()` = 1/(1 + 0.07(n−1)) multiplies every trick's wait; `breach()` = 1 + 0.04(n−1) its reach; `bmore(k)` = floor((n−1)/k); `_some(near, n)` picks different players.
- Steward: slam wait and reach; lamp-bearers (skeletons) at his side, `bmore(2)`. Chaplain: sermon wait, reach and mending reach. Cook: ladle wait and reach, pools at 1 + `bmore(3)` different players at once; cauldron swing wait and reach. Coachman: stampede wait; with 5+, `bmore(3)` pallbearers off the back at each stampede. Captain: charge wait; with 5+, every other guard to a second gate. Gamekeeper: howl wait and reach; a hound for every two players. Shadow: blink, raise and lob waits. Lord: gap, blink and lob waits; lobs at 1 + `bmore(3)` players; sweep, slam reach and sweep width (`lord_half`, +5% a player, at most 0.6π).
- Handbook ("Playing together") says how it all scales. New `bossn_test` (8); `month_test`'s Steward health check follows `BOSS_N`. All 35 suites and co-op pass.
