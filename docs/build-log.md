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
