extends RefCounted
## What goes in the window: the home screen, the handbook (guide, controls, options), a place's notice,
## your backpack, the dawn notice, and the end of the week. main.gd says which; this fills it in.

const GUIDE := [
	["The short version", ["By day, gather and build. At dusk the bell rings. At night the dead rise along the graveyard to the north, one after another without a pause and faster as the night goes on, and make for the keep, where the families are hiding. If the keep falls, Thornhallow is lost. Hold for the month: thirty nights (or seven, in the short game).", "Nearly everything is done by walking up to it and holding {interact}."]],
	["The day", ["A day lasts six minutes, or until everyone presses {ready}.", "Wood comes from trees, stone from the rocky outcrop, iron from the mine, food from the farms to the west or the jetty on the river. The stone, the iron and the fishing move every morning: the dawn notice says where, and the map marks them. You carry 20 of each.", "At the jetty, hold {interact} and press {attack} when something bites."]],
	["Defences", ["The north wall has seven foundations: six walls and a gate. Stand on one and hold {interact}. Barricades and spike rows go anywhere: press {build} or 1 to 4 (or click one, bottom right), then {interact} or click.", "Hold {interact} at a damaged defence to repair it with wood. Carrying stone or iron, hold {interact} again to face a wall with stone, band the gate or brace a barricade. An unbraced barricade rots by half every evening after its first night.", "Nobody can be hit through a standing wall or gate, in either direction. Go out through the gate, or shoot over."]],
	["Your posse", ["Hold {interact} beside a neighbour to rally them. They gather when you gather and fight when you fight. The slum has more, for food. The smithy gives them spears.", "They can die, and they have nerve: when friends fall they may run for the keep until dawn. {toilet} is the emergency toilet break, which sends the dead nearby running. With rank 3 of the leadership book, {orders} tells them to follow, hold or charge."]],
	["Fighting", ["{attack} or a click attacks. {trick} or a right-click is your weapon’s own trick: every weapon has a different one, with a short wait between uses. {eat} eats one food.", "Knocked down, you have 15 seconds for a team-mate to hold {interact} over you. After that a relative takes over your cottage at dawn, with your books but not your gear. Relics lie where you fell.", "From dusk you can hide in your own cottage. It is safe, and the village will call you a coward until the next dusk."]],
	["Things you carry", ["{pack} opens your backpack: what is on you, and six places for spares. Click a thing to use it or put it away. {swap} swaps to the next weapon in the backpack without opening it. {carry} throws a slop bucket or rings a handbell.", "A bow needs the book Slings, Bows and Thrown Turnips, which comes with a sling. A crossbow needs rank 3 of it. Heavy arms need rank 2 of Hammer and Tongs to forge."]],
	["Places", ["The library: three books out of ten, seven ranks each, earned by doing what the book teaches. {skills} shows your books as skill trees: what every rank does and how close the next is. Learning past rank VII is spare, and sells for coin there. The smithy: weapons, armour, spears for the posse. The storehouse: shared materials and a shared arms rack. The market: sells at a penny a piece, buys at two. The slum: recruits.", "The Thorny Rose Inn: bring the innkeeper food by day; from dusk go in, bar the door and drink. At full courage you burst out and charge. The priest, by the chapel: blessings for two shillings, and holy studies.", "The ruins, by the chapel and outside the wall to the south-west and south-east: hold {interact} at a heap of rubble. Relics turn up, more often by moonlight. Searching outside the wall is noisy."]],
	["Playing together", ["Up to eight can play. One of you presses Host a village on the home screen and reads out the village code; the others type it into Join. Everyone gets their own cottage, posse and books; the storehouse, the arms rack and the keep are shared. The host starts the week when everyone is in, and the host's game keeps the save.", "With a village server set (Options), villages go through it: a five-letter code that works from anywhere, and nobody's router matters. Without one, the host's computer asks its router to let friends in; if the router says no, that code only works on the same home network, unless the host opens port 24565 (UDP). The game does not pause for the handbook when others are playing."]],
	["The lie of the land", ["Thornhallow sits in the middle, with the castle up the road to the north and the river to the south. The thorn hedges, far to the west and east, are the edge of the world. West is Hallowshire Forest, with the old steel mine at its top end; east are the downs and the old mill. The stone, the iron and the fish move every morning (the dawn notice says where), and the far places are a long walk, so go early."]],
	["The smithy", ["Anyone can knock out a crude weapon at the smithy. It wears out: chipped after a night's fighting, in bits after a second. Hammer and Tongs makes refined weapons, which last; from rank 4, steel ones, which hit harder still. Steel comes from the old steel mine, at the top of the forest to the north-west, and the market pays well for it but sells none. Anyone can forge armour; steel armour needs rank 4."]],
	["The village", ["Robert Bailiff will talk to you from his upstairs window: stand at his front door. You can knock (it will not open) or jeer at him, which is satisfying, but he remembers, and his guards cost a shilling more for every jeer that day.", "Anyone can ring the village bell in the square. It does nothing at all.", "The training yard's straw dummies: practise on them by day for a little of The Art of Hitting Things (or, with a sling or a bow, Slings, Bows and Thrown Turnips). There is only so much a dummy can teach you in a day."]],
	["The Thorny Rose", ["Hold {interact} at the inn’s door on the square to go in. It is open day and night, until the dead break the door down; your posse waits outside (and comes in with you if you sit down to drink). The door back out is at the bottom of the room.", "The bar: give the innkeeper food and he turns it into ale for the night; hire a mercenary; and after dark, sit down to drink. Each tankard is Dutch courage, and at 100 you burst out and charge.", "Old Marge, Tam the Carter and the stranger in the corner will each talk about three things, and each does one good turn a day for the price of a drink (6d).", "The gambler plays twenty-one, higher or lower, and the pea and the cups, for stakes of sixpence to four shillings. Twenty-one and higher or lower are luck, with the odds a little his way. The cups are not luck: watch the pea go under, follow that cup, and click it when he stops. Walking away from the table loses the stake."]],
	["The torch, the old workings and runes", ["Anyone can make a burning torch at the smithy (three wood). What it hits burns for four seconds after, and Flare ({trick}) sets fire to everything round you and drives it back a step. Bones burn badly, wraiths not at all, and rain halves it. It also lights your way.", "Beside the old steel mine, far to the north-west, a timber frame stands over a hole: hold {interact} to climb down into the old workings. Down there it is dark, the dead cannot reach you, and your posse waits at the top. Three veins of runes glow in the walls. With a burning torch in your hand, hold {interact} at a vein to prise one out: two to a vein each day. The ladder takes you back up, and dawn fetches you out whatever you are doing.", "At the smithy, three runes cut into the weapon in your hand make it a fifth stronger for good, and able to hurt wraiths."]],
	["Ruins, chests and cards", ["The outer ruins are not empty. Rummaging is noisy, and brings shamblers; from the second day it can also wake the Previous Tenant, who is several times the size and has a great deal of health. By day he will not follow you far from his ruin. After dark he goes down to the village with the rest. Whoever puts him down gets his back rent.", "Once a week a chest sent to help the village goes astray. The dawn notice says who sent it and which way the messenger set off. It lies outside the wall, off the map until somebody walks near it. The finder gets the coin; anything else inside can be dropped for a friend.", "A library card (from a chest) is handed in at the library to swap one of your books for another. The new one starts a rank behind the old."]],
	["Letters and notices", ["The Lord of Ashhollow writes. From the second morning, and every other morning after, a headless rider gallops down the castle road at first light and nails a letter to the gatepost just inside the north gate. They are complaints: about the noise, the breakages, and whatever the village has most lately done to his household. Read them at the gatepost.", "The notice board in the square, opposite the bell, has the day's news (the weather, what is expected tonight, when the next boss is due), three notices from the village, and a copy of every letter so far.", "With eight players, more of the dead would rise than the night can hold. Past about 420 in a night there are fewer of them instead, and each is harder to put down and hits harder: the same horde, in fewer pieces."]],
	["Contraptions", ["Barricades for Beginners teaches the village's inventions, one every rank or so, and a box of cogs from the tinker builds any one without the book. Press 5 (or click the fifth card, bottom right) to step through the ones you can build.", "The chicken decoy (rank 1): nothing dead can ignore it, briefly. The pitfall (3): swallows four for good; good inside the wall, for gravediggers. The tar pit (4): everything wades. The holy water trough (5, and a class of holy studies or the Holy Book): burns whatever crosses it, wraiths too. The log roller (6), up the road north of the wall: once a night it flattens a crowd, or a coffin ram. The Thresher (7): a spinning flail, as long as someone stands by to turn the handle."]],
	["Merchants and hired help", ["On about six days of the month a merchant parks a cart by the market: the tinker (iron, tools, boxes of cogs for contraptions), the armourer (forged arms, no smithy needed), the brewer (food, and ale for the inn), the relic pedlar (one real relic among the fakes: rank 2 of relic lore tells which) or the bookseller (loose pages, and An Index of Further Reading). They leave at dusk.", "Each has a job, paid with the best thing on the cart. Take it at the cart, then stay where the job is: most of a day alone, about half a day each with a team-mate. Nobody learns from a book on a day they work for a merchant.", "Robert Bailiff will lend you a village guard for 8 shillings (knock at his back door, north of his house): he holds a gate until dawn. Six guards in all, two to a gate. The Thorny Rose Inn will find you a mercenary for 8 shillings: stronger, in your posse until dawn, and about one in seven turns on you then for two more shillings."]],
	["The Holy Book", ["The last book on the library shelf makes you an apprentice priest: a peasant's version of a mage, which is to say not much of one. {power1} is Smite, a bolt of holy light on the nearest of the dead; from rank 2, {power2} is Pray, a third less harm for ten seconds for you and everyone near you, posse included. Later ranks make the prayer bless weapons and mend wounds, and the smite burst and strike three at once. Smites are holy, so they hurt wraiths.", "One calling at a time. You learn the book by smiting and praying.", "Your title: the village names you after the two books you know best, the one you know best last (the Sooty Ringleader, the Holy Apprentice Priest). It shows top left.", "A fourth book: An Index of Further Reading turns up, rarely, in the ruins. Read it and the library lets you take up one more.", "Every relic goes with a book. Read the book and the relic does a little more: the Silvered Sword hits harder with The Art of Hitting Things, the Chapel Handbell smites with the Holy Book, and so on. Your backpack says which."]],
	["The month", ["Four weeks, each ending with a boss: the Steward on night 7, the Coachman and his hearse on 14, the Captain of the Guard on 21, and the Lord of Ashhollow himself on 30. Each week the dead last a little longer and hit a little harder, and new kinds come down. The dawn notice warns you the morning before.", "Ghouls (from night 8) are fast and climb over barricades, but not walls. Gravediggers (10) tunnel under the north wall and come up inside. Bat swarms (12) fly over everything for the keep: slings, bows and the handbell bring them down. The Lord's guard (15) is armoured: farm tools barely dent it, maces and hammers do. Wraiths (18) drift through walls, and only holy things hurt them: relics, blessed weapons, blessed slop. A coffin ram (20) goes for the north gate: a warhammer, or a very strong gate.", "The weather changes the night. Rain makes mud, and the dead wade slower. Fog hides the castle road. Snow slows everyone. Night 15 is the full moon: relics are easier to find, and the dead are quicker."]],
	["Looking around", ["The view starts from the south, with north up the screen, but you can swing it round your peasant. Press the mouse wheel in and drag, or hold {look} and move the mouse: left and right turn the view, up and down tilt it. {cam_left} and {cam_right} turn it from the keyboard. Roll the wheel to come closer or go further off. {cam_reset} puts it all back.", "Moving follows the view: {up} is always away from you, up the screen. The map in the corner stays north up, and the pale fan on your dot shows which way you are looking."]],
	["Reading the screen", ["Top left: the day and the time left, and whether you are ready. Top middle: the keep, and the boss when one comes. Top right: the map. Left: what you carry. Bottom: your hand, bucket, posse, backpack, skills and toilet break, with their keys, and the four things you can place, bottom right. What holding {interact} would do shows just above the bar at the bottom.", "Places, your backpack, the dawn and this handbook all open in one window in the middle. Esc closes it, or the cross; walking away closes a place's notice."]],
]

