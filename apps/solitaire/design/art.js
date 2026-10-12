// Baize · the art, drawn by cards.js. Each piece returns a complete <svg> string with a
// 372×340 viewBox (the icon 1024×1024). make-art.mjs writes them to design/art/ and
// design/icon.svg; the mocks call them inline so the mock and the asset are one drawing.

(function (root, factory) {
  if (typeof module === 'object' && module.exports) module.exports = factory(require('./cards.js'));
  else root.Art = factory(root.Cards);
})(typeof self !== 'undefined' ? self : this, function (Cards) {
  const { card, fan, pip, nap, defs, COL } = Cards;

  const lampGrad = (id, cx, cy, r, a) =>
    `<radialGradient id="${id}" gradientUnits="userSpaceOnUse" cx="${cx}" cy="${cy}" r="${r}"><stop offset="0" stop-color="${COL.lamp}" stop-opacity="${a}"/><stop offset="1" stop-color="${COL.lamp}" stop-opacity="0"/></radialGradient>`;

  const brassCorner = (x, y, s, flip) => {
    const t = s * 0.28;
    const d = flip
      ? `M${x} ${y} h${s} v${s} h-${t} v-${s - t} h-${s - t} z`
      : `M${x} ${y} h${s} v${t} h-${s - t} v${s - t} h-${t} z`;
    return `<path d="${d}" fill="${COL.brassDeep}"/><path d="${d}" fill="${COL.brass}" transform="translate(-1 -1)"/>`;
  };

  function wrap(inner, w, h) {
    return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${w} ${h}" width="${w}" height="${h}">${defs}${inner}</svg>`;
  }

  // The desk from above, the day's deal half laid, the diary's edge at the right.
  function desk() {
    const out = [];
    out.push(`<defs>${lampGrad('deskLamp', 70, 60, 200, 0.55)}
      <linearGradient id="wood" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#6E5038"/><stop offset="1" stop-color="#4E3627"/></linearGradient>
      <linearGradient id="bz" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#3A5C85"/><stop offset="1" stop-color="#27456A"/></linearGradient>
      <filter id="deskShadow" x="-10%" y="-10%" width="120%" height="130%"><feGaussianBlur stdDeviation="8"/></filter>
      <filter id="pageShadow" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="4"/></filter></defs>`);
    out.push(`<g transform="rotate(-3 186 180)">`);
    out.push(`<rect x="12" y="44" width="350" height="276" rx="16" fill="#0E1A2A" opacity=".35" filter="url(#deskShadow)" transform="translate(0 10)"/>`);
    out.push(`<rect x="12" y="36" width="350" height="276" rx="16" fill="url(#wood)"/>`);
    out.push(`<rect x="13" y="37" width="348" height="274" rx="15" fill="none" stroke="#8A6A4C" stroke-opacity=".5"/>`);
    out.push(`<rect x="30" y="52" width="314" height="244" rx="8" fill="url(#bz)"/>`);
    out.push(`<rect x="30" y="52" width="314" height="244" rx="8" fill="#0E1A2A" opacity=".25" transform="translate(0 2)" style="mix-blend-mode:multiply"/>`);
    out.push(`<rect x="30" y="52" width="314" height="244" rx="8" fill="url(#bz)"/>`);
    out.push(`<clipPath id="bzClip"><rect x="30" y="52" width="314" height="244" rx="8"/></clipPath>`);
    out.push(`<g clip-path="url(#bzClip)">${nap(30, 52, 314, 244, 7, 0.05, 3)}<rect x="30" y="52" width="314" height="244" fill="url(#deskLamp)"/></g>`);
    out.push(brassCorner(34, 56, 16, false));
    out.push(brassCorner(324, 276, 16, true));
    // foundations, top right
    const w = 30;
    out.push(card({ x: 196, y: 62, w, rank: 'A', suit: 'S' }));
    out.push(`<rect x="232" y="62" width="30" height="42" rx="2.4" fill="none" stroke="${COL.stock}" stroke-opacity=".3"/>` + pip('H', 240, 75, 14, COL.stock).replace('fill="#F6EFE0"', 'fill="#F6EFE0" fill-opacity=".22"'));
    out.push(card({ x: 268, y: 62, w, rank: '2', suit: 'C' }));
    out.push(`<rect x="304" y="62" width="30" height="42" rx="2.4" fill="none" stroke="${COL.stock}" stroke-opacity=".3"/>` + pip('D', 312, 75, 14, COL.stock).replace('fill="#F6EFE0"', 'fill="#F6EFE0" fill-opacity=".22"'));
    // stock and waste, top left
    out.push(card({ x: 56, y: 62, w, face: false }));
    out.push(card({ x: 92, y: 62, w, rank: '9', suit: 'D' }));
    // columns
    const cols = [
      [['K', 'H', true]],
      [[null, null, false], ['7', 'S', true]],
      [[null, null, false], [null, null, false], ['J', 'D', true], ['10', 'S', true]],
      [[null, null, false], ['Q', 'C', true]],
      [[null, null, false], [null, null, false], [null, null, false], ['5', 'H', true], ['4', 'C', true]],
      [[null, null, false], [null, null, false], ['8', 'H', true]],
      [[null, null, false], [null, null, false], [null, null, false], [null, null, false], ['6', 'D', true]],
    ];
    cols.forEach((col, i) => {
      let y = 116;
      col.forEach(([rank, suit, up]) => {
        out.push(card({ x: 56 + i * 36, y, w, rank, suit, face: up }));
        y += up ? 12 : 5;
      });
    });
    // a run in the hand
    out.push(`<g transform="translate(150 196) rotate(4)">`);
    out.push(card({ x: 0, y: 0, w: 34, rank: '9', suit: 'S', shadow: 9 }));
    out.push(card({ x: 2, y: 14, w: 34, rank: '8', suit: 'H', rot: 2, shadow: 9 }));
    out.push(card({ x: 5, y: 28, w: 34, rank: '7', suit: 'C', rot: 4, shadow: 9 }));
    out.push(`</g>`);
    out.push(`</g>`);
    // the diary's edge, lower right, lying across the desk's wood
    out.push(`<g transform="translate(258 232) rotate(7)">`);
    out.push(`<rect x="0" y="0" width="98" height="104" rx="4" fill="#0E1A2A" opacity=".3" filter="url(#pageShadow)" transform="translate(2 6)"/>`);
    out.push(`<rect x="0" y="0" width="98" height="104" rx="4" fill="${COL.stock}"/>`);
    out.push(`<path d="M9 14 H60" stroke="${COL.ink}" stroke-opacity=".5" stroke-width="2"/><path d="M9 23 H89" stroke="${COL.ink}" stroke-opacity=".18"/>`);
    for (let r = 0; r < 3; r++) for (let c = 0; c < 4; c++) {
      const x = 9 + c * 21, y = 30 + r * 25;
      if ((r + c) % 3 === 1) out.push(card({ x, y, w: 15, rank: ['6', 'J', '3', '9'][(r * 4 + c) % 4], suit: ['H', 'S', 'D', 'C'][(r + c) % 4] }));
      else out.push(`<rect x="${x}" y="${y}" width="15" height="21" rx="1.5" fill="none" stroke="${COL.ink}" stroke-opacity=".14"/>`);
    }
    out.push(`</g>`);
    return wrap(out.join(''), 372, 340);
  }

  // Four fans bloomed and overlapped at the centre: it came out.
  function fans() {
    const out = [];
    out.push(`<defs>${lampGrad('fanLamp', 50, 30, 240, 0.5)}
      <linearGradient id="bz2" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#2D4F78"/><stop offset="1" stop-color="#1C3454"/></linearGradient>
      <radialGradient id="fanRing" cx="186" cy="230" r="150" gradientUnits="userSpaceOnUse"><stop offset=".55" stop-color="${COL.lamp}" stop-opacity="0"/><stop offset="1" stop-color="${COL.lamp}" stop-opacity=".18"/></radialGradient></defs>`);
    out.push(`<rect x="0" y="0" width="372" height="340" rx="20" fill="url(#bz2)"/>`);
    out.push(`<clipPath id="fanClip"><rect x="0" y="0" width="372" height="340" rx="20"/></clipPath>`);
    out.push(`<g clip-path="url(#fanClip)">${nap(0, 0, 372, 340, 11, 0.045, 3)}<rect width="372" height="340" fill="url(#fanLamp)"/><rect width="372" height="340" fill="url(#fanRing)"/></g>`);
    const w = 58;
    const pivots = [[126, 262, -16, 'S'], [166, 258, -6, 'H'], [206, 258, 6, 'C'], [246, 262, 16, 'D']];
    out.push(`<ellipse cx="186" cy="262" rx="150" ry="16" fill="#0E1A2A" opacity=".35" filter="url(#cardShadowBig)"/>`);
    pivots.forEach(([cx, cy, rot, suit]) => out.push(fan(suit, cx, cy, w, 4.2, rot)));
    // pips in the air
    const flakes = [[40, 60, COL.stock, 7, 3, 30], [330, 80, COL.red, 6, 3, -40], [300, 40, COL.brass, 4, 4, 0], [70, 130, COL.ink, 5, 3, 70],
      [340, 160, COL.stock, 8, 3, 20], [30, 220, COL.red, 4, 4, 0], [350, 250, COL.stock, 6, 3, -60], [110, 40, COL.brass, 3, 3, 0], [250, 20, COL.stock, 7, 3, 50], [20, 300, COL.brass, 5, 3, 15]];
    flakes.forEach(([x, y, c, fw, fh, r]) => out.push(`<rect x="${x}" y="${y}" width="${fw}" height="${fh}" rx="${fw === fh ? fw / 2 : 1}" fill="${c}" transform="rotate(${r} ${x} ${y})"/>`));
    return wrap(out.join(''), 372, 340);
  }

  // The diary open on the cloth, a month of small cards, a pen across the hem.
  function diary() {
    const out = [];
    out.push(`<defs>${lampGrad('diaryLamp', 40, 20, 220, 0.4)}
      <linearGradient id="bz3" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#34547A"/><stop offset="1" stop-color="#213F62"/></linearGradient>
      <filter id="pageShadow2" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="6"/></filter></defs>`);
    out.push(`<rect x="0" y="0" width="372" height="340" rx="20" fill="url(#bz3)"/>`);
    out.push(`<clipPath id="diaryClip"><rect x="0" y="0" width="372" height="340" rx="20"/></clipPath>`);
    out.push(`<g clip-path="url(#diaryClip)">${nap(0, 0, 372, 340, 5, 0.045, 3)}<rect width="372" height="340" fill="url(#diaryLamp)"/></g>`);
    out.push(`<g transform="rotate(-2 186 170)">`);
    out.push(`<rect x="44" y="22" width="284" height="298" rx="7" fill="#0E1A2A" opacity=".4" filter="url(#pageShadow2)" transform="translate(2 10)"/>`);
    out.push(`<rect x="44" y="22" width="284" height="298" rx="7" fill="${COL.stock}"/>`);
    out.push(`<text x="60" y="56" font-family="ui-serif, 'New York', Georgia, serif" font-weight="600" font-size="30" fill="${COL.ink}">October</text>`);
    out.push(`<text x="312" y="54" text-anchor="end" font-family="-apple-system, system-ui, sans-serif" font-weight="600" font-size="9" letter-spacing="2" fill="${COL.ink}" fill-opacity=".6">2026</text>`);
    out.push(`<path d="M60 66 H312" stroke="${COL.ink}" stroke-opacity=".18"/>`);
    'MTWTFSS'.split('').forEach((d, i) => out.push(`<text x="${60 + i * 37 + 13}" y="80" text-anchor="middle" font-family="-apple-system, system-ui, sans-serif" font-weight="600" font-size="8" letter-spacing="1.5" fill="${COL.ink}" fill-opacity=".55">${d}</text>`));
    const cards = { 1: ['6', 'H'], 2: ['J', 'S'], 3: ['9', 'C'], 5: ['3', 'D'], 6: ['Q', 'H'], 8: ['8', 'S'], 9: ['4', 'D'], 10: ['K', 'C'], 11: ['7', 'H'], 12: ['6', 'H'] };
    const under = { 2: true, 6: true, 9: true, 12: true };
    let day = 1;
    for (let r = 0; r < 5; r++) for (let c = 0; c < 7; c++) {
      if (r === 0 && c < 3) continue;
      if (day > 31) break;
      const x = 60 + c * 37, y = 88 + r * 42, w = 26;
      if (cards[day]) {
        out.push(card({ x, y, w, rank: cards[day][0], suit: cards[day][1] }));
        if (under[day]) out.push(`<path d="M${x + 4} ${y + w * 1.4 + 3} H${x + w - 4}" stroke="${COL.brass}" stroke-width="2" stroke-linecap="round"/>`);
      } else {
        out.push(`<rect x="${x + .5}" y="${y + .5}" width="${w - 1}" height="${w * 1.4 - 1}" rx="2.5" fill="none" stroke="${COL.ink}" stroke-opacity=".13"/>`);
        out.push(`<text x="${x + 4}" y="${y + 10}" font-family="-apple-system, system-ui, sans-serif" font-weight="600" font-size="7" fill="${COL.ink}" fill-opacity=".4">${day}</text>`);
      }
      if (day === 12) out.push(`<rect x="${x - 2.5}" y="${y - 2.5}" width="${w + 5}" height="${w * 1.4 + 5}" rx="4" fill="none" stroke="${COL.brass}" stroke-width="2"/>`);
      day++;
    }
    out.push(`<path d="M60 301 H312" stroke="${COL.ink}" stroke-opacity=".18"/>`);
    out.push(`<text x="60" y="313" font-family="-apple-system, system-ui, sans-serif" font-weight="600" font-size="7.5" letter-spacing="1.8" fill="${COL.ink}" fill-opacity=".55">23 ENTRIES · 9 DAYS RUNNING · 14 CLEAN</text>`);
    out.push(`</g>`);
    // the pen, lying across the page's lower corner
    out.push(`<g transform="translate(150 326) rotate(-5)">`);
    out.push(`<rect x="0" y="4" width="130" height="12" rx="6" fill="#0E1A2A" opacity=".35" filter="url(#cardShadow)" transform="translate(0 4)"/>`);
    out.push(`<rect x="0" y="0" width="130" height="12" rx="6" fill="#1E2532"/><rect x="0" y="0" width="130" height="5" rx="2.5" fill="#3A4252"/>`);
    out.push(`<rect x="88" y="0" width="8" height="12" fill="${COL.brass}"/><path d="M130 6 L146 6 L150 4 L150 8 L146 6" fill="${COL.brass}"/><path d="M130 1 L146 4 L146 8 L130 11 Z" fill="${COL.brassDeep}"/>`);
    out.push(`</g>`);
    return wrap(out.join(''), 372, 340);
  }

  // The drawer pulled open: six backs, four cloths, a bundle of past deals, the brass handle.
  function drawer() {
    const out = [];
    out.push(`<defs>${lampGrad('drawerLamp', 60, 30, 240, 0.35)}
      <linearGradient id="wood2" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#6A4D36"/><stop offset="1" stop-color="#4A3325"/></linearGradient>
      <linearGradient id="wood3" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3E2B1F"/><stop offset="1" stop-color="#2E2017"/></linearGradient>
      <filter id="drawerShadow" x="-10%" y="-10%" width="120%" height="140%"><feGaussianBlur stdDeviation="7"/></filter></defs>`);
    out.push(`<rect x="0" y="0" width="372" height="340" rx="20" fill="url(#wood2)"/>`);
    out.push(`<clipPath id="dwClip"><rect x="0" y="0" width="372" height="340" rx="20"/></clipPath>`);
    out.push(`<g clip-path="url(#dwClip)"><rect width="372" height="340" fill="url(#drawerLamp)"/>`);
    for (let i = 0; i < 14; i++) out.push(`<path d="M0 ${20 + i * 24} Q186 ${14 + i * 24 + (i % 3) * 6} 372 ${22 + i * 24}" stroke="#2E2017" stroke-opacity=".25" fill="none"/>`);
    out.push(`</g>`);
    // the drawer, open: its front edge at the bottom, the tray above it
    out.push(`<rect x="18" y="54" width="336" height="262" rx="10" fill="#0E1A2A" opacity=".5" filter="url(#drawerShadow)" transform="translate(0 12)"/>`);
    out.push(`<rect x="18" y="50" width="336" height="250" rx="10" fill="url(#wood3)"/>`);
    out.push(`<rect x="30" y="60" width="312" height="196" rx="6" fill="#213F62"/>`);
    out.push(`<clipPath id="trayClip"><rect x="30" y="60" width="312" height="196" rx="6"/></clipPath>`);
    out.push(`<g clip-path="url(#trayClip)">${nap(30, 60, 312, 196, 3, 0.04, 3)}</g>`);
    out.push(`<rect x="18" y="296" width="336" height="30" rx="8" fill="#5A3F2D"/><rect x="18" y="296" width="336" height="3" fill="#7A5A42" opacity=".7"/>`);
    // handle
    out.push(`<rect x="146" y="304" width="80" height="12" rx="6" fill="${COL.brassDeep}"/><rect x="146" y="303" width="80" height="9" rx="4.5" fill="${COL.brass}"/><rect x="152" y="305" width="68" height="2" rx="1" fill="#F0DDA3" opacity=".8"/>`);
    // backs
    const backs = ['lattice', 'brassLattice', 'chevron', 'houndstooth', 'stars', 'leaf', 'seal'];
    backs.forEach((b, i) => out.push(card({ x: 42 + i * 43, y: 72, w: 36, face: false, back: b, shadow: i === 1 ? 6 : 2, rot: i === 1 ? -4 : 0 })));
    // cloths, folded
    const cloths = ['#34547A', '#7A2E35', '#2F5A42', '#4A5563'];
    cloths.forEach((c, i) => {
      const x = 42 + i * 72, y = 150;
      out.push(`<rect x="${x}" y="${y + 3}" width="62" height="44" rx="4" fill="#0E1A2A" opacity=".35" filter="url(#cardShadow)"/>`);
      out.push(`<rect x="${x}" y="${y}" width="62" height="44" rx="4" fill="${c}"/>`);
      out.push(`<path d="M${x} ${y + 22} H${x + 62}" stroke="#FFFFFF" stroke-opacity=".12" stroke-width="2"/><path d="M${x} ${y + 23} H${x + 62}" stroke="#0E1A2A" stroke-opacity=".3"/>`);
      out.push(`<clipPath id="cl${i}"><rect x="${x}" y="${y}" width="62" height="44" rx="4"/></clipPath><g clip-path="url(#cl${i})">${nap(x, y, 62, 44, 20 + i, 0.06, 3)}</g>`);
    });
    // a bundle of past deals tied with a ribbon
    out.push(`<g transform="translate(240 206) rotate(-8)">`);
    for (let i = 0; i < 4; i++) out.push(`<rect x="${i * 1.5}" y="${-i * 1.5}" width="60" height="42" rx="3" fill="${i === 3 ? COL.stock : '#E6DECB'}" stroke="${COL.ink}" stroke-opacity=".12"/>`);
    out.push(`<rect x="24" y="-6" width="12" height="54" fill="${COL.red}" opacity=".9"/><path d="M30 20 l-9 -8 l9 2 l9 -2 z" fill="#8E2A20"/>`);
    out.push(`</g>`);
    return wrap(out.join(''), 372, 340);
  }

  // The icon: the desk under the lamp with a run of three cards in the hand.
  function icon() {
    const S = 1024;
    const out = [];
    out.push(`<defs>
      <linearGradient id="ibz" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#3A5E88"/><stop offset=".55" stop-color="#2E4F78"/><stop offset="1" stop-color="#1C3452"/></linearGradient>
      <radialGradient id="ilamp" gradientUnits="userSpaceOnUse" cx="150" cy="120" r="620"><stop offset="0" stop-color="${COL.lamp}" stop-opacity=".62"/><stop offset=".45" stop-color="${COL.lamp}" stop-opacity=".18"/><stop offset="1" stop-color="${COL.lamp}" stop-opacity="0"/></radialGradient>
      <linearGradient id="iwood" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7A5A42"/><stop offset=".12" stop-color="#5E4432"/><stop offset="1" stop-color="#3E2B1F"/></linearGradient>
      <linearGradient id="iwoodR" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#7A5A42"/><stop offset=".12" stop-color="#5E4432"/><stop offset="1" stop-color="#3E2B1F"/></linearGradient>
      <filter id="ishadow" x="-30%" y="-30%" width="160%" height="170%"><feGaussianBlur stdDeviation="22"/></filter>
      <filter id="cardShadowBig" x="-40%" y="-40%" width="180%" height="200%"><feGaussianBlur stdDeviation="6"/></filter>
    </defs>`);
    out.push(`<rect width="${S}" height="${S}" fill="url(#ibz)"/>`);
    out.push(nap(0, 0, S, S, 9, 0.05, 7));
    out.push(`<rect width="${S}" height="${S}" fill="url(#ilamp)"/>`);
    // the desk's wood along the bottom and the right
    out.push(`<rect x="0" y="928" width="${S}" height="96" fill="url(#iwood)"/>`);
    out.push(`<rect x="928" y="0" width="96" height="${S}" fill="url(#iwoodR)"/>`);
    out.push(`<path d="M928 0 V928 H0" fill="none" stroke="#0E1A2A" stroke-opacity=".35" stroke-width="6"/>`);
    out.push(`<path d="M928 0 V928 H0" fill="none" stroke="#7A5A42" stroke-opacity=".5" stroke-width="2" transform="translate(3 3)"/>`);
    // the brass corner where they meet
    out.push(`<path d="M856 856 h100 v100 h-26 v-74 h-74 z" fill="${COL.brassDeep}"/><path d="M852 852 h100 v100 h-26 v-74 h-74 z" fill="${COL.brass}"/><path d="M856 856 h92" stroke="#F0DDA3" stroke-width="4" opacity=".8"/>`);
    // a run of three cards in the hand
    const w = 290, h = w * 1.4;
    out.push(`<ellipse cx="470" cy="700" rx="300" ry="90" fill="#0E1A2A" opacity=".45" filter="url(#ishadow)"/>`);
    out.push(`<g transform="translate(0 -20)">`);
    out.push(card({ x: 270, y: 250, w, rank: '8', suit: 'S', rot: -9 }));
    out.push(card({ x: 350, y: 290, w, rank: '7', suit: 'H', rot: 0, shadow: 9 }));
    out.push(card({ x: 430, y: 330, w, rank: '6', suit: 'C', rot: 9, shadow: 9 }));
    out.push(`</g>`);
    return wrap(out.join(''), S, S);
  }

  return { desk, fans, diary, drawer, icon };
});
