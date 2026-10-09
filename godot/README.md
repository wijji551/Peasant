# Defend the Village! in Godot

The game is moving from the web version (https://wijji551.github.io/Peasant/) to Godot 4.7. The web version stays playable at that link, but is no longer being updated: everything new happens here.

## Running it

Open this folder's `project.godot` in Godot 4.7 (it is the "Peasant Defence" project) and press **F5**.

Everything is built in code when the game starts, so the scene in the editor looks empty. That is expected: `main.tscn` is one node with `scripts/main.gd` on it.

It opens on a home screen: your name and colour, **Carry on** from the saved morning, or **New village**, and what is new. The game saves itself every morning.

## Where the move has got to

1. **The rules: done.** Everything the web version's rules do now runs in Godot, with the same numbers: days, dusk and nights, the continuous stream of the dead, gathering, the moving outcrop, mine and fishing, tree regrowth, building and repairs, barricade rot, stone facings and iron bands, the ten books with seven ranks, weapons and their tricks, armour, the pack and the arms rack, the forge, the market, the slum, the Thorny Rose and Dutch courage, the priest and holy studies, blessings, the ruins and relics, the posse with its nerve and orders, the toilet break, the slop bucket and the handbell, the Steward, deaths and relatives, and saving.
2. **The map and models: done.** Every model from the web version, copied shape for shape: peasants and their gear, the four kinds of the dead, every defence, the moving outcrop, mine and jetty, the outer ruins falling down differently every night, trees that topple and grow back, the priest. The keep goes see-through when something is behind it. The effects: chips, sparks, splashes, bones, coins, arrows and stones in flight, rings for the big tricks, the gate opening for friends, defences popping up and shuddering, health bars. The map in the corner, the signs over places, and other players' names.
3. **Menus and readouts: done.** Every notice, your pack, the dawn, the handbook and the end of the week open in one window in the middle, framed by the web version's scroll, so nothing sits on anything else; Esc or the cross closes it. The readouts have fixed places round the edge (see the handbook's "Reading the screen"). The pack is slots with pictures. The handbook has the guide, the controls (change any key) and options, and the game waits while it is open. The home screen has the change log.
   Since then, the look of the place: medieval lettering (Pirata One and IM Fell English, in `fonts/`, free to use), parchment on every card and button, pictures for each resource, the Backpack, a Skills window (K) with each book as a ladder of ranks (spare learning past rank VII sells for coin), a bigger window, Bailiff's House and the Thorny Rose Inn, a proper chapel and priest, real haybales, outer ruins that move to a new clearing every night and stay off the map until found, and weather: night mist, rain, grey and misty days, chimney smoke, and a haunted Ashhollow (dead trees, a gibbet, green fires, wisps, crows, lightning). Anti-aliasing is on.