const CHANGES := [
	["Inside the Thorny Rose", [
		"The inn is a room now. Hold E at its door on the square, day or night, and walk in. The innkeeper is behind the bar with his old business: food for ale, a mercenary for hire, and after dark a seat to drink yourself brave.",
		"Three locals will talk: Old Marge by the fire, Tam the Carter, and a stranger in the corner. Ask each about three things. Stand one a drink (6d, once a day each) and you get a good turn: a pie, word of where the lost chest or the outer ruins are, or how to deal with the next boss.",
		"In the other corner sits a gambler, with three games for coin. Twenty-one, with very old cards. Higher or lower, which pays more the bolder the guess. And the pea under the cups, which is no luck at all: he shows you the pea and you follow it. He gets quicker each time you win, and packs up when he has lost ten shillings to you in a day.",
		"The bookshelf has one book on it, the size of a paving stone. It is for the next update.",
	]],
	["Fire, and what is under the mine", [
		"The burning torch: anyone can make one at the smithy for three wood. It does not hit hard, but whatever it hits catches fire and goes on burning for a few seconds, and its trick, Flare, sets light to everything round you. It lights your way at night. Rain halves the burning; wraiths do not burn at all.",
		"By the mouth of the old steel mine there is now a way down into the old workings: a room you walk into. It is dark. Three veins of runes glow in the walls, two runes to a vein each day, and you can only work them with a burning torch in your hand. Your posse waits at the top.",
		"Runes are shown under steel. Three of them, at the smithy, cut runes into the weapon in your hand: a fifth more damage for good, and it bites wraiths as a blessed weapon does.",
	]],
	["Days with something in them", [
		"Searching the outer ruins by day can now wake the Previous Tenant: far bigger and tougher than a shambler, in his nightshirt, and cross about the noise. He keeps to his ruin by day, so you can run. Put him down and his back rent is yours, and sometimes more.",
		"Once a week a chest of help sets out for Thornhallow, from a mayor, a duchess or somebody else at a safe distance, and does not arrive. The dawn notice says which way the messenger went. Find it, outside the wall, and it is yours: a good sum, and perhaps a relic or a library card.",
		"A library card, handed in at the library, lets you give up one of your books and take another, starting a rank behind where the old one was. Drop it on the ground if you would rather a friend had it.",
	]],
	["The castle", [
		"As night falls the view swings up the road for a long look at Ashhollow Castle, then back. Space or Esc cuts it short, and it can be turned off in the options.",
		"The castle gets worse as the month goes on: banners and green fire in the second week, thorns as tall as trees in the third, and in the last week a black spire, red windows and the sky turning over it.",
	]],
	["Tidying up", [
		"Steel is always shown under iron in what you carry. Anyone can mine it, at the old steel mine at the top of the forest, far to the north-west (the grey-blue square on the map).",
		"A thing in your backpack can be destroyed for good: the little flame on it, pressed twice. Things left on the ground are gone on the second morning.",
		"Your posse finds its own way round the village wall now, by the gates, and a follower who gets properly wedged runs to catch up. When you chop wood they chop beside you, sharing a tree if they must, not off across the forest.",
	]],
	["A new name: Thornhallow, Thirty Nights", [
		"The game has its proper name and a title screen to match. The Lord of Ashhollow now looks as he does in his portrait: beak, tall hat, goblet and all.",
		"The names over places fade to about half when you stand near them, so you can see what is underneath.",
	]],
	["A camera you can turn", [
		"You can look around now. Press the mouse wheel in and drag (or hold V and move the mouse) to swing the view round your peasant and tilt it; roll the wheel to zoom. The comma and full stop keys turn it too, and N puts it back with north up.",
		"Moving follows the view: W is always up the screen. The map in the corner stays north up, with a pale fan on your dot to show which way you are looking. All four keys can be changed in the handbook.",
	]],
	["Build 5, stage 4: letters and notices", [
		"The Lord of Ashhollow has started writing to the village. A headless rider brings each letter down at first light and nails it to the gatepost inside the north gate. He is very polite, and he is complaining: about what you built, whom you hit, and the bell.",
		"The notice board in the square now has something on it: today's weather, what is coming tonight, the next boss, the village's own notices (three new ones a day), and all the Lord's letters so far.",
		"Big games: when more than about 420 of the dead would rise in one night (five players or more, later on), fewer rise, and each is tougher and hits harder. Eight players still face eight hordes' worth, without the night taking an hour.",
		"Two players now start with four followers each, not three. The more players there are, the less each blow from the dead does to walls, gates, barricades and the keep. The Steward is a good deal harder to put down.",
		"Fixed: the Captain of the Guard's party used to hang about outside the side gateways and never come in. Gravediggers could surface wedged between two houses, so the night never ended. And the game runs much faster with a big posse or a lot of the dead.",
	]],
	["Build 5, stage 3: a bigger map", [
		"The land between the thorn hedges is a third wider. Out west, past the forest, and east, on the downs, there are new places for the stone, the iron, the fish and the outer ruins.",
		"The old steel mine has moved deeper into the forest, at its top end. The old mill stands on the eastern downs, with a sheepfold. Neither the mill nor the sheep will help.",
		"The river runs now, with reeds, lily pads and a sandy bank. North of the keep is a village green: a maypole, the well, a duck pond, and the stocks by Robert Bailiff's.",
		"The bigger houses are half-timbered, and the cottages have cabbage patches out the back. The map in the corner is wider to fit it all.",
	]],
	["Build 5, stage 2: the smithy", [
		"The smithy now makes three grades. Anyone can forge crude weapons: cheap, a bit weaker, chipped after a night's fighting and in bits after a second.",
		"Refined weapons (the ones you knew) now need Hammer and Tongs. From rank 4 of it you can forge steel weapons and armour, which are better still.",
		"Steel comes from the old steel mine at the top of the forest, to the north-west. It does not move. The market buys steel at three pence a piece and sells none.",
	]],
	["Build 5, stage 1: the village", [
		"Robert Bailiff now appears at his upstairs window. Stand at his front door to talk to him, knock, or jeer at him. Jeering is free, but his guards cost a shilling more for each one that day.",
		"The village bell in the square can be rung by anyone. It does nothing at all.",
		"The straw dummies in the training yard can be practised on, by day, for a little learning in the fighting books (up to a limit each day).",
		"Peasants say things: when you rally them, when dusk falls, when they lose their nerve, and when they live to see the dawn.",
		"Clearer wording in the skill trees.",
	]],
	["Build 4, stage 4: contraptions (Build 4 is finished)", [
		"Six contraptions, taught by Barricades for Beginners: the chicken decoy, the pitfall, the tar pit, the holy water trough, the log roller and the Thresher. A box of cogs from the tinker builds one you have not learned.",
		"They have their own card bottom right: press 5 to step through the ones you can build.",
		"The log roller goes up the castle road and flattens a crowd (or a coffin ram) once a night. The pitfall swallows four. The Thresher needs someone to turn the handle.",
	]],
	["Build 4, stage 3: merchants and hired help", [
		"Travelling merchants on about six days of the month, with a cart by the market: the tinker, the armourer, the brewer, the relic pedlar and the bookseller. The dawn notice says when one has come.",
		"Each has a job going, paid with the best thing on the cart: a cart wheel to find on the quarry road, a cart to guard, forty barrels to stack, a crate to carry up to the chapel, a ledger to copy out. Most of a day alone, half a day each with help, and no book learning that day.",
		"The relic pedlar's relics are mostly fakes. Rank 2 of Relics and Where They Were Left tells you which one is not.",
		"Village guards: 8 shillings at Robert Bailiff's back door. Each holds a gate for the night.",
		"Mercenaries: 8 shillings at the Thorny Rose Inn. One joins your posse until dawn, hits hard, and now and then turns on you at dawn for more money.",
	]],
	["Build 4, stage 2: the Holy Book", [
		"A new book on the library shelf, The Holy Book (Abridged). It makes you an apprentice priest, with two powers on their own keys: Z for Smite (holy light on the nearest of the dead) and C for Pray (protection for you and everyone near you, from rank 2). Higher ranks bless everyone's weapons, mend wounds, and make the smite burst and strike three at once. Smites are holy, so they hurt wraiths.",
		"Titles: the village names you after the books you know best, from the Splintery Woodcutter to the Holy Master Apprentice Priest. Yours shows top left, and in your skills.",
		"A fourth book: An Index of Further Reading turns up, rarely, in the ruins.",
		"Relics and books lean on each other: every relic does something more if you have read the book it goes with. Your backpack and the arms rack say which book.",
	]],
	["Build 4, stage 1: the month", [
		"Thirty nights now, in four weeks. The home screen offers a new month, or a short game of seven nights that squeezes it all in, with the Lord on the seventh.",
		"Six new kinds of dead: ghouls that climb barricades, gravediggers that tunnel under the north wall, bat swarms that fly straight for the keep, the Lord's armoured guard, wraiths that walk through walls and only mind holy things, and a coffin ram for the gate.",
		"Three new bosses: the Coachman drives his hearse through anything wooden on night 14; the Captain of the Guard leads the guard against one gate on night 21; and on night 30 the Lord of Ashhollow comes down in person, in three stages, ending at the keep door.",
		"The dead are a bit tougher from the start, and a tenth tougher each week after.",
		"Weather that matters: rain slows the dead, fog hides the castle road, snow slows everyone, and night 15 is the full moon. The dawn notice warns you what is coming tonight.",
	]],
	["Godot: the village server is open", [
		"The game now has its own village server, always on, in London. Host and Join use it by themselves: nothing to type, no routers to fiddle with. Hosting gives a five-letter code; send it to your friends.",
		"Your own server can still go in the handbook's Options, if you ever want one.",
	]],
	["Godot: the village server", [
		"Playing together can now go through a village server: a small program on an always-on machine (a free Oracle Cloud one will do) that introduces players and passes their messages on. Nobody's router has to let anyone in, and your friends can host their own villages when you are not on.",
		"A village on the server has a five-letter code. Older codes (with a dash) still work, straight to the host.",
		"Put the server's address in the handbook's Options. If the server does not answer, hosting falls back to your own computer.",
	]],
	["Godot: playing together (stage 5 of the move: the move is done)", [
		"Up to eight in one village. Host a village from the home screen and give your friends the code; they type it into Join.",
		"Your computer asks your router to let them in by itself. If your router will not, the code still works for anyone on the same wifi.",
		"A lobby shows who has come; the host starts the week, or carries on from the saved morning. The host's game keeps the save.",
		"Your own walking happens at once on your screen; everything else follows the host's game, twelve times a second.",
		"If someone's connection goes, their relics stay in the village and their posse goes home. If the host leaves, everyone is sent home and told so.",
	]],
	["Godot: sound (stage 4 of the move)", [
		"Every sound from the web version, made again, and new ones: the dead groaning and rattling as they come near, crows, an owl, thunder after the lightning, a knock, a creaking door, a page turning when a window opens.",
		"Birds and a breeze by day, crickets and wind at night, rain when it rains, and a low moaning drone the closer you get to the castle.",
		"Two tunes: a lute in the village by day, and something slower and less friendly at night.",
		"The handbook's options have a volume for everything, the effects, the ambience and the music. M mutes it all.",
	]],
	["Godot: the look of the place", [
		"Proper medieval lettering, and every card and button is now torn parchment, like the scroll.",
		"What you carry says what it is, with pictures that look like wood, stone, iron, food and coin.",
		"Your pack is now your Backpack. It was always a backpack. It feels better for the name.",
		"The books have moved to a Skills window (K): each book is a ladder of seven ranks showing what every rank does and how near the next one is. Past rank VII, extra learning becomes spare points you can sell for coin.",
		"The game opens in a bigger window, and the home screen is smaller.",
		"Fixed: a notice after the home screen sat off to the right and down. Fixed: trees outside the hedge showed on the map.",
		"Bailiff’s House and the Thorny Rose Inn, by their proper names. The chapel looks like a chapel: a bell tower, a spire, coloured windows. The priest wears white and gold and is, frankly, glowing.",
		"The haybales are haybales, not tents.",
		"The two outer ruins wander off to a new clearing every night, and nobody is told where. Find one and it goes on the map for everyone.",
		"Mist creeps over the ground at night and never quite leaves the castle. Some days it rains, some are grey, some misty. Chimneys smoke.",
		"Ashhollow is haunted now: dead trees, a gibbet, green fires at the gate, purple windows, will-o’-wisps, crows, and lightning at night.",
		"Smoother edges (anti-aliasing).",
	]],
	["Godot: stage 3, patched", [
		"Clicking the mouse no longer crashes the game. It asked the old readouts whether a notice was open, and they had been thrown out. They did not answer, and the game took it badly.",
	]],
	["Godot: the menus (stage 3 of the move)", [
		"Everything that opens now opens in one window in the middle, framed by the scroll, so nothing sits on anything else. Esc or the cross closes it.",
		"The readouts have fixed places round the edge: the day top left, the keep top middle, the map top right, what you carry and your books on the left, your health bottom left, and a bar along the bottom with your weapon’s trick, your bucket, your posse, your pack and the toilet break, each with its key.",
		"The four things you can place sit bottom right, with their costs. Click one, or press 1 to 4.",
		"Your pack is slots with pictures: click a thing to use it or put it away, the cross drops it.",
		"A home screen with your name and colour, Carry on and New village, and this list.",
		"The handbook on Esc: a guide, the controls (change any key) and options. The game waits while it is open.",
		"Lose, and you can try the same day again from its morning."]],
	["Godot: the map and models (stage 2)", ["Every model from the web version, the see-through keep, the effects, the map in the corner and the signs over places."]],
	["Godot: the rules (stage 1)", ["The whole game’s rules, moved across unchanged, with the web version’s 107 checks passing."]],
	["Build 3 (web): the inn and the ruins", ["The Thorny Rose, ruins and relics, a trick for every weapon, the pack and arms rack, ten books of seven ranks, the priest, posse nerve and orders, a continuous stream of the dead, moving outcrop, mine and fishing, regrowing trees, rotting barricades."]],
]

