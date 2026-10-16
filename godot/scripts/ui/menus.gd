extends RefCounted
## What goes in the window: the home screen, the handbook (guide, controls, options), a place's notice,
## your backpack, the dawn notice, and the end of the week. main.gd says which; this fills it in.

## The handbook (version 7.37: in chapters, each with its pages). A paragraph "@books:<n>" is the books of D.BOOK_GROUPS[n], from the books themselves.
const GUIDE := [
	["Getting started", [
		["The short version", ["By day, gather and build. At dusk the bell rings. At night the dead rise along the graveyard to the north, one after another without a pause and faster as the night goes on, and make for the keep, where the families are hiding. If the keep falls, Thornhallow is lost. Hold for the month: thirty nights (or seven, in the short game).", "Nearly everything is done by walking up to it and holding {interact}."]],
		["The day", ["A day lasts six minutes, or until everyone presses {ready}.", "Wood comes from trees, stone from the rocky outcrop, iron from the mine, food from the farms to the west, fish from the jetty on the river. The stone, the iron and the fishing move every morning: the dawn notice says where, and the map marks them. You carry 20 of each (30, 40 and then 50 with the Woodcutter’s Almanac).", "At the jetty, hold {interact} and press {jump} or left-click when something bites."]],
		["Looking around", ["The view starts from the south, with north up the screen, but you can swing it round your peasant. Press the mouse wheel in and drag, or hold {look} and move the mouse: left and right turn the view, up and down tilt it. {cam_left} and {cam_right} turn it from the keyboard. Roll the wheel to come closer or go further off. {cam_reset} puts it all back.", "Moving follows the view: {up} is always away from you, up the screen. The map in the corner stays north up, and the pale fan on your dot shows which way you are looking."]],
		["Reading the screen", ["Top left, on one scroll: the day and the time left, whether you are ready, and under a line what you carry, as pictures with a number: only the things you have, and your coin. A number in red is a full load. Top middle: the keep, and the boss when one comes. Top right: the map, in its frame. Bottom middle: your health, and under it the action bar (your weapon’s trick, each book’s power, what you carry, orders, the toilet break; 1 to 9 for the first nine), with your posse, backpack and skills beside it. What holding {interact} would do shows just above. Hold {build} for the building wheel.", "Places, your backpack, the dawn and this handbook all open in one window in the middle. Esc closes it, or the cross; walking away closes a place's notice."]],
		["The lie of the land", ["Thornhallow sits in the middle, with the castle up the road to the north and the river to the south. The thorn hedges, far to the west and east, are the edge of the world. West is Hallowshire Forest, with the old steel mine at its top end; east are the downs and the old mill. The stone, the iron and the fish move every morning (the dawn notice says where), and the far places are a long walk, so go early."]],
	]],
	["The village and its places", [
		["The library", ["The library: go in by its door, facing the market. The Peasants’ Section, on the right, is where your books are: four of them (five with the Index of Further Reading) from a shelf of sixteen, ten ranks each, earned by doing what the book teaches. The Holy Book, the Jester and the Knight’s Squire do not count against your four. The librarian is at her desk; the rest of the library is behind a rope, for those with a coat of arms. The library shuts at nightfall.", "The library is also where a library card is handed in (they turn up in chests): give up one of your books and take up another, a rank behind where the old one was."]],
		["The smithy, the storehouse, the market and the slum", ["The smithy: pick a tier (crude, iron, steel, mithril, rune), then click a picture to forge it; and kits for your posse. The storehouse: the village’s shared materials on one tab (take out 1, 5 or 20; put in 1, 5 or all) and its spare arms and armour on the other (click a thing to take it, click one of yours to put it in; things that are the same share a place, with a number on it). Mithril and runes can be left there for whoever is the smith. The market: pays a penny a piece for what you bring, and charges two for what you take. The slum: recruits."]],
		["The Thorny Rose", ["Hold {interact} at the inn’s door on the square to go in. It is open day and night, until the dead break the door down; your posse waits outside (and comes in with you if you sit down to drink). The door back out is at the bottom of the room.", "The bar: give the innkeeper food and he turns it into ale for the night; hire a mercenary; and after dark, sit down to drink. Each tankard is Dutch courage, and at 100 you burst out and charge.", "Old Marge, Tam the Carter and the stranger in the corner will each talk about three things, and each does one good turn a day for the price of a drink (6d).", "The gambler plays twenty-one, higher or lower, and the pea and the cups, for stakes of sixpence to four shillings. Twenty-one and higher or lower are luck, with the odds a little his way. The cups are not luck: watch the pea go under, follow that cup, and click it when he stops. Walking away from the table loses the stake."]],
		["The priest", ["The priest is inside his chapel, at the altar rail: go in at the door under the bell tower, by day or by night. Blessings for two shillings: a weapon blessed is holy until dawn, and a slop bucket blessed scorches. He also gives classes in holy studies.", "His classes in holy studies: ask him for one and you are sat in a pew with the bible open on your knees, for forty-five seconds of it. Stay put; get up (hold {interact}, or walk off) and he remembers where you got to. One class lets you bless your own weapon or bucket, anywhere, for nothing; two let you bless the departed, for body walls.", "On the nights of the bells he lights every candle he owns, and the windows blaze for miles around."]],
		["About the village", ["Robert Bailiff will talk to you from his upstairs window: stand at his front door. You can knock (it will not open) or jeer at him, which is satisfying, but he remembers, and his guards cost a shilling more for every jeer that day.", "Anyone can ring the village bell in the square. It does nothing at all.", "The training yard's straw dummies: practise on them by day for a little of The Art of Hitting Things (or, with a sling or a bow, Slings, Bows and Thrown Turnips). There is only so much a dummy can teach you in a day."]],
		["The windmill, the Herder and strays", ["The windmill does something at last. By day, take it 10 food and the miller lays on a banquet for your posse: it mends them slowly all through the night. Not you, only them. Or leave 13 food and 5d on the offering plate inside the east gate, and one of your posse carries it out there for you; it counts once he has arrived. Each leader pays for their own posse, afresh every day.", "The Herder stands by the sheepfold on the downs. Hold {interact} beside him for a lesson in sheep herding: about half a minute stood listening, then two questions. Nobody fails; some take longer. After that he will let you tame a sheep of your own, for one food.", "Your sheep is on the action bar: press it to get on and again to get off, or hold {interact} to get off. It is a quarter quicker than walking, and boots do nothing for it. From its back you cannot fight, gather or use any place. It wants one food a day, taken from what you carry, and will not be ridden hungry. At dusk it goes in the cupboard under your stairs until morning.", "Strays hide round the farms and in the forest, deeper in as the weeks go on, and there are fewer of them. Hold {interact} beside one to talk him round. He joins your posse over and above its usual size: one a week at most, two at a time. He is a bit weaker, and looks it. Each evening there is one chance in the hundred, for every player in the game, that he runs off, with his kit if he had one and a shilling of your coin."]],
	]],
	["Resources", [
		["Gathering", ["Wood comes from trees, stone from the rocky outcrop, iron from the mine, food from the farms to the west, fish from the jetty on the river. The stone, the iron and the fishing move every morning: the dawn notice says where, and the map marks them. You carry 20 of each (30, 40 and then 50 with the Woodcutter’s Almanac). Your posse gathers when you gather.", "Steel comes from the old steel mine at the top of the forest; the market pays well for it but sells none. Mithril is down the Old Mine, beside it. Runes are in the Rune Cave, across the river."]],
		["Fishing, and the farms", ["The farms give food: everyone you lead forages with you. Food is what everything else wants: meals ({eat} heals you a little), the slum, the inn's barrel, the windmill, your sheep, the druid.", "The jetty gives fish, which are not food. A catch is five fish (seven at rank 3 of Field, Hook and Pot), and your posse cannot help. Eat a fish, from the action bar, and it heals 60 at once (all of it, at rank X of Field, Hook and Pot); then there is a wait of thirty seconds before the next. So a few fish in your pack are worth a great deal at night. They also sell at the market for twice what food does. And the river keeps what falls in it: now and then a catch brings up a purse, once in a long while a lump of mithril, and very rarely something somebody dropped.", "Field, Hook and Pot makes you the posse's cook: from its first rank, at night, any of your posse who is badly hurt eats one of your food and mends. Its later ranks make meals and fish better: bigger catches, more of the river's lost things, prize fish, and at rank 10 a fish that heals everyone near you."]],
		["The Old Mine and mithril", ["Anyone can make a burning torch at the smithy (three wood). What it hits burns for four seconds after, and Flare ({trick}) sets fire to everything round you and drives it back a step. Bones burn badly, wraiths not at all, and rain halves it. It also lights your way.", "Beside the old steel mine, far to the north-west, a timber frame stands over a hole: hold {interact} to climb down into the Old Mine. Down there it is dark, the dead cannot reach you, and your posse waits at the top. Three veins of mithril glow purple in the walls. With a burning torch in your hand, hold {interact} at a vein to prise out a lump: two to a vein each day (three with five or six players, four with seven or eight). The ladder takes you back up, and dawn fetches you out whatever you are doing.", "Mithril is what the village used to call runes, until somebody found the real ones. A smith at rank 7 of Hammer and Tongs can forge all of it in mithril: the five weapons, a bow, a crossbow, a cap, a chain shirt and a shield. It is half as good again as iron, glows purple, and the weapons bite wraiths."]],
		["Ruins, chests and cards", ["The ruins: the old one by the chapel, and two outer ruins outside the wall, somewhere new each day (your map shows them once you have found them, or from the morning with the Night Watchman’s Companion at rank 4): hold {interact} at a heap of rubble. Relics turn up, more often by moonlight. Searching outside the wall is noisy.", "The outer ruins are not empty. Rummaging is noisy, and brings shamblers; from the second day it can also wake the Previous Tenant, who is several times the size and has a great deal of health. By day he will not follow you far from his ruin. After dark he goes down to the village with the rest. Whoever puts him down gets his back rent.", "Once a week a chest sent to help the village goes astray. The dawn notice says who sent it and which way the messenger set off. It lies outside the wall, off the map until somebody walks near it. The finder gets the coin; anything else inside can be dropped for a friend.", "A library card (from a chest) is handed in at the library to swap one of your books for another. The new one starts a rank behind the old."]],
	]],
	["Defences", [
		["Walls, gates and barricades", ["The north wall has seven foundations: six walls and a gate. Stand on one and hold {interact}. Barricades and spike rows go anywhere: hold {build} and the building wheel opens round you; let go over the one you want (a quick tap steps through them instead), then {interact} or click to put it down.", "Hold {interact} at a damaged defence to repair it with wood. Carrying stone or iron, hold {interact} again to face a wall with stone, band the gate or brace a barricade. An unbraced barricade rots by half every evening after its first night.", "Nobody can be hit through a standing wall or gate, in either direction. Go out through the gate, or shoot over."]],
		["Watch towers and the side gates", ["The north wall stands three paces further out than it did, and behind it are four places for watch towers: one in each corner and one either side of the gate. A tower is 25 wood and 8 stone, built on its site like a wall. Like the wall, the gates and the side gates, it can be brought in loads, by anybody: hold {interact} at the site and whatever you carry that it still wants goes in. Hold {interact} beside one for its notice: send one of your posse up, or coax one of yours down from the safety of it. Six can be up a tower at once, from anybody’s posse. Any of your posse can go, kit and all, and hired swords too. By day they stay with you; from dusk they climb up and throw stones at anything within about fifteen paces, over the wall and all, and only archers can reach them (ten wood roofs it, which stops that). A tower wants seeing to every morning, 4 wood and 1 iron, or nobody will climb it that night. The dead can break one, and you can take one down yourself, for half of what it cost. Either way the site stays.", "The dead also come round to the west and east gates now. In the first two weeks they use one a night, the east one night and the west the next; from the third week, both. The dawn notice says which. A gate can be built on each gateway, as on the north one. There are no towers there; nobody has asked why."]],
		["Contraptions", ["Barricades for Beginners teaches the village's inventions, one every rank or so, and a box of cogs from the tinker builds any one without the book. They are on the building wheel: hold {build} and pick one.", "The chicken decoy (rank 1): nothing dead can ignore it, briefly. The pitfall (3): swallows four for good; good inside the wall, for gravediggers. The tar pit (4): the dead wade through it, slowly. The holy water trough (5, and a class of holy studies or the Holy Book): burns whatever crosses it, wraiths too. The log roller (6), up the road north of the wall: once a night it flattens a crowd, or a coffin ram. The Thresher (7): a spinning flail, as long as someone stands by to turn the handle."]],
	]],
	["Your posse", [
		["Your posse", ["Hold {interact} beside a neighbour to rally them. They gather when you gather and fight when you fight. The slum has more, for food. The smithy gives them spears.", "Click the Posse slot on the bar to send them home to your cottage, where they wait by the door and see off anything that comes, or to whistle them back to you. A whistle does not carry across the river, and anyone with you on the far bank stays with you: the raft does not run errands.", "They can die, and they have nerve: when friends fall they may run for the keep until dawn. The toilet break, on the action bar, sends the dead nearby running. With How to Win Peasants and Lead Them, the orders button on the bar tells them to follow or to hold where they stand; rank 3 adds charge. That book is learned by leading: your first ten orders of a day, rallying and recruiting, the work and the blows of your posse, and every one of them still standing at dawn."]],
	]],
	["Fighting", [
		["Fighting", ["A left click attacks. {jump} jumps: a quick leap whichever way you are pressing, forwards, sideways or back, and you keep facing the way you were, which is how you get out of the way of a sweep or a charge without turning your back on whoever is doing it. With nothing pressed you jump on the spot, which achieves very little, cheerfully. A right-click, or the first button on the action bar, is your weapon’s own trick: every weapon has a different one, with a short wait between uses. {eat} eats one food.", "Every blow that lands shows what it did. A plain number is an ordinary blow. A big gold one means you have the right tool for the job (a mace on bones, holy things on anything, a hammer on the ram). A small grey one, with a tink, means you have the wrong one: farm tools on armour, anything swung at bats. A big orange one with a mark after it is a lucky double. Small orange ones are things burning. The numbers, and the knock your own blows give the view, can be turned off in Options.", "Knocked down, you have 15 seconds for a team-mate to hold {interact} over you. After that a relative takes over your cottage at dawn, with your books but not your gear. Relics lie where you fell.", "From dusk you can hide in your own cottage. It is safe, and the village will call you a coward until the next dusk."]],
		["Things you carry", ["{pack} opens your backpack: what is on you, and six places for spares. Click a thing to use it or put it away. {swap} swaps to the next weapon in the backpack without opening it. A slop bucket or a handbell has its button on the action bar: it throws the one and rings the other.", "A bow needs the book Slings, Bows and Thrown Turnips, which comes with a sling. A crossbow needs rank 3 of it. Heavy arms need rank 2 of Hammer and Tongs to forge."]],
	]],
	["Books and skills", [
		["How books work", ["{skills} shows your books as skill trees: what every rank does and how close the next is. Learning past rank X is spare: it sells for coin there, or ten spare points hone a page into a book at rank X, two in the hundred on all it does, five pages to a book.", "Your title: the village names you after the two books you know best, the one you know best last (the Sooty Ringleader, the Holy Apprentice Priest). It shows top left.", "A fifth book: An Index of Further Reading turns up, rarely, in the ruins. Read it and the library lets you take up one more.", "A library card (from a chest) is handed in at the library to swap one of your books for another. The new one starts a rank behind the old."]],
		["Gathering and making", ["@books:0"]],
		["Fighting", ["@books:1"]],
		["Leading and looking after", ["@books:2"]],
		["Callings and quests", ["@books:3"]],
		["Powers, and the action bar", ["Every book has a power of its own, from its first rank, on the action bar along the bottom of the screen: click it, or press its number. Many Hands (the Woodcutter): you and your posse gather twice as fast for twenty seconds. Pot Luck (Field, Hook and Pot): one food feeds and heals everyone near you. Shore It Up (Barricades): every defence near you mended by a third. The Whetstone (Hammer and Tongs): everyone near you hits a fifth harder for thirty seconds. Red Mist (the Art of Hitting Things): eight seconds of swinging a third faster, unmovable. The Marked Man (Slings and Bows): one of the dead is marked; everyone’s shots and every tower go for it, and it takes a quarter more. War Cry (Leading): your posse hits harder and does not lose its nerve. A Round on Me (the Ledger): Dutch courage for everyone near you. Hone (Relics): a pillar of light over a heap of rubble that is certain to hold a relic. Smelling Salts (Granny): everyone near you who is down gets up. The Holy Book has its calling’s three: Smite, Pray and Consecrate.", "Each has a wait before it can be used again, shown on its button. Honed pages make them stronger or longer. In the skills window ({skills}) you can put the bar in another order, and take things off it."]],
		["The Holy Book: the apprentice priest", ["The Holy Book, on the library shelf with the other callings, makes you an apprentice priest: a peasant's version of a mage, which is to say not much of one. Smite, on the action bar, is a bolt of holy light on the nearest of the dead; from rank 2, Pray is a third less harm for ten seconds for you and everyone near you, posse included. Later ranks make the prayer bless weapons and mend wounds, and the smite burst and strike three at once; at rank X, Consecrate makes a patch of ground round you that the dead will not cross for eight seconds. Smites are holy, so they hurt wraiths.", "One calling at a time. You learn the book by smiting and praying."]],
		["The Jester: Prospero’s lessons", ["The last book on the library shelf, Jester the Faux Magician, is not there. Take it and you get a note: its author withdrew it, because nobody was reading it properly, and he teaches it himself. He is Prospero, the old jester on the stool by the fire in the Thorny Rose.", "He gives three lessons, by day only, each for a tankard from the inn's barrel (give the innkeeper food to fill it). A lesson is about forty-five seconds stood beside him, and then two questions. A wrong answer gets a remark and another go. The first lesson makes you a jester (it does not count against your books); a priest cannot be one, and a jester cannot be a priest. Before the next lesson, play your newest trick on twenty of the dead.", "The tricks go on the action bar. Is This Your Card? throws a card at the nearest of the dead, about as hard as a smite. Abracadabra, Roughly is a bang and coloured smoke that hurts and staggers everything round you. A Jape at Their Expense confuses the dead near you for six seconds: they wander, and some hit each other. Bosses are not confused. They are insulted, and come for you.", "Every trick is a roll of the dice. One time in six it fails (only a card, only smoke, nobody laughs); one time in six it works twice as well. The ranks, earned by playing tricks on the dead, make them fail less and work better; rank 10, the Encore, means a trick that follows a failure cannot fail. Prospero's Marotte, the jester's relic, does that at any rank."]],
		["The Knight’s Squire: Sir Aldous’s errand", ["Sir Aldous de Vere, a knight, is doing some research in the library, behind the rope. He has mislaid his squire. He wants a short sword, and he is very particular: crude, iron, steel or mithril, a different one for each of you, and he will not say which. Show him one from your hand or your backpack. The wrong one he gives back, with a word about whether he had hoped for something finer or humbler; the right one he keeps. Do not show him a rune sword. He will take it off you at swordpoint, and it is still not the right one.", "Then he wants his squire’s notebook. It is in a chest in the cabin at the end of the lane past the west hedge: follow the west road out through the hedge, where the fingerpost is, and hold {interact}. The squire has gone; the clearing has a few things to say about where. The chest has a lock of three dials, a sheep, a candle and a crow; the cabin has three paintings, numbered I, II and III. Count what is in each. The lane is no place to be after dark: you are sent home when night falls.", "Take him the notebook and he reads you a few pages: the Knight’s Squire, at rank I, and his squire’s old practice blade. The book does not count against your books. It is learned by greatsword blows and Challenges.", "A greatsword takes both hands: nothing goes in the off hand, and taking up a shield puts it away. Only a reader of the Knight’s Squire can swing one, and from rank III the smithy forges them, in every metal. Challenge!, on the action bar: the strongest of the dead near you turns on you, and takes a fifth more from your blows for eight seconds (bosses from rank IX, for half as long).", "The ranks: II, your posse keeps its nerve better near you; III, the smithy forges greatswords; IV, a greatsword sweeps wider; V, Second Wind, a third of your health back once a night when you fall to a quarter; VI, the merchants charge a tenth less; VII, the blow after a parry or a brace is twice as hard; VIII, your posse hits a tenth harder near you; IX, Challenge works on bosses; X, Sir Aldous dubs you Sir or Dame, your posse is one larger, and the living near you take a tenth less harm.", "The relic is Sir Aldous’s Grandfather’s Greatsword: holy, two-handed, a wide sweep and a knock-back. With the book, what you Challenge takes a fifth more from everybody."]],
		["Fire, the Night Watchman, shields and dogs", ["Fire and How to Start It, learned by setting the dead alight: the fire stick (thrown, two to hand at rank 8), fires that rain cannot halve, tar pits you can set alight (four at most), a stick that bursts, the burning pot (built, rank 5: anyone with a bow beside it shoots burning arrows; the crude bow needs no book), burning oil poured from a wall, a gate or a tower (rank 6), and fires that frighten. Its relic: the Everlasting Match.", "The Night Watchman’s Companion, learned by finding things and fighting outside the wall: quicker outside, clearer sight in fog and dark, the dark lantern (rank 3: the dead lose sight of you), the chest and the outer ruins on your map, blows from the dark twice (then three times) as hard on the dead that have not noticed you, outside the wall or with the lantern shut, and never on a boss, half the notice outside, and boots half as good again. Its relic: the Unblinking Lantern.", "Hiding Behind Things, learned by taking blows on a shield: a shield that stops more, half the throw, Brace (rank 3: nothing from the front, and the howl does not freeze you), your posse behind you safer, staggering blocks, a Brace that covers those behind you, arrows stopped outright, and at rank 10 no boss can move you. Its relic: Saint Wilbur’s Pot Lid, which sends arrows back.", "Dogs, and Other Bad Ideas: a dog. It follows you, apart from the posse, and bites what you are fighting. It barks at a gate nobody is watching, pulls down whichever one you point at (That One, rank 3), fetches what has been dropped, gets up again, drags the fallen out of the fight, sniffs out rubble, and at rank 10 cannot be killed, only discouraged. Its relic: Saint Wilbur’s Dog Lead, and a second dog."]],
	]],
	["Arms, armour and relics", [
		["The smithy", ["Anyone can knock out a crude weapon at the smithy. It wears out: chipped after a night's fighting, in bits after a second. Hammer and Tongs makes refined weapons, which last; from rank 4, steel ones, which hit harder still. Steel comes from the old steel mine, at the top of the forest to the north-west, and the market pays well for it but sells none. Anyone can forge armour; steel armour needs rank 4."]],
		["The smithy’s five tiers, and kits", ["Every tier makes the same things: the short sword, spear, mace, billhook and warhammer, a bow and a crossbow, a cap, a chain shirt and a shield. Crude: anyone, from a little iron; the weapons are chipped after a night’s fighting and gone after a second, and crude bows need no book. Iron: the measure of everything else; anyone can make the armour, the weapons need Hammer and Tongs. Armour adds up, piece on piece, but all together it never takes more than 65% off a blow. Steel: a third better, from rank 4. Mithril: half as good again, glowing purple, from rank 7. Rune: a tenth better than mithril, glowing blue, the best there is outside the relics; it needs runes, from the Rune Cave across the river, at the Riverside.", "The priest will bless rune armour for good, a gold piece a piece, for anyone who has sat both his classes: whatever strikes you is scorched, and wraiths do half their harm. Nothing else can be blessed for good.", "Kits, from Hammer and Tongs (crude at rank 1, iron at 3, steel at 6): ten of the metal and five wood, and the kit goes straight to one of your posse. The Wildly Inexperienced Ranger has a bow and a cap and shoots from behind the others; the Wannabe Ill-Equipped Watchman has a weapon (it varies), a cap and a shield and stands in front. From rank 3 you can kit out the whole posse at once. When a kitted peasant falls, the kit lies where they fell, for anybody to pick up and hand on from the backpack. Crude kits come apart after two nights."]],
		["Boots", ["Something on your feet, beside the rest. Somebody Else’s Turnshoes turn up in rubble: a twentieth faster. Hobnailed boots, forged in iron: a tenth. Sabatons, forged in steel: a tenth, and a twentieth off every blow. And three relic pairs, one of each for every player: Brother Fleet’s Swiftly Departing Boots (a quarter faster), the Sandals of the Extremely Devout (where you walk is hallowed, and scorches the dead), and Brother Cinder’s Hot-Foot Boots (what touches you catches light)."]],
		["Relics and their books", ["Every book has a relic, and there is one of it in the ruins for every player who has read that book (one, if nobody has): eight players with the bow book means eight relic crossbows to find. Anyone can find any of them, and trade them on through the storehouse or by dropping them. Carrying a relic with its book read does something more. The relic boots belong to no book: every player may find one of each pair. The Smoking Censer smokes: the dead inside its smoke walk at half speed and strike half as often, and with Relics and Where They Were Left they smoulder as well. The four found most recently: the Thunderer’s Crossbow (heavy and slow to load; its bolts are lightning, and jump to two more of the dead; with Slings, Bows and Thrown Turnips, to three), Saint Walstan’s Scythe (with the Woodcutter’s Almanac, you gather a quarter faster; your posse does not), the Mason’s Blessed Trowel (defences near you mend themselves; with Barricades for Beginners, twice as fast, and your repairs are free), and Saint Dunstan’s Tongs (forging costs a quarter less; with Hammer and Tongs, forged weapons hit a tenth harder).", "Every relic goes with a book. Read the book and the relic does a little more: the Silvered Sword hits harder with The Art of Hitting Things, the Chapel Handbell smites with the Holy Book, and so on. Your backpack says which."]],
	]],
	["Merchants and hired help", [
		["Merchants and hired help", ["On about six days of the month a merchant parks a cart by the market: the tinker (iron, tools, boxes of cogs for contraptions), the armourer (forged arms, no smithy needed), the brewer (food, and ale for the inn), the relic pedlar (one real relic among the fakes: rank 2 of relic lore tells which) or the bookseller (loose pages, and An Index of Further Reading). They leave at dusk.", "Each has a job, paid with the best thing on the cart. Take it at the cart, then stay where the job is: most of a day alone, about half a day each with a team-mate. Nobody learns from a book on a day they work for a merchant.", "Robert Bailiff will lend you a village guard for 8 shillings (knock at his back door, north of his house): he holds a gate until dawn. Six guards in all, two to a gate. The Thorny Rose Inn will find you a mercenary for 8 shillings: stronger, in your posse until dawn, and about one in seven turns on you then for two more shillings."]],
	]],
	["Across the river", [
		["The Riverside", ["Across the river is a hamlet, the Riverside, where the dead never come. First the village builds a raft at the riverbank, south-west of the village: 100 wood, more than one peasant can carry, so bring it in loads. Hold {interact} there to put your wood in.", "The raft crosses by day only, and your posse comes with you. After dusk it stays where it is, and anyone on the far bank is safe there for the night, but out of it. Or swim: hold {interact} at either bank. It takes twenty seconds and half your health, your posse stays behind, and for forty-five seconds after you walk slowly and everything you do is a quarter weaker. Dawn brings everybody home.", "Over there, a small hamlet inside a fence, with a gate on each side: a market round a bonfire, with a merchant who never leaves, who sells materials at three times the price and rune arms and armour for about two gold pieces; a travelling merchant, never the one in the village that day, at half as much again; and the druid at his table outside his cottage. Out through the gates: the far ruin in the fields to the south-west, with more heaps to search and nothing in it that bites; the road south to Hallowshire Town, which is closed; and the two caves, each in a hill of its own and signed. Through the east gate, the Rune Cave: boarded up until a shady fellow outside it is given 20 wood, once, to make it safe. Inside are three seams of runes along the back wall, two to a seam each day (three with five or six players, four with seven or eight), and a statue of Saint Wilbur, the Dog Lord. Through the west gate, Garrick's Cave, where the Tithe Collector is. Garrick stands at its mouth; you pay him, then go in. Hold {interact} at a cave's mouth to go in, and at the daylight to come out. Your posse waits outside.", "The druid sells the recipes for Granny's potions, five shillings each, to readers of Granny's Remedies, and brews them for whatever he asks that day. Pick-Me-Up: a quarter harder for two minutes. Get-a-Move-On: a fifth faster, walking and swinging. Thick Skin: a quarter less harm. Last Warning: fifteen to twenty seconds wreathed in flame (half that in the rain), setting the dead near you alight; it needs a fire rock, raked out of the hamlet's campfire. Potions go on the action bar, and through the storehouse.", "The Tithe Collector, the best weapon there is, is in a chest under the rubble in a cave across the river. Its owner charges a shilling a search, more each week. A search takes a whole minute, and finds it about one time in twenty by day and one in eight after dark. It is a flail, holy and burning at once, with a wide sweep, and its trick, Quake, strikes everything round you and frightens it. It cannot be traded: whoever finds it keeps it, even after dying. There is one piece of ore in the cave each day, for whoever gets to it first."]],
	]],
	["The dead and the bosses", [
		["The month", ["Four weeks, and seven bosses: one on each of nights 7, 11, 14, 18, 21, 28 and 30 (each has its page here). Each week the dead last a good deal longer and hit a little harder, new kinds come down, and the easy ones thin out while the hard ones take their place. The dawn notice warns you the morning before, and the notice board says when the next boss is due.", "Every boss does something besides hit you, and shows it first. A red ring on the ground means something is about to land there; a red line, that something is about to come down it. {jump} jumps, which helps.", "The weather changes the night. Rain makes mud, and the dead wade slower. Fog hides the castle road. Snow slows everyone. Night 15 is the full moon: relics are easier to find, and the dead are quicker."]],
		["The dead", ["From the first night: the bloated dead, slow and very full, who burst when put down and harm everything near them, the dead included; pallbearers, behind a coffin lid that takes three quarters of any blow from the front (go round the side, or use something heavy, or fire); and grave hounds, quick and frail, who go for your posse first. Ghouls (from night 8) are fast and climb over barricades, but not walls. Gravediggers (10) tunnel under the north wall and come up inside. Bat swarms (12) fly over everything for the keep: slings, bows and the handbell bring them down. The Lord's guard (15) is armoured: farm tools barely dent it, maces and hammers do. Wraiths (18) drift through walls, and only holy things, mithril and rune hurt them: relics, blessed weapons, blessed slop, and anything mithril or rune. A coffin ram (20) goes for the north gate: a warhammer, or a very strong gate."]],
		["The Steward (night 7)", ["The Lord’s butler, in a tailcoat, with a candle on a tray. He keeps back and raises the fallen; he is no fighter. Get to him early and he stops raising them.", "Every so often he slams his ledger shut: a red ring round him, and then everyone near is thrown back. Step out of the ring."]],
		["The Lord’s Chaplain (night 11)", ["He preaches. Everyone near is drawn in towards him, and the dead round him mend while he talks. A hard enough blow makes him lose his place, and the sermon stops."]],
		["The Coachman (night 14)", ["He drives the hearse down the castle road at the keep door, through anything made of wood, and turns back for another run. Now and then he whips the horses up and they stampede. Stone and iron hold him; wood does not. Keep off the road."]],
		["The Castle Cook (night 18)", ["He ladles boiling stew where you are standing (a red ring, then a pool that scalds for a few seconds: move), and swings his cauldron round, throwing everyone near him back."]],
		["The Captain of the Guard (night 21)", ["He comes with the Lord’s guard behind him, for one of the three gates: watch which way his banner turns and be there first. He charges down a line, and shows you the line first: step out of it. He and his guard are armoured, so maces and hammers, not farm tools."]],
		["The Gamekeeper (night 28)", ["It is a full moon, and he is a werewolf. He breaks a barricade at a blow and a wall in four, and his howl freezes anyone who is not being prayed over, braced, or wearing the Helm of the Unbothered."]],
		["The Lord of Ashhollow (night 30)", ["First comes his shadow. Fire passes through it, holy things drive it back, and it raises the fallen and throws the dead at you. He waits until it is put down and half the horde with it.", "Then he comes through the north gate himself and clears the field of everyone else. He sweeps his cloak across the ground in front of him, sends bats down a line, slams his goblet on the ground, throws the dead at you, and vanishes to come back behind whoever is furthest off. He takes a great deal of putting down: bring blessed weapons and the best steel the smithy has."]],
		["Bosses with company", ["More of you, more of them: each night's horde is one horde for each player (past what can be shown, fewer of them, each tougher), and the wall, the gates and the keep stand up to it better. The bosses have a third more health for each of you past the first, and their tricks come round sooner, reach further and catch more of you: the Steward has lamp-bearers, the Chaplain preaches further, the Cook ladles two or three of you at once, the Coachman's hearse sheds coffins, the Captain splits his guard between two gates, the Gamekeeper brings his hounds, and the Lord throws the dead at more of you at once. With five or more of you, the Old Mine and the Rune Cave give more."]],
		["The moons", ["There are five in the month, always on the same nights. Night 9, the harvest moon: the dead mend, slowly, unless they are alight. Nights 15 and 28, the full moon: the dead are quick and restless, and relics turn up twice as often in the rubble. Night 19, the frost moon: snow from dusk, and everyone slower in it. Night 23, the blood moon: a very hard night. The horde is its usual size, but every one of the dead takes two and a half times as much putting down and hits nearly twice as hard. The village’s thanks the next morning are two and a half times the usual. The notice board says which is coming."]],
		["The nights of the bells", ["Three nights a month the priest and his congregation ring the chapel bells until dawn, to keep the dead away. It enrages them instead: they come quicker, hit a quarter harder and take a quarter more putting down. There is one such night in each week after the first, never on a boss’s night or the full moon. The notice board says so that morning. The village passes the hat twice the morning after."]],
		["Letters and notices", ["The Lord of Ashhollow writes. From the second morning, and every other morning after, a headless rider gallops down the castle road at first light and nails a letter to the gatepost just inside the north gate. They are complaints: about the noise, the breakages, and whatever the village has most lately done to his household. Read them at the gatepost.", "The notice board in the square, opposite the bell, has the day's news (the weather, what is expected tonight, when the next boss is due), three notices from the village, and a copy of every letter so far.", "With eight players, more of the dead would rise than the night can hold. Past about 420 in a night there are fewer of them instead, and each is harder to put down and hits harder: the same horde, in fewer pieces."]],
	]],
	["Playing together", [
		["Playing together", ["Up to eight can play. One of you presses Host a village on the home screen and reads out the village code; the others type it into Join. Everyone gets their own cottage, posse and books; the storehouse, the arms rack and the keep are shared. The host starts the week when everyone is in, and the host's game keeps the save.", "Nobody has to be there from the start, or every time. Join a village after its week has begun and you move into an empty cottage. Drop out, or lose your connection, and your peasant is kept exactly as it was: join again under the same name and you have it back, the same day or another. When the host carries on from the save with some of you missing, the missing ones wait in the same way. Relics do not wait with you: they stay with the village.", "With a village server set (Options), villages go through it: a five-letter code that works from anywhere, and nobody's router matters. Without one, the host's computer asks its router to let friends in; if the router says no, that code only works on the same home network, unless the host opens port 24565 (UDP). The game does not pause for the handbook when others are playing."]],
	]],
]

