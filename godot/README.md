# Defend the Village! in Godot

The game is moving from the web version (https://wijji551.github.io/Peasant/) to Godot 4.7. The web version stays playable at that link until this one has caught up.

## Running it

Open this folder's `project.godot` in Godot 4.7 (it is the "Peasant Defence" project) and press **F5**.

Everything is built in code when the game starts, so the scene in the editor looks empty. That is expected: `main.tscn` is one node with `scripts/main.gd` on it.

It opens on a home screen: your name and colour, **Carry on** from the saved morning, or **New village**, and what is new. The game saves itself every morning.

## Where the move has got to

1. **The rules: done.** Everything the web version's rules do now runs in Godot, with the same numbers: days, dusk and nights, the continuous stream of the dead, gathering, the moving outcrop, mine and fishing, tree regrowth, building and repairs, barricade rot, stone facings and iron bands, the ten books with seven ranks, weapons and their tricks, armour, the pack and the arms rack, the forge, the market, the slum, the Thorny Rose and Dutch courage, the priest and holy studies, blessings, the ruins and relics, the posse with its nerve and orders, the toilet break, the slop bucket and the handbell, the Steward, deaths and relatives, and saving.
2. **The map and models: done.** Every model from the web version, copied shape for shape: peasants and their gear, the four kinds of the dead, every defence, the moving outcrop, mine and jetty, the outer ruins falling down differently every night, trees that topple and grow back, the priest. The keep goes see-through when something is behind it. The effects: chips, sparks, splashes, bones, coins, arrows and stones in flight, rings for the big tricks, the gate opening for friends, defences popping up and shuddering, health bars. The map in the corner, the signs over places, and other players' names.
3. **Menus and readouts: done.** Every notice, your pack, the dawn, the handbook and the end of the week open in one window in the middle, framed by the web version's scroll, so nothing sits on anything else; Esc or the cross closes it. The readouts have fixed places round the edge (see the handbook's "Reading the screen"). The pack is slots with pictures. The handbook has the guide, the controls (change any key) and options, and the game waits while it is open. The home screen has the change log.
4. **Sound:** not started.
5. **Co-op:** not started. The rules are written so the host runs them and the others are sent the result, as in the web version.

## Controls

The same as the web version: **W A S D** move, **Space** or left click attacks, **Shift** or right click is your weapon's trick, hold **E** to do things (gather, build, rally, search, open a place's notice), **F** eats, **I** opens your pack, **X** swaps weapon, **G** uses what you carry, **Q** gives orders, **T** is the toilet break, **Tab** or **1** to **4** picks something to place, **R** says you are ready for the night, **Esc** closes things (or quits). In a notice, press the number or click.

## How it is laid out

- `scripts/rules/`: the rules, with nothing on screen. `data.gd` is the numbers, items and books; `map.gd` is what is solid, where the trees grow and how the ruins fall; `ents.gd` is the things that move; `rules.gd` is everything that happens.
- `scripts/main.gd`: runs the rules thirty times a second with the player's keys, and shows the result.
- `scripts/world.gd`: the fixed map, built from boxes, cylinders and cones.
- `scripts/view/`: the models (`models.gd`, built by `mesher.gd`), the peasants, the dead, the trees, the defences, the things that move each morning, and the effects.
- `scripts/ui/`: the window and what goes in it (`window.gd`, `menus.gd`, `notices.gd`), the look (`look.gd`: parchment, the scroll, the pictures), the keys and settings, the map in the corner, and the signs and names over the world.
- `scripts/hud.gd`: the readouts.
- `tests/`: `rules_test.gd` (107 checks, the same as the web version's), `ui_test.gd` (26 checks of the menus, driven as a player would), `click_test.gd` (clicks the home screen and the game with the mouse; needs a window, not headless) and `bot_week.gd` (a bot plays the whole week).

## Tests

Run from this folder, with Godot on the command line:

    godot --headless --path . -s res://tests/rules_test.gd
    godot --headless --path . -s res://tests/ui_test.gd
    godot --headless --path . -s res://tests/bot_week.gd
    godot --headless --path . -s res://tests/bot_week.gd -- walls

All 107 rule checks pass. The careful bot holds all seven nights; the bot that only builds walls falls on night 3, as it does in the web version (night 2 to 4).

Tested in Godot 4.7.2 on Linux with the Compatibility renderer and a software graphics driver. Not yet seen on this project's own settings (Forward+ on Direct3D 12), where the lighting may come out brighter or darker.
