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
