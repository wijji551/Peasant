// ===== core: constants, helpers, input =====
const TAU = Math.PI * 2;
const clamp = (v, a, b) => v < a ? a : v > b ? b : v;
const lerp = (a, b, t) => a + (b - a) * t;
const dist2 = (ax, az, bx, bz) => { const dx = ax - bx, dz = az - bz; return dx * dx + dz * dz; };
const $ = id => document.getElementById(id);
function mulberry32(a) { return function () { a |= 0; a = a + 0x6D2B79F5 | 0; let t = Math.imul(a ^ a >>> 15, 1 | a); t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t; return ((t ^ t >>> 14) >>> 0) / 4294967296; }; }
function angLerp(a, b, t) { const d = ((b - a + Math.PI) % TAU + TAU) % TAU - Math.PI; return a + d * t; }

// --- the map (x east, z south; north is -z)
const VW = 28, VN = -22, VS = 26, GATE_Z = 2;      // village half-width, north wall z, south wall z, side-gate z
const KEEP = { x: 0, z: 0, h: 3.3 };
const HILL = { x: 0, z: -116 };
const SPAWN = { x: 0, z: -69, w: 32 };             // the dead rise anywhere along the graveyard, 32 either side of the road
const BOUNDS = { x0: -92, x1: 92, z0: -62, z1: 53 };
const SLOTX = [-18, -12, -6, 0, 6, 12, 18];         // north wall foundations; the middle one is the gate

// --- rules (starting values, to tune in play)
const DAY_LEN = 360, DUSK_LEN = 20, LAST_DAY = 7;
const NIGHT_BASE = 28, NIGHT_PER_PLAYER = 1, NIGHT_GROWTH = 1.24, ALIVE_CAP = 220, NIGHT_RISE = 80, NIGHT_RISE_DAY = 10;   // NIGHT_RISE: seconds the dead keep rising on night 1, and how much longer each night after   // the horde alone on night 1, what each extra player adds, how it grows each night, and the most that walk at once
const CARRY = 20, POSSE_MAX = 3, POSSE_SOLO = 5, POP_PER_PLAYER = 6, MAX_BODIES = 3, PACK_MAX = 6;
const PLAYER_HP = 100, PEASANT_HP = 75, KEEP_HP = 1000, INN_HP = 160;
const PLAYER_SPEED = 7, PEASANT_WORK_TIME = 4, TREE_WOOD = 6;
const RES = ['wood', 'stone', 'iron', 'food'];
const GATHER = {                                   // what holding E gathers, and how long one piece takes
  tree: { res: 'wood', time: 1.5, verb: 'chop', book: 0 }, stone: { res: 'stone', time: 1.9, verb: 'quarry stone', book: 0 }, iron: { res: 'iron', time: 2.3, verb: 'mine iron', book: 0 },
  food: { res: 'food', time: 1.6, verb: 'forage', book: 1 }, fish: { res: 'food', time: 0, verb: 'fish', book: 1 }
};
const GK = ['', 'tree', 'stone', 'iron', 'food', 'fish', 'search'];
const COST = { barricade: { wood: 5 }, spikes: { wood: 8 }, wall: { wood: 15 }, gate: { wood: 20 }, bodywall: { bodies: 3 }, decoy: { bodies: 1 } };
const REINF = {                                    // reinforcing a built defence
  wall: { cost: { stone: 10 }, mul: 3, name: 'face it with stone' }, gate: { cost: { iron: 8 }, mul: 2, name: 'band it with iron' },
  barricade: { cost: { iron: 3 }, mul: 2, name: 'brace it with iron' }, spikes: { cost: { iron: 4 }, mul: 1, name: 'tip them with iron', smith: 2 }
};
const SHP = { barricade: 90, spikes: 40, wall: 260, gate: 220, bodywall: 110, decoy: 70 };
const SDIM = { barricade: { hw: 1.7, hd: 0.45 }, spikes: { hw: 1.7, hd: 0.8 }, wall: { hw: 3, hd: 0.45 }, gate: { hw: 3, hd: 0.45 }, bodywall: { hw: 1.7, hd: 0.5 }, decoy: { hw: 0.45, hd: 0.45 } };
const SNAME = { barricade: 'barricade', spikes: 'spike row', wall: 'palisade wall', gate: 'gate', bodywall: 'body wall', decoy: 'decoy' };
const SKINDS = ['wall', 'gate', 'barricade', 'spikes', 'bodywall', 'decoy'];
const BUILDS = ['barricade', 'spikes', 'bodywall', 'decoy'];

