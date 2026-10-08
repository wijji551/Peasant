// ===== screens, heads-up display, controls, main loop =====
const App = { screen: 'home', name: 'Peasant', col: 0, kick: null, buildSel: null, prevPhase: 'title', endShown: false, hudT: 0, atkHeld: false, cine: 0, back: 0, panel: null, panelPage: '', panelSig: '', edge: '', edgeT: 0, enterAt: 0, dawnSeen: -1, dawnAt: 0, slowT: 0 };
const show = (id, on) => { $(id).hidden = !on; };
const esc = t => String(t).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
function setStatus(msg, bad) { const s = $('status'); s.textContent = msg || ''; s.classList.toggle('bad', !!bad); }
function readProfile() { App.name = ($('name').value.trim() || 'Peasant').slice(0, 14); try { localStorage.setItem('dtv-name', App.name); localStorage.setItem('dtv-col', App.col); } catch (e) { } }
const PLACES = [{ name: 'Market', x: 0, z: 21.6, y: 3.2 }, { name: 'Smithy', x: 16.5, z: -4.7, y: 6 }, { name: 'Storehouse', x: 17, z: 10.6, y: 6.5 }, { name: 'Library', x: 17, z: 20.4, y: 8 }, { name: 'Slum', x: -17.6, z: 20.5, y: 3.4 }, { name: 'The Thorny Rose', x: -17.5, z: -4.7, y: 7.5 }, { name: 'Robert Bailiff', x: -14.5, z: -12.6, y: 8.6 }, { name: 'Farms: food', x: -58, z: 30, y: 1.5 }, { name: 'The keep', x: 0, z: 0, y: 12.4 },
  { name: 'Chapel: the priest', x: 17, z: -14, y: 8.4 }, { name: 'Old ruins: search', x: 10.8, z: -15.4, y: 3.4 }, { name: 'West ruins: search', x: -58, z: 46, y: 5 }, { name: 'East ruins: search', x: 58, z: 46, y: 5 },
  { name: 'Outcrop: stone', y: 3.6, at: () => QUARRY }, { name: 'Mine: iron', y: 4, at: () => MINEC }, { name: 'Jetty: fishing', y: 1.6, at: () => ({ x: JETTY.x, z: JETTY.z + 2.6 }) }];
const saveLabel = d => `Carry on from day ${d.day}`;

function uiHome(msg) {
  App.screen = 'home'; S.phase = 'title'; S.players = []; S.peasants = []; S.undead = []; S.structs = []; S.boss = null; App.buildSel = null; App.panel = null;
  for (const t of trees) setTreeState(t, 0, 0); S.tv++; S.sites = [0, 0, 0]; setSites(S.sites); S.drops = []; S.day = 1;
  show('home', true); show('lobby', false); show('hud', false); show('end', false); $('labels').textContent = ''; $('places').textContent = '';
  const d = readSave(); show('contRow', !!d);
  if (d) { $('btnCont').textContent = saveLabel(d); $('contNote').textContent = 'Saved in this browser: ' + d.players.map(p => p.dn).join(', ') + '.'; }
  setStatus(msg || '', !!msg); setBusy(false);
}
function setBusy(b) { for (const id of ['btnSolo', 'btnHost', 'btnJoin', 'btnCont']) $(id).disabled = b; }
function uiLobby() {
  if (App.screen !== 'lobby') return;
  $('lobbyCode').textContent = Net.code;
  $('lobbyList').innerHTML = '';
  for (const p of Lobby.players) { const li = document.createElement('li'); const d = document.createElement('span'); d.className = 'dot'; d.style.background = PCOL[p.col % 8]; li.append(d, document.createTextNode(p.name + (p.id === Net.myId ? ' (you)' : '') + (p.id === 1 ? ', host' : ''))); $('lobbyList').append(li); }
  const host = Net.role === 'host', d = host ? readSave() : null;
  show('btnStart', host); show('btnStartSave', !!d); if (d) $('btnStartSave').textContent = saveLabel(d);
  $('lobbyHint').textContent = host ? 'Give this code to the others. They open the same file, type it in and press Join. Up to 8 can play.' + (d ? ' Carrying on gives each saved peasant to whoever has the same name.' : '') : 'Waiting for the host to ring the morning bell.';
  $('lobbyCount').textContent = Lobby.players.length + ' of 8 peasants';
}
function uiHostLeft(why) { leaveNet(); uiHome(why || 'The host has left, so that village is closed.'); }
function goLobby() { App.screen = 'lobby'; show('home', false); show('lobby', true); uiLobby(); }

function beginGame(save) {                       // host or solo; save = carry on from the saved morning
  const infos = Lobby.players.map(lp => ({ id: lp.id, name: lp.name, col: lp.col, remote: lp.id !== Net.myId }));
  if (save) loadGame(save, infos);
  else { S.players = infos.map((info, i) => { const p = mkPlayer(info, i); p.remote = info.remote; return p; }); newGame(); }
  sendRoster(); enterGame();
}
function enterGame() {
  App.screen = 'game'; App.endShown = false; App.prevPhase = 'title'; App.buildSel = null; App.cine = 0; App.back = 0; App.panel = null; App.panelPage = ''; App.bookSig = ''; App.hudKeys = ''; App.menu = null; show('menu', false); App.enterAt = performance.now(); App.dawnSeen = -1;
  toasts.length = 0;
  show('home', false); show('lobby', false); show('hud', true); show('end', false); show('dawn', false); show('panel', false);
  $('hudCode').textContent = Net.role === 'solo' ? '' : 'Village code ' + Net.code;
  for (const k in keys) keys[k] = false;
}

// --- buttons
function initUi() {
  let nm = '', col = 0; try { nm = localStorage.getItem('dtv-name') || ''; col = +localStorage.getItem('dtv-col') || 0; } catch (e) { }
  $('name').value = nm; App.col = clamp(col, 0, 7);
  const sw = $('swatches');
  PCOL.forEach((c, i) => { const b = document.createElement('button'); b.type = 'button'; b.className = 'sw'; b.style.background = c; b.title = PCOLN[i]; b.setAttribute('aria-label', PCOLN[i]); b.setAttribute('aria-pressed', i === App.col); b.onclick = () => { App.col = i; for (const o of sw.children) o.setAttribute('aria-pressed', o === b); }; sw.append(b); });
  const solo = save => { readProfile(); leaveNet(); Lobby.players = [{ id: 1, name: save ? save.players[0].name : App.name, col: save ? save.players[0].col : App.col }]; beginGame(save); };
  $('btnSolo').onclick = () => solo(null);
  $('btnCont').onclick = () => { const d = readSave(); if (d) solo(d); };
  $('btnHost').onclick = () => {
    readProfile(); setBusy(true); setStatus('Opening the village gates…');
    loadPeer(ok => {
      if (!ok) { setBusy(false); return setStatus('Could not load the co-op connection. Co-op needs an internet connection.', true); }
      startHost(err => { setBusy(false); if (err) { leaveNet(); return setStatus('Could not open a village for co-op (' + err + '). Check your connection and try again.', true); } setStatus(''); goLobby(); });
    });
  };
  const join = () => {
    readProfile(); const code = $('code').value.trim().toUpperCase().replace(/[^A-Z]/g, '');
    if (code.length !== 5) return setStatus('A village code is five letters.', true);
    setBusy(true); setStatus('Looking for the village…');
    loadPeer(ok => {
      if (!ok) { setBusy(false); return setStatus('Could not load the co-op connection. Co-op needs an internet connection.', true); }
      startClient(code, err => { setBusy(false); if (err) { leaveNet(); return setStatus(err, true); } setStatus(''); goLobby(); });
    });
  };
  $('btnJoin').onclick = join; $('code').addEventListener('keydown', e => { if (e.key === 'Enter') join(); });
  $('btnStart').onclick = () => { if (Net.role === 'host') beginGame(null); };
  $('btnStartSave').onclick = () => { const d = readSave(); if (Net.role === 'host' && d) beginGame(d); };
  $('btnLeave').onclick = () => { leaveNet(); uiHome(); };
  $('btnCopy').onclick = () => { const done = () => { $('btnCopy').textContent = 'Copied'; setTimeout(() => $('btnCopy').textContent = 'Copy', 1400); }; try { navigator.clipboard.writeText(Net.code).then(done, () => { }); } catch (e) { } };
  $('btnAgain').onclick = () => { if (Net.role === 'client') return; const d = S.phase === 'lost' ? readSave() : null; beginGame(d); };
  $('btnTitle').onclick = () => { leaveNet(); uiHome(); };
  $('btnDawn').onclick = () => show('dawn', false);
  initMenu();
  $('c').addEventListener('mousedown', e => { if (App.screen !== 'game' || App.menu) return; if (e.button === 0) { if (App.buildSel) placeGhost(); else App.atkHeld = true; } else if (e.button === 2) useAbility(); });
  $('c').addEventListener('contextmenu', e => e.preventDefault());
  addEventListener('mouseup', () => { App.atkHeld = false; });
  BUILDS.forEach((k, i) => { $('build' + (i + 1)).onclick = () => selectBuild(k); });
  $('panelOpts').addEventListener('click', e => { const v = e.target.closest('[data-a]'); if (v) { if (!v.disabled) invDo(v.dataset.a, isNaN(+v.dataset.arg) ? v.dataset.arg : +v.dataset.arg); return; } const b = e.target.closest('button[data-i]'); if (b) panelDo(+b.dataset.i); });
}
function buildsNow() { return ME ? BUILDS.filter(k => !COST[k].bodies || ME.bodies >= COST[k].bodies) : []; }
function selectBuild(k) { App.buildSel = App.buildSel === k || !buildsNow().includes(k) ? null : k; App.panel = null; }
function openPanel(id) { App.panel = App.panel === id ? null : id; App.panelPage = ''; App.panelSig = ''; App.buildSel = null; }

