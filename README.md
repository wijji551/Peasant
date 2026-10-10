# Thornhallow Thirty Nights

A co-op game for 1 to 8 players, in the manner of Thronefall. The peasants of Thornhallow defend their keep from the dead who walk down from Ashhollow Castle every night. Robert Bailiff has bolted his door.

This is **Build 3** (the first week: seven nights). What each build contains is in [docs/build-log.md](docs/build-log.md).

## Playing

**Play it at https://wijji551.github.io/Peasant/** (once GitHub Pages is switched on for this repository: see Updating the game). Everyone opens that link; one player hosts and gives the others the five-letter village code.

It also still works as a single file: `out/defend-the-village.html` after a build can be opened straight from disk or sent to someone.

Esc in the game opens the handbook: a guide, the controls (they can be changed) and options.

## How it is put together

- `src/` is the game, in plain JavaScript, in the order it is joined: core rules tables and input, the WebGL renderer, the map, the models, the rules, co-op, drawing, screens. `src/shell.html` is the page and its styles.
- `build.js` joins `src/` into one HTML file in `out/` (as `defend-the-village.html` and `index.html`). It needs Node and nothing else: `node build.js`.
- `tools/scroll.py` draws the scroll that frames every notice and writes it into `src/shell.html`. Run it only after changing the frame.
- There are no libraries to install. Co-op loads PeerJS 1.5.4 from a public CDN in the player's browser, only when someone hosts or joins. The fonts come from Google Fonts, with fallbacks.

## Updating the game

Change the source, push to `main`, and the workflow in `.github/workflows/pages.yml` builds and publishes it. Players get the new version the next time they open the link.

One-time setup: in the repository on GitHub, Settings, Pages, Build and deployment, set Source to "GitHub Actions".

Players on different builds cannot join each other (the village code is tied to the build), and a save from one build may not load in the next. Saves are kept in each host's browser.

## Tests

The tests drive the real page in a headless browser. They need Playwright (`npm i -D playwright`, then `npx playwright install chromium`) and the built game served locally:

    node build.js
    npm run serve        # in another terminal
    npm test             # the rules (about 110 checks) and a whole week
    npm run test:page    # notices, keys, the handbook, saving
    npm run test:coop    # two tabs playing together
    npm run test:bot     # a bot plays the week alone

They are slow where there is no graphics card, and a few of the page tests are sensitive to that. The publishing workflow does not run them.

## A Godot trial

`godot/` is the game moving across to Godot 4.7. The rules are all there and tested; the map, menus, sound and co-op are being moved in stages, and the web version stays live until it has caught up. See its own README. The publishing workflow ignores it.

## Not done, and known limits

- Nights 8 to 30, weather, merchants, hired help and contraptions are still to come.
- Co-op uses the free public PeerJS connection service. That is fine for friends; a public game would want its own, and a relay for players whose networks block direct connections.
- Keyboard and mouse only.
- There is no licence file yet. Until one is added, nobody else has permission to reuse this code.