var m                                  # main.gd
var w                                  # the window
var menu_tab := "guide"
var rebinding := ""
var bind_msg := ""
var notice_sig := ""


func _init(main_, window_) -> void:
	m = main_
	w = window_


# ---------------------------------------------------------------- home
func home() -> void:
	# The title screen: the picture has the name on it, so the scroll is small and sits under the title, on the left.
	var saved = m.read_save()
	var b: VBoxContainer = w.open("home", "", "", 430, 436 if saved else 388, false, false)
	w.pin = Vector2(0.045, 0.372)
	b.add_theme_constant_override("separation", 8)
	Look.label(b, "YOUR NAME AND COLOUR", 13, Look.RUST)
	var name := LineEdit.new()
	name.text = Settings.name
	name.placeholder_text = "Peasant"
	name.max_length = 14
	name.custom_minimum_size.x = 260
	name.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	name.text_changed.connect(func(t): Settings.name = t.strip_edges(); Settings.save())
	b.add_child(name)
	var sw := HBoxContainer.new()
	sw.add_theme_constant_override("separation", 6)
	b.add_child(sw)
	for i in 8:
		var s := Button.new()
		s.custom_minimum_size = Vector2(30, 30)
		s.tooltip_text = D.PCOLN[i]
		s.focus_mode = Control.FOCUS_NONE
		var st := StyleBoxFlat.new()
		st.bg_color = Color(D.PCOL[i])
		st.set_corner_radius_all(15)
		st.set_border_width_all(4 if i == Settings.col else 2)
		st.border_color = Look.INK if i == Settings.col else Color(Look.OUTLINE, 0.4)
		for k in ["normal", "hover", "pressed"]: s.add_theme_stylebox_override(k, st)
		s.pressed.connect(func(): Settings.col = i; Settings.save(); home())
		sw.add_child(s)
	if saved:
		var who: Array = saved.players.map(func(p): return p.dn)
		var cb := _big(b, "Carry on from day %d" % int(saved.day), func(): m.begin(saved), true)
		cb.tooltip_text = "Saved: " + ", ".join(who) + "."
		cb.size_flags_horizontal = Control.SIZE_FILL
	var nr := HBoxContainer.new()
	nr.add_theme_constant_override("separation", 8)
	b.add_child(nr)
	var nm := _big(nr, "Thirty nights", func(): m.begin_new(D.MONTH), saved == null)
	nm.tooltip_text = "A new month: thirty nights, four bosses, and every kind of dead. Saved every morning."
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nm.custom_minimum_size.x = 0
	var ns := _big(nr, "Seven nights", func(): m.begin_new(D.WEEK), false)
	ns.tooltip_text = "A short game: the month squeezed into seven nights. New dead every night, and the Lord on the seventh."
	ns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ns.custom_minimum_size.x = 0
	# playing together
	Look.label(b, "PLAY TOGETHER (UP TO 8)", 13, Look.RUST)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	b.add_child(row)
	var hb := Button.new(); hb.text = "Host a village"; hb.focus_mode = Control.FOCUS_NONE
	hb.pressed.connect(func(): _host())
	row.add_child(hb)
	var jc := LineEdit.new(); jc.placeholder_text = "Village code"; jc.custom_minimum_size.x = 150; jc.max_length = 21
	jc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	jc.text_submitted.connect(func(t): _join(t))
	row.add_child(jc)
	var jb := Button.new(); jb.text = "Join"; jb.focus_mode = Control.FOCUS_NONE
	jb.pressed.connect(func(): _join(jc.text))
	row.add_child(jb)
	var note: String = Net.me.status
	if note != "" and not Net.me.online():
		var nl := Look.para(b, note, 14, Look.ROSE)
		nl.custom_minimum_size.x = 300
		Net.me.status = ""
	var last := HBoxContainer.new()
	last.add_theme_constant_override("separation", 8)
	b.add_child(last)
	for pair in [["What is new", func(): news()], ["Handbook", func(): menu("guide")]]:
		var fb := Button.new(); fb.text = pair[0]; fb.focus_mode = Control.FOCUS_NONE
		fb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fb.pressed.connect(pair[1])
		last.add_child(fb)


