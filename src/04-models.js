// ===== characters, defences and other things drawn many times =====
const PL = {};
function initPools() {
  at();
  let b;
  // --- peasant (also used, slightly larger, for players). Tunic and banner are white here and tinted per copy.
  b = new Builder(0.045);
  b.box(0.2, 0.46, 0.22, -0.14, 0, 0, 0x4a3a2c).box(0.2, 0.46, 0.22, 0.14, 0, 0, 0x4a3a2c);
  b.box(0.42, 0.4, 0.4, 0, 1.03, 0.02, P.skin).box(0.1, 0.1, 0.06, 0, 1.15, 0.24, 0xd9a279, 0, 0, 0, false);
  b.cyl(0.34, 0.34, 0.07, 7, 0, 1.42, 0, P.straw).cyl(0.17, 0.2, 0.2, 7, 0, 1.56, 0, P.straw);
  PL.body = addPool(b, 96);
  b = new Builder(0.045);
  b.box(0.66, 0.6, 0.42, 0, 0.44, 0, 0xffffff).box(0.17, 0.5, 0.2, -0.42, 0.52, 0, 0xffffff).box(0.17, 0.5, 0.2, 0.42, 0.52, 0, 0xffffff);
  b.box(0.64, 0.09, 0.42, 0, 0.5, 0, 0x9a8a78, 0, 0, 0, false).cyl(0.23, 0.25, 0.1, 7, 0, 1.48, 0, 0xffffff, 0, 0, 0, false);
  PL.tunic = addPool(b, 96);
  b = new Builder(0.04);
  b.box(0.07, 1.75, 0.07, 0, -0.55, 0, P.wood).box(0.36, 0.06, 0.06, 0, 1.2, 0, P.iron);
  for (const x of [-0.15, 0, 0.15]) b.box(0.05, 0.32, 0.05, x, 1.22, 0, P.iron);
  PL.fork = addPool(b, 96);
  b = new Builder(0.04);
  b.box(0.07, 1.05, 0.07, 0, -0.25, 0, P.wood).box(0.1, 0.26, 0.34, 0, 0.5, 0.16, P.iron);
  PL.axe = addPool(b, 96);
  b = new Builder(0.04);
  b.box(0.06, 2.3, 0.06, -0.3, 0.55, -0.27, 0xffffff, 0, 0, 0, false).box(0.86, 0.56, 0.06, 0.14, 2.28, -0.27, 0xffffff).box(0.3, 0.2, 0.06, 0.72, 2.28, -0.27, 0xffffff, 0, 0, 0, false);
  PL.banner = addPool(b, 24);                    // a tall flag in the player's colour: this, not the name, is how you tell who is who
  // forged arms. Held like the pitchfork: the hand is at the origin and the business end points up.
  b = new Builder(0.035); b.box(0.07, 0.26, 0.07, 0, -0.08, 0, P.wood).box(0.32, 0.06, 0.09, 0, 0.18, 0, P.iron).box(0.1, 0.95, 0.035, 0, 0.24, 0, 0xcfd4dc);
  PL.sword = addPool(b, 16);
  b = new Builder(0.035); b.box(0.06, 2.2, 0.06, 0, -0.65, 0, P.wood).cyl(0, 0.1, 0.42, 4, 0, 1.55, 0, 0xcfd4dc);
  PL.spear = addPool(b, 96);
  b = new Builder(0.035); b.box(0.07, 0.95, 0.07, 0, -0.15, 0, P.wood).ico(0.2, 0, 0.9, 0, P.iron).box(0.46, 0.07, 0.07, 0, 0.865, 0, 0x8f949e, 0, 0, 0, false).box(0.07, 0.07, 0.46, 0, 0.865, 0, 0x8f949e, 0, 0, 0, false);
  PL.mace = addPool(b, 16);
  b = new Builder(0.035); b.box(0.06, 2.0, 0.06, 0, -0.6, 0, P.wood).box(0.05, 0.55, 0.3, 0, 1.0, 0.16, 0xcfd4dc).box(0.05, 0.14, 0.3, 0, 1.5, 0.3, 0xcfd4dc);
  PL.bill = addPool(b, 16);
  b = new Builder(0.035); b.box(0.08, 1.3, 0.08, 0, -0.3, 0, P.wood).box(0.3, 0.28, 0.56, 0, 0.92, 0, P.iron);
  PL.hammer = addPool(b, 16);
  // armour is modelled pale and tinted per item: a cooking pot, an iron cap and a relic helm are the same shape
  b = new Builder(0.035); b.cyl(0.25, 0.28, 0.26, 7, 0, 1.43, 0, 0xffffff).box(0.07, 0.22, 0.06, 0, 1.22, 0.24, 0xffffff, 0, 0, 0, false);
  PL.helm = addPool(b, 24);
  b = new Builder(0.035); b.box(0.71, 0.46, 0.47, 0, 0.52, 0, 0xffffff).box(0.19, 0.2, 0.22, -0.42, 0.82, 0, 0xffffff, 0, 0, 0, false).box(0.19, 0.2, 0.22, 0.42, 0.82, 0, 0xffffff, 0, 0, 0, false);
  PL.mail = addPool(b, 24);
  b = new Builder(0.035); b.box(0.09, 0.66, 0.54, -0.56, 0.36, 0.12, P.wood3).box(0.11, 0.7, 0.07, -0.56, 0.34, 0.12, P.iron, 0, 0, 0, false).box(0.14, 0.16, 0.16, -0.58, 0.61, 0.12, P.iron, 0, 0, 0, false);
  PL.shield = addPool(b, 24);
  // found arms: what a village has lying about
  b = new Builder(0.035); b.box(0.09, 0.5, 0.09, 0, -0.1, 0, P.wood).cyl(0.17, 0.11, 0.72, 6, 0, 0.35, 0, P.wood2);
  PL.club = addPool(b, 24);
  b = new Builder(0.035); b.box(0.07, 1.5, 0.07, 0, -0.45, 0, P.wood).box(0.34, 0.44, 0.05, 0, 1.05, 0, 0xb9bec8);
  PL.spade = addPool(b, 24);
  b = new Builder(0.035); b.box(0.06, 2, 0.06, 0, -0.6, 0, P.wood).box(0.62, 0.07, 0.07, 0, 1.4, 0, P.wood2); for (let i = -2; i <= 2; i++) b.box(0.04, 0.04, 0.22, i * 0.14, 1.41, 0.12, P.iron, 0, 0, 0, false);
  PL.rake = addPool(b, 24);
  b = new Builder(0.035); b.box(0.07, 2, 0.07, 0, -0.6, 0, P.wood).box(0.05, 0.13, 0.95, 0, 1.3, 0.45, 0xcfd4dc, 0, -0.25, 0);
  PL.scythe = addPool(b, 24);
  b = new Builder(0.03); b.box(0.06, 0.2, 0.06, 0, -0.06, 0, P.wood).box(0.07, 0.44, 0.03, 0, 0.14, 0, 0xcfd4dc);
  PL.dagger = addPool(b, 24);
  b = new Builder(0.035); b.box(0.06, 0.5, 0.06, 0, -0.1, 0, P.iron).box(0.56, 0.56, 0.07, 0, 0.4, 0, 0x34343b);
  PL.pan = addPool(b, 24);
  b = new Builder(0.03); b.box(0.05, 0.5, 0.05, 0, 0, 0, 0x6b4a2f).box(0.05, 0.3, 0.05, 0, 0.5, 0.1, 0x6b4a2f, 0, 0.7, 0).ico(0.11, 0, 0.72, 0.26, P.stone2);
  PL.sling = addPool(b, 24);
  b = new Builder(0.03); b.box(0.06, 0.8, 0.06, 0, -0.1, 0.16, P.wood2).box(0.06, 0.5, 0.06, 0, 0.66, 0.16, P.wood2, 0, -0.5, 0).box(0.06, 0.5, 0.06, 0, -0.56, -0.08, P.wood2, 0, 0.5, 0).box(0.02, 1.56, 0.02, 0, -0.5, -0.1, 0xe9e4cf, 0, 0, 0, false);
  PL.bow = addPool(b, 24);
  b = new Builder(0.03); b.box(0.09, 0.1, 0.85, 0, 0.2, 0.3, P.wood2).box(0.85, 0.06, 0.07, 0, 0.23, 0.68, P.iron).box(0.03, 0.03, 0.5, 0, 0.3, 0.4, 0xcfd4dc, 0, 0, 0, false);
  PL.xbow = addPool(b, 24);
  b = new Builder(0.03); b.cyl(0.2, 0.16, 0.3, 7, -0.48, 0.44, -0.16, 0xffffff).box(0.03, 0.16, 0.34, -0.48, 0.72, -0.16, 0xdddddd, 0, 0, 0, false);
  PL.bucket = addPool(b, 24);

  // --- the undead
  b = new Builder(0.045);
  b.box(0.24, 0.5, 0.26, -0.17, 0, 0, 0x3d4138).box(0.24, 0.5, 0.26, 0.17, 0, 0, 0x3d4138);
  b.box(0.72, 0.74, 0.46, 0, 0.48, 0.04, 0x5e6455, 0, 0.22, 0);
  b.box(0.46, 0.42, 0.44, 0.04, 1.14, 0.22, 0x8bab86, 0, 0.15, 0.12);
  b.box(0.16, 0.16, 0.72, -0.43, 0.92, 0.44, 0x8bab86, 0, -0.12, 0).box(0.16, 0.16, 0.72, 0.43, 0.86, 0.44, 0x8bab86, 0, 0.1, 0);
  b.box(0.09, 0.07, 0.05, -0.07, 1.3, 0.47, 0xe4ffb0, 0, 0, 0, false).box(0.09, 0.07, 0.05, 0.15, 1.33, 0.46, 0xe4ffb0, 0, 0, 0, false);
  PL.shamb = addPool(b, 320, { emi: true });
  b = new Builder(0.04);
  b.box(0.1, 0.56, 0.1, -0.13, 0, 0, 0xe9e4cf).box(0.1, 0.56, 0.1, 0.13, 0, 0, 0xe9e4cf);
  b.box(0.34, 0.12, 0.2, 0, 0.55, 0, 0xddd7bf).box(0.08, 0.3, 0.08, 0, 0.6, 0, 0xddd7bf, 0, 0, 0, false).box(0.44, 0.3, 0.24, 0, 0.8, 0, 0xe9e4cf);
  b.box(0.36, 0.34, 0.34, 0, 1.16, 0.02, 0xf1edda).box(0.26, 0.08, 0.26, 0, 1.1, 0.05, 0xddd7bf, 0, 0, 0, false);
  b.box(0.09, 0.09, 0.04, -0.09, 1.31, 0.19, 0x2b2433, 0, 0, 0, false).box(0.09, 0.09, 0.04, 0.09, 1.31, 0.19, 0x2b2433, 0, 0, 0, false);
  b.box(0.08, 0.5, 0.08, -0.3, 0.58, 0, 0xe9e4cf).box(0.08, 0.5, 0.08, 0.3, 0.58, 0.06, 0xe9e4cf, 0, -0.4, 0);
  b.box(0.06, 0.8, 0.04, 0.3, 0.5, 0.42, 0x8d8f96, 0, 1.1, 0);
  PL.skel = addPool(b, 200, { emi: true });
  b = new Builder(0.04);                         // skeleton archer: a hood, and a bow held out in front
  b.box(0.1, 0.56, 0.1, -0.13, 0, 0, 0xddd8c2).box(0.1, 0.56, 0.1, 0.13, 0, 0, 0xddd8c2);
  b.box(0.34, 0.12, 0.2, 0, 0.55, 0, 0xd1cbb3).box(0.44, 0.3, 0.24, 0, 0.8, 0, 0xddd8c2);
  b.box(0.36, 0.34, 0.34, 0, 1.16, 0.02, 0xece8d5).box(0.42, 0.2, 0.4, 0, 1.36, -0.02, 0x4a3f55);
  b.box(0.09, 0.09, 0.04, -0.09, 1.25, 0.19, 0x2b2433, 0, 0, 0, false).box(0.09, 0.09, 0.04, 0.09, 1.25, 0.19, 0x2b2433, 0, 0, 0, false);
  b.box(0.08, 0.08, 0.5, -0.3, 0.9, 0.24, 0xddd8c2).box(0.08, 0.08, 0.36, 0.3, 0.9, 0.12, 0xddd8c2);
  b.box(0.06, 0.5, 0.06, -0.3, 0.98, 0.5, 0x6b4a2f, 0, -0.35, 0).box(0.06, 0.5, 0.06, -0.3, 0.5, 0.5, 0x6b4a2f, 0, 0.35, 0);
  PL.archer = addPool(b, 120, { emi: true });
  b = new Builder(0.045);                        // the Steward: the Lord's butler, in a tailcoat, carrying a candle on a tray
  b.box(0.2, 0.7, 0.22, -0.14, 0, 0, 0x1d1a24).box(0.2, 0.7, 0.22, 0.14, 0, 0, 0x1d1a24);
  b.box(0.62, 0.8, 0.38, 0, 0.68, 0, 0x26222e).box(0.2, 0.62, 0.05, 0, 0.8, 0.2, 0xe9e6dc, 0, 0, 0, false).box(0.1, 0.1, 0.06, 0, 1.36, 0.21, 0x7d1f27, 0, 0, 0, false);
  b.box(0.5, 0.5, 0.1, 0, 0.3, -0.22, 0x26222e, 0, -0.25, 0);
  b.box(0.36, 0.42, 0.36, 0, 1.5, 0, 0xcfd6c8).box(0.38, 0.1, 0.38, 0, 1.9, -0.02, 0x15131a).box(0.07, 0.05, 0.03, -0.08, 1.72, 0.19, 0xe9ffb5, 0, 0, 0, false).box(0.07, 0.05, 0.03, 0.08, 1.72, 0.19, 0xe9ffb5, 0, 0, 0, false);
  b.box(0.15, 0.6, 0.17, -0.4, 0.82, 0, 0x26222e).box(0.15, 0.17, 0.5, 0.4, 1.1, 0.2, 0x26222e);
  b.cyl(0.26, 0.26, 0.04, 8, 0.4, 1.2, 0.5, 0xb9bcc4).box(0.07, 0.3, 0.07, 0.4, 1.24, 0.5, 0xf2ecd8).box(0.06, 0.1, 0.06, 0.4, 1.54, 0.5, 0xffd27a, 0, 0, 0, false);
  PL.steward = addPool(b, 4, { emi: true });

  // --- defences
  b = new Builder(0.06); logs(b, -3, 0, 3, 0); b.box(5.8, 0.2, 0.16, 0, 1.5, 0.44, P.timber, 0, 0, 0, false);
  PL.wall = addPool(b, 8);
  b = new Builder(0.05); b.box(5.7, 0.16, 1, 0, 0, 0, P.stone2); for (const s of [-1, 1]) b.box(0.34, 0.5, 0.34, s * 2.75, 0, 0, P.stone3);
  for (let i = 0; i < 4; i++) b.box(0.7, 0.05, 0.16, -1.8 + i * 1.2, 0.16, 0, P.wood3, 0, 0, 0, false);
  PL.found = addPool(b, 8, { cast: false });
  b = new Builder(0.05); b.box(5.7, 0.16, 1.3, 0, 0, 0, P.stone); for (const s of [-1, 1]) b.box(0.7, 0.8, 1, s * 2.65, 0, 0, P.stone3);
  PL.foundGate = addPool(b, 2, { cast: false });
  b = new Builder(0.06); for (const s of [-1, 1]) b.box(0.8, 3.8, 1, s * 2.7, 0, 0, P.timber); b.box(6.6, 0.55, 1.1, 0, 3.8, 0, P.timber); b.roof(1.9, 0.8, 7, 0, 4.35, 0, P.roof2, Math.PI / 2);
  PL.gateFrame = addPool(b, 2);
  b = new Builder(0.05); b.box(2.25, 3.35, 0.2, 1.125, 0.12, 0, P.wood2); for (const y of [0.8, 2.6]) b.box(2.25, 0.16, 0.26, 1.125, y, 0, P.iron, 0, 0, 0, false);
  PL.door = addPool(b, 4);
  b = new Builder(0.05); b.box(3.4, 0.22, 0.22, 0, 0.72, 0, P.wood).box(3.2, 0.3, 0.1, 0, 0.22, 0.3, P.wood3);
  for (const x of [-1.3, -0.43, 0.43, 1.3]) { b.box(0.2, 1.55, 0.2, x, 0, 0, P.wood2, 0, 0.62, 0); b.box(0.2, 1.55, 0.2, x + 0.22, 0, 0, P.wood3, 0, -0.62, 0); }
  PL.barricade = addPool(b, 64);
  b = new Builder(0.04); b.box(3.4, 0.08, 1.5, 0, 0, 0, 0x7d6c4b, 0, 0, 0, false);
  for (let i = 0; i < 9; i++) b.cyl(0, 0.12, 1.15, 4, -1.5 + i * 0.375, 0, i % 2 ? 0.3 : -0.3, i % 2 ? P.wood2 : P.wood3, 0, i % 2 ? 0.55 : -0.55, 0);
  PL.spikes = addPool(b, 64);
  b = new Builder(0.05);                         // stone facing for a wall, iron bands for a gate
  for (let i = 0; i < 5; i++) b.box(1.14, 1.25, 0.42, -2.36 + i * 1.18, 0, -0.58, i % 2 ? P.stone : P.stone2);
  for (let i = 0; i < 4; i++) b.box(1.14, 0.55, 0.38, -1.77 + i * 1.18, 1.25, -0.56, i % 2 ? P.stone2 : P.stone3);
  PL.wallRe = addPool(b, 8);
  b = new Builder(0.04); for (const sx of [-1, 1]) for (const y of [0.7, 2.0, 3.2]) b.box(0.9, 0.16, 1.1, sx * 2.7, y, 0, P.iron);
  b.box(6.7, 0.14, 1.16, 0, 4.0, 0, P.iron);
  PL.gateRe = addPool(b, 2);
  b = new Builder(0.05);                         // what a peasant community does with its fallen
  for (const [x, y, ry, c] of [[-0.75, 0, 0.1, 0x8f7f63], [0.8, 0, -0.12, 0x7f7460], [0, 0.42, 0.05, 0x9a8a6c]]) { b.box(1.45, 0.42, 0.56, x, y, 0, c, ry); b.box(0.36, 0.34, 0.36, x + 0.86, y + 0.04, 0.02, 0xc9b79a, ry); b.box(0.2, 0.2, 0.6, x - 0.8, y + 0.05, 0, 0x4a3a2c, ry); }
  for (const x of [-1.5, 0, 1.5]) b.box(0.12, 1.25, 0.12, x, 0, 0.36, P.wood2, 0, -0.25, 0);
  b.box(3.3, 0.12, 0.1, 0, 0.82, 0.5, P.wood3, 0, 0, 0, false);
  PL.bodywall = addPool(b, 24);
  b = new Builder(0.05); b.box(0.12, 2.0, 0.12, 0, 0, -0.22, P.wood2).box(1.3, 0.1, 0.1, 0, 1.25, -0.22, P.wood2);
  b.box(0.6, 0.62, 0.38, 0, 0.72, 0, 0x8f7f63, 0, 0.1, 0).box(0.2, 0.5, 0.22, -0.14, 0.2, 0.04, 0x4a3a2c).box(0.2, 0.5, 0.22, 0.14, 0.2, 0.04, 0x4a3a2c, 0, 0, 0.2);
  b.box(0.4, 0.38, 0.38, 0, 1.36, 0.06, 0xc9b79a, 0, 0.3, 0.2).cyl(0.36, 0.36, 0.07, 7, 0, 1.74, 0.02, P.straw, 0, 0.2, 0.2);
  b.box(0.16, 0.5, 0.16, -0.52, 0.86, -0.1, 0x8f7f63, 0, 0, 0.5).box(0.16, 0.5, 0.16, 0.52, 0.86, -0.1, 0x8f7f63, 0, 0, -0.5);
  PL.decoy = addPool(b, 24);
  // --- places that move: the rocky outcrop, the mine, the jetty, and the rubble of the outer ruins
  b = new Builder(0.06); b.box(6.4, 0.06, 5.4, 0, 0, 0, 0xcfc9bb, 0.2, 0, 0, false);
  for (const [x, z, w, h, d, ry, c] of [[-1.1, -0.5, 2.1, 2.4, 1.8, 0.3, P.stone], [0.9, 0.5, 1.9, 1.7, 1.6, 1.1, P.stone2], [0.3, -1.1, 1.5, 1.1, 1.3, 2.0, P.stone3], [-0.6, 1.1, 1.4, 0.9, 1.2, 0.7, P.stone2], [1.9, -0.7, 1.0, 0.7, 0.9, 2.6, P.stone], [-2.4, 0.9, 0.8, 0.5, 0.7, 1.5, P.stone3], [2.5, 1.4, 0.6, 0.4, 0.6, 0.4, P.stone2]]) b.box(w, h, d, x, 0, z, c, ry);
  PL.outcrop = addPool(b, 2);
  b = new Builder(0.06); b.cyl(1.9, 3.1, 2.3, 8, 0, 0, 0, 0x93a064).box(0.7, 1.9, 1.8, -2.75, 0, 0, 0x2a2420);
  for (const sz of [-1, 1]) b.box(0.3, 2.1, 0.3, -3.05, 0, sz * 1.02, P.timber); b.box(0.4, 0.3, 2.6, -3.05, 2.1, 0, P.timber);
  for (const [x, z, sz2] of [[-3.7, 1.9, 0.5], [-3.3, 2.3, 0.4], [-4.0, 2.4, 0.34]]) b.box(sz2, sz2 * 0.8, sz2, x, 0, z, 0x6d5a50, x);
  b.box(4.4, 0.05, 3.6, -3.9, 0, 0, 0xb9a988, 0, 0, 0, false);
  PL.mine = addPool(b, 2);
  b = new Builder(0.05); b.box(1.8, 0.2, 7, 0, 0.25, 4.1, P.wood); for (const sx of [-1, 1]) for (const zz of [1.6, 4.6, 7.1]) b.box(0.25, 1, 0.25, sx * 0.8, -0.2, zz, P.timber);
  b.box(0.16, 1.5, 0.16, 1.5, 0, 0.4, P.timber).box(0.8, 0.45, 0.08, 1.5, 1.05, 0.46, 0x8fcbd8).box(2.6, 0.05, 3.4, 0, 0, -1.2, P.path2, 0, 0, 0, false);
  PL.jetty = addPool(b, 2);
  b = new Builder(0.05); b.box(1, 1, 1, 0, 0, 0, 0xffffff);
  PL.rub = addPool(b, 40);
  b = new Builder(0.05); b.cyl(0.4, 0.48, 1, 6, 0, 0, 0, P.stone);
  PL.pillar = addPool(b, 12);
  b = new Builder(0.04); b.box(0.9, 0.3, 0.7, 0, 0, 0, 0xffffff, 0.3).box(0.6, 0.26, 0.5, 0.3, 0.3, 0.1, 0xe6e6e6, 1.1).box(0.4, 0.2, 0.4, -0.5, 0, 0.5, 0xdcdcdc, 0.8).box(1.5, 0.1, 0.16, 0, 0.36, -0.3, 0xa58560, 0.5, 0, 0.2);
  PL.spot = addPool(b, 12);
  b = new Builder(0, false); b.box(0.05, 0.05, 0.95, 0, 0, 0, 0x6b4a2f).box(0.1, 0.1, 0.16, 0, -0.025, 0.5, 0xcfd4dc).box(0.14, 0.02, 0.2, 0, 0.015, -0.42, 0xe9e4cf);
  PL.arrow = addPool(b, 80, { cast: false });
  // translucent previews for free-placed defences
  GH.barricade = addMesh((() => { const g = new Builder(0, false); g.box(3.4, 1.3, 0.9, 0, 0, 0, 0xffffff); return g; })(), { mode: 'ghost', alpha: 0.45, visible: false, mat: m4() });
  GH.spikes = addMesh((() => { const g = new Builder(0, false); g.box(3.4, 0.7, 1.6, 0, 0, 0, 0xffffff); return g; })(), { mode: 'ghost', alpha: 0.45, visible: false, mat: m4() });
  GH.bodywall = addMesh((() => { const g = new Builder(0, false); g.box(3.4, 1.0, 1.0, 0, 0, 0, 0xffffff); return g; })(), { mode: 'ghost', alpha: 0.45, visible: false, mat: m4() });
  GH.decoy = addMesh((() => { const g = new Builder(0, false); g.box(0.9, 1.9, 0.9, 0, 0, 0, 0xffffff); return g; })(), { mode: 'ghost', alpha: 0.45, visible: false, mat: m4() });
  GH.ring = addMesh((() => { const g = new Builder(0, false); g.add(() => gRing(0.86, 1, 28), 0, 0, 0, 0xffffff); return g; })(), { mode: 'ghost', alpha: 0.85, visible: false, mat: m4(), tint: [1, 0.95, 0.72] });

  // --- trees and stumps (placed once; a felled tree shrinks away and leaves its stump)
  b = new Builder(0.06); b.cyl(0.2, 0.28, 1.1, 5, 0, 0, 0, P.trunk).cone(1.25, 2.0, 6, 0, 0.8, 0, P.leaf).cone(0.98, 1.8, 6, 0, 1.95, 0, P.leaf, 0.5).cone(0.62, 1.4, 6, 0, 3.0, 0, P.leaf, 1);
  PL.pine = addPool(b, 800, { keep: true });
  b = new Builder(0.06); b.cyl(0.22, 0.3, 1.5, 5, 0, 0, 0, P.trunk).ico(1.35, 0, 2.4, 0, P.leaf2, 0.85).ico(0.85, 0.7, 3.2, 0.25, P.leaf2, 0.9);
  PL.round = addPool(b, 400, { keep: true });
  b = new Builder(0.05); b.cyl(0.24, 0.32, 0.34, 6, 0, 0, 0, P.trunk).cyl(0.2, 0.2, 0.03, 6, 0, 0.34, 0, 0xcaa972, 0, 0, 0, false);
  PL.stump = addPool(b, 1000, { keep: true, cast: false });
  for (const t of trees) { t.pi = (t.kind ? PL.round : PL.pine).put(IDENT); t.si = PL.stump.put(IDENT); setTree(t, 1, 0, false); }

  // --- small flying bits, and health bars
  b = new Builder(0, false); b.box(0.16, 0.16, 0.16, 0, -0.08, 0, 0xffffff);
  PL.bits = addPool(b, 500, { cast: false });
  b = new Builder(0, false); b.add(gQuad, 0, 0, 0, 0xffffff);
  PL.barBg = addPool(b, 200, { mode: 'bar' }); PL.barFg = addPool(b, 200, { mode: 'bar' });
}
const GH = {};
const _tm = m4();
function setTree(t, grow, tilt, stump) {         // grow 1 = standing, about a third = a sapling, 0 = gone
  const s = t.s * grow, pool = t.kind ? PL.round : PL.pine;
  m4trs(_tm, t.x, 0, t.z, t.rot, 0, tilt, s, s, s); pool.set(t.pi, _tm, t.tint[0], t.tint[1], t.tint[2]);
  const st = stump ? t.s : 0; m4trs(_tm, t.x, 0, t.z, t.rot, 0, 0, st, st, st); PL.stump.set(t.si, _tm);
}
const showTree = t => t.st === 0 ? setTree(t, 1, 0, false) : t.st === 1 ? setTree(t, 0, 0, true) : setTree(t, 0.34, 0, false);
