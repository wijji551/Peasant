// ===== the map of Thornhallow, built from simple shapes =====
const P = {
  grass: 0x9dbf68, grass2: 0x90b45e, grass3: 0xa8c872, vill: 0xb9c67d, path: 0xdcc78e, path2: 0xcfb97f,
  cream: 0xf0e3c3, cream2: 0xe4d2a8, roof: 0xb0573c, roof2: 0x934834, roof3: 0xc0703f, thatch: 0xcdb46a,
  timber: 0x5b4130, wood: 0x8b6b47, wood2: 0x7d5f3f, wood3: 0x98784f, stone: 0xc3bcab, stone2: 0xa69f90, stone3: 0x8a8478,
  slate: 0x67768b, water: 0x6fb4c8, water2: 0x8fcbd8, sand: 0xe3d6a4, field1: 0xd0b256, field2: 0x9c7d47, field3: 0xb9c66b,
  castle: 0x7d778c, castle2: 0x686279, croof: 0x4d3b69, skin: 0xe8b98f, straw: 0xdcbc62, iron: 0x70757f, red: 0xb23a31,
  leaf: 0x5d9349, leaf2: 0x6aa04e, trunk: 0x6b4a2f, grave: 0x8f8c95, dead: 0x8c9a70, dead2: 0x7f8d68, hedge: 0x3f6b3a, hedge2: 0x39603a, hedge3: 0x47753f
};
const colliders = [];
const addCol = (x, z, hw, hd) => colliders.push({ x, z, hw, hd, rot: 0 });
const trees = [];
let B, G, W;

function logs(b, x0, z0, x1, z1) {              // a run of sharpened palisade logs
  const len = Math.hypot(x1 - x0, z1 - z0), n = Math.max(1, Math.round(len / 0.78));
  for (let i = 0; i < n; i++) {
    const f = (i + 0.5) / n, x = lerp(x0, x1, f), z = lerp(z0, z1, f), h = 2.55 + ((i * 7) % 5) * 0.08, c = [P.wood, P.wood2, P.wood3][i % 3];
    b.cyl(0.36, 0.4, h, 5, x, 0, z, c, i * 1.3); b.cone(0.38, 0.6, 5, x, h, z, c, i * 1.3);
  }
}
function house(x, z, ry, w, d, h, wallC, roofC, o) {
  o = o || {}; at(x, z, ry); const f = 0.4, dx = o.dx || 0;
  B.box(w + 0.4, f, d + 0.4, 0, 0, 0, P.stone2);
  B.box(w, h, d, 0, f, 0, wallC);
  if (!o.plain) {
    for (const sx of [-1, 1]) for (const sz of [-1, 1]) B.box(0.28, h, 0.28, sx * (w / 2 - 0.08), f, sz * (d / 2 - 0.08), P.timber, 0, 0, 0, false);
    B.box(w + 0.12, 0.22, d + 0.12, 0, f + h - 0.22, 0, P.timber, 0, 0, 0, false);
  }
  const rh = o.rh || Math.min(w, d) * 0.5;
  if (w >= d) B.roof(d + 1.1, rh, w + 1.1, 0, f + h, 0, roofC, Math.PI / 2); else B.roof(w + 1.1, rh, d + 1.1, 0, f + h, 0, roofC, 0);
  if (!o.nodoor) B.box(1.05, 1.75, 0.16, dx, f, d / 2 + 0.02, o.doorC || P.timber);
  const wy = f + h * 0.5;
  if (w > 3.2) for (const sx of [-1, 1]) if (Math.abs(sx * w * 0.3 - dx) > 0.95) { B.box(0.82, 0.82, 0.1, sx * w * 0.3, wy - 0.1, d / 2 + 0.01, P.timber, 0, 0, 0, false); W.box(0.6, 0.6, 0.1, sx * w * 0.3, wy + 0.01, d / 2 + 0.04, 0xffffff); }
  for (const sx of [-1, 1]) { B.box(0.1, 0.82, 0.82, sx * (w / 2 + 0.01), wy - 0.1, 0, P.timber, 0, 0, 0, false); W.box(0.1, 0.6, 0.6, sx * (w / 2 + 0.04), wy + 0.01, 0, 0xffffff); }
  if (o.chim) B.box(0.7, rh + 1, 0.7, w * 0.28, f + h, -d * 0.12, P.stone2);
  const sw = Math.abs(Math.sin(ry)) > 0.5; addCol(x, z, (sw ? d : w) / 2 + 0.25, (sw ? w : d) / 2 + 0.25);
  at();
}
function treeOk(x, z) {
  if (x > -VW - 4 && x < VW + 4 && z > VN - 6 && z < VS + 4) return false;      // the village
  if (Math.abs(x) < 34 && z < VN) return false;                                 // the north field and the graveyard, where the dead come down
  if (Math.abs(z - GATE_Z) < 4.5 && Math.abs(x) < 50) return false;             // the gate paths
  if (Math.hypot(x - HILL.x, z - HILL.z) < 47) return false;                    // castle hill
  if (x > -74 && x < -42 && z > 17 && z < 44) return false;                     // farms
  if (Math.abs(Math.abs(x) - 58) < 10 && z > 37 && z < 54) return false;        // outer ruins
  if (Math.abs(x) > 90.5 && Math.abs(x) < 98) return false;                     // the thorn hedge
  if (Math.abs(z + 62.8) < 1.6 && Math.abs(x) < 93) return false;               // the line of stakes
  for (const k of [0, 1]) for (const c of SITES[k]) if (Math.hypot(x - c.x, z - c.z) < 6.5) return false;   // every place the stone or the iron can turn up
  for (const c of SITES[2]) if (Math.abs(x - c.x) < 3.5 && z > 46) return false;                              // and the paths to the jetties
  if (z > 53.5) return false;                                                   // river
  return true;
}