## What has changed, build by build: opened from the title screen.
func news() -> void:
	w.open("news", "What is new", "", 660, 580, true, true)
	for c in CHANGES:
		w.head(c[0])
		for line in c[1]:
			w.para("•  " + line, 14, Look.INK)
	w.foot_button("Back", func(): w.close(), true)


func _big(parent: Control, text: String, cb: Callable, primary: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(260, 40)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	b.add_theme_font_size_override("font_size", 19)
	if primary:
		b.add_theme_stylebox_override("normal", w._primary())
		b.add_theme_stylebox_override("hover", Look.primary_hover())
		b.add_theme_stylebox_override("pressed", Look.primary_hover())
		b.add_theme_color_override("font_color", Color("fbeec2"))
		b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


# ---------------------------------------------------------------- the handbook
func menu(tab: String = "") -> void:
	if tab != "": menu_tab = tab
	var in_game: bool = m.in_game()
	var b: VBoxContainer = w.open("menu", "The handbook", "", 760, 600, true)
	w.tabs([["guide", "Guide"], ["keys", "Controls"], ["opts", "Options"]], menu_tab, func(t): rebinding = ""; bind_msg = ""; menu(t))
	match menu_tab:
		"guide":
			for g in GUIDE:
				w.head(g[0])
				for p in g[1]: w.para(p, 16)
		"keys":
			var grid := GridContainer.new()
			grid.columns = 3
			grid.add_theme_constant_override("h_separation", 14)
			grid.add_theme_constant_override("v_separation", 4)
			b.add_child(grid)
			for a in Keys.ACTIONS:
				var l := Look.label(grid, a[1], 15, Look.INK)
				l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				Look.label(grid, "Press a key…" if rebinding == a[0] else Keys.all_names(a[0]), 15, Look.ROSE if rebinding == a[0] else Look.INK_SOFT)
				var c := Button.new()
				c.text = "Cancel" if rebinding == a[0] else "Change"
				c.focus_mode = Control.FOCUS_NONE
				var act: String = a[0]
				c.pressed.connect(func(): rebinding = "" if rebinding == act else act; bind_msg = ""; menu())
				grid.add_child(c)
			w.para(bind_msg if bind_msg != "" else "Choose Change, then press the key you want. A key does one thing: whatever had it before is left without.", 14, Look.INK_SOFT)
			w.para("Fixed: a click attacks and a right-click is your weapon’s trick. The numbers pick from a notice, your backpack, or the things to place. Esc closes whatever is open, and otherwise opens this handbook.", 14, Look.INK_SOFT)
			var r := Button.new(); r.text = "Back to the usual keys"; r.focus_mode = Control.FOCUS_NONE
			r.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			r.pressed.connect(func(): Keys.reset(); rebinding = ""; bind_msg = "The usual keys are back."; menu())
			b.add_child(r)
		"opts":
			var g := GridContainer.new()
			g.columns = 2
			g.add_theme_constant_override("h_separation", 16)
			g.add_theme_constant_override("v_separation", 10)
			b.add_child(g)
			for row in [["All sound", "vol"], ["Effects", "fx_vol"], ["Birds, wind and rain", "amb_vol"], ["Music", "music_vol"]]:
				Look.label(g, row[0], 15)
				var vh := HBoxContainer.new(); g.add_child(vh)
				var vs := HSlider.new(); vs.min_value = 0; vs.max_value = 100; vs.step = 5; vs.value = Settings.volume(row[1]); vs.custom_minimum_size.x = 180
				var vl := Look.label(vh, "", 15)
				vh.add_child(vs); vh.move_child(vs, 0)
				var key: String = row[1]
				vl.text = "%d%%" % Settings.volume(key) if Settings.volume(key) else "off"
				vs.value_changed.connect(func(v): Settings.set_volume(key, int(v)); vl.text = "%d%%" % int(v) if v else "off"; Settings.save(); Sound.apply_settings(); Sound.play("pop"))
			Look.label(g, "Mute (%s)" % Keys.name("mute"), 15)
			var mu := CheckBox.new(); mu.button_pressed = Settings.muted; mu.toggled.connect(func(on): Settings.muted = on; Settings.save(); Sound.apply_settings()); g.add_child(mu)
			Look.label(g, "Village server, for playing together", 15)
			var rv := LineEdit.new()
			rv.text = Settings.relay
			rv.placeholder_text = "the game's own (type none to host from here)" if Net.DEFAULT_RELAY != "" else "none: host from this computer"
			rv.custom_minimum_size.x = 260
			rv.text_changed.connect(func(t): Settings.relay = t.strip_edges(); Settings.save())
			g.add_child(rv)
			Look.label(g, "Names over the other players", 15)
			var tg := CheckBox.new(); tg.button_pressed = Settings.tags; tg.toggled.connect(func(on): Settings.tags = on; Settings.save()); g.add_child(tg)
			Look.label(g, "See through the keep when something is behind it", 15)
			var sk := CheckBox.new(); sk.button_pressed = Settings.see_keep; sk.toggled.connect(func(on): Settings.see_keep = on; Settings.save()); g.add_child(sk)
			Look.label(g, "Look up at the castle as night falls", 15)
			var cp2 := CheckBox.new(); cp2.button_pressed = Settings.castle_pan; cp2.toggled.connect(func(on): Settings.castle_pan = on; Settings.save()); g.add_child(cp2)
			w.para("These are kept on this computer.", 13, Look.INK_SOFT)
	var code_txt := ""
	if Net.me.is_host(): code_txt = "  Village code: %s." % (Net.me.code if Net.me.code != "" else Net.me.lan_code)
	w.hint(("The game goes on while you read: the others are still out there." if Net.me.online() else "The game waits while you read." if in_game else "") + code_txt)
	if in_game:
		var lv: Button = w.foot_button("Leave the village", func(): _leave())
		lv.tooltip_text = "Back to the home screen. The village was saved this morning."
	w.foot_button("Back to the game" if in_game else "Close", func(): w.close(), true)


var _leave_armed := false
func _leave() -> void:
	if not _leave_armed:
		_leave_armed = true
		bind_msg = ""
		w.hint("Really? That closes the village for everyone. Press it again." if Net.me.is_host() else "Really leave? Press it again." if Net.me.is_client() else "Really leave? Press it again. You will carry on from this morning next time.")
		return
	_leave_armed = false
	w.close()
	m.to_home()


## A key was pressed while the handbook waits for one.
func take_key(k: int) -> void:
	var a := rebinding
	rebinding = ""
	if k == KEY_ESCAPE:
		bind_msg = "Left as it was."
	elif k >= KEY_0 and k <= KEY_9:
		bind_msg = "The numbers are kept for notices, the backpack and the things to place."
	else:
		var had := Keys.action_of(k)
		Keys.set_bind(a, k)
		bind_msg = ("%s now does “%s”. “%s” %s." % [Keys.key_name(k), _act_label(a), _act_label(had), ("keeps " + Keys.all_names(had)) if Keys.keys_of(had).size() else "has no key now"]) if had != "" and had != a else "%s it is." % Keys.key_name(k)
	menu()


static func _act_label(a: String) -> String:
	for y in Keys.ACTIONS:
		if y[0] == a: return y[1]
	return a


# ---------------------------------------------------------------- a place's notice
func notice(id: String, page: String, force: bool = false) -> void:
	if id == "gambler":                                 # the gambler has a table of his own
		gamble(force)
		return
	var d := Notices.data(m.R, id, m.me, page)
	if d.is_empty():
		return
	var sig := str(d) + str(Settings.binds)
	if sig == notice_sig and w.is_open("notice") and not force:
		return
	notice_sig = sig
	w.open("notice", d.title, d.intro, 600, 580, m.me.state != "inn", false)
	var n := 0
	for o in d.o:
		if o.has("head"):
			w.head(o.head)
			continue
		if o.has("text"):                             # something to read, not to choose
			w.para(o.text, 15)
			continue
		n += 1
		var i := n - 1
		w.option(n, o.label, o.get("sub", ""), o.ok, func(): m.option(i))
	w.hint("Press the number, or click." + ("" if m.me.state == "inn" else " Walk away or press Esc to close."))


# ---------------------------------------------------------------- the gambler's table
const Cups := preload("res://scripts/ui/cups.gd")
var _gamble_sig := ""
const SUIT_COL := [Color("a8362c"), Color("b8862b"), Color("4f6480"), Color("4f7a3a")]

func _playing_card(parent: Control, c: int) -> void:   # a card face up (c 0 to 51), or face down (c < 0)
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", Look.card(Color("fff6dc") if c >= 0 else Color("7a4a22"), Look.OUTLINE, 6))
	pc.custom_minimum_size = Vector2(64, 86)
	parent.add_child(pc)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	pc.add_child(v)
	if c < 0:
		var q := Look.label(v, "?", 30, Color("e8d5a8"), true)
		q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		return
	var r := c % 13
	var nm: String = D.CARD_N[r]
	var top := Look.label(v, {"Knave": "Kn", "Queen": "Q", "King": "K", "Ace": "A"}.get(nm, nm), 28, SUIT_COL[c / 13], true)
	top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var st := Look.label(v, D.CARD_SUIT[c / 13], 11, SUIT_COL[c / 13])
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _card_row(title: String, cards: Array, hidden: int = 0) -> void:
	Look.label(w.body, title, 13, Look.RUST)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	w.body.add_child(row)
	for c in cards: _playing_card(row, int(c))
	for i in hidden: _playing_card(row, -1)


func gamble(force: bool = false) -> void:
	var p: E.Player = m.me
	var G: Dictionary = p.game
	var over: bool = not G.is_empty() and G.get("done", false)
	var gs := G.duplicate()
	if gs.has("t"): gs.t = float(gs.t) <= 0.0           # the countdown itself must not redraw the table (it would restart the cups)
	var sig := str(gs) + str(p.coin) + str(p.gwon)
	if sig == _gamble_sig and w.is_open("notice") and not force:
		return
	_gamble_sig = sig
	var act := func(a: String, arg = null) -> void: m.cmd({"t": "act", "a": a, "arg": arg})
	var packed: bool = p.gwon >= D.GAMBLE_DAY
	var says: String = D.GAMBLER_SAYS[(m.R.day + p.slot) % D.GAMBLER_SAYS.size()]
	w.open("notice", "The gambler", "", 620, 580, true, false)
	w.para("You have %s.%s" % [D.coins(p.coin), (" You are %s up on him today." % D.coins(p.gwon)) if p.gwon > 0 else (" He is %s up on you today." % D.coins(-p.gwon)) if p.gwon < 0 else ""], 15, Look.INK_SOFT)
	if G.is_empty():
		w.para("A man in a deep hood, a pack of very old cards, and three wooden cups. %s" % says if not packed else "The gambler has swept his cups into his coat. “Enough for one day, friend. You have had %s of mine. Come back tomorrow, and bring it with you.”" % D.coins(p.gwon), 16)
		if not packed:
			for g in [["21", "Twenty-one", "Cards: nearer twenty-one than him, without going over. Pays your stake again."],
					["hl", "Higher or lower", "Will the next card be higher or lower? The safer the guess, the less it pays."],
					["cups", "The pea and the cups", "Watch the pea, follow the cup. No luck in it: only your eyes, and his hands."]]:
				w.head(g[1])
				w.para(g[2], 14, Look.INK_SOFT)
				var row := HBoxContainer.new()
				row.add_theme_constant_override("separation", 8)
				w.body.add_child(row)
				for bet in D.BETS:
					var b := Button.new()
					b.text = "Stake " + D.coins(bet)
					b.focus_mode = Control.FOCUS_NONE
					b.disabled = p.coin < bet
					var gk: String = g[0]
					var bb: int = bet
					b.pressed.connect(func(): act.call("gstart", "%s:%d" % [gk, bb]))
					row.add_child(b)
		w.hint("Walk away or press Esc to leave the table.")
		return
	var again := func() -> void:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		w.body.add_child(row)
		var gk: String = G.g
		var bb: int = int(G.bet)
		var b1 := Button.new(); b1.text = "Again, for " + D.coins(bb); b1.focus_mode = Control.FOCUS_NONE
		b1.disabled = p.coin < bb or packed
		b1.pressed.connect(func(): act.call("gend"); act.call("gstart", "%s:%d" % [gk, bb]))
		row.add_child(b1)
		var b2 := Button.new(); b2.text = "Something else"; b2.focus_mode = Control.FOCUS_NONE
		b2.pressed.connect(func(): act.call("gend"))
		row.add_child(b2)
	var verdict := func() -> void:
		var won: bool = int(G.win) > int(G.bet)
		w.para(str(G.msg), 16, Look.INK)
		w.para(("You get %s back: %s up." % [D.coins(int(G.win)), D.coins(int(G.win) - int(G.bet))]) if won else "Your stake comes back." if int(G.win) == int(G.bet) else "Your %s is his." % D.coins(int(G.bet)), 15, Color("3f6b2a") if won else Look.ROSE if int(G.win) == 0 else Look.INK_SOFT)
	match str(G.g):
		"21":
			w.head("Twenty-one, for " + D.coins(int(G.bet)))
			_card_row("His cards" + (": %d" % Rules.total21(G.him) if over and G.him.size() > 1 else ""), G.him, 0 if over and G.him.size() > 1 else 1)
			_card_row("Yours: %d" % Rules.total21(G.me), G.me)
			if over:
				verdict.call(); again.call()
			else:
				var row := HBoxContainer.new()
				row.add_theme_constant_override("separation", 8)
				w.body.add_child(row)
				var b1 := Button.new(); b1.text = "Another card"; b1.focus_mode = Control.FOCUS_NONE; b1.pressed.connect(func(): act.call("ghit")); row.add_child(b1)
				var b2 := Button.new(); b2.text = "Stand on %d" % Rules.total21(G.me); b2.focus_mode = Control.FOCUS_NONE; b2.pressed.connect(func(): act.call("gstand")); row.add_child(b2)
		"hl":
			w.head("Higher or lower, for " + D.coins(int(G.bet)))
			_card_row("He turns up", [G.card] + ([G.next] if int(G.next) >= 0 else []), 0 if int(G.next) >= 0 else 1)
			if over:
				verdict.call(); again.call()
			else:
				var pays := Rules.hl_pays(int(G.card), int(G.bet))
				var row := HBoxContainer.new()
				row.add_theme_constant_override("separation", 8)
				w.body.add_child(row)
				for k in 2:
					var b := Button.new()
					b.text = ("Higher" if k == 0 else "Lower") + (": pays %s" % D.coins(pays[k]) if pays[k] > 0 else ": cannot be")
					b.focus_mode = Control.FOCUS_NONE
					b.disabled = pays[k] <= 0
					var a: String = "ghi" if k == 0 else "glo"
					b.pressed.connect(func(): act.call(a))
					row.add_child(b)
				w.para("An ace is the lowest card and a king the highest.", 13, Look.INK_SOFT)
		"cups":
			w.head("The pea and the cups, for " + D.coins(int(G.bet)))
			var cv := Cups.new()
			cv.ball = int(G.ball); cv.swaps = G.swaps; cv.sp = float(G.sp)
			cv.can_pick = float(G.t) <= 0.0
			if over:
				cv.shown = int(G.at); cv.chosen = int(G.pick)
			cv.picked.connect(func(i): act.call("gcup", i))
			w.body.add_child(cv)
			if over:
				verdict.call(); again.call()
			else:
				w.para("Watch the pea go under, then follow its cup. When he stops, click the cup." if float(G.t) > 0.0 else "“Well?” Click a cup.", 15, Look.INK_SOFT)
	w.hint("Walking away from the table forfeits a game in progress.")


# ---------------------------------------------------------------- your backpack, as slots
var _pack_sig := ""
var _arm_inv := ""
var _destroy_arm := -1              # which backpack place has had its flame pressed once
var _info: Label

func pack(force: bool = false) -> void:
	var p: E.Player = m.me
	if str(p.inv) != _arm_inv:                          # the backpack has changed: nothing is half-destroyed any more
		_arm_inv = str(p.inv); _destroy_arm = -1
	var sig := str([p.inv, p.wpn, p.head, p.body, p.off, p.trk, p.bless, p.holy, p.books, p.bodies, p.bbod, p.coin >= D.BLESS_FEE, Settings.binds, _destroy_arm])
	if sig == _pack_sig and w.is_open("pack") and not force:
		return
	_pack_sig = sig
	var W: Dictionary = D.IT[p.wpn]
	w.open("pack", "Your backpack", "In your hand: %s. {trick}: %s, %s." % [W.n, D.AB[W.ab].n, D.AB[W.ab].d], 640, 560, true, false)
	w.head("On you")
	var on := HBoxContainer.new()
	on.add_theme_constant_override("separation", 8)
	w.body.add_child(on)
	for k in D.SLOTS:
		var id: int = p.get(k)
		var has_it: bool = id >= 0 and not (k != "wpn" and id == 0)
		var tip := (D.it_cap(id) + ". " + (Notices.item_sub(p, id) if Notices.item_sub(p, id) != "" else "Everyone has one. It cannot be put away.") + (" Click to put it away." if id > 0 else "")) if has_it else ""
		var blessed: bool = (k == "wpn" and p.bless & 1) or (k == "trk" and p.bless & 2)
		var slot: String = k
		_slot(on, id if has_it else -1, Notices.SLOTN[k], "", tip, blessed, func(): m.inv_do("uneq", slot), Callable())
	w.head("In your backpack (%d of %d)" % [p.inv.size(), D.PACK_MAX])
	var inv := HBoxContainer.new()
	inv.add_theme_constant_override("separation", 8)
	w.body.add_child(inv)
	for i in D.PACK_MAX:
		if i >= p.inv.size():
			_slot(inv, -1, "", str(i + 1), "", false, Callable(), Callable())
			continue
		var id: int = p.inv[i]
		var can := Rules.can_use(p, id)
		var j := i
		var burn := func() -> void:
			if _destroy_arm == j:
				_destroy_arm = -1; m.inv_do("destroy", j)
			else:
				_destroy_arm = j; pack(true)
		_slot(inv, id, "", str(i + 1), "%s. %s Click to %s." % [D.it_cap(id), Notices.item_sub(p, id), Notices.lower(Notices.WEARV[D.IT[id].s])], false,
			func(): m.inv_do("eq", j), func(): m.inv_do("dropi", j), not can, burn, _destroy_arm == j)
	_info = w.para("Point at a thing to read about it. Click it to use it or put it away. The little cross drops it on the ground (it lies there two days); the little flame, pressed twice, destroys it for good.", 14, Look.INK_SOFT)
	_info.custom_minimum_size.y = 58
	var bl: Array = Notices.data(m.R, "pack", p, "").o.filter(func(o): return o.get("a") == "bless")
	if bl.size():
		w.head("Blessings")
		for o in bl:
			var arg: String = o.arg
			var bt := Button.new()
			bt.text = o.label
			bt.tooltip_text = Keys.fill(o.sub)
			bt.disabled = not o.ok
			bt.focus_mode = Control.FOCUS_NONE
			bt.alignment = HORIZONTAL_ALIGNMENT_LEFT
			bt.pressed.connect(func(): m.inv_do("bless", arg))
			w.body.add_child(bt)
	w.hint("1 to 6: use it. {swap}: next weapon, without opening this. {pack} or Esc: close. Spare arms can go on the rack in the storehouse.")


# ---------------------------------------------------------------- playing together
func _host() -> void:
	var why: String = Net.me.host(Settings.name if Settings.name != "" else "Peasant", Settings.col)
	if why != "":
		Net.me.status = why
		home()
		return
	var saved = m.read_save()
	Net.me.saved_day = int(saved.day) if saved else 0
	lobby()


func _join(text: String) -> void:
	var why: String = Net.me.join(text, Settings.name if Settings.name != "" else "Peasant", Settings.col)
	if why != "":
		Net.me.status = why
		home()
		return
	lobby()


## Who is coming: the code to give your friends, and everyone who has joined. The host starts the week.
func lobby() -> void:
	var N: Net = Net.me
	if not N.online():                               # the connection has gone (or never came): back home, saying why
		home()
		return
	var host := N.is_host()
	var b: VBoxContainer = w.open("lobby", "Your village" if host else "Joining a village", "", 640, 540, false, false)
	if host:
		w.head("The village code")
		var cr := HBoxContainer.new()
		cr.add_theme_constant_override("separation", 14)
		b.add_child(cr)
		var shown: String = N.code if N.code != "" else ("....." if N.via_relay else N.lan_code)
		var cl := Look.label(cr, shown, 34, Look.INK, true)
		cl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cp := Button.new(); cp.text = "Copy"; cp.focus_mode = Control.FOCUS_NONE
		cp.pressed.connect(func(): DisplayServer.clipboard_set(shown); cp.text = "Copied")
		cr.add_child(cp)
		match N.port_open:
			"relay": w.para("Friends type this into Join on their home screen. It works from anywhere: everyone goes through the village server.", 14, Look.INK_SOFT)
			"trying": w.para("Asking the village server for a code..." if N.via_relay else "Asking your router to let friends in...", 14, Look.INK_SOFT)
			"open": w.para("Friends type this into Join on their home screen. On the same home network, %s works too." % N.lan_code, 14, Look.INK_SOFT)
			_: w.para("Your router would not open the way in by itself, so this is the code for your home network only: it works for anyone on the same wifi. For friends elsewhere, open port %d (UDP) to this computer on your router, then give them your internet address instead." % N.PORT, 14, Look.ROSE)
	elif N.my_id == 0:
		w.para(N.status if N.status != "" else "Knocking on the village gate...", 16, Look.INK)
	w.head("Who is here (%d of %d)" % [N.lobby.size(), N.MAX_PLAYERS])
	for l in N.lobby:
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 10)
		b.add_child(r)
		var dot := Panel.new()
		var st := StyleBoxFlat.new(); st.bg_color = Color(D.PCOL[int(l.col) % 8]); st.set_corner_radius_all(9); st.border_color = Look.INK; st.set_border_width_all(1)
		dot.add_theme_stylebox_override("panel", st)
		dot.custom_minimum_size = Vector2(18, 18)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		r.add_child(dot)
		Look.label(r, str(l.name) + ("  (host)" if int(l.id) == 1 else "") + ("  (you)" if int(l.id) == N.my_id else ""), 18)
	if host:
		w.foot_button("Close the village", func(): N.leave(); home())
		if N.saved_day > 0:
			w.foot_button("Carry on from day %d" % N.saved_day, func(): m.begin(m.read_save()))
		w.foot_button("A short game", func(): m.begin_new(D.WEEK))
		w.foot_button("Start a new month", func(): m.begin_new(D.MONTH), true)
		w.hint("Start when everyone is in. Nobody can join once the month has begun. The short game is seven nights.")
	else:
		w.foot_button("Leave", func(): N.leave(); home())
		w.hint("Waiting for the host to start." if N.my_id != 0 else "")