// --- the notices: one for each place, and one for your pack
const lower = t => t.charAt(0).toLowerCase() + t.slice(1), bookNeed = n => `rank ${n[1]} of ${BOOKS[n[0]].name}`;
function itemSub(p, id) {                         // one line about a thing, for a notice
  const I = IT[id], A = AB[I.ab];
  let t = I.s === 'w' ? `${I.dmg} damage${I.rng ? ', ranged' : ''}${I.holy ? ', holy' : ''}. Shift: ${A.n}, ${A.d}.` : I.cut ? `Takes ${Math.round(I.cut * 100)}% off every blow${I.arrow ? ` and stops ${Math.round(I.arrow * 100)}% of arrows` : ''}${I.slow ? ', and slows you a little' : ''}.` : '';
  if (I.note && I.s !== 'w') t += (t ? ' ' : '') + I.note + '.';
  if (I.need && !canUse(p, id)) t += ` You cannot use it yet: it needs ${bookNeed(I.need)}.`;
  return t;
}
const WEARV = { w: 'Take in hand', h: 'Put on', b: 'Put on', o: 'Take up', t: 'Carry' };
function panelData(id, p, page) {
  const o = [];
  if (id === 'market') {
    const pr = n => p.gab ? Math.floor(n * 1.5) : n;
    o.push({ head: 'Sell' }); for (const r of RES) o.push({ label: `Sell 5 ${r}`, sub: `for ${pr(Math.min(5, p[r]))}d. You carry ${p[r]}.`, ok: p[r] > 0, a: 'sell', arg: r });
    o.push({ head: 'Buy' }); for (const r of RES) o.push({ label: `Buy 5 ${r}`, sub: 'for 10d', ok: p.coin >= 2 && p[r] < cap(p), a: 'buy', arg: r });
    return { title: 'The market', intro: `You have ${coins(p.coin)}. ` + (p.gab ? 'You have the Gift of the Gab: the stalls pay you three pence for every two pieces, and still charge two a piece.' : 'The stalls pay a penny a piece and charge two.'), o };
  }
  if (id === 'store') {
    if (page === 'arms') {
      o.push({ head: 'Put on the rack' });
      p.inv.forEach((it, i) => o.push({ label: `Put in: ${IT[it].n}`, sub: 'From your pack.', ok: true, a: 'puti', arg: i }));
      for (const k of SLOTS) if (p[k] > 0) o.push({ label: `Put in: ${IT[p[k]].n}`, sub: k === 'wpn' ? 'It is in your hand. You go back to the pitchfork.' : 'You are wearing it.', ok: true, a: 'pute', arg: k });
      o.push({ head: 'Take from the rack' });
      S.items.forEach((it, i) => o.push({ label: `Take: ${IT[it].n}`, sub: itemSub(p, it), ok: p.inv.length < PACK_MAX || wearsNow(p, it), a: 'takei', arg: i }));
      o.push({ label: 'Back to the materials', sub: '', ok: true, page: '' });
      return { title: 'The arms rack', intro: `Spare arms, shared by the whole village: ${S.items.length} on the rack. Your pack holds ${p.inv.length} of ${PACK_MAX}.`, o };
    }
    o.push({ head: 'Put in' }); for (const r of RES) o.push({ label: `Put in your ${r}`, sub: `You carry ${p[r]}.`, ok: p[r] > 0, a: 'put', arg: r });
    o.push({ head: 'Take out' }); for (const r of RES) o.push({ label: `Take 5 ${r}`, sub: `${S.store[r]} inside`, ok: S.store[r] > 0 && p[r] < cap(p), a: 'take', arg: r });
    o.push({ head: 'Spare arms' }); o.push({ label: 'The arms rack', sub: `${S.items.length} spare weapon${S.items.length === 1 ? '' : 's'} and bits of armour. Leave what you do not need for the others.`, ok: true, page: 'arms' });
    return { title: 'The storehouse', intro: 'Shared by the whole village. Anyone can put in or take out.', o };
  }
  if (id === 'smithy') {
    const forge = i => { const I = IT[i], c = forgeCost(p, I.cost), locked = I.heavy && rk(p, 3) < 2; o.push({ label: `Forge ${itA(i)}`, sub: locked ? 'Heavy arms need rank 2 of Hammer and Tongs.' : `${costText(c)}. ` + (I.s === 'w' ? `${I.note}. ${I.dmg} damage. Shift: ${AB[I.ab].n}.` + (canUse(p, i) ? '' : ` You cannot use it yet: it needs ${bookNeed(I.need)}.`) : itemSub(p, i)), ok: !locked && has(p, c), a: 'forge', arg: i }); };
    if (page === 'armour') {
      o.push({ head: 'Armour' }); FORGE_A.forEach(forge);
      const c = forgeCost(p, PEASANT_ARM), un = S.peasants.filter(q => q.owner === p.id && !q.armed && q.state !== 'body').length;
      o.push({ head: 'Your posse' }); o.push({ label: rk(p, 3) >= 3 ? 'Arm your whole posse with spears' : 'Arm one of your posse with a spear', sub: `${costText(c)} each. ${un} of yours still ${un === 1 ? 'carries' : 'carry'} a pitchfork.`, ok: un > 0 && has(p, c), a: 'armp' });
      o.push({ label: 'Back to the weapons', sub: '', ok: true, page: '' });
    } else { o.push({ head: 'Weapons' }); FORGE_W.forEach(forge); o.push({ head: 'More' }); o.push({ label: 'Armour, and spears for your posse', sub: 'Iron cap, chain shirt, shield.', ok: true, page: 'armour' }); }
    return { title: 'The smithy', intro: `You carry ${p.iron} iron and ${p.wood} wood. What you forge goes on; what it replaces goes in your pack.` + (p.books[3] ? '' : ' Hammer and Tongs, in the library, makes all of this cheaper.'), o };
  }
  if (id === 'library') {
    const slots = bookSlots(p), owned = p.books.filter(r => r > 0).length;
    BOOKS.forEach((B, b) => {
      const r = p.books[b];
      o.push({ label: B.name + (r ? ` · rank ${r} of 7` : ''), sub: !r ? `${B.what}. ${B.ranks[0]}.` : `Latest: ${lower(B.ranks[r - 1])}.` + (r < 7 ? ` Next: ${lower(B.ranks[r])} (${Math.floor(p.xp[b])} of ${needXp(b, r)}, by ${B.by}).` : ' You have finished it.'), ok: !r && slots > 0, a: 'book', arg: b });
    });
    return { title: 'The library', intro: (slots > 0 ? (owned ? 'You may take up another book.' : 'The peasants’ section is one shelf of ten books, with seven ranks in each. Choose your first.') : owned >= 3 ? 'You have your three books.' : 'Reach rank 2 in a book to take up a second, and rank 3 in two books to take up a third.') + (p.coward ? ' Cowards learn at half speed today.' : ''), o };
  }
  if (id === 'slum') {
    const c = { food: slumFood(p) }, pop = S.peasants.filter(q => q.state !== 'body').length, full = pop >= popCap(), pfull = p.posse >= posseMax(p);
    o.push({ label: 'Recruit a peasant', sub: full ? 'The village has no room for more.' : pfull ? `Your posse is full (${p.posse} of ${posseMax(p)}).` : `${costText(c)}${p.coward ? ', double for a coward' : ''}. You carry ${p.food}.`, ok: !full && !pfull && has(p, c), a: 'recruit' });
    return { title: 'The slum', intro: 'There are always more peasants here, and they will follow anyone who feeds them.', o };
  }
  if (id === 'inn') {
    if (p.state === 'inn') {
      o.push({ label: 'Drink a tankard', sub: p.drinkT > 0 ? 'Drinking…' : S.ale > 0 ? `${S.ale} left in the barrel.` : 'The barrel is empty. Somebody should have brought the innkeeper food.', ok: S.ale > 0 && p.drinkT <= 0 && p.cg < 100, a: 'drink' });
      o.push({ label: 'Unbar the door and go out', sub: 'Sober, more or less.', ok: true, a: 'innout' });
      return { title: 'Inside the Thorny Rose', intro: `Dutch courage: ${p.cg}%. At 100 you burst out and charge for ${chargeLen(p)} seconds: faster, stronger and tougher. Nothing can reach you in here until the door gives way (${Math.round(S.innHp / INN_HP * 100)}% left).`, o };
    }
    const day = S.phase === 'day';
    o.push({ label: 'Give the innkeeper 5 food', sub: `He turns each piece into a tankard for tonight. ${S.ale} in the barrel. You carry ${p.food}.`, ok: p.food > 0, a: 'ale' });
    o.push({ label: 'Go in and bar the door', sub: day ? 'The Rose opens at dusk.' : S.innHp <= 0 ? 'The door is in pieces until morning.' : 'Your posse comes in with you. The dead will try the door.', ok: !day && S.innHp > 0, a: 'innin' });
    return { title: 'The Thorny Rose', intro: `Dutch courage: ${p.cg}%. Drink inside at night until you are brave enough to charge. The innkeeper only has as much ale as the village brings him food that day.`, o };
  }
  if (id === 'priest' || id === 'pack') {
    const here = id === 'priest', fee = f => f ? 'Free: you have the learning.' : `${coins(BLESS_FEE)}.`, can = f => f || (here && p.coin >= BLESS_FEE), W = IT[p.wpn];
    const bless = () => {
      if (here || p.holy >= 1) o.push({ label: `Bless your ${W.n}`, sub: W.holy ? 'It is holy already.' : p.bless & 1 ? 'Blessed until dawn.' : fee(p.holy >= 1) + ' Holy until dawn: half as much damage again, and bones stay down.', ok: !W.holy && !(p.bless & 1) && can(p.holy >= 1), a: 'bless', arg: 'w' });
      if (here || p.holy >= 1) o.push({ label: 'Bless your slop bucket', sub: p.trk !== 28 ? 'You carry no bucket. The ruins have them.' : p.bless & 2 ? 'Blessed. Heaven help whoever it lands on.' : fee(p.holy >= 1) + ' It will burn as well as stink.', ok: p.trk === 28 && !(p.bless & 2) && can(p.holy >= 1), a: 'bless', arg: 'k' });
      if (here || p.holy >= 2) o.push({ label: 'Bless a body you carry', sub: !p.bodies ? 'You carry none.' : `${p.bbod} of ${p.bodies} blessed. ` + fee(p.holy >= 2) + ' A blessed body can be built into a wall, gate or barricade.', ok: p.bbod < p.bodies && can(p.holy >= 2), a: 'bless', arg: 'b' });
    };
    if (here) {
      o.push({ head: 'Blessings' }); bless();
      o.push({ head: 'Holy studies' }); o.push({ label: p.holy >= 2 ? 'Holy studies: finished' : p.study ? `In class: ${Math.floor(p.holyT)} of ${HOLY_TIME} seconds` : `Sit a class in holy studies (${p.holy} of 2 done)`, sub: p.holy >= 2 ? 'You can bless anything yourself, anywhere, from your pack (I).' : p.study ? 'Stay beside the priest. Press again to walk out; he will remember where you got to.' : `About ${HOLY_TIME} seconds beside the priest. After one class you can bless your own weapon and bucket for nothing; after two, the departed as well. It does not count as one of your three books.`, ok: p.holy < 2, a: 'study' });
      return { title: 'The priest', intro: `A blessing lasts until dawn. You have ${coins(p.coin)}.`, o };
    }
    if (page === 'drop') {
      o.push({ head: 'Throw away' }); p.inv.forEach((it, i) => o.push({ label: `Drop: ${IT[it].n}`, sub: 'It stays on the ground where you stand.', ok: true, a: 'dropi', arg: i }));
      o.push({ label: 'Back', sub: '', ok: true, page: '' });
      return { title: 'Your pack', intro: 'Anything dropped can be picked up again, by anyone.', o };
    }
    o.push({ head: `In your pack (${p.inv.length} of ${PACK_MAX})` });
    p.inv.forEach((it, i) => o.push({ label: `${WEARV[IT[it].s]}: ${IT[it].n}`, sub: itemSub(p, it), ok: canUse(p, it), a: 'eq', arg: i }));
    const on = SLOTS.filter(k => p[k] > 0);
    if (on.length) { o.push({ head: 'On you' }); for (const k of on) o.push({ label: `Put away: ${IT[p[k]].n}`, sub: p.inv.length >= PACK_MAX ? 'Your pack is full.' : k === 'wpn' ? 'Back to the pitchfork.' : '', ok: p.inv.length < PACK_MAX, a: 'uneq', arg: k }); }
    if (p.holy >= 1) { o.push({ head: 'Blessings' }); bless(); }
    if (p.inv.length) o.push({ label: 'Throw something away', sub: '', ok: true, page: 'drop' });
    return { title: 'Your pack', intro: `In your hand: ${W.n}. Shift: ${AB[W.ab].n}, ${AB[W.ab].d}. Spare arms can go on the rack in the storehouse for the others.`, o };
  }
  return null;
}
// small pictures of things, for the pack
const ICON = {
  fork: 'M12 22V8M7 3v5h10V3M12 3v5', sword: 'M12 2l2 3v10h-4V5zM8 15h8M12 15v6', spear: 'M12 22V7M12 1l3 6H9z', mace: 'M12 22V11M8 7a4 4 0 1 0 8 0a4 4 0 1 0-8 0M12 1v2M5 7h2M17 7h2',
  bill: 'M10 22V3M10 3c5 0 7 3 7 7c-2-2-4-3-7-3', hammer: 'M12 22V9M6 3h12v6H6z', club: 'M10 22l1-9c-2-4-1-10 2-10s4 6 2 10l-1 9z', spade: 'M12 2v12M9 2h6M7 14h10v3c0 3-3 5-5 5s-5-2-5-5z',
  rake: 'M12 22V6M5 6h14M5 6v4M8.5 6v4M12 6v4M15.5 6v4M19 6v4', scythe: 'M8 22V3M8 4c6-2 11 0 13 5c-4-3-8-3-13-2', dagger: 'M12 3l2.5 9h-5zM8 13h8M12 13v7', pan: 'M3 9a6 6 0 1 0 12 0a6 6 0 1 0-12 0M13.5 13.5L21 21',
  sling: 'M5 4c3 8 3 8 7 12M19 4c-3 8-3 8-7 12M9.5 18.5a2.5 2.5 0 1 0 5 0a2.5 2.5 0 1 0-5 0', bow: 'M7 2c10 4 10 16 0 20M7 2v20M7 12h13M17 9l3 3-3 3', xbow: 'M3 8c5-5 13-5 18 0M12 5v16M3 8l9 5l9-5',
  helm: 'M4 16v-3a8 8 0 0 1 16 0v3zM12 9v7', mail: 'M7 3L2 7l3 4l2-1v11h10V10l2 1l3-4l-5-4c-1 2-9 2-10 0z', shield: 'M12 2l8 3v6c0 6-4 9-8 11c-4-2-8-5-8-11V5z',
  bucket: 'M5 8h14l-2 13H7zM5 8c2-7 12-7 14 0', bell: 'M12 2v3M6 17c0-9 2-12 6-12s6 3 6 12zM4 17h16M12 17v3', censer: 'M12 2v6M7 12a5 5 0 0 0 10 0zM7 12h10M10 20h4M12 17v3M9 6c-2-1 0-3-2-4M15 6c2-1 0-3 2-4'
};
const icon = id => { const I = IT[id]; return `<svg viewBox="0 0 24 24" class="ic${I.tier === 'relic' ? ' relic' : ''}" aria-hidden="true"><path d="${ICON[id === 26 ? 'bell' : id === 27 ? 'censer' : I.pool] || ''}"/></svg>`; };
const SLOTN = { wpn: 'In hand', head: 'Head', body: 'Body', off: 'Off hand', trk: 'Carried' };
function invHtml(p) {                             // the pack, drawn as slots: what is on you, then the six places in the pack
  const info = id => esc(itCap(id) + '. ' + (itemSub(p, id) || (id === 0 ? 'Everyone has one. It cannot be put away.' : '')));
  let h = '<div class="opt head">On you</div><div class="slots">';
  for (const k of SLOTS) {
    const id = p[k];
    if (id >= 0 && !(k !== 'wpn' && id === 0)) h += `<div class="slotw"><button class="slot on" data-a="uneq" data-arg="${k}" data-info="${info(id)}${id > 0 ? ' Click to put it away.' : ''}"${id > 0 ? '' : ' data-fixed="1"'}>${icon(id)}<span>${esc(IT[id].n)}${(k === 'wpn' && p.bless & 1) || (k === 'trk' && p.bless & 2) ? ' ✝' : ''}</span><em>${SLOTN[k]}</em></button></div>`;
    else h += `<div class="slotw"><div class="slot empty"><em>${SLOTN[k]}</em></div></div>`;
  }
  h += `</div><div class="opt head">In your pack (${p.inv.length} of ${PACK_MAX})</div><div class="slots six">`;
  for (let i = 0; i < PACK_MAX; i++) {
    const id = p.inv[i];
    if (id === undefined) { h += `<div class="slotw"><div class="slot empty"><kbd>${i + 1}</kbd></div></div>`; continue; }
    const can = canUse(p, id);
    h += `<div class="slotw"><button class="slot${can ? '' : ' locked'}" data-a="eq" data-arg="${i}" data-info="${info(id)} Click to ${lower(WEARV[IT[id].s])}.">${icon(id)}<kbd>${i + 1}</kbd><span>${esc(IT[id].n)}</span></button><button class="drop" data-a="dropi" data-arg="${i}" title="Drop it on the ground" aria-label="Drop ${esc(IT[id].n)}">×</button></div>`;
  }
  h += '</div><p class="small" id="invInfo">Point at a thing to read about it. Click it to use it or put it away; the little cross drops it.</p>';
  const bl = panelData('pack', p, '').o.filter(o => o.a === 'bless');
  if (bl.length) h += '<div class="opt head">Blessings</div>' + bl.map(o => `<button class="opt" data-a="bless" data-arg="${o.arg}"${o.ok ? '' : ' disabled'}><span>${esc(o.label)}</span><small>${esc(keyed(o.sub))}</small></button>`).join('');
  return h;
}
function invDo(a, arg) {
  const p = ME; if (!p) return;
  if (a === 'eq' && IT[p.inv[arg]] && !canUse(p, p.inv[arg])) { sfx('no'); return banner('Not yet', `${itCap(p.inv[arg])} needs ${bookNeed(IT[p.inv[arg]].need)}. The book is in the library.`, 3000); }
  if (a === 'uneq' && p[arg] === 0) { sfx('no'); return banner('The pitchfork stays', 'It is what you hold when you hold nothing else.', 1800); }
  if (a === 'uneq' && p.inv.length >= PACK_MAX) { sfx('no'); return banner('Your pack is full', 'Drop something, or leave it on the arms rack in the storehouse.', 2200); }
  act(a, arg); sfx('pop', 0.4); App.panelSig = '';
}
function renderPanel() {
  const p = ME; if (p && p.state === 'inn' && live()) App.panel = 'inn';
  const st = App.panel && STATIONS.find(s => s.id === App.panel), inn = p && p.state === 'inn';
  if (App.wasInn && !inn) App.panel = null; App.wasInn = inn;
  if (!App.panel || !p || !live() || !(inn || (p.state === 'ok' && (App.panel === 'pack' || (st && dist2(p.x, p.z, st.x, st.z) <= (st.r + 1.6) ** 2))))) { App.panel = null; App.panelPage = ''; show('panel', false); App.panelSig = ''; return; }
  if (App.panel === 'pack') {
    const W = IT[p.wpn], sig = 'pack' + JSON.stringify([p.inv, SLOTS.map(k => p[k]), p.bless, p.holy, p.books, p.bodies, p.bbod, p.coin >= BLESS_FEE, BIND]);
    if (sig !== App.panelSig) {
      App.panelSig = sig; txt('panelTitle', 'Your pack'); txt('panelIntro', `In your hand: ${W.n}. ${kn('trick')}: ${AB[W.ab].n}, ${AB[W.ab].d}.`);
      $('panelOpts').innerHTML = invHtml(p); txt('panelHint', `1 to 6: use it. ${kn('swap')}: next weapon, without opening this. ${kn('pack')} or Esc: close.`);
    }
    return show('panel', true);
  }
  const d = panelData(App.panel, p, App.panelPage), sig = JSON.stringify(d) + kn('trick');
  if (sig === App.panelSig) return; App.panelSig = sig;
  $('panelTitle').textContent = d.title; $('panelIntro').textContent = keyed(d.intro);
  let n = 0; $('panelOpts').innerHTML = d.o.map(o => o.head ? `<div class="opt head">${esc(o.head)}</div>` : `<button class="opt" data-i="${n}"${o.ok ? '' : ' disabled'}><kbd>${++n > 10 ? '·' : n % 10}</kbd><span>${esc(o.label)}</span><small>${esc(keyed(o.sub))}</small></button>`).join('');
  txt('panelHint', inn ? 'Press the number, or click.' : 'Press the number, or click. Walk away to close.');
  show('panel', true);
}
function panelDo(i) {
  if (App.panel === 'pack') { if (ME && ME.inv[i] !== undefined) invDo('eq', i); return; }
  const d = App.panel && ME ? panelData(App.panel, ME, App.panelPage) : null; if (!d) return;
  const o = d.o.filter(x => !x.head)[i]; if (!o) return;
  if (!o.ok) return sfx('no');
  if (o.page !== undefined) { App.panelPage = o.page; sfx('pop', 0.4); } else act(o.a, o.arg);
  App.panelSig = '';
}
// words on screen name the keys as the player has set them
const keyed = t => String(t).replace(/\bHold E\b/g, 'Hold ' + kn('interact')).replace(/Press E or click/g, `Press ${kn('interact')} or click`).replace(/Press Space/g, 'Press ' + kn('attack')).replace(/\(I opens it\)/g, `(${kn('pack')} opens it)`).replace(/your pack \(I\)/g, `your pack (${kn('pack')})`).replace(/\bShift: /g, kn('trick') + ': ').replace(/\bG (lobs|rings)/g, (m, w) => kn('carry') + ' ' + w).replace(/Tab changes/g, kn('build') + ' changes');