// --- everything a peasant can hold or wear. s: w weapon, h head, b body, o off hand, t carried.
// arc is the smallest cosine of the angle a swing reaches: 0.5 is a third of a circle, 0 is half. rng marks a ranged weapon and how far it carries.
const IT = [
  { n: 'pitchfork', s: 'w', tier: 'found', dmg: 12, cd: 0.42, reach: 2.3, arc: 0.5, ab: 'pin', pool: 'fork', note: 'Long and light' },
  { n: 'short sword', s: 'w', tier: 'forged', dmg: 18, cd: 0.36, reach: 1.9, arc: 0.5, ab: 'parry', pool: 'sword', swing: 1, cost: { iron: 6, wood: 2 }, note: 'Quick and balanced' },
  { n: 'spear', s: 'w', tier: 'forged', dmg: 20, cd: 0.5, reach: 2.9, arc: 0.85, ab: 'brace', pool: 'spear', cost: { iron: 4, wood: 4 }, note: 'The longest reach, a narrow jab' },
  { n: 'mace', s: 'w', tier: 'forged', dmg: 22, cd: 0.6, reach: 1.9, arc: 0.5, blunt: true, ab: 'shatter', pool: 'mace', swing: 1, cost: { iron: 8, wood: 2 }, note: 'Skeletons it breaks stay broken' },
  { n: 'billhook', s: 'w', tier: 'forged', dmg: 20, cd: 0.6, reach: 2.8, arc: 0, heavy: true, ab: 'hook', pool: 'bill', swing: 1, cost: { iron: 8, wood: 4 }, note: 'Heavy. Long reach and a wide sweep' },
  { n: 'warhammer', s: 'w', tier: 'forged', dmg: 45, cd: 1.0, reach: 2.0, arc: 0.5, blunt: true, heavy: true, ab: 'smash', pool: 'hammer', swing: 1, cost: { iron: 12, wood: 4 }, note: 'Heavy. Slow and devastating' },
  { n: 'club', s: 'w', tier: 'found', dmg: 24, cd: 0.75, reach: 1.8, arc: 0.5, blunt: true, ab: 'wallop', pool: 'club', swing: 1, note: 'Slow, heavy single hits' },
  { n: 'spade', s: 'w', tier: 'found', dmg: 19, cd: 0.7, reach: 2.0, arc: 0.4, kb: 0.8, ab: 'bury', pool: 'spade', swing: 1, note: 'A slow swing with a knock-back' },
  { n: 'rake', s: 'w', tier: 'found', dmg: 11, cd: 0.4, reach: 2.6, arc: 0.3, ab: 'trip', pool: 'rake', swing: 1, note: 'Long and light' },
  { n: 'scythe', s: 'w', tier: 'found', dmg: 17, cd: 0.8, reach: 2.5, arc: -0.2, ab: 'reap', pool: 'scythe', swing: 1, note: 'A wide sweep, slow to recover' },
  { n: 'kitchen dagger', s: 'w', tier: 'found', dmg: 8, cd: 0.24, reach: 1.4, arc: 0.5, ab: 'backstab', pool: 'dagger', note: 'Very fast, very short' },
  { n: 'frying pan', s: 'w', tier: 'found', dmg: 8, cd: 0.34, reach: 1.6, arc: 0.5, blunt: true, ab: 'clang', pool: 'pan', swing: 1, note: 'Weak and quick' },
  { n: 'sling', s: 'w', tier: 'found', dmg: 9, cd: 0.8, rng: 12, ab: 'aimed', pool: 'sling', shot: 0, note: 'A weak ranged attack, and no shortage of stones' },
  { n: 'bow', s: 'w', tier: 'forged', dmg: 16, cd: 0.9, rng: 16, ab: 'volley', pool: 'bow', shot: 1, need: [5, 1], cost: { iron: 2, wood: 8 }, note: 'Solid ranged damage, over the wall' },
  { n: 'crossbow', s: 'w', tier: 'forged', dmg: 34, cd: 1.8, rng: 18, heavy: true, ab: 'pierce', pool: 'xbow', shot: 1, need: [5, 3], cost: { iron: 10, wood: 8 }, note: 'Heavy. Slow to load, hits very hard' },
  { n: 'the Slightly Blessed Spade', s: 'w', tier: 'relic', dmg: 26, cd: 0.6, reach: 2.1, arc: 0.4, kb: 1.6, holy: true, ab: 'bury', pool: 'spade', swing: 1, tint: [1.25, 1.1, 0.6], note: 'Holy, with a heavy knock-back' },
  { n: 'Saint Wilbur’s Pitchfork', s: 'w', tier: 'relic', dmg: 20, cd: 0.4, reach: 2.7, arc: 0.5, holy: true, line: true, ab: 'pin', pool: 'fork', tint: [1.25, 1.1, 0.6], note: 'Holy. Its Pin goes through a whole line' },
  { n: 'the Silvered Sword', s: 'w', tier: 'relic', dmg: 28, cd: 0.34, reach: 2.0, arc: 0.5, holy: true, ab: 'parry', pool: 'sword', swing: 1, tint: [1.2, 1.25, 1.35], note: 'Holy, quick and sharp' },
  { n: 'cooking pot', s: 'h', tier: 'found', cut: 0.08, pool: 'helm', tint: [0.42, 0.4, 0.42] },
  { n: 'iron cap', s: 'h', tier: 'forged', cut: 0.15, pool: 'helm', tint: [0.8, 0.83, 0.88], cost: { iron: 5 } },
  { n: 'the Helm of the Unbothered', s: 'h', tier: 'relic', cut: 0.2, pool: 'helm', tint: [1.25, 1.05, 0.5], note: 'Your posse never loses its nerve' },
  { n: 'padded jerkin', s: 'b', tier: 'found', cut: 0.15, pool: 'mail', tint: [0.74, 0.55, 0.36] },
  { n: 'chain shirt', s: 'b', tier: 'forged', cut: 0.3, slow: 0.06, pool: 'mail', tint: [0.68, 0.71, 0.76], cost: { iron: 10 } },
  { n: 'the Vicar’s Breastplate', s: 'b', tier: 'relic', cut: 0.4, pool: 'mail', tint: [1.2, 1.05, 0.55], note: 'Burns any undead that strikes you' },
  { n: 'barrel lid', s: 'o', tier: 'found', cut: 0.08, arrow: 0.3, pool: 'shield', tint: [0.8, 0.66, 0.46] },
  { n: 'iron-rimmed shield', s: 'o', tier: 'forged', cut: 0.15, arrow: 0.5, pool: 'shield', tint: [1, 1, 1], cost: { iron: 4, wood: 4 } },
  { n: 'the Chapel Handbell', s: 't', tier: 'relic', pool: 'bucket', tint: [1.3, 1.0, 0.35], note: 'G rings it: every undead nearby is stunned. A long wait between rings' },
  { n: 'the Smoking Censer', s: 't', tier: 'relic', pool: 'bucket', tint: [0.9, 0.9, 1.1], note: 'Undead near you are slowed' },
  { n: 'slop bucket', s: 't', tier: 'found', pool: 'bucket', tint: [0.6, 0.48, 0.3], note: 'G lobs it, once: every undead it splashes runs from the smell' }
];
const SLOTK = { w: 'wpn', h: 'head', b: 'body', o: 'off', t: 'trk' }, SLOTS = ['wpn', 'head', 'body', 'off', 'trk'];
const RELICS = [15, 16, 17, 20, 23, 26, 27], FOUND_W = [6, 7, 8, 9, 10, 11, 12], FOUND_A = [18, 21, 24], FORGE_W = [1, 2, 3, 4, 5, 13, 14], FORGE_A = [19, 22, 25];
const itA = id => { const I = IT[id]; return I.tier === 'relic' ? I.n : (/^[aeiou]/.test(I.n) ? 'an ' : 'a ') + I.n; };
const itCap = id => { const n = IT[id].n; return n.charAt(0).toUpperCase() + n.slice(1); };
// each weapon's own trick, on Shift. cd is the wait between uses, in seconds.
const AB = {
  pin: { n: 'Pin', cd: 8, d: 'holds one enemy in place for a few seconds' }, parry: { n: 'Parry', cd: 7, d: 'turns aside the next blow and staggers whoever swung it' },
  brace: { n: 'Brace', cd: 7, d: 'a thrust through everything in a line, stopping it dead' }, shatter: { n: 'Shatter', cd: 9, d: 'cracks them open: everyone’s blows hurt them more for a while' },
  hook: { n: 'Hook', cd: 8, d: 'drags the farthest enemy in reach out of the crowd, off its feet' }, smash: { n: 'Smash', cd: 11, d: 'a ground blow that flattens everything near it' },
  wallop: { n: 'Wallop', cd: 6, d: 'a wound-up blow that stuns and sends one enemy flying' }, bury: { n: 'Bury', cd: 7, d: 'puts a wounded enemy, or a heap of bones, back in the ground for good' },
  trip: { n: 'Trip', cd: 8, d: 'sweeps a group off their feet' }, reap: { n: 'Reap', cd: 8, d: 'one swing all the way round' },
  backstab: { n: 'Backstab', cd: 4, d: 'triple damage on an enemy that is busy with someone else' }, clang: { n: 'Clang', cd: 10, d: 'the noise draws the undead to you, and the pan stops arrows for a while' },
  aimed: { n: 'Aimed stone', cd: 6, d: 'a careful shot that hits three times as hard and staggers' }, volley: { n: 'Volley', cd: 9, d: 'three arrows at once' }, pierce: { n: 'Pierce', cd: 10, d: 'a bolt that passes through everything in its way' }
};
const PEASANT_ARM = { iron: 3, wood: 2 }, SLUM_FOOD = 5, FISH_FOOD = 3, BLESS_FEE = 24, HOLY_TIME = 45, TANKARD = 25, DRINK_TIME = 3, SEARCHES = 2, SEARCH_TIME = 3.5, TOILET_CD = 60;
// --- the ten books. Seven ranks each; a rank is earned by doing what the book teaches.
const XPM = [1, 3, 7, 13, 21, 32];                 // how much doing each further rank takes, as a multiple of the book's first step
const BOOKS = [
  { name: 'The Woodcutter’s Almanac', what: 'Resource gathering', base: 60, by: 'chopping, quarrying and mining', ranks: ['Gather wood, stone and iron faster (and faster again with every rank)', 'Carry 30 of each material', 'Your posse works faster', 'Your posse keeps gathering while you do something else nearby', 'Carry 40 of each material', 'One piece in five comes with a second', 'Carry 50 of each material'] },
  { name: 'Field, Hook and Pot', what: 'Food', base: 40, by: 'fishing and foraging', ranks: ['Fish and forage faster (and faster again with every rank)', 'Meals heal 35', 'A catch is 4 fish', 'One meal feeds your whole posse', 'Meals heal 50', 'Slum recruits cost 3 food', 'Meals heal 65 and steady your posse’s nerve'] },
  { name: 'Barricades for Beginners', what: 'Defence making', base: 8, by: 'building and repairing', ranks: ['Building costs a fifth less (and a little less with every rank)', 'Repairs are quicker and cost half', 'Your barricades and body walls are a quarter stronger', 'Your barricades do not rot at dusk', 'Your spike rows last twice as long', 'Your barricades and body walls are half as strong again', 'Contraptions (they arrive in a later build)'] },
  { name: 'Hammer and Tongs', what: 'Blacksmithing', base: 3, by: 'forging', ranks: ['Forging takes a third less iron (and a little less with every rank)', 'Forge heavy arms and iron tips for spikes', 'Arm your whole posse at once', 'Forged weapons hit a tenth harder in your hands', 'Your armour takes a further 5% off every blow', 'Your posse’s spears hit harder', 'Reinforcing a defence costs half'] },
  { name: 'The Art of Hitting Things', what: 'Combat training', base: 60, by: 'landing blows', ranks: ['Hit harder up close (and harder again with every rank)', 'One blow in eight misses you', 'Your weapon’s trick is ready a fifth sooner', 'Your swings reach wider', 'Your weapon’s trick is ready a third sooner', '20 more health', 'Every fifth blow lands twice as hard'] },
  { name: 'Slings, Bows and Thrown Turnips', what: 'Ranged combat', base: 40, by: 'landing shots', ranks: ['You can use a bow, and a sling comes with the book (shots hit harder with every rank)', 'You never miss', 'You can use a crossbow', 'You shoot a fifth faster', 'Emergency toilet breaks come round a third sooner', 'Every shot also strikes a second enemy', 'Aimed stones, volleys and piercing bolts are ready in half the time'] },
  { name: 'How to Win Peasants and Lead Them', what: 'Peasant leadership', base: 50, by: 'recruiting, and your posse’s blows', ranks: ['Your posse keeps its nerve better (and better again with every rank)', 'A posse one larger', 'Orders: Q tells your posse to follow, hold or charge', 'A posse two larger', 'Your posse hits a quarter harder', 'A posse three larger', 'Your posse never runs away'] },
  { name: 'The Landlord’s Ledger', what: 'Dutch courage', base: 4, by: 'drinking at the Thorny Rose', ranks: ['Every tankard goes further (and further again with every rank)', 'A longer charge: 26 seconds', 'Half the hangover', 'No hangover', 'When you drink, everyone in the inn gets a mouthful', 'A longer charge: 32 seconds', 'The charge hits twice as hard'] },
  { name: 'Relics and Where They Were Left', what: 'Relic lore', base: 4, by: 'searching the ruins', ranks: ['Search faster (and faster again with every rank)', 'Your map marks the rubble that still hides something', 'Relics turn up half as often again', 'You find twice the materials and coins', 'Holy things hit harder in your hands', 'Relics turn up far more often', 'Nothing lurking in the ruins notices you'] },
  { name: 'Granny’s Remedies', what: 'Healing', base: 4, by: 'bandaging and reviving', ranks: ['Bandage a hurt ally: hold E beside them (it heals more with every rank)', 'Revive twice as fast, and to better health', 'Each of your posse survives one fatal blow a night', 'You mend slowly all the time, even in a fight', 'You last twice as long when down', 'A bandage heals completely', 'Once a night you get back up by yourself'] }
];
const UN = [
  { name: 'shambler', hp: 46, spd: 1.5, dmg: 8, sdmg: 7, kdmg: 3, cd: 1.3, r: 0.5 },
  { name: 'skeleton', hp: 16, spd: 2.9, dmg: 5, sdmg: 3, kdmg: 2, cd: 0.9, r: 0.4 },
  { name: 'skeleton archer', hp: 14, spd: 2.4, dmg: 6, sdmg: 2, kdmg: 2, cd: 2.4, r: 0.4, rng: 11 },
  { name: 'the Steward', hp: 520, spd: 1.3, dmg: 10, sdmg: 8, kdmg: 5, cd: 1.2, r: 0.75 }
];
const RELS = ['{n}’s twin', '{n}’s cousin', '{n}’s second cousin', '{n}’s cousin’s lodger', '{n}’s great-aunt’s godchild', 'someone who once met {n} at a fair', 'a creditor of {n}’s', 'a passer-by mistaken for {n}'];
const relName = (n, k) => k <= 0 ? n : k <= RELS.length ? RELS[k - 1].replace('{n}', n) : `a stranger claiming to be ${n} (no. ${k - RELS.length + 1})`;
// money: 12 bronze pence to the silver shilling, 20 shillings to the gold piece
function coins(d) { d = Math.max(0, Math.round(d)); const g = d / 240 | 0, s = (d % 240) / 12 | 0, p = d % 12; return (g ? g + ' gold ' : '') + (g || s ? s + 's ' : '') + p + 'd'; }
const costText = c => Object.keys(c).map(k => c[k] + ' ' + (k === 'bodies' ? (c[k] === 1 ? 'body' : 'bodies') : k)).join(' and ');
// places where pressing E opens a notice of things to do
const STATIONS = [
  { id: 'market', x: 0, z: 19.7, r: 3.4, name: 'the market', verb: 'trade at the market' },
  { id: 'smithy', x: 12.4, z: -4.7, r: 3.2, name: 'the smithy', verb: 'use the smithy' },
  { id: 'store', x: 12.9, z: 10.6, r: 3, name: 'the storehouse', verb: 'open the storehouse' },
  { id: 'library', x: 13.4, z: 20.4, r: 3, name: 'the library', verb: 'read in the library' },
  { id: 'slum', x: -17.6, z: 17.4, r: 3.4, name: 'the slum', verb: 'recruit in the slum' },
  { id: 'inn', x: -13.1, z: -4.7, r: 2.5, name: 'the Thorny Rose', verb: 'call at the Thorny Rose' },
  { id: 'priest', x: 13.6, z: -10.6, r: 2.3, name: 'the priest', verb: 'speak to the priest' }
];
const INN = { x: -17.5, z: -4.7, dx: -13.6, dz: -4.7 };   // inside, and the door
const FARM = { x0: -70, x1: -46.5, z0: 20.4, z1: 41.6 };
// --- the stone, the iron and the fish are somewhere new every morning
const SITES = [
  [{ x: 60, z: -8, n: 'east of the village' }, { x: 44, z: -38, n: 'in the north-east field' }, { x: 72, z: 26, n: 'far to the east' }, { x: -40, z: -54, n: 'north of the forest' }, { x: 38, z: 40, n: 'south-east, towards the river' }],
  [{ x: 58, z: 24, n: 'east, beyond the gate' }, { x: 78, z: -30, n: 'far to the north-east' }, { x: -78, z: -55, n: 'at the top of the forest' }, { x: -34, z: 46, n: 'south-west, by the river' }, { x: 82, z: 46, n: 'in the far south-east corner' }],
  [{ x: 12, z: 53.4, n: 'south of the village' }, { x: -28, z: 53.4, n: 'on the west reach' }, { x: 34, z: 53.4, n: 'on the east reach' }, { x: -80, z: 53.4, n: 'far downstream, to the west' }, { x: 76, z: 53.4, n: 'far upstream, to the east' }]
];
const QUARRY = { x: 60, z: -8, hw: 2.3, hd: 1.9, rot: 0 }, MINEC = { x: 58, z: 24, hw: 2.2, hd: 2.2, rot: 0 }, MINE = { x: 55, z: 24, dir: 1 }, JETTY = { x: 12, z: 53.4 };
function setSites(a) {
  const q = SITES[0][a[0]] || SITES[0][0], m = SITES[1][a[1]] || SITES[1][0], j = SITES[2][a[2]] || SITES[2][0];
  QUARRY.x = q.x; QUARRY.z = q.z; MINEC.x = m.x; MINEC.z = m.z; MINE.dir = m.x >= 0 ? 1 : -1; MINE.x = m.x - MINE.dir * 3; MINE.z = m.z; JETTY.x = j.x; JETTY.z = j.z;
}
// --- the ruins. The old ruins by the chapel never change; the two outer ruins fall down differently every night.
const RUINS = [{ x: 11, z: -13.4, name: 'the old ruins' }, { x: -58, z: 47.6, name: 'the west ruins' }, { x: 58, z: 47.6, name: 'the east ruins' }];
let ruinKey = '', ruinNow = null;
function ruinLayout(seed, day) {                  // the same on every computer, from the game's seed and the day
  const key = seed + ':' + day; if (key === ruinKey) return ruinNow;
  const rub = [], pil = [], spots = [{ x: 9.8, z: -14.3, ruin: 0 }, { x: 12.3, z: -16.6, ruin: 0 }];
  for (const side of [1, 2]) {
    const R = RUINS[side], rnd = mulberry32((seed | 0) * 31 + day * 977 + side * 131), rr = (a, b) => a + (b - a) * rnd();
    const n = 8 + (rnd() * 5 | 0);
    for (let i = 0; i < n; i++) { const tall = rnd() < 0.25; rub.push({ x: R.x + rr(-7, 7), z: R.z + rr(-4.4, 4.4), w: rr(1.2, 3.6), h: tall ? rr(2.6, 4.2) : rr(0.5, 2.2), d: rr(0.5, 0.8), rot: (rnd() * 4 | 0) * Math.PI / 4 + rr(-0.15, 0.15), c: i % 2 }); }
    for (let i = 0; i < 2 + (rnd() * 3 | 0); i++) pil.push({ x: R.x + rr(-6, 6), z: R.z + rr(-4, 4), h: rr(1.4, 3.6) });
    for (let i = 0; i < 3; i++) { let x, z, ok = false; for (let t = 0; t < 12 && !ok; t++) { x = R.x + rr(-6.5, 6.5); z = R.z + rr(-3.9, 3.9); ok = spots.every(s => dist2(s.x, s.z, x, z) > 9); } spots.push({ x, z, ruin: side }); }
  }
  ruinKey = key; ruinNow = { rub, pil, spots }; return ruinNow;
}