function buildWorld() {
  B = new Builder(0.07); G = new Builder(0, false); W = new Builder(0, false);
  const rnd = mulberry32(1337), rr = (a, b) => a + (b - a) * rnd();
  at();
  // --- ground
  G.box(900, 1, 900, 0, -1, 0, P.grass);
  for (let i = 0; i < 300; i++) { const s = rr(2.5, 7.5); G.box(s, 0.01 + i * 0.0001, s * rr(0.6, 1.5), rr(-140, 140), 0, rr(-150, 95), i % 2 ? P.grass2 : P.grass3, rr(0, 3)); }
  G.box(2 * VW, 0.045, VS - VN, 0, 0, (VS + VN) / 2, P.vill);
  G.box(420, 0.05, 104, 0, 0, -115.2, P.dead);                     // dead ground: everything beyond the stakes belongs to the castle
  for (let i = 0; i < 70; i++) { const s = rr(3, 8); G.box(s, 0.055, s * rr(0.6, 1.4), rr(-130, 130), 0, rr(-150, -67), P.dead2, rr(0, 3)); }
  G.box(6.5, 0.07, 56, 0, 0, -50, P.path);                         // castle road
  G.box(6.5, 0.07, VS - VN, 0, 0, (VS + VN) / 2, P.path);          // avenue through the village
  G.box(92, 0.07, 5, 0, 0, GATE_Z, P.path);                        // west gate to east gate
  G.box(15, 0.08, 12.6, 0, 0, 0, P.path2);                           // the square round the keep
  for (let i = 0; i < 70; i++) { const onRoad = i % 2; G.box(rr(0.4, 0.9), 0.085, rr(0.4, 0.9), onRoad ? rr(-2.8, 2.8) : rr(-44, 44), 0, onRoad ? rr(-76, 24) : GATE_Z + rr(-2, 2), P.path2, rr(0, 3)); }
  // river, south
  G.box(300, 0.03, 4, 0, 0, 56.5, P.sand); G.box(300, 0.05, 14, 0, 0, 65, P.water); G.box(300, 0.06, 2.5, 0, 0, 62, P.water2); G.box(300, 0.06, 1.5, 0, 0, 68, P.water2);

  // --- castle hill and Ashhollow Castle
  B.cyl(30, 42, 7, 14, HILL.x, 0, HILL.z, 0x87a65d);
  G.add(() => gBox(6.5, 0.3, 14.4), 0, 3.42, -80.2, P.path2, 0, 0.53, 0);
  G.box(6.5, 0.1, 22, 0, 7, -97.5, P.path2);
  at(HILL.x, HILL.z, 0);
  B.box(21, 8, 13, 0, 7, 0, P.castle); B.box(22, 1, 14, 0, 15, 0, P.castle2);
  for (let i = -4; i <= 4; i++) B.box(1.3, 1, 0.8, i * 2.4, 16, 6.6, P.castle2);
  for (const sx of [-1, 1]) for (const sz of [-1, 1]) { B.cyl(3, 3.3, 13, 7, sx * 10.5, 7, sz * 6.5, P.castle2); B.cone(3.9, 5.5, 7, sx * 10.5, 20, sz * 6.5, P.croof); }
  B.box(7, 16, 7, 0, 7, -1, P.castle); B.cone(5.6, 7.5, 4, 0, 23, -1, P.croof, Math.PI / 4);
  B.box(3.8, 4.8, 0.4, 0, 7, 6.5, 0x231c2d);
  W.box(1.2, 1.9, 0.2, 0, 18.4, 2.56, 0xffffff);                   // the one lit window
  at();
  // the graveyard, strung out along the foot of the hill: the dead rise anywhere along it
  for (let i = 0; i < 40; i++) {
    const sd = i % 2 ? 1 : -1, x = sd * rr(4.5, 35), z = rr(-73, -64.2), ry = rr(-0.3, 0.3);
    B.box(0.75, rr(0.8, 1.2), 0.24, x, 0, z, P.grave, ry, 0, rr(-0.12, 0.12));
    if (i % 3 === 0) { B.box(0.16, 1.5, 0.16, x + 1.6, 0, z + 0.8, P.grave, ry); B.box(0.7, 0.16, 0.16, x + 1.6, 1, z + 0.8, P.grave, ry); }
    if (i % 5 === 0) G.box(1.1, 0.07, 2.1, x, 0, z + 1.4, 0x6f6a5c, ry);
  }
  for (const [x, z] of [[-11, -67], [12.5, -71], [-27, -70], [29, -66.5], [-33, -65]]) { B.cyl(0.18, 0.34, 2.6, 5, x, 0, z, 0x4a3b33); B.box(0.14, 1.3, 0.14, x + 0.4, 1.9, z, 0x4a3b33, 0, 0, -0.8); B.box(0.12, 1.1, 0.12, x - 0.35, 2.1, z, 0x4a3b33, 0, 0, 0.7); }
  // --- the edge of where a peasant may go. North: a line of warning stakes. West and east: the thorn hedge the village is named for. South: the river.
  for (let x = -90; x <= 90; x += 4.5) {
    if (Math.abs(x) < 4) continue;
    const lean = rr(-0.16, 0.16); B.cyl(0.09, 0.13, 2, 5, x, 0, -62.8, 0x4a3b33, rr(0, 3), 0, lean); B.box(0.34, 0.3, 0.32, x + lean * -1.9, 1.95, -62.8, 0xe9e4cf, rr(-0.5, 0.5));
    if ((x / 4.5 | 0) % 2 === 0) B.box(4.3, 0.07, 0.07, x + 2.25, 1.15, -62.8, 0x5d4a3a, 0, 0, rr(-0.04, 0.04), false);
  }
  for (const sx of [-1, 1]) { at(sx * 5.2, -62.2, sx * 0.25); B.box(0.16, 1.7, 0.16, 0, 0, 0, P.timber); B.box(1.7, 0.9, 0.1, 0, 1.0, 0.1, P.wood3); B.box(1.2, 0.12, 0.12, 0, 1.55, 0.16, P.red, 0, 0, 0, false); B.box(1.2, 0.12, 0.12, 0, 1.25, 0.16, P.red, 0, 0, 0, false); at(); }
  for (const sx of [-1, 1]) for (let z = -64; z <= 55; z += 2.9) {
    const h = rr(1.7, 2.7), w = rr(2.6, 3.6), x = sx * (94.3 + rr(-0.3, 0.3));
    B.box(w, h, 3.3, x, 0, z, [P.hedge, P.hedge2, P.hedge3][(Math.abs(z) | 0) % 3], rr(-0.12, 0.12));
    B.cone(0.55, 1.1, 4, x - sx * rr(0.2, 1.1), h - 0.2, z + rr(-1, 1), P.hedge2, rr(0, 3)); B.cone(0.4, 0.9, 4, x - sx * 1.5, h * 0.45, z + rr(-1.2, 1.2), 0x2f5233, rr(0, 3), 0, sx * 1.1);
  }

  // --- the village wall (permanent stretches). The north side between the corners is seven foundations.
  const wall = (x0, z0, x1, z1) => { logs(B, x0, z0, x1, z1); addCol((x0 + x1) / 2, (z0 + z1) / 2, Math.abs(x1 - x0) / 2 + 0.42, Math.abs(z1 - z0) / 2 + 0.42); };
  wall(-VW, VN, -21, VN); wall(21, VN, VW, VN);
  wall(-VW, VN, -VW, GATE_Z - 3); wall(-VW, GATE_Z + 3, -VW, VS);
  wall(VW, VN, VW, GATE_Z - 3); wall(VW, GATE_Z + 3, VW, VS);
  wall(-VW, VS, VW, VS);
  for (const s of [-1, 1]) {                                        // west and east gateways, open in week 1
    at(s * VW, GATE_Z, Math.PI / 2);
    for (const e of [-1, 1]) { B.box(0.8, 3.8, 1, e * 3, 0, 0, P.timber); W.box(0.26, 0.36, 0.26, e * 3, 2.5, -s * 0.66, 0xffffff); }
    B.box(7, 0.55, 1.1, 0, 3.8, 0, P.timber); B.roof(1.9, 0.8, 7.4, 0, 4.35, 0, P.roof2, Math.PI / 2);
    at();
  }
  for (const s of [-1, 1]) { B.cyl(0.3, 0.42, 1.5, 6, s * 4.4, 0, -24.6, P.stone3); B.cyl(0.55, 0.34, 0.4, 6, s * 4.4, 1.5, -24.6, P.iron); W.box(0.5, 0.5, 0.5, s * 4.4, 1.85, -24.6, 0xffffff); }

  // --- the keep: small, square and the only stone building the village finished
  at(0, 0, 0); const KB = new Builder(0.07), B0 = B; B = KB;                // its own mesh: it turns see-through when something is behind it
  B.box(6.6, 0.8, 6.6, 0, 0, 0, P.stone3); B.box(5.6, 7, 5.6, 0, 0.8, 0, P.stone);
  for (const sx of [-1, 1]) for (const sz of [-1, 1]) B.box(1.2, 8, 1.2, sx * 2.6, 0.8, sz * 2.6, P.stone2);
  B.box(6.3, 0.6, 6.3, 0, 7.8, 0, P.stone2);
  for (let i = -1; i <= 1; i++) for (const s of [-1, 1]) { B.box(0.8, 0.6, 0.5, i * 1.5, 8.4, s * 2.9, P.stone2); B.box(0.5, 0.6, 0.8, s * 2.9, 8.4, i * 1.5, P.stone2); }
  B.cone(3.3, 3, 4, 0, 8.4, 0, P.slate, Math.PI / 4);
  B.box(0.14, 2.6, 0.14, 0, 11.2, 0, P.timber); B.box(1.3, 0.8, 0.07, 0.7, 12.9, 0, P.red);
  B.box(1.7, 2.5, 0.2, 0, 0.8, -2.85, P.timber); B.box(2.2, 0.32, 0.3, 0, 3.3, -2.85, P.stone3);
  for (const s of [-1, 1]) { W.box(0.45, 1, 0.1, s * 1.4, 4.4, -2.83, 0xffffff); W.box(0.45, 1, 0.1, s * 1.4, 4.4, 2.83, 0xffffff); W.box(0.1, 1, 0.45, -2.83, 4.4, s * 1.4, 0xffffff); W.box(0.1, 1, 0.45, 2.83, 4.4, s * 1.4, 0xffffff); }
  W.box(0.3, 0.4, 0.3, 1.25, 2.6, -3.1, 0xffffff);
  B = B0; at(); addCol(0, 0, KEEP.h, KEEP.h);

  // --- Robert Bailiff's house: bolted, boarded, one lit window upstairs
  house(-14.5, -12.6, 0, 9, 6.4, 4.8, P.cream, P.roof2, { chim: true, rh: 3.3 });
  at(-14.5, -12.6, 0);
  B.box(1.5, 0.18, 0.1, 0, 1.05, 3.32, P.wood3, 0, 0, 0.5); B.box(1.5, 0.18, 0.1, 0, 1.05, 3.32, P.wood3, 0, 0, -0.5);
  W.box(0.7, 0.7, 0.1, 0, 3.9, 3.25, 0xffffff); B.box(0.92, 0.92, 0.1, 0, 3.79, 3.21, P.timber, 0, 0, 0, false);
  at();
  // --- the old ruins and the priest's chapel
  house(17, -14, 0, 4.4, 6.2, 3.4, P.stone, P.slate, { plain: true, rh: 2.8 });
  B.box(1, 1.5, 1, 17, 6.2, -12, P.stone2); B.cone(0.9, 1.2, 4, 17, 7.7, -12, P.slate, Math.PI / 4); B.box(0.14, 1, 0.14, 17, 8.8, -12, P.stone3); B.box(0.6, 0.14, 0.14, 17, 9.3, -12, P.stone3);
  for (let i = 0; i < 9; i++) { const x = rr(8.3, 13.2), z = rr(-18.2, -12.4); B.box(rr(1, 2.6), rr(0.5, 2.3), 0.5, x, 0, z, i % 2 ? P.stone2 : P.stone3, rr(0, 3)); }
  for (const [x, z] of [[9.2, -16], [8.4, -11.6]]) B.cyl(0.36, 0.42, rr(1.4, 2.6), 6, x, 0, z, P.stone2);
  // --- the Thorny Rose Inn
  house(-17.5, -4.7, Math.PI / 2, 8, 6, 4.2, P.cream, P.roof, { chim: true, rh: 3 });
  B.box(0.18, 3, 0.18, -13.4, 0, -1.4, P.timber); B.box(1.5, 0.14, 0.14, -12.8, 2.86, -1.4, P.timber); B.box(1, 0.8, 0.1, -12.6, 1.95, -1.4, P.cream2); B.box(0.42, 0.42, 0.14, -12.6, 2.14, -1.4, P.red);
  for (const [x, z] of [[-13.6, -7.2], [-13.2, -6.3]]) B.cyl(0.42, 0.42, 0.9, 7, x, 0, z, P.wood2);
  // --- the smithy
  house(17.5, -4.7, -Math.PI / 2, 6.5, 5.6, 3.2, P.stone, P.slate, { plain: true, chim: true, rh: 2.4 });
  for (const zz of [-6.8, -2.6]) B.box(0.24, 2.4, 0.24, 13.2, 0, zz, P.timber);
  B.box(2.2, 0.16, 5.2, 13.7, 2.5, -4.7, P.roof2, 0, 0, 0.22);
  B.box(0.9, 0.5, 0.45, 13, 0, -5.6, P.iron); B.box(1.2, 0.8, 1.2, 13.4, 0, -3.5, P.stone3); W.box(0.8, 0.14, 0.8, 13.4, 0.8, -3.5, 0xffffff);
  // --- training yard
  for (let i = 0; i <= 8; i++) { const fx = -22 + i * 1.25; B.box(0.2, 1, 0.2, fx, 0, 7.4, P.wood2); B.box(0.2, 1, 0.2, fx, 0, 14, P.wood2); }
  B.box(10, 0.12, 0.1, -17, 0.75, 7.4, P.wood3, 0, 0, 0, false); B.box(10, 0.12, 0.1, -17, 0.75, 14, P.wood3, 0, 0, 0, false);
  G.box(10, 0.06, 6.6, -17, 0, 10.7, P.path2);
  for (const x of [-20, -17, -14]) { B.box(0.18, 1.7, 0.18, x, 0, 10.8, P.timber); B.box(1.1, 0.16, 0.16, x, 1.15, 10.8, P.timber); B.box(0.5, 0.7, 0.4, x, 0.75, 10.8, P.straw); B.ico(0.3, x, 1.9, 10.8, P.straw); }
  // --- storehouse
  house(17.5, 10.6, -Math.PI / 2, 7, 5.6, 3.6, P.cream2, P.thatch, { rh: 2.8 });
  for (const [x, z, h] of [[13.3, 8.2, 0.9], [13.1, 9.2, 0.9], [13.6, 13, 1]]) B.cyl(0.45, 0.45, h, 7, x, 0, z, P.wood2);
  B.box(1, 0.8, 1, 13.4, 0, 12, P.wood3, 0.3); B.box(0.8, 0.7, 0.8, 13.5, 0.8, 12.1, P.wood, 0.7);
  // --- the slum
  house(-21.5, 19.2, 0.12, 3, 2.8, 1.7, P.cream2, P.thatch, { plain: true, rh: 1.5 });
  house(-17.6, 21.6, -0.2, 3.3, 2.7, 1.6, 0xd6c193, P.wood2, { plain: true, rh: 1.3 });
  house(-13.8, 19.4, 0.25, 2.8, 2.8, 1.8, P.cream2, P.thatch, { plain: true, rh: 1.6 });
  // --- the market
  for (const [x, c] of [[-5, P.red], [0, 0x3f77c4], [5, 0xe0a526]]) {
    at(x, 21.6, 0);
    for (const sx of [-1, 1]) for (const sz of [-1, 1]) B.box(0.16, 2.1, 0.16, sx * 1.3, 0, sz * 0.9, P.timber);
    for (let i = 0; i < 5; i++) B.box(0.6, 0.12, 2.3, -1.2 + i * 0.6, 2.1 + (i % 2) * 0.01, 0, i % 2 ? P.cream : c, 0, 0, 0, false);
    B.box(2.6, 0.14, 1.2, 0, 0.85, 0, P.wood3); B.box(0.5, 0.35, 0.5, -0.6, 0.99, 0, P.straw); B.box(0.5, 0.3, 0.5, 0.5, 0.99, 0.1, P.roof3);
    at(); addCol(x, 21.6, 1.4, 0.8);
  }
  // --- the library
  house(17.5, 20.4, -Math.PI / 2, 6.6, 6, 4.6, P.stone, P.roof2, { rh: 3.4 });
  // --- bell and notice board in the square
  at(5.5, -9.5, 0); for (const s of [-1, 1]) B.box(0.22, 2.6, 0.22, s * 0.8, 0, 0, P.timber); B.box(2.1, 0.22, 0.26, 0, 2.6, 0, P.timber); B.cyl(0.2, 0.42, 0.6, 7, 0, 1.85, 0, 0xc9962f); at();
  at(-5.5, -9.5, 0); for (const s of [-1, 1]) B.box(0.18, 1.9, 0.18, s * 0.9, 0, 0, P.timber); B.box(2, 1.2, 0.12, 0, 0.75, 0, P.wood3); B.box(0.6, 0.8, 0.14, -0.4, 0.95, 0, P.cream); B.box(0.5, 0.5, 0.14, 0.45, 1.2, 0, P.cream2); at();
  // --- cottages, one per player
  for (let i = 0; i < 8; i++) { const c = cottage(i); house(c.x, c.z, c.dir > 0 ? 0 : Math.PI, 3.7, 3.3, 2.0, i % 2 ? P.cream : P.cream2, [P.roof, P.thatch, P.roof3, P.roof2][i % 4], { rh: 1.9, chim: i % 3 === 0 }); }

  // --- outside the wall: the farms. The stone, the iron, the jetty and the outer ruins are drawn each frame, because they move.
  for (let i = 0; i < 6; i++) G.box(24, 0.05, 3, -58, 0, 22 + i * 3.6, [P.field1, P.field2, P.field3][i % 3]);
  for (let i = 0; i <= 13; i++) { B.box(0.2, 0.9, 0.2, -70.5 + i * 2, 0, 19.6, P.wood2); B.box(0.2, 0.9, 0.2, -70.5 + i * 2, 0, 42.8, P.wood2); }
  house(-47, 24, Math.PI / 2, 5, 7, 3.6, 0xa9493b, P.roof2, { plain: true, rh: 2.6 });
  for (const [x, z] of [[-48, 33], [-46.5, 36], [-49, 38.5]]) { B.cyl(1.1, 1.3, 1.3, 7, x, 0, z, P.straw); B.cone(1.3, 1.1, 7, x, 1.3, z, P.straw); }
  colliders.push(QUARRY, MINEC);                                   // the outcrop and the mine move about; their models are drawn each frame

  addMesh(G, { cast: false });
  addMesh(B);
  GFX.keep = addMesh(KB);
  addMesh(W, { mode: 'glow' });

  // --- trees: Hallowshire Forest to the west, and a scatter elsewhere
  const place = (x0, x1, z0, z1, tries, gap) => {
    for (let i = 0; i < tries; i++) {
      const x = rr(x0, x1), z = rr(z0, z1); if (!treeOk(x, z)) continue;
      let ok = true; for (const t of trees) if (dist2(x, z, t.x, t.z) < gap * gap) { ok = false; break; }
      if (!ok) continue;
      // where its sapling will come up, a stride or two from the stump
      let a = rr(0, TAU), dx = Math.cos(a) * 1.4, dz = Math.sin(a) * 1.4; if (!treeOk(x + dx, z + dz)) { dx = -dx; dz = -dz; if (!treeOk(x + dx, z + dz)) dx = dz = 0; }
      trees.push({ i: trees.length, x, z, ox: x, oz: z, dx, dz, st: 0, par: 0, gd: 0, s: rr(0.85, 1.35), rot: rr(0, TAU), kind: rnd() < 0.72 ? 0 : 1, tint: [rr(0.88, 1.08), rr(0.92, 1.1), rr(0.82, 1.02)], wood: TREE_WOOD, alive: true, shake: 0 });
    }
  };
  place(-90, -34, -48, 17, 420, 2.5);
  place(-125, 125, -95, 53, 520, 3.4);
}
// a tree is standing (0), a stump (1) or a sapling (2). Each time it regrows it swaps between its own spot and the spot beside it.
function setTreeState(t, st, par) { t.st = st; t.par = par; t.alive = st === 0; t.x = t.ox + (par ? t.dx : 0); t.z = t.oz + (par ? t.dz : 0); if (st === 0 && !(t.wood > 0)) t.wood = TREE_WOOD; }
const treeCodes = () => { const a = []; for (const t of trees) if (t.st || t.par) a.push(t.i * 6 + t.st * 2 + t.par); return a; };
function applyTreeCodes(a) { const m = new Map(); for (const c of a) m.set(c / 6 | 0, c % 6); for (const t of trees) { const c = m.get(t.i) || 0; if (t.st !== (c >> 1) || t.par !== (c & 1)) setTreeState(t, c >> 1, c & 1); } }