// --- the handbook: a guide, the controls (which can be changed) and a few options. Esc opens it.
const GUIDE = [
  ['The short version', ['By day, gather and build. At dusk the bell rings. At night the dead rise along the graveyard to the north, one after another without a pause and faster as the night goes on, and make for the keep, where the families are hiding. If the keep falls, Thornhallow is lost. Hold for seven nights.', 'Nearly everything is done by walking up to it and holding {interact}.']],
  ['The day', ['A day lasts six minutes, or until everyone presses {ready}.', 'Wood comes from trees, stone from the rocky outcrop, iron from the mine, food from the farms to the west or the jetty on the river. The stone, the iron and the fishing move every morning: the dawn notice says where, and the map marks them. You carry 20 of each.', 'At the jetty, hold {interact} and press {attack} when something bites.']],
  ['Defences', ['The north wall has seven foundations: six walls and a gate. Stand on one and hold {interact}. Barricades and spike rows go anywhere: press {build} or 1 to 4, then {interact} or click.', 'Hold {interact} at a damaged defence to repair it with wood. Carrying stone or iron, hold {interact} again to face a wall with stone, band the gate or brace a barricade. An unbraced barricade rots by half every evening after its first night.', 'Nobody can be hit through a standing wall or gate, in either direction. Go out through the gate, or shoot over.']],
  ['Your posse', ['Hold {interact} beside a neighbour to rally them. They gather when you gather and fight when you fight. The slum has more, for food. The smithy gives them spears.', 'They can die, and they have nerve: when friends fall they may run for the keep until dawn. {toilet} is the emergency toilet break, which sends the dead nearby running. With rank 3 of the leadership book, {orders} tells them to follow, hold or charge.']],
  ['Fighting', ['{attack} or a click attacks. {trick} or a right-click is your weapon’s own trick: every weapon has a different one, with a short wait between uses. {eat} eats one food.', 'Knocked down, you have 15 seconds for a team-mate to hold {interact} over you. After that a relative takes over your cottage at dawn, with your books but not your gear. Relics lie where you fell.', 'From dusk you can hide in your own cottage. It is safe, and the village will call you a coward until the next dusk.']],
  ['Things you carry', ['{pack} opens your pack: what is on you, and six places for spares. Click a thing to use it or put it away. {swap} swaps to the next weapon in the pack without opening it. {carry} throws a slop bucket or rings a handbell.', 'A bow needs the book Slings, Bows and Thrown Turnips, which comes with a sling. A crossbow needs rank 3 of it. Heavy arms need rank 2 of Hammer and Tongs to forge.']],
  ['Places', ['The library: three books out of ten, seven ranks each, earned by doing what the book teaches. The smithy: weapons, armour, spears for the posse. The storehouse: shared materials and a shared arms rack. The market: sells at a penny a piece, buys at two. The slum: recruits.', 'The Thorny Rose: bring the innkeeper food by day; from dusk go in, bar the door and drink. At full courage you burst out and charge. The priest, by the chapel: blessings for two shillings, and holy studies.', 'The ruins, by the chapel and outside the wall to the south-west and south-east: hold {interact} at a heap of rubble. Relics turn up, more often by moonlight. Searching outside the wall is noisy.']],
  ['Playing together', ['One player hosts and gives the others the five-letter village code. The host’s browser runs the game and saves it every morning; if the host leaves, the village closes. Each extra player brings another whole horde.']]
];
const fillKeys = t => esc(t).replace(/\{(\w+)\}/g, (m, a) => `<kbd>${esc(BIND[a] ? kn(a) : a)}</kbd>`);
function renderMenu() {
  const tab = App.menu; if (!tab) return;
  const game = App.screen === 'game';
  txt('menuNote', !game ? '' : Net.role === 'solo' ? 'The game is paused while you read.' : 'The game goes on while you read: the others are still out there.');
  for (const b of $('menuTabs').children) b.setAttribute('aria-pressed', b.dataset.tab === tab);
  let h = '';
  if (tab === 'guide') h = '<div class="guide">' + GUIDE.map(g => `<h3>${esc(g[0])}</h3>` + g[1].map(p => `<p>${fillKeys(p)}</p>`).join('')).join('') + '</div>';
  else if (tab === 'keys') {
    h = '<div class="bind">' + ACTIONS.map(([a, label]) => `<span>${esc(label)}</span><kbd class="${BIND[a].length ? '' : 'none'}">${App.rebinding === a ? 'Press a key…' : esc(kAll(a))}</kbd><button class="btn alt sm" data-bind="${a}">${App.rebinding === a ? 'Cancel' : 'Change'}</button>`).join('') + '</div>'
      + `<p class="small">${esc(App.bindMsg || 'Choose Change, then press the key you want. A key does one thing: whatever had it before is left without, and shows as “no key set”.')}</p>`
      + '<p class="small">Fixed: a click attacks and a right-click is your weapon’s trick. The numbers pick from a notice, your pack, or the things to place. Esc closes whatever is open, and otherwise opens this handbook.</p>'
      + '<p><button class="btn alt sm" data-bind="!reset">Back to the usual keys</button></p>';
  } else {
    h = `<div class="opts"><label><span>Sound</span><input type="range" id="optVol" min="0" max="100" step="5" value="${OPT.vol}"><b id="optVolN">${OPT.vol ? OPT.vol + '%' : 'off'}</b></label>`
      + `<label><span>Name tags over the other players</span><input type="checkbox" id="optTags"${OPT.tags ? ' checked' : ''}></label>`
      + `<label><span>See through the keep when something is behind it</span><input type="checkbox" id="optKeep"${OPT.seeKeep ? ' checked' : ''}></label></div>`
      + '<p class="small">These are kept in this browser.</p>';
  }
  $('menuBody').innerHTML = h;
  txt('btnMenuClose', game ? 'Back to the game' : 'Close'); show('btnMenuLeave', game);
  txt('btnMenuLeave', App.leaveArmed ? (Net.role === 'host' ? 'Really? That closes the village for everyone. Click again.' : 'Really leave? Click again.') : 'Leave the village');
}
function openMenu(tab) { App.menu = tab || App.menuTab || 'guide'; App.leaveArmed = false; App.rebinding = null; App.bindMsg = ''; for (const k in keys) keys[k] = false; App.atkHeld = false; renderMenu(); show('menu', true); $('menuBody').scrollTop = 0; }
function closeMenu() { App.menuTab = App.menu; App.menu = null; rebind = null; App.rebinding = null; show('menu', false); renderHomeKeys(); App.panelSig = ''; App.hudKeys = ''; }
function renderHomeKeys() {
  $('homeKeys').innerHTML = [['Move', ['up', 'left', 'down', 'right'].map(kn).join(' ') + (BIND.up.includes('ArrowUp') ? ', or the arrow keys' : '')], ['Attack · your weapon’s trick', `${kn('attack')} or click · ${kn('trick')} or right-click`], ['Gather, build, search, rally, use a place', 'Hold ' + kn('interact')], ['Eat · your pack · ready for the night', [kn('eat'), kn('pack'), kn('ready')].join(' · ')]].map(r => `<tr><td>${esc(r[0])}</td><td>${esc(r[1])}</td></tr>`).join('');
}
function initMenu() {
  $('menuTabs').addEventListener('click', e => { const b = e.target.closest('[data-tab]'); if (b) { App.menu = b.dataset.tab; App.rebinding = null; rebind = null; renderMenu(); $('menuBody').scrollTop = 0; } });
  $('menuBody').addEventListener('click', e => {
    const b = e.target.closest('[data-bind]'); if (!b) return; const a = b.dataset.bind; b.blur();
    if (a === '!reset') { resetBinds(); App.rebinding = null; rebind = null; App.bindMsg = 'The usual keys are back.'; return renderMenu(); }
    if (App.rebinding === a) { App.rebinding = null; rebind = null; return renderMenu(); }
    App.rebinding = a; App.bindMsg = '';
    rebind = code => {
      App.rebinding = null;
      if (code === 'Escape') App.bindMsg = 'Left as it was.';
      else if (/^Digit\d$/.test(code)) App.bindMsg = 'The numbers are kept for notices, the pack and the things to place.';
      else { const had = actOf(code); setBind(a, code); App.bindMsg = had && had !== a ? `${keyName(code)} now does “${ACTIONS.find(x => x[0] === a)[1]}”. “${ACTIONS.find(x => x[0] === had)[1]}” ${BIND[had].length ? 'keeps ' + kAll(had) : 'has no key now'}.` : `${keyName(code)} it is.`; }
      renderMenu();
    };
    renderMenu();
  });
  $('menuBody').addEventListener('input', e => {
    const t = e.target;
    if (t.id === 'optVol') { OPT.vol = +t.value; txt('optVolN', OPT.vol ? OPT.vol + '%' : 'off'); } else if (t.id === 'optTags') OPT.tags = t.checked; else if (t.id === 'optKeep') OPT.seeKeep = t.checked;
    store.set('dtv-opt', OPT); if (t.id === 'optVol') sfx('pop');
  });
  $('btnMenuClose').onclick = closeMenu;
  $('btnMenuLeave').onclick = () => { if (!App.leaveArmed) { App.leaveArmed = true; return renderMenu(); } closeMenu(); leaveNet(); uiHome(); };
  $('btnMenu').onclick = () => openMenu(); $('btnHelp').onclick = () => openMenu('guide'); $('chipPack').onclick = () => { if (ME && ME.state === 'ok') openPanel('pack'); };
  $('panelOpts').addEventListener('mouseover', e => { const b = e.target.closest('[data-info]'), i = $('invInfo'); if (b && i) i.textContent = b.dataset.info; });
  $('panelOpts').addEventListener('focusin', e => { const b = e.target.closest('[data-info]'), i = $('invInfo'); if (b && i) i.textContent = b.dataset.info; });
  renderHomeKeys();
}

