# Defend the Village! in Godot

The game is moving from the web version (https://wijji551.github.io/Peasant/) to Godot 4.7. The web version stays playable at that link until this one has caught up.

## Running it

Open this folder's `project.godot` in Godot 4.7 (it is the "Peasant Defence" project) and press **F5**.

Everything is built in code when the game starts, so the scene in the editor looks empty. That is expected: `main.tscn` is one node with `scripts/main.gd` on it.

The game saves itself every morning and carries on from there next time. Starting again from day 1 needs the save deleted for now (it lives in Godot's user folder as `dtv-save.json`); the home screen, with a New village button, comes with the menus stage.

## Where the move has got to

1. **The rules: done.** Everything the web version's rules do now runs in Godot, with the same numbers: days, dusk and nights, the continuous stream of the dead, gathering, the moving outcrop, mine and fishing, tree regrowth, building and repairs, barricade rot, stone facings and iron bands, the ten books with seven ranks, weapons and their tricks, armour, the pack and the arms rack, the forge, the market, the slum, the Thorny Rose and Dutch courage, the priest and holy studies, blessings, the ruins and relics, the posse with its nerve and orders, the toilet break, the slop bucket and the handbell, the Steward, deaths and relatives, and saving.
2. **The map and models: started.** The village from the trial, now with the moving outcrop, mine and jetty, the outer ruins falling down differently every night, the north wall's foundations and everything you build, trees that are felled and grow back, gear in the peasants' hands. Still to come: the see-through keep, proper effects, and nicer models for the dead.
3. **Menus and HUD: started.** The notices for every place and your pack work, as plain parchment boxes. Still to come: the scroll look, the slot inventory, the handbook, changing keys, the home screen and the change log.
4. **Sound:** not started.
5. **Co-op:** not started. The rules are written so the host runs them and the others are sent the result, as in the web version.

## Controls

The same as the web version: **W A S D** move, **Space** or left click attacks, **Shift** or right click is your weapon's trick, hold **E** to do things (gather, build, rally, search, open a place's notice), **F** eats, **I** opens your pack, **X** swaps weapon, **G** uses what you carry, **Q** gives orders, **T** is the toilet break, **Tab** or **1** to **4** picks something to place, **R** says you are ready for the night, **Esc** closes things (or quits). In a notice, press the number or click.

## How it is laid out

- `scripts/rules/`: the rules, with nothing on screen. `data.gd` is the numbers, items and books; `map.gd` is what is solid, where the trees grow and how the ruins fall; `ents.gd` is the things that move; `rules.gd` is everything that happens.
- `scripts/main.gd`: runs the rules thirty times a second with the player's keys, and shows the result.
- `scripts/world.gd`: the fixed map, built from boxes, cylinders and cones.
- `scripts/view/`: the peasants, the dead, the trees, the defences, and the things that move each morning.
- `scripts/ui/`: the notices, and the keys.
- `scripts/hud.gd`: the readouts.
- `tests/`: `rules_test.gd` (107 checks, the same as the web version's) and `bot_week.gd` (a bot plays the whole week).

## Tests

Run from this folder, with Godot on the command line:

    godot --headless --path . -s res://tests/rules_test.gd
    godot --headless --path . -s res://tests/bot_week.gd
    godot --headless --path . -s res://tests/bot_week.gd -- walls

All 107 rule checks pass. The careful bot holds all seven nights; the bot that only builds walls falls on night 3, as it does in the web version (night 2 to 4).

Tested in Godot 4.7.2 on Linux with the Compatibility renderer and a software graphics driver. Not yet seen on this project's own settings (Forward+ on Direct3D 12), where the lighting may come out brighter or darker.