# ---------------------------------------------------------------- skills: each book as a ladder of seven ranks
var skill_book := -1
var _skills_sig := ""
const ROMAN := ["", "I", "II", "III", "IV", "V", "VI", "VII"]

func skills(force: bool = false) -> void:
	var p: E.Player = m.me
	var owned: Array = []
	for i in D.BOOKS.size():
		if Rules.rk(p, i) > 0: owned.append(i)
	if skill_book < 0 or not owned.has(skill_book):
		skill_book = owned[0] if owned.size() else -1
	var sig := str(p.books) + str(p.xp.map(func(x): return floori(x))) + str(floori(p.spare)) + str(skill_book) + str(p.coward)
	if not force and w.is_open("skills") and sig == _skills_sig:
		return
	_skills_sig = sig
	var slots := Rules.book_slots(p)
	w.open("skills", "Your skills", "%s, %s. " % [p.dn, Rules.title_of(p)] + "Every book is learned by doing what it teaches, and each rank takes more practice than the last." + (" You can take %s more from the library." % ("one" if slots == 1 else str(slots)) if slots > 0 else ""), 940, 640, true, true)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 18)
	w.body.add_child(cols)
	# left: the ten books
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 270
	left.add_theme_constant_override("separation", 4)
	cols.add_child(left)
	for i in D.BOOKS.size():
		var bk: Dictionary = D.BOOKS[i]
		var bt := Button.new()
		bt.focus_mode = Control.FOCUS_NONE
		bt.toggle_mode = true
		bt.button_pressed = i == skill_book
		var rr := Rules.rk(p, i)
		bt.disabled = rr == 0
		bt.alignment = HORIZONTAL_ALIGNMENT_LEFT
		bt.text = ("%s   %s" % [ROMAN[rr], bk.what]) if rr else "—   " + bk.what
		bt.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		bt.clip_text = true
		bt.tooltip_text = bk.name if rr else bk.name + ". In the library."
		bt.add_theme_font_size_override("font_size", 16)
		var bi := i
		bt.pressed.connect(func(): skill_book = bi; skills.call_deferred(true))
		left.add_child(bt)
	# right: the chosen book's ranks
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 0)
	cols.add_child(right)
	if skill_book < 0:
		Look.para(right, "No book yet. The library has one waiting for you: walk in and hold {interact}.".replace("{interact}", Keys.name("interact")), 18, Look.INK_SOFT)
	else:
		var b := skill_book
		var bk: Dictionary = D.BOOKS[b]
		var rank: int = Rules.rk(p, b)
		Look.label(right, bk.name, 26, Look.INK, true)
		Look.para(right, "%s. You learn it by %s.%s" % [bk.what, bk.by, " Halved while you are a coward." if p.coward else ""], 15, Look.INK_SOFT)
		var gap := Control.new(); gap.custom_minimum_size.y = 8; right.add_child(gap)
		for r in range(1, 8):
			var got := rank >= r
			var next := rank + 1 == r
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 12)
			right.add_child(row)
			var med := PanelContainer.new()
			var ms := StyleBoxFlat.new()
			ms.bg_color = Look.GOLD if got else Color("efe0b6") if next else Color("e2d3aa")
			ms.border_color = Look.OUTLINE if got or next else Color(Look.OUTLINE, 0.35)
			ms.set_border_width_all(2)
			ms.set_corner_radius_all(20)
			med.add_theme_stylebox_override("panel", ms)
			med.custom_minimum_size = Vector2(40, 40)
			med.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			row.add_child(med)
			var num := Look.label(med, ROMAN[r], 17, Look.INK if got or next else Color(Look.INK, 0.4))
			num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			var tv := VBoxContainer.new()
			tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			tv.add_theme_constant_override("separation", 1)
			row.add_child(tv)
			var t := Look.para(tv, Keys.fill(bk.ranks[r - 1]), 16, Look.INK if got else Look.INK_SOFT if next else Color(Look.INK_SOFT, 0.6))
			if next:
				var lo := Rules.need_xp(b, rank - 1) if rank > 1 else 0
				var hi := Rules.need_xp(b, rank)
				var f := clampf((p.xp[b] - lo) / float(hi - lo), 0, 1)
				var bar := ProgressBar.new()
				bar.custom_minimum_size = Vector2(0, 8)
				bar.show_percentage = false
				bar.max_value = 1.0
				bar.value = f
				var bg := StyleBoxFlat.new(); bg.bg_color = Color("3a2d22"); bg.set_corner_radius_all(3)
				var fg := StyleBoxFlat.new(); fg.bg_color = Look.GOLD; fg.set_corner_radius_all(3)
				bar.add_theme_stylebox_override("background", bg)
				bar.add_theme_stylebox_override("fill", fg)
				tv.add_child(bar)
				Look.label(tv, "Next rank: %d%% of the way" % roundi(f * 100), 13, Look.RUST)
			if r < 7:                                              # the line joining one rank to the next
				var link := HBoxContainer.new()
				right.add_child(link)
				var stem := ColorRect.new()
				stem.color = Look.GOLD if rank > r else Color(Look.OUTLINE, 0.3)
				stem.custom_minimum_size = Vector2(4, 10)
				var pad := Control.new(); pad.custom_minimum_size.x = 18
				link.add_child(pad); link.add_child(stem)
		if rank >= 7:
			var done := Look.para(right, "Mastered. What you learn from this book now is spare.", 15, Look.RUST)
			done.custom_minimum_size.y = 26
	# spare learning, sold for coin
	w.head("Spare learning")
	var sp := floori(p.spare)
	var srow := HBoxContainer.new()
	srow.add_theme_constant_override("separation", 14)
	w.body.add_child(srow)
	var st := Look.para(srow, ("%d spare point%s, worth %s." % [sp, "" if sp == 1 else "s", D.coins(sp * D.SPARE_PAY)]) if sp > 0 else "When a book reaches rank VII, whatever more you learn from it is kept here as spare points, and sold for %s each." % D.coins(D.SPARE_PAY), 15, Look.INK_SOFT)
	st.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sell := Button.new()
	sell.text = "Sell for coin"
	sell.disabled = sp <= 0
	sell.focus_mode = Control.FOCUS_NONE
	sell.pressed.connect(func(): m.sell_spare())
	srow.add_child(sell)
	w.hint("{skills} or Esc: close.")