// --- controls
function onKeyDown(code) {
  if (code === 'Escape') {                        // closes whatever is open; with nothing open, the handbook
    if (App.menu) return closeMenu();
    if (App.screen === 'game' && (App.buildSel || App.panel || !$('dawn').hidden)) { show('dawn', false); App.buildSel = null; if (!ME || ME.state !== 'inn') App.panel = null; return; }
    if (App.screen === 'game' || App.screen === 'home') openMenu();
    return;
  }
  if (App.menu || App.screen !== 'game') return;
  const a = actOf(code);
  if (a === 'mute') { muted = !muted; banner(muted ? 'Sound off' : 'Sound on', '', 900); }
  if (!ME) return;
  if (a === 'ready' && S.phase === 'day') { const v = !ME.ready; if (Net.role === 'client') Net.tr.send({ t: 'rdy', v }); ME.ready = v; sfx('pop'); show('dawn', false); }
  const dg = /^Digit([0-9])$/.exec(code);
  if (dg && App.panel) return panelDo((+dg[1] + 9) % 10);
  if (ME.state !== 'ok') return;
  if (a === 'pack') return openPanel('pack');
  if (a === 'trick') return useAbility();
  if (a === 'swap') { const i = ME.inv.findIndex(id => IT[id].s === 'w' && canUse(ME, id)); if (i < 0) { sfx('no'); return banner('No other weapon', 'There is no weapon in your pack that you can use.', 1500); } banner(itCap(ME.inv[i]), '', 800); sfx('pop', 0.5); App.panelSig = ''; return act('eq', i); }
  if (a === 'carry') { if (ME.trk !== 28 && ME.trk !== 26) { sfx('no'); return banner('Nothing to use', 'A slop bucket or a handbell goes here. The ruins have them.', 1500); } if (ME.trk === 26 && ME.useCd > 0) return sfx('no'); aimAssist(ME); return send('use', () => doUse(ME)); }
  if (a === 'toilet') { if (ME.tbCd > 0) { sfx('no'); return banner('Not yet', `The posse needs ${Math.ceil(ME.tbCd)} more seconds, and a drink of water.`, 1300); } if (!ME.posse) { sfx('no'); return banner('No posse', 'An emergency toilet break needs a posse.', 1300); } return send('tb', () => doToilet(ME)); }
  if (a === 'orders') { if (rk(ME, 6) < 3) { sfx('no'); return banner('No orders yet', 'Orders need rank 3 of How to Win Peasants and Lead Them.', 1700); } const n = (ME.ord + 1) % 3; banner(['Follow me', 'Hold here', 'Charge!'][n], '', 900); sfx('pop'); return send('ord', () => doOrder(ME)); }
  if (a === 'build') { const b = buildsNow(), i = b.indexOf(App.buildSel); App.buildSel = i + 1 < b.length ? b[i + 1] : null; App.panel = null; }
  else if (dg && +dg[1] >= 1 && +dg[1] <= BUILDS.length) selectBuild(BUILDS[+dg[1] - 1]);
  else if (a === 'interact' && App.buildSel) placeGhost();
  else if (a === 'eat') { if (ME.food < 1) { sfx('no'); banner('You have no food', 'The farms and the river have some.', 1300); } else if (Net.role === 'client') Net.tr.send({ t: 'eat' }); else doEat(ME); }
  else if (a === 'attack' && ME.gk === 5) { if (Net.role === 'client') Net.tr.send({ t: 'fish' }); else doFish(ME); }
}
function send(t, local) { if (Net.role === 'client') Net.tr.send({ t, r: r2(ME.r) }); else local(); }
function useAbility() {                          // Shift or right-click: your weapon's own trick
  if (!ME || ME.state !== 'ok' || App.screen !== 'game' || !live()) return;
  if (ME.abCd > 0) return sfx('no');
  aimAssist(ME); if (Net.role === 'client') ME.abCd = abWait(ME);
  send('abl', () => doAbility(ME));
}
function ghostPos() { const rot = Math.round(ME.r / (Math.PI / 4)) * (Math.PI / 4); return { x: ME.x + Math.sin(ME.r) * 2.7, z: ME.z + Math.cos(ME.r) * 2.7, rot }; }
function placeGhost() {
  const k = App.buildSel; if (!k || !ME || ME.state !== 'ok') return;
  const g = ghostPos(), c = costOf(ME, k);
  if (!has(ME, c)) { sfx('no'); return banner(`A ${SNAME[k]} needs ${costText(c)}`, '', 1100); }
  if (!validPlace(k, g.x, g.z, g.rot)) { sfx('no'); if (COST[k].bodies && insideVillage(g.x, g.z)) banner('Not inside the village', 'The fallen go outside the wall.', 1500); return; }
  if (Net.role === 'client') Net.tr.send({ t: 'bld', k, x: r2(g.x), z: r2(g.z), rot: r2(g.rot) }); else tryPlace(ME, k, g.x, g.z, g.rot);
}
let localAtkCd = 0;
function localStep(dt) {
  const p = ME; localAtkCd = Math.max(0, localAtkCd - dt);
  if (!p || App.screen !== 'game') return;
  const on = live() && !App.menu;                 // with the handbook open you stand still
  p.eHold = on && held('interact') && !App.buildSel && (p.state === 'ok' || p.state === 'hide');
  if (!on || p.state !== 'ok') return;
  let mx = (held('right') ? 1 : 0) - (held('left') ? 1 : 0), mz = (held('down') ? 1 : 0) - (held('up') ? 1 : 0);
  const l = Math.hypot(mx, mz);
  if (l > 0) {
    const sp = PLAYER_SPEED * (p.body >= 0 && IT[p.body].slow ? 1 - IT[p.body].slow : 1) * (1 - 0.05 * (p.bodies | 0)) * (p.charge > 0 ? 1.35 : p.hang > 0 ? 0.6 : 1);
    mx /= l; mz /= l; if (p.hang > 0) { const w = Math.sin(performance.now() / 260) * 0.6; const ax = mx + -mz * w, az = mz + mx * w, al = Math.hypot(ax, az); mx = ax / al; mz = az / al; }   // the hangover wobble
    p.r = angLerp(p.r, Math.atan2(mx, mz), Math.min(1, dt * 14));
    p.x += mx * sp * dt; collideFriend(p, 0.45, 0); p.z += mz * sp * dt; collideFriend(p, 0.45, 1);   // one axis at a time, so corners do not snag
    const e = p.x >= BOUNDS.x1 - 0.01 || p.x <= BOUNDS.x0 + 0.01 ? 'hedge' : p.z <= BOUNDS.z0 + 0.01 ? 'stakes' : p.z >= BOUNDS.z1 - 0.01 ? 'river' : '';
    if (e) { App.edge = e; App.edgeT = performance.now(); }
  }
  if (Net.role === 'client' && p.gk) { const it = findInteract(p); if (it && it.type === 'gather') p.r = angLerp(p.r, Math.atan2(it.x - p.x, it.z - p.z), Math.min(1, dt * 12)); }
  if ((held('attack') || App.atkHeld) && localAtkCd <= 0 && p.gk !== 5) {
    const I = IT[p.wpn]; localAtkCd = I.cd * (I.rng && rk(p, 5) >= 5 ? 0.8 : 1); aimAssist(p);
    if (Net.role === 'client') { p.ac = (p.ac | 0) + 1; Net.tr.send({ t: 'atk', r: r2(p.r) }); } else doAttack(p);
  }
}
const EDGE = { hedge: 'The thorn hedge. Nothing gets through it, which is how the village got its name.', stakes: 'Past the stakes the ground belongs to the castle. Nobody sensible goes further.', river: 'The river is too cold and too deep.' };