const PCOL = ['#c8443a', '#3f77c4', '#e0a526', '#4f9d57', '#8e55b5', '#e07a2f', '#3aa6a0', '#d46a9a'];
const PCOLN = ['Red', 'Blue', 'Gold', 'Green', 'Purple', 'Orange', 'Teal', 'Rose'];
const hex3 = h => { const n = parseInt(h.slice(1), 16); return [(n >> 16 & 255) / 255, (n >> 8 & 255) / 255, (n & 255) / 255]; };
const PCOL3 = PCOL.map(hex3);
const PNAMES = ['Aldith', 'Wat', 'Hob', 'Maud', 'Gib', 'Cecily', 'Dunstan', 'Agnes', 'Odo', 'Mabel', 'Tibb', 'Edith', 'Hugh the Lesser', 'Joan', 'Perkin', 'Alys', 'Godwin', 'Rohese', 'Ham', 'Isolde', 'Bartholomew', 'Emmot', 'Diggory', 'Sibyl', 'Old Ned', 'Young Ned', 'Marjory', 'Pip', 'Gunnora', 'Wilkin', 'Bet', 'Lambert', 'Tilda', 'Jankin', 'Avice', 'Sim', 'Parnell', 'Colin', 'Hawise', 'Noll'];

// each player's cottage: two rows of four, south of the keep
function cottage(i) {
  const col = i % 4, row = i >> 2;
  const x = -7.5 + col * 5, z = row ? 15.2 : 9, dir = row ? 1 : -1;
  return { x, z, dir, sx: x, sz: z + dir * 3.1 };
}

