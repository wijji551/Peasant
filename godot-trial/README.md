# Peasant Defence: a Godot trial of Defend the Village!

This is a small trial, to see how the game looks and feels in Godot before deciding whether to move it there. The full game is the web version (https://wijji551.github.io/Peasant/).

## Running it

Open this folder's `project.godot` in Godot 4.7 (it is the "Peasant Defence" project) and press **F5**.

Everything is built in code when the game starts, so the scene in the editor looks empty. That is expected: `main.tscn` is one node with `scripts/main.gd` on it.

## Controls

- **W A S D** or the arrow keys: move
- **Space** or left click: attack with the pitchfork
- **R**: ready for the night (skips the rest of the day)
- **Esc**: stop

## What is in it

- The village of Thornhallow at the same measurements as the web version: keep, cottages, the Thorny Rose, smithy, chapel and old ruins, storehouse, library, market, slum, the wall and its three gateways, the forest, the farms, the graveyard and Ashhollow Castle.
- A peasant to walk about, with a posse of three who follow and fight.
- Day turning to dusk and night: the light changes, the windows and lanterns come on.
- At night the dead rise along the graveyard, one after another, come through the north gate and make for the keep. More each night.
- A keep with health, your own health, and a new day when the night is won.

## What is not

Everything else: gathering and building, the books, weapons and their tricks, the inn, the ruins, the priest, saving, menus, sound, and co-op. In this trial the north wall is already built, the posse get back up at dawn, and you get back up after a few seconds.

## How it is laid out

- `scripts/main.gd`: the day and night, the light, the camera, when the dead rise.
- `scripts/world.gd`: the map, built from boxes, cylinders and cones.
- `scripts/peasant.gd`: the player and the posse.
- `scripts/shambler.gd`: the dead.
- `scripts/hud.gd`: the readouts.
- `scripts/build.gd`: helpers for making shapes.

## Tested

Run in Godot 4.7.2 on Linux with the Compatibility renderer and a software graphics driver: two nights played by a test bot with no script errors, and screenshots by day and night. It has not yet been seen on this project's own settings (Forward+ on Direct3D 12), where the lighting may come out brighter or darker and will need a look.