const CHANGES := [
	["Version 7.41: a real cockerel", [
		"The cockerel at dawn is a real one now, a recording, rather than one made from scratch: \"Cartoon Rooster Sounds\" by DRAGON-STUDIO, from Pixabay. He still crows a moment after the morning chord, every morning.",
	]],
	["Version 7.40: a cockerel you can hear", [
		"The cockerel at dawn has been made again, as a voice rather than a buzz: cock-a-doodle-DOOOO, the last note held, climbing, cracking and falling away. He crows on his own now, a moment after the morning chord instead of underneath it, and at full volume, every morning including the first.",
	]],
	["Version 7.39: polish, before the test plays", [
		"Mended: hosting \"Carry on from day N\" (or \"Try day N again\") started a new month and saved over the old one. It carries on now.",
		"Mended: buying the stranger a drink in the weeks before the Chaplain, the Cook and the Gamekeeper took your sixpence and told you nothing. He has a word about every one of them now.",
		"Mended: closing the morning notice with {ready} also marked you ready for the night, which, alone, ended the day on the spot.",
		"Mended: your dog was sent home with the hired help every morning, and a new one with a new name took to you. It is the same dog now, up and about again at dawn.",
		"Mended: anything dropped indoors or across the river (or that would not fit in a full backpack there) landed at the far edge of the map. It is left outside the way in, in the village.",
		"Mended: holding the attack button never got the faster blows from Red Mist, Get-a-Move-On or the bow ranks. Clicking a button on the screen no longer swings your weapon as well.",
		"Mended: the Knight's Squire could be handed back with a library card, and then never had again. The card will not take it.",
		"Mended: a notice that does not dim the screen no longer blocks the action bar and the buttons round it. Esc closes the posse card on its own; at the bar of the Rose it opens the handbook.",
		"Mended, for those who joined: \"(N at home)\" on the posse card, the food errand, and the right dust and chips when the posse works on after you.",
		"Taking down a watch tower asks first. Putting something down where it cannot go says why. \"I'm a stuck little peasant\" says when it can be used again. The market's Buy says what you will really get. \"Leave the village\" asks twice every time.",
		"A warning a minute before dusk, and at twenty seconds, with the day's timer in red: the raft stops at dusk, and the library and the lane shut. When a team-mate goes down you are told who, and which way. The ready line says who the night is waiting for. Alone, the game waits when you switch to another window.",
		"A night spent in the chapel or down the Old Mine no longer counts as standing: the dead grow restless, as they do when everyone hides, and there is no share of the hat for it.",
		"The map marks the doors of the chapel (with a cross), the library, the inn, the lane and the Old Mine, the merchant's cart, and your own cottage. Signs by the doors, and \"Out\" signs inside the library, the chapel and the cabin.",
		"F11 (or Alt and Enter) fills the whole screen, and there is a tick box for it in the options. The calling's third power can have a key of its own now.",
		"Words put right: holy is a third as much again (not half), and those blows show in gold; a library card takes a book to rank VII at most, and loose pages are only offered below rank VII; seven bosses, not four; the jetty gives fish, not food; the market pays a penny and charges two; the tar pit slows the dead, not you; the dog drags fallen players; mithril and rune hurt wraiths too; Last Warning is half as long in the rain; the priest's price for rune armour is what he really takes; library cards come in the chests; and the Lord's hint says what really helps.",
	]],
	["Version 7.38: a door you can see, and a quieter torch", [
		"The chapel's door is on the front of the bell tower now, where you can see it: a pointed stone doorway, a pair of oak doors with iron straps and two rings, and a step. The bell tower used to stand in front of the old door and hide it, and the round window too, which has moved up the tower above the new one.",
		"A burning torch no longer throws little yellow sparks out of the top as you walk about. The flame is enough on its own.",
	]],
	["Version 7.37: the chapel, inside, and a handbook you can find things in", [
		"The priest has moved indoors. The chapel has a door now, under the bell tower, and inside it a nave: flagstones, a red runner up the aisle, four rows of pews either side, the altar rail, and the altar with its cloth, cross and candlesticks, where the priest stands. There is a pulpit, a brass eagle with the bible open on its wings, a font at the back and a collection box for the roof. The chapel is open day and night, so you can still be blessed before a fight.",
		"Holy studies are sat in a pew now. Ask the priest for a class and you take the first free seat, front row first, with the bible open on your knees, for the forty-five seconds. A bar over your head shows how far you have got. Hold {interact} to close the book and get up, or just walk off: he remembers where you got to, as before.",
		"On the nights of the bells the chapel's windows blaze and flicker in their colours, red, blue, gold and violet, as candle after candle is lit, and the colours fall on the grass outside. Inside, every ledge, step and pew end has a candle on it.",
		"The handbook is in chapters now: Getting started, The village and its places, Resources, Defences, Your posse, Fighting, Books and skills, Arms, armour and relics, Merchants and hired help, Across the river, The dead and the bosses, and Playing together. Pick a chapter on the left; it scrolls on the right, with a heading for each part. Every boss has a page of its own, and so does what changes when there are more of you.",
		"The books are sorted into kinds, on the library shelf, in the handbook and in your skills: gathering and making; fighting; leading and looking after; and the callings and quests, which do not count against your books.",
		"The ducks on the village pond swim about now, each at its own pace, and turn back now and then.",
	]],
	["Version 7.36: the bosses, with company", [
		"Every boss now grows with the number of players in a way you can see, not only in health. For each player past the first, a boss has a third more health (it was half), and its tricks come round about 7% sooner and reach 4% further: with eight of you, half as often again, and a quarter further.",
		"The Steward comes down with a lamp-bearer for every two of you past the first. The Chaplain's sermon reaches further, and mends the dead further off. The Cook ladles stew at two of you at once from four players, three from seven. The Coachman, with five or more of you, sheds a coffin off the back of the hearse at every stampede, and a pallbearer climbs out. The Captain, with five or more, sends half his guard to a second gate. The Gamekeeper brings his hounds, one for every two of you. The Lord's shadow raises, throws and blinks more often; the Lord himself throws the dead at more of you at once, and his cloak sweeps wider.",
	]],
	["Version 7.35: more ore for a bigger village", [
		"With five or more players, the Old Mine’s veins and the Rune Cave’s seams give more each day: one more mithril in each vein and one more rune in each seam for every two players above three. Five or six players: three to a vein and a seam. Seven or eight: four.",
	]],
	["Version 7.34: one Lord", [
		"In the last week there were two Lords at the castle, one in the lit window and one on the wall over the gate. He has left the window now: in the last week he is only on the wall.",
	]],
	["Version 7.33: the Lord, as he should look", [
		"The Lord of Ashhollow has been redrawn from his portrait: a pale, square face with red eyes that glow and teeth he would rather you did not see, black hair, a tall black top hat with a gold band and a red ribbon, a great stand-up collar, red within, a black tailcoat over a red waistcoat with gold buttons, a white cravat and a gold jabot, and a cloak to the ground, black outside and red inside. His goblet stays upright in his hand whatever he is doing, and when he stands about he raises it to you.",
		"He can be seen at the castle from the first day now: a small figure on a balcony in the one lit window, looking down on the village. In the last week he comes out on to the wall over the gate, and raises his goblet. The night he comes down in person, he is in neither.",
		"His shadow has his shape: the hat, and the great collar.",
	]],
	["Version 7.32: the posse, the torch, the caves", [
		"Sending your posse home now tells you so, in the middle of the screen: how many are on their way to your cottage. The posse’s card is drawn on top of everything else, so nothing can take the click, and it no longer pops up again by itself when the dawn notice or the handbook closes.",
		"A burning torch has a real flame: tongues of fire that leap and lick and stand up straight whichever way you hold it.",
		"No more trees growing inside Garrick’s Cave and the Rune Cave (they were the woods across the river, which did not know the caves were there).",
	]],
	["Version 7.31: the road, the trees, the Old Mine", [
		"The west and east roads out to the hedge are clear: the trees that stood in them have moved to the verges.",
		"The village’s own trees, the ones you chop, now sway in the wind with the woods beyond the hedge, and bend over in a storm.",
		"The way down the Old Mine looks like a mine: a shaft in a collar of stones, a headframe over it with a winding wheel and a bucket on its rope, the top of the ladder, a spoil heap, a cart of rubble on rails with a purple lump in it, a lantern for the night, and a sign.",
		"You no longer show through trees and roofs as a pale shape. Turn the view, or carry a torch.",
		"Down the Old Mine, and in the two caves across the river, there is no birdsong, wind, rain or thunder: water dripping, the hill creaking, and music of its own, slow and hollow.",
	]],
	["Version 7.30: the Knight’s Squire", [
		"The library is a room now: go in by its door. The Peasants’ Section, a shelf on bricks with a sign asking you not to lick the books, is where you choose your books. The librarian is at her desk. The rest of the library is behind a red rope, for members of the nobility, and you can see all of it and have none of it. It shuts at nightfall.",
		"Sir Aldous de Vere is in there, doing some research. He wants a sword, a particular one, and a different one from each of you. Bring him the right one, and he sends you down the lane past the west hedge, to his cabin in the woods, for his squire’s notebook. The squire has gone. Nobody knows where. The lock on his chest is in his paintings.",
		"A new book: the Knight’s Squire, read to you by Sir Aldous, from day one. Greatswords, which take both hands; Challenge!, which makes the strongest of the dead nearby come for you and take a fifth more from your blows; and ten ranks, up to being knighted, Sir or Dame. Its relic is a two-handed sword.",
		"The Holy Book, the Jester and the Knight’s Squire no longer count against your books.",
	]],
	["Version 7.29: townsfolk", [
		"Seven of the village’s townsfolk now go about their day: working the farm, walking out to the mill, fishing from the bank, taking a drink at the Thorny Rose, chopping at a tree at the edge of the wood, or standing about the market, the square and the notice board. They gather nothing. They are only living here, which is brave of them.",
		"Walk up to one and they will say hello, or something like it.",
		"At dusk they drop what they are doing and run for the keep, and hide in it until morning. Every player sees the same townsfolk doing the same thing.",
	]],
	["Version 7.28: the weather has a wind", [
		"The wind now goes with the weather: a breeze on clear days, stronger when it is overcast, nearly still in fog, a drift in the snow. Trees, bushes, grass and every banner follow it.",
		"Rain is a storm now: the trees bend over and thrash, the rain is driven slantwise, it splashes where it lands, leaves and bits are torn off and blow past, the sky is darker, and a storm wind howls and gusts under the rain.",
		"In a storm there is lightning by day too, a fork you can see coming down somewhere beyond the wall, and the thunder after it.",
	]],
	["Version 7.27: wind, crows, things in the dark, and the roads out", [
		"The trees, the bushes and the long grass move in the wind now: a slow breeze rolling across the land, gusting now and then.",
		"Now and then a flock of crows lifts out of the trees beyond the wall, circles, and goes off complaining.",
		"At night, out on the dead ground beyond the north wall, eyes open among the dead trees, look at you, blink, and are gone; and a will-o’-the-wisp or two drifts about out there. Nobody has followed one. Nobody is going to.",
		"The west and east roads no longer stop in the middle of a field: they go on, out through a gap in the hedge, past a milestone and into the woods, rutted by carts that went somewhere better.",
	]],
	["Version 7.26: the country beyond the edges", [
		"The thorn hedge at the village’s west and east edges is a ragged run of bushes now, not a wall of green boxes, and beyond it the woods are thick all the way to the horizon.",
		"Across the river from the village there is somebody else’s countryside: fields in hedgerows, haystacks, copses and odd oaks, grass and flowers, and three farmsteads with their barns. Nobody from over there has ever come to help.",
		"Beyond the castle the dead ground carries on into a dead wood, with a ridge of grey hills behind it, somewhere in the mist.",
		"The Riverside no longer stops at a straight line: it is ringed with woods, a little open at first and thick further out, with the road south going on through them; and the far side of its river is wooded too.",
	]],
	["Version 7.25: warm lights, lanterns, and the words brought up to date", [
		"Windows glow amber at night, like candlelight, instead of white. Lanterns have iron frames and warm glass, and the braziers at the north gate have fires in them, not white boxes.",
		"Eight lantern posts along the roads, by the gates, the square and the cottages, so there is some light to fight in after dark.",
		"Every book, relic, handbook page and passing remark now says what the game actually does: fish heal sixty (fully at rank X); blows from the dark are twice or three times as hard, outside the wall or with the lantern shut, never on a boss; the ‘better with every rank’ books say they stop at rank VII; armour says it tops out at 65%; Saint Walstan’s Scythe speeds you, not your posse; the Dog Lead’s dogs both bite; the Helm of the Unbothered mentions the werewolf’s howl.",
		"The smithy no longer says nobody can cross the river; the lobby no longer says nobody can join late; the outer ruins are somewhere new each day; contraptions are on the building wheel; Tam the Carter knows about mithril; the stranger knows all the boss nights; hobnailed boots no longer pretend anyone hears them.",
	]],
	["Version 7.24: a balance pass, a haunted hilltop, and folk who look like themselves", [
		"A blow from the dark (the Night Watchman’s Companion) worked on your first blow on every one of the dead, which with a sweeping weapon flattened whole rows. Now it needs you out in the dark beyond the wall, or your lantern shut; it is twice as hard, three times at rank X, and never works on a boss.",
		"Armour, however it is stacked, takes at most 65% off a blow; the Vicar’s Breastplate takes 30%, not 40%. A fish heals 60, and you fully only at rank X of Field, Hook and Pot; the wait between fish is thirty seconds (twenty at rank IX).",
		"Holy weapons hit a third harder, not half as hard again (1.6 times with Relics and Where They Were Left at rank V). A charge is a third harder (1.6 at rank VII of the Ledger, not double). A burning one held by your dog takes a quarter more, not a quarter and then another quarter.",
		"The Silvered Sword swings a little slower. Warhammers, in every metal, hit about a sixth harder. The Woodcutter’s Almanac stops at fifty of each material; rank VIII now has your posse gather a quarter faster instead.",
		"Watch towers are back as they were: sent up by day, your posse climbs at dusk. They walk round houses to get there, and hired swords can go up too.",
		"The Posse slot’s choices are a parchment card in the game’s own style. Sending them home from your own doorstep, or whistling for a posse already with you, now says so, instead of seeming to do nothing.",
		"The Lord’s hilltop is no longer bare grass: a ruined curtain wall with a skull on each gatepost, his family graveyard and mausoleum behind iron railings, a dry fountain gone green, gargoyles and green-lit lanterns up the road, dead trees with crows in them, coffins waiting, bones, and a low mist.",
		"Villagers wear what they like: caps, hoods, headscarves, felt hats, straw hats, a fringe and not much else, or a great deal of hair; and their skins and tunics differ. Your posse still wears your colour.",
		"Behind a tree or a roof, you show through it as a pale shape, so you are never lost. Dust at your heels when you run, splashes when you swim, a snap when the dog bites; and the Out signs stand to one side of the door, not on top of you.",
	]],
	["Version 7.23: three colours of relic boots, and a back door", [
		"The three relic boots now look like three different things: Brother Fleet’s are a deep green, the Sandals of the Extremely Devout a deep blue, and Brother Cinder’s a deep red. Each glows in its own colour rather than all in the same gold, casts a little of that colour on the ground round your feet, and has its picture drawn in its colour in the backpack and the storehouse.",
		"Robert Bailiff’s back door now exists. People had been knocking on a wall. It has a knocker now, and a step, and it is still bolted.",
	]],
	["Version 7.22: tower crews, dogs over the river, and the stranger’s table", [
		"At dusk, a watch tower’s crew now walks round whatever is in the way to get there. Before, they could be caught on houses for half a minute. Hired swords can be sent up too.",
		"Your dog, and Saint Wilbur’s second dog, now come across the river on the raft with you, wait at a cave’s mouth while you are inside, and come home on the raft.",
		"The stranger in the Thorny Rose has a table and chair of his own, in the corner by the door. He had been sitting in the barrels. Nobody had liked to say.",
	]],
	["Version 7.21: two proper caves, the Old Mine, and the river", [
		"Garrick’s Cave and the Rune Cave are now caves you walk into, each lit by torches. In Garrick’s, the rubble heap with the Tithe Collector somewhere under it, and the day’s piece of ore. Garrick himself now stands by the mouth, where he can see who goes in.",
		"The Rune Cave has its three seams inside, along the back wall, a statue of Saint Wilbur, the Dog Lord, with his dog, and something glinting behind a rock where nobody can reach it. Nobody has tried very hard. It is boarded up until a shady fellow by the mouth is given his twenty wood.",
		"Your posse waits outside a cave’s mouth while you are in it.",
		"The Old Workings are now the Old Mine, wherever they are mentioned, and the hole by the steel mine glows faintly purple with the mithril down below.",
		"The river at the Riverside was mostly covered over by a field. It is now a river again, the full width, with its bank.",
		"Banners no longer shudder when you stop. The wind now keeps one pace and only blows harder or softer.",
	]],
	["Version 7.20: halos, towers in loads, and the posse sent home", [
		"Blessed rune armour is back to its rune blue, and no longer washes out white. Instead, whoever wears a blessed helm, top or shield has an angel’s ring over their head, like the priest’s, slowly breathing gold and white.",
		"Watch towers, the north wall, its gate and the side gates can be built in loads. Hold {interact} at the site and whatever you carry that it still wants goes in; anybody can add to it, and it goes up once it has the lot. Nobody needs to carry thirty wood any more.",
		"Click Posse on the bar: send them home to your cottage, where they wait by the door, or whistle them back to you. A whistle does not carry across the river, and nobody is sent home from the far bank without the raft.",
		"Saint Wilbur’s Dog Lead has its own picture in the backpack and the storehouse.",
		"Long names, such as Brother Fleet’s Swiftly Departing Boots, now fit inside their cards.",
		"On a sheep, you ride: legs either side of the fleece and still, and the sheep does the walking.",
	]],
	["Version 7.19: wind, a sharper tithe, and tidier grass", [
		"Banners now fly in the wind. The cloth ripples and flaps on its pole, harder when you run, as though it were trying to get there first.",
		"The Tithe Collector now hits for 50, up from 40. It is the best weapon in the game, and it now has the figures to say so.",
		"The ground has been thinned by about a quarter: fewer tufts, pebbles, flowers, bushes and toadstools. The countryside was getting above itself.",
	]],
	["Version 7.18: mends to boots, dogs and the blessed", [
		"Boots now stay on your feet. Before, they stood still where they were while your legs walked off without them.",
		"The dog no longer walks backwards. It was being turned round twice, which is once too many for a dog. It also waits until its place at your side is a little way off before it trots over, so it no longer goes round in circles every time you turn; and with two dogs, each keeps to its own side.",
		"Saint Wilbur’s Dog Lead now looks like a dog lead: a coil of leather at your hip, a strap from your hand to each dog’s collar, and the dogs’ collars turned gold. Every dog has a collar now.",
		"Blessed rune armour now looks blessed: a golden holy light that swells and fades about whoever wears it, and motes of light rising off it.",
	]],
	["Version 7.17: fish, and the cook", [
		"Fish are now their own catch, apart from the farm's food. Eating one, from the action bar, puts you back to full health at once, with a wait of twenty seconds before the next. Farm food is what everything else uses.",
		"Field, Hook and Pot has been rethought. From its first rank you are the posse's cook: at night, any of your posse who is badly hurt eats one of your food and mends. Its ranks now also bring more of the river's lost things, fish that sell for more, prize fish worth a shilling on the spot, fish you can eat sooner, and at rank 10 a fish that heals everyone near you.",
		"Fish sell at the market for twice what food does, and the market does not sell fish. It is not that sort of market.",
	]],
	["Version 7.16: a bit of character underfoot", [
		"The open grass, in the village’s fields and across the river, now has tufts of long grass, pebbles, little clumps of flowers, bare patches of earth and the odd small bush. And toadstools under the trees of the forest.",
		"Mole hills. A few turn up every morning out in the countryside, and three across the river (never in the village or the hamlet). Walk past one and the mole pops out, has a look at you, and leaves a few pence behind. Nobody knows where moles get money, and nobody has asked them.",
	]],
	["Version 7.15: the dead, as they should look", [
		"The dead are back to the colours of the dead: grey, mottled, and in want of a wash. The green is now only a faint glow about the edges, and a sickly green light on the ground about each of them, so you can still pick them out at night. They should no longer be mistaken for anything from a block-building game.",
		"The raft’s building site, on the riverbank south-west of the village, can now be found: a sandy slipway with planks, stakes and rope, a sign, a red flag on a tall pole, a label saying how much wood it has, and a red mark on the map.",
		"A test copy: Thornhallow-Test.exe, on the same download page, is the same game with a Developer tab in the handbook. Go to any day of the month, at dawn or straight to dusk; everything always full; nothing can hurt you; every book at any rank; a priest or a jester at once; every relic on the rack; the raft and the Rune Cave built. It keeps its own saved game, so it never spoils a real one.",
	]],
	["Version 7.14: the Riverside, done properly", [
		"The hamlet across the river is smaller and snugger: a fence round it with a gate on each side, a market round a bonfire, three cottages with window boxes, a well, and two of the hamlet’s folk to talk to, Widow Thrupp and Young Ned.",
		"The druid now looks like a druid (antlers, beard, staff, and the general air of a man who talks to trees), and lives in a cottage with a tree growing up through the roof, and flowers and toadstools round it.",
		"A pen with a cow called Dorothy and a donkey called the Donkey, who moo and bray, and chickens loose about the market, pecking.",
		"The two caves are now in hills of their own outside the fence, with signs: the Rune Cave through the east gate, glowing blue, and Garrick’s Cave, with the Tithe Collector in it, through the west gate.",
		"The river runs, as the village’s does. Countryside round about: fields, hedgerows, hay bales, the far ruin out in the fields, and the road south to Hallowshire Town, with a broken-down cart at the start of it and a signpost that has opinions. Torches are lit round the hamlet at night.",
	]],
	["Version 7.13: a tidier corner", [
		"The top left of the screen is one smaller scroll: the day, the time, who you are, and under a line what you carry, as pictures with a number. It only shows what you actually have, so an empty-handed peasant has a short scroll and a rich one a longer one.",
		"The map is smaller, and sits in a parchment frame of its own.",
	]],
	["Version 7.12: the raft to the Riverside", [
		"A raft, at last, for the whole village: 100 wood at the riverbank, south-west of the village, brought in as many loads as it takes. It crosses by day, and your posse comes too.",
		"The Riverside, on the far bank: a hamlet where the dead never come. Two merchants (one who never leaves, and charges for it; one who travels, and charges for that), a second ruin with nothing in it that bites, and the Rune Cave, where the runes are. Rune arms and armour can now actually be forged.",
		"A druid, who sells the recipes for Granny’s potions to readers of Granny’s Remedies and brews them for whatever he fancies that day. Four potions: harder, faster, tougher, and on fire.",
		"The Tithe Collector: a burning, holy flail, the best weapon in the game, in a chest under the rubble in a cave across the river. The cave’s owner charges by the search. It cannot be traded, and every player must find their own.",
		"After dark the raft stays put. You can swim, but you arrive half drowned and your posse stays behind, looking at you.",
	]],
	["Version 7.11: the Jester", [
		"The second calling. Jester the Faux Magician has been withdrawn from the library by its author, who has left a note. He is Prospero, on the stool by the fire at the Thorny Rose, and he teaches it himself, in three lessons, for a drink each.",
		"Three tricks, on the action bar: Is This Your Card?, Abracadabra, Roughly, and A Jape at Their Expense, which confuses the dead into hitting each other and insults the bosses into coming for you. You asked for this.",
		"Every trick is a roll of the dice. Usually it works. Sometimes it is only a card. Sometimes it is exactly the right card.",
		"Ten ranks, earned by playing tricks on the dead, and a relic: Prospero’s Marotte, a stick with a small head on it that answers back.",
		"Jesters wear the cap and bells. The inn’s bookshelf is now empty, as Prospero has taken his book back.",
	]],
	["Version 7.10: village life", [
		"The windmill lays on a banquet. Take 10 food out to it by day, or leave 13 food and 5d on the new offering plate inside the east gate for one of your posse to carry, and your posse mends slowly all night. Only your posse: the miller was very clear that he is not feeding you.",
		"The Herder, by the sheepfold on the downs, gives a lesson in sheep herding with two questions after it. Pass, and you can tame a sheep of your own and ride it about by day, a quarter quicker than walking. You cannot fight from a sheep. People have tried.",
		"A sheep wants one food a day and will not be ridden hungry. At dusk it goes in the cupboard under your stairs.",
		"Strays, at last. They hide round the farms and in the forest, and can be talked round into your posse over and above its usual size. They are a bit weaker, and a bit unreliable: now and then one runs off in the evening with his kit and a shilling of yours.",
		"Fishing by hoik, from version 7.4, is staying. The fish have been told.",
	]],
	["Version 7.9: four more books, boots, and relics for everybody", [
		"Four more books on the library shelf, after the Holy Book: Fire and How to Start It, The Night Watchman’s Companion, Hiding Behind Things, and Dogs, and Other Bad Ideas. Ten ranks each, a power or two each, and a relic each. The handbook has the lot.",
		"Fire and How to Start It throws fire sticks, sets tar pits alight, pours burning oil off the wall and builds the burning pot, which turns anybody’s arrows into burning ones. The village has been asked to keep buckets handy, and has not.",
		"The Night Watchman’s Companion is for going out there: quicker outside the wall, a dark lantern that the dead cannot see past, and a blow from the dark worth three of an ordinary one.",
		"Hiding Behind Things is for standing in the gateway with a shield and Brace, and nothing from the front gets through. Some people enjoy that sort of thing.",
		"Dogs, and Other Bad Ideas comes with a dog. It follows you, bites things, barks at gates nobody is watching, fetches, and pulls down whichever of the dead you point at. It has a name. You did not choose it.",
		"Boots: a new place to wear things, on your feet. Three ordinary pairs (turnshoes from the rubble, hobnailed boots in iron, sabatons in steel) and three relic pairs, one of each for every player.",
		"Relics follow the books now. There is one of each book’s relic for every player who has read that book: eight players with the bow book, eight relic crossbows to find. Anyone can find any of them.",
		"The iron page of the smithy no longer shows its bow and crossbow twice. There was only ever one of each. The smith has been spoken to.",
		"The village news has moved up the left side of the screen, out of the way of the action bar.",
	]],
	["Version 7.8: powers, the action bar and the building wheel", [
		"Every book has a power of its own now, from its first rank. Many Hands, Pot Luck, Shore It Up, The Whetstone, Red Mist, The Marked Man, War Cry, A Round on Me, Hone and Smelling Salts. The handbook says what each does. The Holy Book keeps Smite and Pray, and at rank X gains Consecrate: ground the dead will not cross. The dead were not consulted.",
		"Hone points at a heap of rubble that is certain to hold a relic, with a pillar of light over it you can see from the castle. So can everyone else. Be quick.",
		"The Marked Man puts a red mark over one of the dead. Everyone’s shots and every tower go for it, and it takes a quarter more. It is not personal. It is, a bit.",
		"Everything you can do is on one bar along the bottom of the screen, with your health just above it: your weapon’s trick, every power, your bucket or bell, posse orders and the toilet break. Click them, or press 1 to 9. Right-click still does your weapon’s trick.",
		"The old keys for those (Shift, G, Q, T, Z and C) are free now. Anyone attached to them can have them back in the handbook’s keys.",
		"In the skills window ({skills}) the bar can be put in another order, and things taken off it. On a small screen it shrinks to fit rather than fall off the edge.",
		"Building is on a wheel. Hold {build} and everything you can put down opens in a ring round you; let go over the one you want. A quick tap still steps through them, for the traditionally minded.",
	]],
	["Version 7.7: ten ranks, honing, and more books", [
		"Every book has three more ranks: ten, where it was seven. They take a good deal of practice. Nobody said learning was quick, and if they did, they had not read the Woodcutter’s Almanac to rank X.",
		"Some of what they do: carry fifty of everything; a posse four larger; meals that heal eighty; watch towers at half the upkeep; repairs a quarter stronger until dawn; contraptions that set themselves up again once a night; kits that never wear out; rune, at last, for anyone who can reach the runes; every fourth blow twice as hard; killing blows that carry on into the next of the dead; shots that go through to the one behind, and a free volley every tenth; a hip flask; a charge that nothing can knock back; and a certain find, once a day. The rest are in the skills window ({skills}).",
		"The Holy Book’s eighth rank is “So Help Me Lord, Please?”. When a boss would throw, pull or freeze you, you pray in haste, by yourself, and two times in three it works. A small cross shows over your head when it does. It is not clear who is listening, but somebody is.",
		"Honing. Once a book is at rank X, what you learn past it is spare, as before, and ten spare points can now be honed into a page of any book at rank X. Each page is two in the hundred on everything the book does, up to five pages. Spare points can still be sold for coin, for those who would rather have the money.",
		"Four books to a peasant, once three of yours are at rank 4, and a fifth with An Index of Further Reading from the ruins. The library has been told. It is not pleased about the extra stamping.",
		"Charging out of the Thorny Rose no longer looks like one of the bloated dead going off. It never should have. The bloated dead were consulted, and are disappointed.",
		"The powers for every book, the action bar and the building wheel come next, in 7.8.",
	]],
	["Version 7.6: the smithy", [
		"The smithy has a new menu. Pick a tier along the top, and it shows you a picture of everything that tier can make. Click one to forge it. Point at one to read about it first, if you are the careful sort.",
		"Five tiers, and every one makes everything: the five weapons, a bow, a crossbow, a cap, a chain shirt and a shield. Crude, iron, steel, mithril and rune. Before this, steel had no bows and the top tier had no armour at all, which nobody had noticed except the people being shot.",
		"What the village has been calling runes are mithril. They glow purple, they come from the same veins in the old workings, and anything you made from them is now called mithril and hits a little less hard than it did. Whatever you were carrying has been relabelled. Nobody had the heart to tell you sooner.",
		"Real runes glow blue, and make the rune tier, a tenth better than mithril and the best there is outside the relics. They come from a cave across the river. Nobody can get across the river yet. The smith has hung the pictures up anyway, to be going on with.",
		"The priest will now bless rune armour for good, for anyone who has sat both his classes, at a gold piece a piece. He is not doing this for free. The dead that strike you are scorched, and wraiths do half their harm.",
		"Kits for your posse, from Hammer and Tongs: crude at rank 1, iron at 3, steel at 6. The Wildly Inexperienced Ranger gets a bow and a cap and shoots from behind the others. The Wannabe Ill-Equipped Watchman gets a weapon, a cap and a shield and stands in front. You can see what they have on. From rank 3 you can kit out the whole posse in one go.",
		"A kit outlives the peasant wearing it. It lies where they fell, for anyone to pick up and hand to somebody else from the backpack. Crude kits come apart after two nights, as crude things do.",
		"The old ruins by the chapel have been tidied a little smaller, to give the new watch tower some elbow room. Nothing of value was lost. Nothing of value was there.",
	]],
	["Version 7.5: walls, towers and the other two gates", [
		"The north wall has been moved three paces further out. Nobody asked the wall.",
		"Behind it are four sites for watch towers: one in each corner, and one either side of the gate. A tower is 25 wood and 8 stone. Hold {interact} beside it and it has a notice, with two choices: send one of your posse up, or coax one down from the safety of the tower.",
		"Six can be up a tower at once, from anybody’s posse. Four towers hold twenty-four between them. From dusk they throw stones over the wall at anything within about fifteen paces, and only archers can reach them up there, unless it has a roof (ten wood).",
		"A tower wants seeing to every morning: 4 wood and 1 iron, or nobody will climb it that night. They have been up one with rotten rungs before, and will not be again.",
		"The dead can break a tower, and so can you: taking one down gives back half of what it cost. Either way the site stays, for when you change your mind.",
		"The watch platform has gone; it became the watch tower, and moved. If you had one built, it is still standing, and still works, out of habit.",
		"The dead come round to the west and east gates now. In the first two weeks, one a night: the east, then the west, and so on. From the third week, both. The dawn notice says which. A gate can be built on each, as on the north one. The werewolf still needs four blows for one.",
		"Jumping goes whichever way you are pressing, forwards, sideways or back, and you keep facing the way you were, so you can get out of the Lord’s way without turning your back on him. With nothing pressed you jump on the spot. It does nothing, but it is something to do while waiting.",
	]],
	["Version 7.4: the Lord", [
		"The Lord of Ashhollow now has 10,000 health, before counting how many of you there are. Blows that are not holy no longer glance off him. There are simply a great many of them needed.",
		"He does not come down first. His shadow does: a long, dark thing that goes about the field on his behalf. Fire goes straight through it, and it steps somewhere else, unhurt and faintly insulted. Holy things drive it back. It raises the fallen dead again, and it picks up the ones nearby and throws them, at you or at whatever you built.",
		"The Lord waits until his shadow is put down and half the night’s horde with it. Then he comes in person, through the north gate, and the rest of the dead have the sense to leave. There is organ music. He brought it.",
		"In person he sweeps his cloak in front of him, sends a line of bats down the road, brings his goblet down on the ground hard enough to throw people, vanishes and comes back behind whoever was keeping furthest away, and throws a shambler at you now and then because it is there. Each of these is shown on the ground a moment before. It is still advice.",
		"Space now jumps: a quick leap in the way you are going, which gets you out of most of the above if you are paying attention. A left click attacks. If you had set Space to attack, it has been taken back and given a better job.",
		"At the water, Space or a left click lands a fish.",
	]],
	["Version 7.3: the bosses, and three more of them", [
		"The bosses had been too easy to kill. The Steward now has 3,000 health, the Coachman 4,500 and the Captain of the Guard 6,000, before counting how many of you there are.",
		"And each now does something about you. The Steward serves notice: he slams his ledger shut, and everyone near him is thrown back. The Coachman whips up his horses, and they stampede, and anyone in the road ends up beside it. The Captain lines up a charge, shows you the line, and comes down it: step out of the line.",
		"The Lord’s Chaplain, on night 11. He preaches, and whoever hears him is drawn slowly in, and the dead near him mend while he does it. A hard enough blow makes him lose his place. He has been losing it since 1407.",
		"The Castle Cook, on night 18. He ladles boiling stew wherever somebody is standing (there is a moment to move before it is hot), and he swings his cauldron round, which sends people a long way. The stew is not recommended.",
		"The Gamekeeper, on night 28, the second full moon. He is a werewolf, and his night is mostly him. One blow breaks a barricade; four take down a wall or a gate. His howl freezes everyone who hears it where they stand, unless they are being prayed over or wearing the Helm of the Unbothered.",
		"A red ring on the ground means something is about to land there. It is advice.",
		"The Lord of Ashhollow is unchanged for now. His turn is next.",
	]],
	["Version 7.2: the dead, taken more seriously", [
		"The dead have twice the health they had in the first week, and three times from the second week on, and they still grow tougher every week on top of that. A shambler on the first night now takes about nine blows of a pitchfork. You were warned they were too easy. Somebody listened.",
		"The bloated dead, from the first night: slow, and very full. Put one down and it bursts, and everything near it, living or dead, gets the worst of it. Do it from a distance, or next to a crowd of its friends.",
		"Pallbearers, from the first night: they carry a coffin lid in front of them, and a blow from the front does a quarter of what it should. Go round the side, or bring something heavy, or set them alight. The lid belonged to somebody. Try not to think about it.",
		"Grave hounds, from the first night: quick, frail, and much more interested in your posse than in you. Keep your peasants close.",
		"The horde changes as the month goes on. In the first week three quarters of it is the easy sort; by the last week it is mostly the hard sort, and the shamblers are thin on the ground.",
		"All of the dead but the bosses have a faint, evil glow about the edges, which shows best at night. The bosses were consulted, and preferred not to.",
	]],
	["Version 7.1: mends", [
		"A word on numbers. This is version 7.1. Small additions go up by a tenth; the big updates get the whole numbers. Nothing else about the arithmetic is guaranteed.",
		"The Smoking Censer now does what it always said it did, and where you can see it. It smokes, out to eight paces. The dead in the smoke walk at half speed and strike half as often, and they go grey about it. (Bosses are slowed on their feet only. They did not get where they are by breathing in.)",
		"The Thunderer’s Bow is now the Thunderer’s Crossbow. As a bow it was quick, and rather too good. As a crossbow it is heavy, slow to load and hits a great deal harder, and its bolts are still lightning. If you had the bow, you now have the crossbow. Nobody asked you.",
		"The ordinary crossbow loads a quarter faster, having been found underwhelming.",
		"Peasants on a watch platform throw smaller stones: five harm, where it was eight. They were enjoying it too much.",
		"The storehouse stacks. Two steel warhammers are one place on the shelf with a 2 on it, not two places.",
		"The rain is a good deal quieter. It is still raining.",
		"A cockerel at dawn. Somebody has to be pleased about it.",
	]],
	["The blood moon, corrected", [
		"The blood moon (night 23) was two and a half times as many of the dead. It is now two and a half times the difficulty instead: the horde is its usual size, and every one of them takes two and a half times as much putting down and hits nearly twice as hard. They come down the road red.",
	]],
	["Moons, the watch platform, and Robert Bailiff at dusk", [
		"Five moons a month. The harvest moon (night 9): the dead slowly mend, so finish what you start. Fire stops the mending. The full moon (nights 15 and 28): the dead are quick, and relics glint in the rubble. The frost moon (night 19): it snows. The blood moon (night 23): two and a half nights’ worth of the dead in one, under a red sky, and the hat goes round two and a half times after.",
		"The watch platform, which the design always had and the game did not: twenty wood, built like a barricade. Hold {interact} at it to post one of your posse there. From dusk they climb up and throw stones over the wall at whatever comes in reach. Nothing can get at them up there but archers, and ten more wood puts a roof on that stops the arrows.",
		"Every dusk Robert Bailiff throws open his window and shouts at you all to defend his village. His window has moved along to where the inn does not hide it, and has shutters now.",
		"Health bars over walls and gates turn with the view, as the posse’s do.",
	]],
	["The storehouse, relics, leading and fishing", [
		"The storehouse is laid out like a bank. Materials: take out 1, 5 or 20, put in 1, 5 or all, one row each, no more wall of text. Things: the village’s spare arms and armour in a grid; click one to take it, click one of yours to put it in. Runes can be stored too.",
		"A relic for every book. Four new ones are out in the rubble: the Thunderer’s Bow, whose arrows are lightning; Saint Walstan’s Scythe; the Mason’s Blessed Trowel; and Saint Dunstan’s Tongs. The handbook says what each does.",
		"Leading: {orders} works from the first rank of How to Win Peasants and Lead Them (follow, or hold; charge still comes at rank 3), and the book is now learned by leading: orders, your posse’s work as well as its blows, and bringing them through the night alive. It was nearly impossible to get to rank 3 before.",
		"Fishing is worth the walk: a catch is five fish (seven at rank 3), and the river now and then gives up a purse, a rune, or something somebody dropped. The farm is still better for a big posse.",
		"Books are shown by their titles, with what they are about in brackets: Hammer and Tongs (Blacksmithing).",
		"The log roller’s logs now roll: five of them, down the road, with dust. Houses no longer have timbers sticking out of their corners.",
	]],
	["Tougher dead, and the nights of the bells", [
		"The dead take more putting down as the month goes on: half as much again in the second week, twice in the third, nearly three times in the fourth. The first week is as it was. One blow no longer does for everything.",
		"The nights of the bells: three nights a month (one in each week after the first) the priest and his congregation ring the chapel bells until dawn. It enrages the dead: quicker, a quarter stronger and a quarter harder to put down. The notice board and the morning news warn you, and the hat goes round twice afterwards.",
		"Relics glow: the metal, a halo round it, and light on whatever is near, in the hand, on your head or back, and lying on the ground. Rune weapons glow violet.",
		"The farm is marked on the map.",
	]],
	["Fixes from the first long game", [
		"Black nights: on a foggy night the whole screen went black. The fog was being measured from the wrong place and swallowed everything. Fixed: fog now closes in just beyond you, as it was meant to.",
		"Playing together, indoors: a joined player down the old workings or in the Rose was being held at the edge of the map by the host's game. So they could not climb out, the host could not see them, and they were stuck. Fixed.",
		"Joining: a village can now be joined after its week has begun, and if you drop out your peasant is kept for you to come back to, under the same name. Before, a late or dropped player was simply turned away. The host also waits most of a minute for a slow computer before deciding it has gone (it was twelve seconds).",
		"The old steel mine: its mouth was drawn on the west side and worked from the east, so nobody could find where to stand. It faces the village now, and can be worked from in front.",
		"I’m a stuck little peasant: a button at the bottom of the handbook (Esc) that puts you and your posse outside your own front door.",
		"Health bars over the posse turn with the view and show the right amount. Hold {interact} to get up from the bar. Rain is thinner to look at, and the mud slows the living a little as well as the dead.",
		"The training dummies say what they are for when you stand by one.",
	]],
	["Rune weapons", [
		"Runes now make the top tier of weapons: the rune sword, spear, mace, billhook and warhammer. Each takes four runes and the steel a steel one takes.",
		"Only a smith at rank 7 of Hammer and Tongs, the last rank, can forge them. They hit a good deal harder than steel (about a quarter more), and they hurt wraiths.",
		"Cutting three runes into any old weapon is gone: that was a stopgap. Runes still come from the old workings, with a torch.",
		"The name is settled: Thornhallow Thirty Nights.",
	]],
	["Blows that feel like something", [
		"A swing leaves a sweep in the air where the blade went: a wide crescent for a billhook or a scythe, a quick dart for a pitchfork or a spear. Orange for the torch, gold for holy things, violet for a rune-cut blade. Your posse and the dead have smaller ones of their own.",
		"A blow that lands shows a number. Big and gold means the right tool for the job, small and grey means the wrong one, big and orange with a mark is a lucky double, and small orange ones are things on fire. So the game now tells you, without a handbook, that your pitchfork is not getting through that armour.",
		"Blows have a noise of their own now: a thwack, a tink off armour, something grander for a double. Heavy weapons whoosh. Whatever is hit flinches.",
		"Your own blows knock the view a little, and being hit jolts it. Tricks got bigger: Smash, Clang, Flare and the rest send a ring racing out along the ground, and the sweeping ones go right round you.",
		"If the numbers or the knocks annoy you, both are in Options.",
	]],
	["The game keeps itself up to date", [
		"The game can now be handed out as one file, Thornhallow.exe, with nothing to install.",
		"When it reaches the title screen it asks whether a newer build is out. If there is, it fetches it quietly (a few megabytes) and the corner of the title screen offers to restart into it. If you do not, you get it the next time you start the game anyway.",
		"The corner of the title screen says which build you are on. Two builds cannot share a village, so if a friend cannot join, the game says which of you is behind.",
		"A build that fails to start is given up on, and the game goes back to the last one that worked.",
	]],
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
	["A new name: Thornhallow Thirty Nights", [
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
var guide_ch := 0                     # the handbook's chapter being read

func guide_page(b: VBoxContainer) -> void:
	guide_ch = clampi(guide_ch, 0, GUIDE.size() - 1)
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 16); b.add_child(row)
	var ls := ScrollContainer.new(); ls.custom_minimum_size = Vector2(222, 418); ls.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; row.add_child(ls)
	var left := VBoxContainer.new(); left.custom_minimum_size.x = 208; left.add_theme_constant_override("separation", 2); ls.add_child(left)
	for i in GUIDE.size():
		var bt := Button.new(); bt.text = GUIDE[i][0]; bt.toggle_mode = true; bt.button_pressed = i == guide_ch
		bt.focus_mode = Control.FOCUS_NONE; bt.alignment = HORIZONTAL_ALIGNMENT_LEFT; bt.add_theme_font_size_override("font_size", 14)
		bt.custom_minimum_size.y = 30
		var ii := i
		bt.pressed.connect(func(): guide_ch = ii; menu())
		left.add_child(bt)
	var rs := ScrollContainer.new(); rs.size_flags_horizontal = Control.SIZE_EXPAND_FILL; rs.custom_minimum_size.y = 418   # the pages scroll; the chapters stay put
	rs.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; row.add_child(rs)
	var right := VBoxContainer.new(); right.size_flags_horizontal = Control.SIZE_EXPAND_FILL; right.add_theme_constant_override("separation", 6); rs.add_child(right)
	Look.label(right, GUIDE[guide_ch][0], 24, Look.INK, true)
	for sec in GUIDE[guide_ch][1]:
		if sec[0] != GUIDE[guide_ch][0]:                  # (a chapter of one page has no heading of its own)
			var hd := Look.label(right, str(sec[0]).to_upper(), 13, Look.RUST)
			hd.add_theme_constant_override("line_spacing", 0)
		for p in sec[1]:
			if str(p).begins_with("@books:"):
				for bi in D.BOOK_GROUPS[int(str(p).substr(7))][1]:
					var B: Dictionary = D.BOOKS[bi]
					var pw: String = (" Its power: %s, %s." % [D.POWERS[bi].n, D.POWERS[bi].d]) if bi < D.POWERS.size() and not D.POWERS[bi].is_empty() else ""
					Look.label(right, B.name, 17, Look.INK, true)
					Look.para(right, Keys.fill("%s. Learned by %s.%s Rank I: %s." % [B.what, B.by, pw, Notices.lower(B.ranks[0])]), 15, Look.INK_SOFT)
				continue
			Look.para(right, Keys.fill(p), 16)
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
	nm.tooltip_text = "A new month: thirty nights, seven bosses, and every kind of dead. Saved every morning."
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
# ---------------------------------------------------------------- the developer console (the test copy, version 7.15)
var dev_day := 1
var dev_msg := ""

func dev_page(b: VBoxContainer) -> void:
	var R: Rules = m.R
	var p: E.Player = m.me
	if Net.me.is_client():
		w.para("Only whoever is hosting can use the developer console. Ask them, or start a game of your own.", 15)
		return
	if dev_day < 1: dev_day = R.day
	w.para("For trying things out. None of this is in the real game, and this copy keeps its own saved game." + ("  " + dev_msg if dev_msg != "" else ""), 14, Look.INK_SOFT)
	var btn := func(row: HBoxContainer, t: String, f: Callable) -> void:
		var c := Button.new(); c.text = t; c.focus_mode = Control.FOCUS_NONE
		c.pressed.connect(func(): f.call(); menu())
		row.add_child(c)
	var row_ := func() -> HBoxContainer:
		var h := HBoxContainer.new(); h.add_theme_constant_override("separation", 8); b.add_child(h); return h
	w.head("The day")
	var r1: HBoxContainer = row_.call()
	btn.call(r1, " − ", func(): dev_day = maxi(1, dev_day - 1))
	Look.label(r1, "Day %d of %d" % [dev_day, R.last_day], 17, Look.INK, true)
	btn.call(r1, " + ", func(): dev_day = mini(R.last_day, dev_day + 1))
	btn.call(r1, "Go to that morning", func(): R.dev_day(dev_day); dev_msg = "It is the morning of day %d." % R.day)
	btn.call(r1, "…and straight to dusk", func(): R.dev_day(dev_day); R.timeLeft = 0.5; dev_msg = "Day %d, and dusk is falling." % R.day)
	var bn := ""
	for d in D.BOSS_NIGHTS:
		if int(d) == dev_day: bn = D.UN[D.BOSS_NIGHTS[d]].name
	var mo := Rules.moon_of(dev_day, R.last_day)
	w.para(("Night %d brings %s. " % [dev_day, bn] if bn != "" else "No boss that night. ") + ("The %s moon is up." % mo if mo != "" else ""), 13, Look.INK_SOFT)
	var r2: HBoxContainer = row_.call()
	btn.call(r2, "Dusk now", func(): if R.phase == "day": R.timeLeft = 0.5)
	btn.call(r2, "Clear the dead", func():
		for u in R.undead: u.hp = 0; R.kill_undead(u)
		if R.night: R.night.q = []; R.night.boss = -1)
	btn.call(r2, "End the night", func():
		R.undead = []; R.boss = null
		if R.night: R.night.q = []; R.night.boss = -1)
	w.head("You")
	var r3: HBoxContainer = row_.call()
	var full := CheckBox.new(); full.text = "Always full of everything"; full.button_pressed = Dev.full; full.focus_mode = Control.FOCUS_NONE
	full.toggled.connect(func(on_): Dev.full = on_); r3.add_child(full)
	var safe := CheckBox.new(); safe.text = "Nothing can hurt you"; safe.button_pressed = Dev.safe; safe.focus_mode = Control.FOCUS_NONE
	safe.toggled.connect(func(on_): Dev.safe = on_); r3.add_child(safe)
	var r4: HBoxContainer = row_.call()
	Look.label(r4, "Every book at rank", 15)
	for rk_ in [1, 4, 7, 10]:
		btn.call(r4, str(rk_), func(): Dev.books(p, rk_); dev_msg = "Every book at rank %d." % rk_)
	btn.call(r4, "No books", func(): for i in p.books.size(): p.books[i] = 0; p.xp[i] = 0.0; p.jl = 0)
	var r5: HBoxContainer = row_.call()
	btn.call(r5, "Make me a priest", func(): Dev.calling(p, 0); dev_msg = "An apprentice priest, at rank X.")
	btn.call(r5, "Make me a jester", func(): Dev.calling(p, 1); dev_msg = "A jester, all three lessons, rank X.")
	btn.call(r5, "Neither", func(): Dev.calling(p, -1))
	w.head("The village")
	var r6: HBoxContainer = row_.call()
	btn.call(r6, "Every relic and rune piece on the rack", func(): Dev.rack(R); dev_msg = "The storehouse rack is full of good things.")
	btn.call(r6, "Build the raft and the Rune Cave", func(): R.raft = true; R.raftW = D.RAFT.wood; R.rcave = true; R.sv += 1)
	var r7: HBoxContainer = row_.call()
	btn.call(r7, "Take me to the Riverside", func(): R.raft = true; R.raftW = D.RAFT.wood; R.enter_room(p, "riverside"); w.close())
	btn.call(r7, "Take me home", func(): if p.room != "": R.leave_room(p); w.close())
	btn.call(r7, "A sheep, and the Herder's lesson", func(): p.herd = true; p.sheep = true; p.sheepFed = R.day)


func menu(tab: String = "") -> void:
	if tab != "": menu_tab = tab
	_leave_armed = false                                 # (version 7.39) "Leave" asks twice every time the handbook is opened
	var in_game: bool = m.in_game()
	var b: VBoxContainer = w.open("menu", "The handbook" + (" (test copy)" if Dev.on() else ""), "", 760, 600, true)
	var tabs_ := [["guide", "Guide"], ["keys", "Controls"], ["opts", "Options"]]
	if Dev.on() and in_game: tabs_.append(["dev", "Developer"])
	if menu_tab == "dev" and not (Dev.on() and in_game): menu_tab = "guide"
	w.tabs(tabs_, menu_tab, func(t): rebinding = ""; bind_msg = ""; menu(t))
	match menu_tab:
		"dev":
			dev_page(b)
		"guide":                                         # (version 7.37) chapters down the left, and the chapter's pages on the right
			guide_page(b)
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
			w.para("Fixed: a click attacks and a right-click is your weapon’s trick. The numbers 1 to 9 use the action bar, or pick an option when a notice is open. Esc closes whatever is open, and otherwise opens this handbook.", 14, Look.INK_SOFT)
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
			Look.label(g, "Numbers when a blow lands", 15)
			var nb := CheckBox.new(); nb.button_pressed = Settings.numbers; nb.toggled.connect(func(on): Settings.numbers = on; Settings.save()); g.add_child(nb)
			Look.label(g, "Your own blows knock the view a little", 15)
			var sh := CheckBox.new(); sh.button_pressed = Settings.shake; sh.toggled.connect(func(on): Settings.shake = on; Settings.save()); g.add_child(sh)
			Look.label(g, "Fill the whole screen (F11)", 15)
			var fs := CheckBox.new(); fs.button_pressed = Settings.fullscreen; fs.toggled.connect(func(on): Settings.fullscreen = on; Settings.save(); Settings.apply_window()); g.add_child(fs)
			w.para("These are kept on this computer.", 13, Look.INK_SOFT)
	if in_game:
		var sb: Button = w.foot_button("I’m a stuck little peasant", func(): m.cmd({"t": "act", "a": "unstick"}); w.close())
		sb.tooltip_text = "Wedged in a wall, lost down a hole, or the door will not open? This puts you, and your posse, outside your own front door."
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
		bind_msg = "The numbers are kept for the action bar and for notices."
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
	if id == "store":                                   # and the storehouse a counter
		store(force)
		return
	if id == "smithy":                                  # and the smithy a wall of pictures
		smithy(force)
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


# ---------------------------------------------------------------- the storehouse
var store_tab := "res" if OS.get_environment("DTV_STORE_TAB") == "" else OS.get_environment("DTV_STORE_TAB")
var _store_sig := ""

## The storehouse, laid out like a bank: materials on one tab (take 1, 5 or 20; put in 1, 5 or all), and the
## village's spare things on the other (click one to take it; click one of yours to put it in). Things that are
## the same are shown once, with how many there are.
func store(force: bool = false) -> void:
	var p: E.Player = m.me
	var R: Rules = m.R
	var sig := str([store_tab, R.store, R.items, p.inv, p.wpn, p.head, p.body, p.off, p.trk, p.feet, D.STORE_RES.map(func(k): return p.get(k)), Settings.binds])
	if sig == _store_sig and w.is_open("notice") and not force:
		return
	_store_sig = sig
	var act := func(a: String, arg) -> void: m.cmd({"t": "act", "a": a, "arg": arg})
	w.open("notice", "The storehouse", "", 700, 580, true, false)
	w.tabs([["res", "Materials"], ["items", "Things (%d)" % R.items.size()]], store_tab, func(t): store_tab = t; store(true))
	if store_tab == "res":
		w.para("Shared by the whole village. You can carry %d of each." % Rules.cap(p), 15, Look.INK_SOFT)
		var g := GridContainer.new()
		g.columns = 5
		g.add_theme_constant_override("h_separation", 14)
		g.add_theme_constant_override("v_separation", 8)
		w.body.add_child(g)
		for h in ["", "", "In store", "Take out", "Put in  (you carry)"]:
			Look.label(g, h, 13, Look.RUST)
		for k in D.STORE_RES:
			var have: int = p.get(k)
			var inside: int = int(R.store.get(k, 0))
			var room: int = Rules.cap(p) - have
			var ic := TextureRect.new()
			ic.texture = Look.icon(k, 30)
			ic.custom_minimum_size = Vector2(30, 30)
			ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			g.add_child(ic)
			Look.label(g, D.RES_NAME[k], 18)
			var cnt := Look.label(g, str(inside), 20, Look.INK if inside > 0 else Color(Look.INK, 0.4), true)
			cnt.custom_minimum_size.x = 64
			for side in [0, 1]:                         # 0: take out, 1: put in
				var row := HBoxContainer.new()
				row.add_theme_constant_override("separation", 5)
				g.add_child(row)
				for n in ([1, 5, 20] if side == 0 else [1, 5, 0]):
					var bt := Button.new()
					bt.focus_mode = Control.FOCUS_NONE
					bt.custom_minimum_size.x = 46
					bt.text = "All" if n == 0 else str(n)
					var key: String = k
					var amt: int = n
					if side == 0:
						bt.disabled = inside <= 0 or room <= 0
						bt.tooltip_text = ("You can carry no more %s." % k) if room <= 0 and inside > 0 else "Take %d %s (or what there is, or what you can carry)." % [n, k]
						bt.pressed.connect(func(): act.call("take", "%s:%d" % [key, amt]))
					else:
						bt.disabled = have <= 0
						bt.tooltip_text = "Put in all the %s you carry." % k if n == 0 else "Put in %d %s (or what you have)." % [n, k]
						bt.pressed.connect(func(): act.call("put", key if amt == 0 else "%s:%d" % [key, amt]))
					row.add_child(bt)
				if side == 1: Look.label(row, "  %d" % have, 16, Look.INK_SOFT)
		w.hint("Click a number to take out or put in that many. Walk away or press Esc to close.")
	else:
		w.head("In the storehouse (%d of 60): click a thing to take it" % R.items.size())
		var bank := HFlowContainer.new()
		bank.add_theme_constant_override("h_separation", 6)
		bank.add_theme_constant_override("v_separation", 6)
		w.body.add_child(bank)
		if R.items.is_empty():
			Look.para(bank, "Nothing yet. Spare arms and armour left here are for anybody in the village to take.", 15, Look.INK_SOFT).custom_minimum_size.x = 600
		var kinds := []                                  # things that are the same share a place, with a number on it
		var first := {}
		var many := {}
		for i in R.items.size():
			var id0: int = R.items[i]
			if not first.has(id0):
				first[id0] = i; many[id0] = 0; kinds.append(id0)
			many[id0] += 1
		for it in kinds:
			var j: int = first[it]
			var n: int = many[it]
			var fits: bool = p.inv.size() < D.PACK_MAX or Rules.wears_now(p, it)
			_slot(bank, it, "", "× %d" % n if n > 1 else "", "%s%s. %s %s" % [D.it_cap(it), " (there are %d)" % n if n > 1 else "", Notices.item_sub(p, it), ("Click to take one." if n > 1 else "Click to take it.") if fits else "Your backpack is full."], false,
				(func(): act.call("takei", j)) if fits else Callable(), Callable(), not Rules.can_use(p, it))
		w.head("Yours: click a thing to put it in")
		var mine := HFlowContainer.new()
		mine.add_theme_constant_override("h_separation", 6)
		mine.add_theme_constant_override("v_separation", 6)
		w.body.add_child(mine)
		for k in D.SLOTS:
			var id: int = p.get(k)
			if id > 0:
				var slot: String = k
				_slot(mine, id, Notices.SLOTN[k], "", "%s. %s. Click to put it in the storehouse." % [D.it_cap(id), "It is in your hand: you go back to the pitchfork" if k == "wpn" else "You are wearing it"], false, func(): act.call("pute", slot), Callable())
		for i in D.PACK_MAX:
			if i >= p.inv.size():
				_slot(mine, -1, "", "", "", false, Callable(), Callable())
				continue
			var j := i
			_slot(mine, p.inv[i], "", "", "%s. %s Click to put it in the storehouse." % [D.it_cap(p.inv[i]), Notices.item_sub(p, p.inv[i])], false, func(): act.call("puti", j), Callable())
		_info = w.para("Point at a thing to read about it.", 14, Look.INK_SOFT)
		_info.custom_minimum_size.y = 48
		w.hint("Click a thing to move it. Walk away or press Esc to close.")


# ---------------------------------------------------------------- the smithy
var smithy_tab := "crude" if OS.get_environment("DTV_SMITHY_TAB") == "" else OS.get_environment("DTV_SMITHY_TAB")
var _smithy_sig := ""
var _slot_w := 88.0              # how wide an item's card is (the smithy's are wider, to fit the price)
var _slot_strip := ""            # and a word left off the front of its name (the smithy's tier, which the tab says already)
const SMITHY_TABS := [["crude", "Crude"], ["forged", "Iron"], ["steel", "Steel"], ["mithril", "Mithril"], ["rune", "Rune"], ["kits", "Posse"]]

## The smithy: pick a tier, and a page of pictures opens, one for each thing that tier can make. Click one to forge it.
func smithy(force: bool = false) -> void:
	var p: E.Player = m.me
	var R: Rules = m.R
	var h3 := Rules.rk(p, 3)
	var sig := str([smithy_tab, p.wood, p.iron, p.steel, p.mith, p.rune, p.wpn, p.head, p.body, p.off, p.inv, h3, R.peasants.filter(func(q): return q.owner == p.id).map(func(q): return [q.kit, q.armed]), Settings.binds])
	if sig == _smithy_sig and w.is_open("notice") and not force:
		return
	_smithy_sig = sig
	var act := func(a: String, arg) -> void: m.cmd({"t": "act", "a": a, "arg": arg})
	w.open("notice", "The smithy", "", 720, 600, true, false)
	w.tabs(SMITHY_TABS, smithy_tab, func(t): smithy_tab = t; smithy(true))
	w.para("You carry %d wood, %d iron, %d steel, %d mithril and %d rune%s. What you forge goes on; what it replaces goes in your backpack." % [p.wood, p.iron, p.steel, p.mith, p.rune, "" if p.rune == 1 else "s"], 14, Look.INK_SOFT)
	var tier := smithy_tab
	var ids := []
	var blurb := ""
	match tier:
		"crude":
			blurb = "Anyone can make these. Crude weapons are chipped after a night’s fighting and gone after a second; crude armour lasts, being mostly hope."
			ids = D.CRUDE_W.map(func(b): return D.crude_of(b)) + D.BOWS.map(func(b): return D.tier_item(b, "crude")) + D.ARMOUR.map(func(b): return D.tier_item(b, "crude")) + [D.I_TORCH]
		"forged":
			blurb = "Iron: the measure of everything else. Anyone can make the armour; the weapons need Hammer and Tongs%s." % ("" if h3 >= 1 else ", which you have not read")
			ids = D.FORGE_W.filter(func(i): return not D.BOWS.has(i)) + D.BOWS + D.ARMOUR + [D.I_HOBNAILS]   # (FORGE_W has the bows in it already: they were showing twice)
		"steel":
			blurb = "A third better than iron, from the old steel mine. Rank 4 of Hammer and Tongs%s." % ("" if h3 >= 4 else " (you are at rank %d)" % h3)
			ids = D.STEEL_W.map(func(b): return D.steel_of(b)) + D.BOWS.map(func(b): return D.tier_item(b, "steel")) + D.STEEL_A.map(func(b): return D.steel_of(b)) + [D.I_SABATONS]
		"mithril":
			blurb = "Half as good again as iron, and it glows purple. Mithril comes from the Old Mine under the steel mine: take a torch. Rank %d of Hammer and Tongs%s." % [D.MITHRIL_RANK, "" if h3 >= D.MITHRIL_RANK else " (you are at rank %d)" % h3]
			ids = D.STEEL_W.map(func(b): return D.tier_item(b, "mithril")) + D.BOWS.map(func(b): return D.tier_item(b, "mithril")) + D.ARMOUR.map(func(b): return D.tier_item(b, "mithril"))
		"rune":
			blurb = "The best there is outside the relics, and it glows blue. It needs rank 10 of Hammer and Tongs, and runes, from the Rune Cave at the Riverside, across the river: a shady fellow outside it wants twenty wood before anyone goes in."
			ids = D.STEEL_W.map(func(b): return D.tier_item(b, "rune")) + D.BOWS.map(func(b): return D.tier_item(b, "rune")) + D.ARMOUR.map(func(b): return D.tier_item(b, "rune"))
		"kits":
			blurb = "A kit goes straight to one of your posse who has none, and they fight with what it gives them. When one of them falls, the kit outlives them: it lies where they fell, for anybody. Crude kits from rank 1 of Hammer and Tongs, iron from 3, steel from 6; crude ones come apart after two nights."
			ids = D.kits()
	if tier != "kits" and Rules.rk(p, D.B_SQUIRE) > 0:   # (version 7.30) a greatsword, for a reader of the Knight's Squire (forged from its rank III)
		ids.append(D.great_of(tier))
		blurb += " Greatswords: rank 3 of the Knight’s Squire%s." % ("" if Rules.rk(p, D.B_SQUIRE) >= 3 else " (you are at rank %d)" % Rules.rk(p, D.B_SQUIRE))
	w.para(blurb, 15)
	var bank := HFlowContainer.new()
	bank.add_theme_constant_override("h_separation", 6)
	bank.add_theme_constant_override("v_separation", 6)
	w.body.add_child(bank)
	for id in ids:
		if id < 0: continue
		var I: Dictionary = D.IT[id]
		var c := Rules.forge_cost(p, I.cost)
		var why := Rules.forge_why(p, id)
		var locked := why != "" or not Rules.can_forge(p, id)
		var ok := not locked and Rules.has(p, c)
		var tip := "%s. %s." % [D.it_cap(id), D.cost_text(c)]
		if I.s == "w": tip += " %s. %d damage. {trick}: %s." % [I.note, I.dmg, D.AB[I.ab].n] + ("" if Rules.can_use(p, id) else " You cannot use it yet: it needs %s." % Notices.book_need(I.need))
		elif I.s == "k": tip += " " + I.note + "."
		else: tip += " " + Notices.item_sub(p, id)
		if why != "": tip += " " + why
		elif not ok: tip += " You have not got enough."
		else: tip += " Click to forge it."
		var forge_id: int = id
		_slot_w = 104.0; _slot_strip = {"crude": "crude ", "steel": "steel ", "mithril": "mithril ", "rune": "rune "}.get(tier, "")
		_slot(bank, id, D.cost_text(c).replace(" and ", ", "), "", tip, false, (func(): act.call("forge", forge_id)) if ok else Callable(), Callable(), locked or not ok)
		_slot_w = 88.0; _slot_strip = ""
	if tier == "kits":
		var row := HFlowContainer.new()
		row.add_theme_constant_override("h_separation", 8)
		row.add_theme_constant_override("v_separation", 6)
		w.body.add_child(row)
		var free := R.peasants.filter(func(q): return R.kit_free(p, q)).size()
		if h3 >= 3:
			for id in D.kits():
				if not Rules.can_forge(p, id): continue
				var b := Button.new()
				b.focus_mode = Control.FOCUS_NONE
				b.text = "All: %s" % D.IT[id].n.replace("’s kit", "s")
				b.tooltip_text = "Kit out every one of your posse who has none, while what you carry lasts."
				b.disabled = free == 0 or not Rules.has(p, Rules.forge_cost(p, D.IT[id].cost))
				var kid: int = id
				b.pressed.connect(func(): act.call("kitall", kid))
				row.add_child(b)
		var sc := Rules.forge_cost(p, D.PEASANT_ARM)
		var un := R.peasants.filter(func(q): return q.owner == p.id and not q.armed and q.kit <= 0 and q.state != "body").size()
		var sp := Button.new()
		sp.focus_mode = Control.FOCUS_NONE
		sp.text = ("Spears all round" if h3 >= 3 else "A spear for one") + " (%s)" % D.cost_text(sc)
		sp.disabled = un == 0 or not Rules.has(p, sc)
		sp.tooltip_text = "The old way: a spear, for anyone. %d of yours still carry a pitchfork. A kit is better." % un
		sp.pressed.connect(func(): act.call("armp", null))
		row.add_child(sp)
		w.para("%d of your posse %s no kit." % [free, "has" if free == 1 else "have"], 14, Look.INK_SOFT)
	_info = w.para("Point at a thing to read about it.", 14, Look.INK_SOFT)
	_info.custom_minimum_size.y = 64
	w.hint("Pick a tier, then click a thing to forge it. Walk away or press Esc to close.")


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
	var sig := str([p.inv, p.wpn, p.head, p.body, p.off, p.trk, p.feet, p.bless, p.holy, p.books, p.bodies, p.bbod, p.coin >= D.BLESS_FEE, Settings.binds, _destroy_arm, p.flask])
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
	if p.flask:                                         # the hip flask (rank 9 of the Landlord's Ledger)
		var fb := Button.new()
		fb.text = "Drink from your hip flask"
		fb.tooltip_text = "One tankard’s worth of Dutch courage, wherever you are. Enough of it and you charge."
		fb.focus_mode = Control.FOCUS_NONE
		fb.alignment = HORIZONTAL_ALIGNMENT_LEFT
		fb.pressed.connect(func(): m.cmd({"t": "act", "a": "flask"}))
		w.body.add_child(fb)
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
		w.hint("Start when you are ready. Friends can still join after the month has begun: they move into an empty cottage. The short game is seven nights.")
	else:
		w.foot_button("Leave", func(): N.leave(); home())
		w.hint("Waiting for the host to start." if N.my_id != 0 else "")


# ---------------------------------------------------------------- skills: each book as a ladder of seven ranks
var skill_book := -1
var _skills_sig := ""
const ROMAN := ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]

func skills(force: bool = false) -> void:
	var p: E.Player = m.me
	var owned: Array = []
	for i in D.BOOKS.size():
		if Rules.rk(p, i) > 0: owned.append(i)
	if skill_book < 0 or not owned.has(skill_book):
		skill_book = owned[0] if owned.size() else -1
	var sig := str(p.books) + str(p.xp.map(func(x): return floori(x))) + str(floori(p.spare)) + str(skill_book) + str(p.coward) + str(p.pages) + str(m.bar_all()) + str(Settings.bar_order) + str(Settings.bar_off)
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
	left.custom_minimum_size.x = 330
	left.add_theme_constant_override("separation", 3)
	cols.add_child(left)
	var order := []                                   # (version 7.37) in kinds, each under its heading
	for G in D.BOOK_GROUPS:
		order.append(str(G[0]).split(" (")[0])
		order.append_array(G[1])
	for i_ in order:
		if i_ is String:
			var gh := Look.label(left, str(i_).to_upper(), 12, Look.RUST)
			gh.add_theme_constant_override("line_spacing", 0)
			continue
		var i: int = i_
		var bk: Dictionary = D.BOOKS[i]
		var bt := Button.new()
		bt.focus_mode = Control.FOCUS_NONE
		bt.toggle_mode = true
		bt.button_pressed = i == skill_book
		var rr := Rules.rk(p, i)
		bt.disabled = rr == 0
		bt.alignment = HORIZONTAL_ALIGNMENT_LEFT
		bt.text = "%s   %s\n       (%s)" % [ROMAN[rr] if rr else "—", bk.name, bk.what]     # the book, and in a word what it is about
		bt.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		bt.clip_text = true
		bt.tooltip_text = D.book_title(i) if rr else D.book_title(i) + (". Sir Aldous, in the library, has it." if i == D.B_SQUIRE else ". In the library.")
		bt.add_theme_font_size_override("font_size", 14)
		bt.add_theme_constant_override("line_spacing", -3)
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
		Look.para(right, "(%s.) You learn it by %s.%s" % [bk.what, bk.by, " Halved while you are a coward." if p.coward else ""], 15, Look.INK_SOFT)
		var gap := Control.new(); gap.custom_minimum_size.y = 8; right.add_child(gap)
		for r in range(1, D.MAX_RANK + 1):
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
			med.custom_minimum_size = Vector2(40, 34)
			med.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			row.add_child(med)
			var num := Look.label(med, ROMAN[r], 17, Look.INK if got or next else Color(Look.INK, 0.4))
			num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			var tv := VBoxContainer.new()
			tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			tv.add_theme_constant_override("separation", 1)
			row.add_child(tv)
			var t := Look.para(tv, Keys.fill(bk.ranks[r - 1]), 15, Look.INK if got else Look.INK_SOFT if next else Color(Look.INK_SOFT, 0.6))
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
			if r < D.MAX_RANK:                                     # the line joining one rank to the next
				var link := HBoxContainer.new()
				right.add_child(link)
				var stem := ColorRect.new()
				stem.color = Look.GOLD if rank > r else Color(Look.OUTLINE, 0.3)
				stem.custom_minimum_size = Vector2(4, 6)
				var pad := Control.new(); pad.custom_minimum_size.x = 18
				link.add_child(pad); link.add_child(stem)
		if rank >= D.MAX_RANK:
			var pg: int = int(p.pages[b]) if b < p.pages.size() else 0
			var done := Look.para(right, "Mastered. What you learn from this book now is spare, and can be honed into it: %d of %d pages, %d in the hundred on everything it does." % [pg, D.HONE_MAX, pg * 2], 15, Look.RUST)
			done.custom_minimum_size.y = 26
			var hb := Button.new()
			hb.focus_mode = Control.FOCUS_NONE
			hb.text = "Hone a page into it (%d spare points)" % D.HONE_COST
			hb.disabled = pg >= D.HONE_MAX or p.spare < D.HONE_COST
			hb.tooltip_text = "It takes five pages at most." if pg >= D.HONE_MAX else "Spare learning from any book can hone any book at rank X."
			var hbk := b
			hb.pressed.connect(func(): m.cmd({"t": "act", "a": "hone", "arg": hbk}); skills.call_deferred(true))
			right.add_child(hb)
	# spare learning, sold for coin
	w.head("Spare learning")
	var sp := floori(p.spare)
	var srow := HBoxContainer.new()
	srow.add_theme_constant_override("separation", 14)
	w.body.add_child(srow)
	var st := Look.para(srow, ("%d spare point%s, worth %s." % [sp, "" if sp == 1 else "s", D.coins(sp * D.SPARE_PAY)]) if sp > 0 else "When a book reaches rank X, whatever more you learn from it is kept here as spare points, to be sold for %s each or honed into a book at rank X, ten to a page." % D.coins(D.SPARE_PAY), 15, Look.INK_SOFT)
	st.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sell := Button.new()
	sell.text = "Sell for coin"
	sell.disabled = sp <= 0
	sell.focus_mode = Control.FOCUS_NONE
	sell.pressed.connect(func(): m.sell_spare())
	srow.add_child(sell)
	# the action bar: put it in order, take things off it (the first nine have the number keys)
	w.head("Your action bar")
	w.para("Everything you can do is a button on the bar along the bottom; the first nine are also on the number keys. Move them up or down, or take them off the bar altogether.", 14, Look.INK_SOFT)
	var on: Array = m.bar_slots()
	var all_: Array = on + m.bar_all().filter(func(x): return not on.has(x))
	for i in all_.size():
		var id: String = all_[i]
		var info: Array = m.bar_info(id)
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 8)
		w.body.add_child(r)
		var shown := on.has(id)
		var n := on.find(id)
		var lab := Look.label(r, ("%s  %s" % [str(n + 1) if n >= 0 and n < 9 else "·", info[1]]) if shown else "      %s (off the bar)" % info[1], 15, Look.INK if shown else Look.INK_SOFT)
		lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for spec in [["▲", -1], ["▼", 1]]:
			var mv := Button.new()
			mv.text = spec[0]
			mv.focus_mode = Control.FOCUS_NONE
			mv.disabled = not shown or (spec[1] < 0 and n == 0) or (spec[1] > 0 and n == on.size() - 1)
			var step: int = spec[1]
			mv.pressed.connect(func():
				var o: Array = m.bar_slots()
				var j := o.find(id)
				if j < 0 or j + step < 0 or j + step >= o.size(): return
				o[j] = o[j + step]; o[j + step] = id
				Settings.bar_order = o; Settings.save(); skills(true))
			r.add_child(mv)
		var tg := Button.new()
		tg.text = "Take off" if shown else "Put back"
		tg.focus_mode = Control.FOCUS_NONE
		tg.pressed.connect(func():
			if Settings.bar_off.has(id): Settings.bar_off.erase(id)
			else: Settings.bar_off.append(id)
			Settings.save(); skills(true))
		r.add_child(tg)
	w.hint("{skills} or Esc: close.")