4. **Sound: done.** Every effect from the web version, made again, and new ones; ambience (birds and breeze, crickets and wind, rain, the castle's drone); a tune for the day and one for the night. Effects, ambience and music each have a volume in the options; M mutes. The sounds are files in `sounds/`, made by `tools/make_sounds.py` in the repository (`python3 tools/make_sounds.py` makes them again), so they can be tuned.
5. **Co-op: done.** Up to eight players. One hosts from the home screen and reads out the village code; the others type it into Join. The host's game runs the rules for everyone and sends the result twelve times a second; each joined game sends what its player does, and walks its own player at once. Godot's own networking (ENet over UDP port 24565): the host's game asks the router to open the port by itself (UPnP), and the code is the host's address written as letters. If the router will not, the code for the same home network still works, or the host opens the port by hand.

   Better: a **village server** (`relay/` in the repository, with a step-by-step guide for a free Oracle Cloud machine). Everyone connects out to it, so no router needs to let anyone in; villages on it have five-letter codes. Set its address in the game's Options (or as `Net.DEFAULT_RELAY`). If it does not answer, hosting falls back to direct.

The move to Godot is finished, and so are the design doc's Build 4 and Build 5:

6. **Build 4, the month: done.** Thirty nights in four weeks (or the short game: the month squeezed into seven). Six more kinds of the dead (ghouls, gravediggers, bat swarms, the Lord's guard, wraiths, coffin rams), a boss at the end of each week (the Steward, the Coachman and his hearse, the Captain of the Guard, the Lord of Ashhollow), weather that matters, travelling merchants and their jobs, village guards and mercenaries for hire, six contraptions, the Holy Book (an apprentice priest: Smite and Pray), titles from what you have read, a fourth book, and relics that do more with the right book.
7. **Build 5, polish: done.** Robert Bailiff at his window (talk, knock, jeer), a village bell to ring, training dummies, peasants who talk, a smithy for everyone (crude, refined and steel), a land a third wider with an old steel mine and an old mill, a river that runs, a village green, half-timbered houses, the Lord's letters of complaint (brought by a headless rider), and a notice board with something on it. With many players, a horde too big to show comes as fewer, tougher dead.

What is left is play-testing: the numbers for weeks 2 to 4, and for more than four players, are first guesses (see `docs/build-log.md` in the repository).

## Controls

**W A S D** move (up the screen, whichever way the view is turned); press the **mouse wheel** in and drag, or hold **V** and move the mouse, to look around; roll the wheel to zoom; **,** and **.** turn the view and **N** puts it back; **Space** or left click attacks, **Shift** or right click is your weapon's trick, hold **E** to do things (gather, build, rally, search, open a place's notice), **F** eats, **I** opens your backpack, **K** your skills, **Z** and **C** are an apprentice priest's powers, **X** swaps weapon, **G** uses what you carry, **Q** gives orders, **T** is the toilet break, **Tab** or **1** to **5** picks something to place (5 steps through the contraptions), **R** says you are ready for the night, **Esc** closes things (or quits). In a notice, press the number or click.

## How it is laid out

- `scripts/rules/`: the rules, with nothing on screen. `data.gd` is the numbers, items and books; `map.gd` is what is solid, where the trees grow and how the ruins fall; `ents.gd` is the things that move; `rules.gd` is everything that happens.
- `scripts/main.gd`: runs the rules thirty times a second with the player's keys, and shows the result.
- `scripts/world.gd`: the fixed map, built from boxes, cylinders and cones.
- `scripts/view/`: the models (`models.gd`, built by `mesher.gd`), the peasants, the dead, the trees, the defences, the things that move each morning, the effects, and the weather and mood (`atmos.gd`: mist, rain, wisps, crows, lightning, smoke).
- `scripts/ui/`: the window and what goes in it (`window.gd`, `menus.gd`, `notices.gd`), the look (`look.gd`: parchment, the scroll, the pictures), the keys and settings, the map in the corner, and the signs and names over the world.
- `scripts/hud.gd`: the readouts.
- `scripts/net/net.gd`: playing together: hosting, joining, the lobby, and what goes back and forth.
- `scripts/audio/sound.gd`: everything you hear. `Sound.play("chop", 1.0, Vector2(x, z))` plays an effect, quieter further from the camera.
- `tests/`: `rules_test.gd` (the web version's checks, and the skills and the wandering ruins), `month_test.gd`, `holy_test.gd`, `merchant_test.gd`, `contr_test.gd`, `village_test.gd`, `smithy_test.gd` and `letters_test.gd` (one for each stage of Builds 4 and 5), `ui_test.gd` (the menus and the sound, driven as a player would), `click_test.gd` (clicks the home screen and the game with the mouse; needs a window, not headless), `net_host.gd` and `net_client.gd` (co-op: run together by `net_test.sh`), `bot_week.gd` (a bot plays the whole week, or the month) and `balance.gd` (the same night fought by 1, 2, 4 and 8 players, to compare).

## Tests

Run from this folder, with Godot on the command line:

    godot --headless --path . -s res://tests/rules_test.gd
    godot --headless --path . -s res://tests/ui_test.gd
    godot --headless --path . -s res://tests/bot_week.gd
    godot --headless --path . -s res://tests/bot_week.gd -- walls
    godot --headless --path . -s res://tests/bot_week.gd -- month
    godot --headless --path . -s res://tests/balance.gd -- 1,7,14 1,2,4,8
    tests/net_test.sh godot          # co-op: a host and a friend, two copies of the game, on one computer
    tests/net_test.sh godot relay    # the same, through a village server run here too

Every check passes. The careful bot holds the first seven nights; the bot that only builds walls falls on night 3, as it does in the web version (night 2 to 4).

Tested in Godot 4.7.2 on Linux with the Compatibility renderer and a software graphics driver. Not yet seen on this project's own settings (Forward+ on Direct3D 12), where the lighting may come out brighter or darker.