func _slot(parent: Control, id: int, label: String, num: String, tip: String, blessed: bool, cb: Callable, drop: Callable, locked: bool = false, destroy: Callable = Callable(), armed: bool = false) -> void:
	var box := Control.new()
	box.custom_minimum_size = Vector2(88, 96)
	parent.add_child(box)
	var b := Button.new()
	b.set_anchors_preset(Control.PRESET_FULL_RECT)
	b.focus_mode = Control.FOCUS_NONE
	b.disabled = id < 0
	var st := Look.card(Color("fff6dc") if id >= 0 else Color("e2cf9c"), Look.OUTLINE if id >= 0 else Color("8a7556"), 4)
	if id < 0: b.self_modulate = Color(1, 1, 1, 0.6)
	b.add_theme_stylebox_override("normal", st)
	b.add_theme_stylebox_override("disabled", st)
	var hv := Look.card(Color("fffbe9"), Look.ROSE, 4)
	b.add_theme_stylebox_override("hover", hv)
	b.add_theme_stylebox_override("pressed", hv)
	box.add_child(b)
	if cb.is_valid(): b.pressed.connect(cb)
	if tip != "":
		b.mouse_entered.connect(func(): if _info: _info.text = Keys.fill(tip))
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_top = 4; v.offset_bottom = -4; v.offset_left = 2; v.offset_right = -2
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 0)
	box.add_child(v)
	if num != "":
		var nl := Look.label(v, num, 11, Look.ROSE)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if id >= 0:
		var ic := TextureRect.new()
		ic.texture = Look.icon(id, 40)
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.custom_minimum_size = Vector2(40, 40)
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if locked: ic.modulate = Color(1, 1, 1, 0.4)
		v.add_child(ic)
		var nm := Look.label(v, D.IT[id].n + (" ✝" if blessed else ""), 11, Look.INK if not locked else Color(Look.INK, 0.5))
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nm.custom_minimum_size.x = 80
	if label != "":
		var ll := Look.label(v, label, 11, Look.INK_SOFT)
		ll.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for c in v.get_children(): c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if drop.is_valid():
		var x := Button.new()
		x.text = "✕"
		x.tooltip_text = "Drop it on the ground"
		x.focus_mode = Control.FOCUS_NONE
		x.add_theme_font_size_override("font_size", 11)
		x.position = Vector2(50, -6)
		x.size = Vector2(26, 24)
		x.pressed.connect(drop)
		box.add_child(x)
	if destroy.is_valid():                              # the little flame: break it up for good. Press twice.
		var k := Button.new()
		k.icon = Look.icon("burn", 16)
		k.tooltip_text = "Press again to destroy it for good" if armed else "Destroy it for good (press twice)"
		k.focus_mode = Control.FOCUS_NONE
		k.position = Vector2(-6, -6)
		k.size = Vector2(26, 24)
		if armed: k.modulate = Color(1.0, 0.45, 0.35)
		k.pressed.connect(destroy)
		box.add_child(k)