func _slot(parent: Control, id: int, label: String, num: String, tip: String, blessed: bool, cb: Callable, drop: Callable, locked: bool = false, destroy: Callable = Callable(), armed: bool = false) -> void:
	var box := Control.new()
	box.custom_minimum_size = Vector2(_slot_w, 96 if _slot_w <= 88 else 112)
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
		var isz := 28 if D.IT[id].n.length() > 26 else 40               # a long name: a smaller picture, to leave it room
		ic.texture = Look.icon(id, isz)
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.custom_minimum_size = Vector2(isz, isz)
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if locked: ic.modulate = Color(1, 1, 1, 0.4)
		v.add_child(ic)
		var nmt: String = D.IT[id].n
		if _slot_strip != "" and nmt.begins_with(_slot_strip): nmt = nmt.substr(_slot_strip.length())
		if nmt.length() > 24 and nmt.begins_with("the "): nmt = nmt.substr(4)       # long relic names: room for the rest (version 7.20)
		var nm := Look.label(v, nmt + (" ✝" if blessed else ""), 9 if nmt.length() > 26 else 10 if nmt.length() > 18 else 11, Look.INK if not locked else Color(Look.INK, 0.5))
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nm.add_theme_constant_override("line_spacing", -3)
		nm.custom_minimum_size.x = _slot_w - 8
	if label != "":
		var ll := Look.label(v, label, 10 if _slot_w > 88 else 11, Look.INK_SOFT)
		ll.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if _slot_w > 88:
			ll.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			ll.custom_minimum_size.x = _slot_w - 8
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