// --- input. Every action has its keys, and the handbook (Esc) lets the player change them.
const keys = {};
const ACTIONS = [['up', 'Move north'], ['left', 'Move west'], ['down', 'Move south'], ['right', 'Move east'], ['attack', 'Attack, and land a fish'], ['trick', 'Your weapon’s trick'],
  ['interact', 'Gather, build, search, rally, use a place (hold)'], ['eat', 'Eat'], ['pack', 'Open your pack'], ['carry', 'Use what you carry: bucket or handbell'],
  ['swap', 'Swap to the next weapon in your pack'], ['orders', 'Posse orders: follow, hold, charge'], ['toilet', 'Emergency toilet break'], ['build', 'Next thing to place'], ['ready', 'Ready for the night'], ['mute', 'Sound on or off']];
const BIND_DEF = { up: ['KeyW', 'ArrowUp'], left: ['KeyA', 'ArrowLeft'], down: ['KeyS', 'ArrowDown'], right: ['KeyD', 'ArrowRight'], attack: ['Space'], trick: ['ShiftLeft', 'ShiftRight'], interact: ['KeyE'], eat: ['KeyF'], pack: ['KeyI'], carry: ['KeyG'], swap: ['KeyX'], orders: ['KeyQ'], toilet: ['KeyT'], build: ['Tab'], ready: ['KeyR'], mute: ['KeyM'] };
const store = { get(k, d) { try { const v = JSON.parse(localStorage.getItem(k) || 'null'); return v == null ? d : v; } catch (e) { return d; } }, set(k, v) { try { localStorage.setItem(k, JSON.stringify(v)); } catch (e) { } } };
const BIND = {}; { const sv = store.get('dtv-keys', {}); for (const a in BIND_DEF) BIND[a] = Array.isArray(sv[a]) ? sv[a].filter(c => typeof c === 'string') : BIND_DEF[a].slice(); }
const OPT = Object.assign({ vol: 70, tags: true, seeKeep: true }, store.get('dtv-opt', {}));
const held = a => BIND[a].some(c => keys[c]);
const actOf = code => { for (const a in BIND) if (BIND[a].includes(code)) return a; return ''; };
const KEYN = { Space: 'Space', ShiftLeft: 'Shift', ShiftRight: 'Right Shift', ControlLeft: 'Ctrl', ControlRight: 'Right Ctrl', AltLeft: 'Alt', AltRight: 'Right Alt', ArrowUp: 'Up arrow', ArrowDown: 'Down arrow', ArrowLeft: 'Left arrow', ArrowRight: 'Right arrow', Backquote: '`', Minus: '-', Equal: '=', BracketLeft: '[', BracketRight: ']', Semicolon: ';', Quote: '’', Comma: ',', Period: '.', Slash: '/', Backslash: '\\', CapsLock: 'Caps Lock', Backspace: 'Backspace', Enter: 'Enter' };
const keyName = c => KEYN[c] || c.replace(/^Key|^Digit/, '').replace(/^Numpad/, 'Num ');
const kn = a => BIND[a].length ? keyName(BIND[a][0]) : 'no key';
const kAll = a => BIND[a].length ? BIND[a].map(keyName).join(' or ') : 'no key set';
function setBind(a, code) { for (const k in BIND) BIND[k] = BIND[k].filter(c => c !== code); BIND[a] = [code]; store.set('dtv-keys', BIND); }   // a key does one thing: whatever had it loses it
function resetBinds() { for (const a in BIND_DEF) BIND[a] = BIND_DEF[a].slice(); store.set('dtv-keys', BIND); }
let typing = false, rebind = null;                // rebind: a function waiting to be told the next key pressed
addEventListener('keydown', e => {
  if (rebind) { e.preventDefault(); const f = rebind; rebind = null; f(e.code); return; }
  const t = e.target; typing = t && ((t.tagName === 'INPUT' && t.type === 'text') || t.tagName === 'TEXTAREA');
  if (typing || e.ctrlKey || e.metaKey) return;
  if (actOf(e.code) || ['Tab', 'Space', 'ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight'].includes(e.code)) e.preventDefault();
  if (!keys[e.code]) { keys[e.code] = true; if (typeof onKeyDown === 'function') onKeyDown(e.code); }
});
addEventListener('keyup', e => { keys[e.code] = false; });
addEventListener('blur', () => { for (const k in keys) keys[k] = false; });