# ---------------------------------------------------------------- dawn, and the end
func dawn(day: int, lines: Array) -> void:
	w.open("dawn", "Day %d of %d" % [day, m.R.last_day], "", 620, minf(560, 250 + 52 * lines.size()), true)
	for l in lines:
		w.para("•  " + l, 16)
	w.foot_button("To work", func(): w.close(), true)
	w.hint("Esc closes this. It says where the stone, the iron and the fish are today; so does the map.")


func ending(won: bool) -> void:
	var R: Rules = m.R
	var month: bool = R.last_day >= D.MONTH
	w.open("end", ("The month is over" if month else "The short game is won") if won else "The keep has fallen", "", 620, 520, false)
	w.para(("Thornhallow has held for thirty nights. The Lord of Ashhollow has been put back in his box, and the castle is to let again. Robert Bailiff has opened an upstairs window to say that it all went exactly as he planned." if month
		else "Thornhallow has held for seven very long nights, and the Lord of Ashhollow has gone back up the hill in several pieces. Robert Bailiff has opened an upstairs window to say that it all went exactly as he planned.") if won
		else "The dead reached the families in the keep. Robert Bailiff’s door remains bolted.", 16)
	if won:
		for l in R.dawn.lines: w.para("•  " + l, 14, Look.INK_SOFT)
	w.para("Undead put down: %d  ·  Peasants lost: %d  ·  Defences built: %d  ·  Keep: %d of %d" % [R.stats.kills, R.stats.lost, R.stats.built, maxi(0, roundi(R.keepHp)), roundi(D.KEEP_HP)], 15, Look.RUST)
	w.para("Well done. The bookshelf has been dusted for next time." if won else "Day %d was saved at dawn, so you can have it again." % R.day, 14, Look.INK_SOFT)
	w.foot_button("Home", func(): m.to_home())
	if Net.me.is_client():
		w.hint("The host chooses what happens next.")
	elif won:
		w.foot_button("Start a new month", func(): m.begin_new(D.MONTH), true)
	else:
		w.foot_button("Try day %d again" % R.day, func(): m.begin(m.read_save()), true)