// --- heads-up display
let bannerT = 0;
function banner(title, sub, ms) { $('bannerTitle').textContent = title; $('bannerSub').textContent = sub || ''; const b = $('banner'); b.hidden = false; b.classList.remove('in'); void b.offsetWidth; b.classList.add('in'); bannerT = performance.now() + (ms || 3200); }
const fmt = s => { s = Math.max(0, Math.ceil(s)); return (s / 60 | 0) + ':' + String(s % 60).padStart(2, '0'); };
const txt = (id, v) => { const e = $(id); if (e.textContent !== v) e.textContent = v; };
const txt2 = (e, v) => { if (e.textContent !== v) e.textContent = v; };
const ROMAN = ['', 'I', 'II', 'III', 'IV', 'V', 'VI', 'VII'];
function phaseChanged(ph) {
  if (ph === 'day') { show('end', false); App.endShown = false; }
  else if (ph === 'dusk') { banner('Dusk', S.day === LAST_DAY ? 'The bell rings. Somebody at the castle is polishing the silver.' : 'The bell rings. Something is stirring at Ashhollow Castle.', 5200); sfx('bell'); App.cine = 5.2; show('dawn', false); App.panel = null; }
  else if (ph === 'night') banner('Night ' + S.day, S.day >= 4 ? 'The dead are rising all along the graveyard, and some have brought bows.' : 'The dead are rising all along the graveyard.', 4200);
  else if (ph === 'won') sfx('dawn');
  else if (ph === 'lost') sfx('lost');
}
function showEnd(won) {
  App.endShown = true; App.buildSel = null; App.panel = null; show('dawn', false);
  txt('endTitle', won ? 'The first week is over' : 'The keep has fallen');
  txt('endText', won ? 'Thornhallow has held for seven nights, and the Steward has gone back up the hill in several pieces. Robert Bailiff has opened an upstairs window to say that it all went exactly as he planned.' : 'The dead reached the families in the keep. Robert Bailiff’s door remains bolted.');
  $('endLines').innerHTML = won ? S.dawn.lines.map(l => `<li>${esc(l)}</li>`).join('') : '';
  txt('endStats', `Undead put down: ${S.stats.kills}  ·  Peasants lost: ${S.stats.lost}  ·  Defences built: ${S.stats.built}  ·  Keep: ${Math.max(0, Math.round(S.keepHp))} of ${KEEP_HP}`);
  txt('endNote', won ? 'That was the first week of the month. Nights 8 to 30 arrive in later builds.' : `Day ${S.day} was saved at dawn, so you can have it again.`);
  const boss = Net.role !== 'client'; show('btnAgain', boss); txt('btnAgain', won ? 'Start a new week' : `Try day ${S.day} again`);
  txt('endWait', boss ? '' : 'The host decides whether to go again.');
  show('end', true);
}
function updateHud(dt) {
  const nowT = performance.now();
  if (bannerT && nowT > bannerT) { bannerT = 0; $('banner').hidden = true; }
  if (App.screen !== 'game') return;
  if (S.phase !== App.prevPhase) { App.prevPhase = S.phase; phaseChanged(S.phase); App.endT = nowT; }
  if ((S.phase === 'won' || S.phase === 'lost') && !App.endShown && nowT - App.endT > 2200) showEnd(S.phase === 'won');
  if (S.dawn.seq !== App.dawnSeen && S.phase === 'day') {                      // a new morning: the notice
    App.dawnSeen = S.dawn.seq; App.dawnAt = nowT;
    txt('dawnTitle', `Day ${S.dawn.day} of ${LAST_DAY}`); $('dawnLines').innerHTML = S.dawn.lines.map(l => `<li>${esc(l)}</li>`).join('');
    show('dawn', S.dawn.lines.length > 0); banner('Day ' + S.dawn.day, '', 2600); if (S.dawn.day > 1) sfx('dawn');
  }
  if (!$('dawn').hidden && (nowT - App.dawnAt > 15000 || S.phase !== 'day')) show('dawn', false);
  // prompt and target ring (every frame, so the bar is smooth)
  const it = ME && !App.buildSel && live() ? findInteract(ME) : null;
  GH.ring.visible = !!it && ME.state === 'ok';
  if (it) { m4trs(GH.ring.mat, it.x, 0.12, it.z, it.rot || 0, 0, 0, it.rad, 1, it.wide ? 1 : it.rad); GH.ring.tint = it.ok ? [1, 0.95, 0.72] : [0.9, 0.5, 0.4]; }
  if (it && it.type === 'station' && held('interact') && !App.menu && ME.state === 'ok' && App.panel !== it.st.id) { App.panel = it.st.id; App.panelPage = ''; App.panelSig = ''; sfx('pop', 0.5); }
  let ptxt = it && !(it.type === 'station' && App.panel) ? it.label : '';
  if (!ptxt && ME && ME.state === 'ok' && nowT - App.edgeT < 500) ptxt = EDGE[App.edge] || '';
  if (ME && ME.state === 'down') ptxt = 'You are down. A team-mate can revive you for ' + Math.ceil(ME.downT || 0) + ' more seconds.';
  else if (ME && ME.state === 'dead') ptxt = 'You are dead. A relative arrives at dawn.';
  else if (App.buildSel && ME) ptxt = `Press E or click to place a ${SNAME[App.buildSel]} (${costText(costOf(ME, App.buildSel))}). Tab changes, Esc cancels.`;
  show('prompt', !!ptxt); if (ptxt) txt('promptText', keyed(ptxt));
  $('promptBar').style.width = (ME && it && it.ok && ME.gk !== 5 ? Math.round((ME.prog || 0) * 100) : 0) + '%';
  if (ME && (ME.state !== 'ok' || (App.buildSel && !buildsNow().includes(App.buildSel)))) App.buildSel = null;
  for (const k of BUILDS) GH[k].visible = false;
  if (App.buildSel && ME && ME.state === 'ok') { const g = ghostPos(), gm = GH[App.buildSel], ok = has(ME, costOf(ME, App.buildSel)) && validPlace(App.buildSel, g.x, g.z, g.rot); gm.visible = true; m4trs(gm.mat, g.x, 0.02, g.z, g.rot, 0, 0, 1, 1, 1); gm.tint = ok ? [0.6, 0.95, 0.5] : [0.95, 0.4, 0.35]; }
  // signs over the places you can use, when you are near them
  const pc = $('places');
  if (!pc.children.length) for (const P2 of PLACES) { const d = document.createElement('div'); d.className = 'plc'; d.textContent = P2.name; pc.append(d); }
  PLACES.forEach((P2, i) => { if (P2.at) { const a = P2.at(); P2.x = a.x; P2.z = a.z; } const d = pc.children[i], near = dist2(CAM.fx, CAM.fz, P2.x, P2.z) < 30 * 30; d.style.opacity = near ? 1 : 0; if (near) { const q = project(P2.x, P2.y || 4.6, P2.z); d.style.transform = `translate(${Math.round(q[0])}px,${Math.round(q[1])}px) translate(-50%,-100%)`; } });
  // name labels
  const lab = $('labels'), shown = OPT.tags ? S.players.filter(p => p !== ME && p.state !== 'hide' && p.state !== 'inn') : [];   // your own flag is enough for you
  while (lab.children.length < shown.length) { const d = document.createElement('div'); d.className = 'nm'; lab.append(d); }
  while (lab.children.length > shown.length) lab.lastChild.remove();
  shown.forEach((p, i) => { const d = lab.children[i], q = project(p.x, 3.75 + Math.max(0, (p.bodies | 0) - 2) * 0.4, p.z); txt2(d, p.dn + (p.coward ? ' (coward)' : '')); d.style.transform = `translate(${Math.round(q[0])}px,${Math.round(q[1])}px) translate(-50%,-100%)`; d.style.borderColor = PCOL[p.col % 8]; });
  if (nowT - App.hudT < 100) return; App.hudT = nowT;
  // everything below changes ten times a second
  renderPanel();
  const day = S.phase === 'day', ph = S.phase;
  txt('hudPhase', ph === 'dusk' ? 'Dusk' : ph === 'night' || ph === 'lost' ? 'Night ' + S.day : `Day ${S.day} of ${LAST_DAY}`);
  txt('hudTimer', day ? 'Dusk in ' + fmt(S.timeLeft) : ph === 'dusk' ? 'Night falls in ' + fmt(S.timeLeft) : ph === 'night' ? (S.left > 0 ? (S.wave > 0 ? `${S.left} undead left · ${S.wave} still to rise` : `${S.left} undead left · the last have risen`) : 'The graveyard is quiet') : ph === 'won' ? 'The week is over' : 'The keep has fallen');
  if (ME) {
    const c = cap(ME);
    for (const r of RES) { txt('hud-' + r, ME[r] + ' / ' + c); $('chip-' + r).classList.toggle('full', ME[r] >= c); }
    txt('hudCoin', coins(ME.coin));
    let nv = 100; for (const q of S.peasants) if (q.owner === ME.id && q.state !== 'body' && q.state !== 'hide' && q.nv < nv) nv = q.nv;
    txt('hudPosse', ME.posse + ' / ' + posseMax(ME) + (rk(ME, 6) >= 3 && ME.posse ? ' · ' + ['following', 'holding', 'charging'][ME.ord | 0] : '') + (ME.posse && nv < 40 ? ' · about to run' : ME.posse && nv < 70 ? ' · uneasy' : ''));
    show('chipBodies', ME.bodies > 0); txt('hudBodies', ME.bodies + ' / ' + MAX_BODIES + (ME.bbod ? ` (${ME.bbod} blessed)` : ''));
    const W = IT[ME.wpn], A = AB[W.ab];
    txt('hudGear', [W.n + (ME.bless & 1 ? ' (blessed)' : '')].concat(['head', 'body', 'off'].filter(k => ME[k] >= 0).map(k => IT[ME[k]].n)).join(', '));
    txt('hudAb', A.n + (ME.abCd > 0 ? ` in ${Math.ceil(ME.abCd)}s` : ': ready')); $('chipAb').classList.toggle('full', ME.abCd > 0);
    show('chipTrk', ME.trk >= 0); if (ME.trk >= 0) txt('hudTrk', IT[ME.trk].n + (ME.bless & 2 ? ' (blessed)' : '') + (ME.trk === 26 && ME.useCd > 0 ? ` in ${ME.useCd}s` : ''));
    txt('hudPack', ME.inv.length + ' / ' + PACK_MAX);
    if (App.hudKeys !== JSON.stringify(BIND)) { App.hudKeys = JSON.stringify(BIND); txt('labAb', kn('trick')); txt('labTrk', kn('carry')); txt('labPack', 'Pack · ' + kn('pack')); for (const k of document.querySelectorAll('#bm .bcard')) k.title = `${kn('build')} steps through these`; }
    const cg = ME.state === 'inn' || ME.cg > 0 || ME.charge > 0 || ME.hang > 0; show('chipCg', cg);
    if (cg) { txt('labCg', ME.charge > 0 ? 'Charging' : ME.hang > 0 ? 'Hangover' : 'Courage'); txt('hudCg', ME.charge > 0 ? Math.ceil(ME.charge) + 's' : ME.hang > 0 ? Math.ceil(ME.hang) + 's' : ME.cg + '%'); }
    $('hpFill').style.width = Math.round(ME.hp / maxHp(ME) * 100) + '%'; txt('hpLab', ME.food > 0 && ME.hp < maxHp(ME) && ME.state === 'ok' ? `Your health. ${kn('eat')} eats.` : 'Your health');
    const bsig = ME.books.join() + '|' + ME.xp.map(Math.floor).join() + ME.coward;
    if (bsig !== App.bookSig) {
      App.bookSig = bsig;
      $('hudBooks').innerHTML = ME.books.some(r => r) ? BOOKS.map((B, b) => { const r = ME.books[b]; if (!r) return ''; const lo = r > 1 ? needXp(b, r - 1) : 0, pc = r >= 7 ? 100 : Math.min(100, (ME.xp[b] - lo) / (needXp(b, r) - lo) * 100); return `<div class="bk"><span>${esc(B.name)}</span><span class="rk">${ROMAN[r]}</span><i><b style="width:${pc}%"></b></i></div>`; }).join('') : 'No book yet. The library has one for you.';
    }
    BUILDS.forEach((k, i) => { const b = $('build' + (i + 1)); b.setAttribute('aria-pressed', App.buildSel === k); if (COST[k].bodies) b.hidden = ME.bodies < COST[k].bodies; else txt('bcost' + (i + 1), costText(costOf(ME, k))); });
  }
  $('keepFill').style.width = Math.max(0, S.keepHp / KEEP_HP * 100) + '%'; txt('keepNum', Math.max(0, Math.round(S.keepHp)) + ' / ' + KEEP_HP);
  show('bossBox', !!S.boss); if (S.boss) { const mx = S.boss.max || UN[3].hp; $('bossFill').style.width = Math.max(0, S.boss.hp / mx * 100) + '%'; txt('bossNum', Math.max(0, Math.ceil(S.boss.hp)) + ' / ' + mx); }
  const rd = S.players.filter(p => p.ready).length;
  txt('readyHint', day ? (ME && ME.ready ? `You are ready (${rd} of ${S.players.length}). Press ${kn('ready')} to change your mind.` : `Press ${kn('ready')} when you are ready for the night (${rd} of ${S.players.length} ready)`) : '');
  show('readyHint', day);
  const pl = $('plist');
  while (pl.children.length < S.players.length) { const li = document.createElement('li'); li.innerHTML = '<span class="dot"></span><span class="pn"></span><span class="ps"></span>'; pl.append(li); }
  while (pl.children.length > S.players.length) pl.lastChild.remove();
  S.players.forEach((p, i) => { const li = pl.children[i]; li.children[0].style.background = PCOL[p.col % 8]; txt2(li.children[1], p.dn); txt2(li.children[2], p.state === 'down' ? 'down' : p.state === 'dead' ? 'dead' : p.state === 'hide' ? 'hiding' : p.state === 'inn' ? 'in the Rose' : p.charge > 0 ? 'charging' : day && p.ready ? 'ready' : p.coward ? 'coward' : ''); });
  show('tr', !App.panel); show('plist', S.players.length > 1);
  const tl = $('toasts'), live2 = toasts.filter(t => nowT - t.at < 8000);
  while (tl.children.length < live2.length) tl.append(document.createElement('li'));
  while (tl.children.length > live2.length) tl.lastChild.remove();
  live2.forEach((t, i) => { txt2(tl.children[i], t.t); tl.children[i].style.opacity = nowT - t.at > 6500 ? 0 : 1; });
  drawMini($('mini'));
}

// --- main loop
let lastT = 0, keepHcSeen = 0;
function drainEvents() {
  if (!S.ev.length) return;
  const ev = S.ev.splice(0); handleEvents(ev);
  if (Net.role === 'host' && Net.conns.size) { Net.evOut.push(...ev); if (Net.evOut.length > 80) Net.evOut.splice(0, Net.evOut.length - 80); }
}
function frame(now) {
  requestAnimationFrame(frame);
  const dt = Math.min(0.25, (now - lastT) / 1000 || 0.016); lastT = now;
  const cv = GFX.canvas, dpr = Math.min(window.devicePixelRatio || 1, 2), w = Math.round(cv.clientWidth * dpr), h = Math.round(cv.clientHeight * dpr);
  if (cv.width !== w || cv.height !== h) { cv.width = w; cv.height = h; }
  ME = App.screen === 'game' ? S.players.find(p => p.id === Net.myId) || null : null;
  if (App.screen === 'game') {
    for (let rem = dt; rem > 1e-4; rem -= 0.05) {             // slow machines take several small steps so the game keeps real time
      const st = Math.min(0.05, rem); localStep(st);
      if (Net.role === 'client') clientStep(st); else if (!(App.menu && Net.role === 'solo')) { simStep(st); hostNet(st); }   // alone, the handbook pauses the game
    }
    drainEvents();
    if (S.keepHc !== keepHcSeen) { keepHcSeen = S.keepHc; if (S.phase === 'night') sfx('keep', 0.5); $('keepBar').classList.remove('hit'); void $('keepBar').offsetWidth; $('keepBar').classList.add('hit'); }
  }
  // camera: follow me in the game, drift over the village on the notice board
  CAM.t += dt; let nf = S.nf, zoom;
  const asp = cv.width / Math.max(1, cv.height), wide = asp < 0.8 ? 1.7 : asp < 1.3 ? 1.25 : 1;
  if (App.screen === 'game') {
    const home = ME ? cottage(ME.slot) : null;
    let f = ME && ME.state !== 'dead' ? (ME.state === 'hide' ? { x: home.x, z: home.z } : ME.state === 'inn' ? { x: INN.x + 2, z: INN.z } : ME) : { x: 0, z: -12 }, k = Math.min(1, dt * 6); zoom = (1 + 0.12 * nf) * wide;
    // at dusk the view glides up to the castle for a moment; touching a movement key brings it straight back
    if (App.cine > 0) { App.cine -= dt; if (S.phase !== 'dusk' || held('up') || held('left') || held('down') || held('right')) App.cine = 0; }
    if (App.cine > 1.4) { f = { x: 0, z: -127 }; k = Math.min(1, dt * 1.5); zoom = 1.55 * wide; App.back = 1.3; }
    else if (App.back > 0) { App.back -= dt; k = Math.min(1, dt * 3.5); }
    CAM.fx = lerp(CAM.fx, f.x, k); CAM.fz = lerp(CAM.fz, f.z, k);
  } else {
    const a = CAM.t * 0.05; CAM.fx = lerp(CAM.fx, Math.sin(a) * 9, 0.02); CAM.fz = lerp(CAM.fz, -6 + Math.cos(a) * 8, 0.02);
    const c = (CAM.t % 60) / 60; nf = c < 0.45 ? 0 : c < 0.6 ? (c - 0.45) / 0.15 : c < 0.88 ? 1 : 1 - (c - 0.88) / 0.12; zoom = 1.45 * wide;
  }
  CAM.zoom = lerp(CAM.zoom, zoom, Math.min(1, dt * 3));
  setCamera(CAM.fx, CAM.fz, CAM.zoom); setLight(nf, CAM.fx, CAM.fz);
  drawWorld(dt); updateHud(dt); renderFrame();
}
function boot() {
  const cv = $('c'); let ok = false;
  try { ok = initGfx(cv); } catch (e) { console.error(e); }
  initUi();
  if (!ok) { setStatus('This browser cannot draw the village: it needs WebGL 2. A current Chrome, Edge, Firefox or Safari will work.', true); setBusy(true); return; }
  buildWorld(); initPools(); uiHome();
  // a small hook for testing from the console
  window.__dtv = {
    S, App, Net, trees, keys, BIND, OPT, GFX, openMenu, closeMenu, findInteract, panelData, act, readSave, toasts, wallBetween, me: () => ME, IT, BOOKS, UN, SITES, QUARRY, MINE, MINEC, JETTY, KEEP, ruinLayout, colliders,
    sim: { nightQueue, doAbility, doUse, doToilet, doOrder, doAttack, doAct, doSearch, spawnUndead, hitU, hurtFriend, endNight, duskFalls, gain, rollDay, growTrees, nightPlan, saveGame, homeSpot, posseMax, cap, needXp, addXp, bookSlots, tryPlace, collideFriend },
    fast(sec, fn) { for (let t = 0; t < sec; t += 1 / 30) { ME = S.players.find(p => p.id === Net.myId) || null; if (fn && fn(t) === false) return t; localStep(1 / 30); if (Net.role !== 'client') simStep(1 / 30); if (S.ev.length > 200) drainEvents(); } return sec; }
  };
  requestAnimationFrame(frame);
}
boot();
