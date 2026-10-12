// Baize · the card, drawn once. Every card in the mocks, the art and the icon comes from here,
// so the geometry DESIGN.md describes (5:7, radius 8% of width, one centre pip, serif indexes
// top-left and upside down bottom-right, brass court emblems) is the same everywhere.
// CardFace.swift reproduces it.
//
// Browser: <script src="cards.js"></script> → window.Cards. Node: require('./cards.js').

(function (root, factory) {
  if (typeof module === 'object' && module.exports) module.exports = factory();
  else root.Cards = factory();
})(typeof self !== 'undefined' ? self : this, function () {
  const COL = {
    stock: '#F6EFE0', ink: '#1E2532', red: '#B8372A', green: '#2F6B45', blue: '#2B5C9B',
    lattice: '#34547A', brass: '#D9B35C', brassDeep: '#A47E35', lamp: '#F3C37A',
    baize: '#34547A', baizeNight: '#14243A', walnut: '#5E4432', walnutNight: '#3A2A1F',
  };

  // Suit pips in a 100×100 box.
  const PIP = {
    S: 'M50 5 C34 28 10 42 10 62 A19 19 0 0 0 45 72 C43 81 38 88 31 95 L69 95 C62 88 57 81 55 72 A19 19 0 0 0 90 62 C90 42 66 28 50 5 Z',
    H: 'M50 92 C24 68 6 52 6 31 A22 22 0 0 1 50 22 A22 22 0 0 1 94 31 C94 52 76 68 50 92 Z',
    C: 'M50 8 A16 16 0 0 1 63 34 A17 17 0 1 1 57 60 C58 74 62 85 70 95 L30 95 C38 85 42 74 43 60 A17 17 0 1 1 37 34 A16 16 0 0 1 50 8 Z',
    D: 'M50 4 Q70 30 92 50 Q70 70 50 96 Q30 70 8 50 Q30 30 50 4 Z',
  };
  const RED = { S: false, H: true, C: false, D: true };
  const NAME = { S: 'spades', H: 'hearts', C: 'clubs', D: 'diamonds' };

  // Court emblems in a 100×60 box, brass.
  const EMBLEM = {
    K: '<path d="M10 52 L10 18 L30 34 L50 6 L70 34 L90 18 L90 52 Z"/><rect x="10" y="52" width="80" height="8" rx="2"/>',
    Q: '<ellipse cx="50" cy="34" rx="36" ry="18" fill="none" stroke-width="7"/><circle cx="50" cy="16" r="7"/>',
    J: '<path d="M22 58 C22 20 46 4 78 6 C70 30 56 50 22 58 Z"/><path d="M26 56 C40 40 52 28 70 12" fill="none" stroke-width="3" stroke-linecap="round"/>',
  };

  function pip(suit, x, y, size, color) {
    const s = size / 100;
    return `<path d="${PIP[suit]}" fill="${color}" transform="translate(${x.toFixed(2)} ${y.toFixed(2)}) scale(${s.toFixed(4)})"/>`;
  }

  function pipColor(suit, o) {
    if (o.fourColour) return { S: o.ink, H: o.red, C: o.green, D: o.blue }[suit];
    return RED[suit] ? o.red : o.ink;
  }

  // One card. x,y top-left; w width; h = 1.4w. rot in degrees about the centre.
  function card(opts) {
    const o = Object.assign({
      x: 0, y: 0, w: 54, rank: 'A', suit: 'S', face: true, rot: 0, back: 'lattice',
      gilt: false, shadow: 0, large: false, fourColour: false, id: '',
      stock: COL.stock, ink: COL.ink, red: COL.red, green: COL.green, blue: COL.blue,
      lattice: COL.lattice, brassDeep: COL.brassDeep, dim: 0,
    }, opts);
    const w = o.w, h = w * 1.4, r = w * 0.08;
    const parts = [];
    if (o.shadow > 0) {
      parts.push(`<rect x="0" y="${(o.shadow * 0.6).toFixed(1)}" width="${w}" height="${h}" rx="${r}" fill="#0E1A2A" opacity="${Math.min(0.45, 0.18 + o.shadow * 0.02).toFixed(2)}" filter="url(#cardShadow${o.shadow >= 8 ? 'Big' : ''})"/>`);
    }
    parts.push(`<rect width="${w}" height="${h}" rx="${r}" fill="${o.stock}"/>`);
    if (o.face) {
      const ink = pipColor(o.suit, o);
      const rank = String(o.rank);
      const court = rank === 'K' || rank === 'Q' || rank === 'J';
      const fs = w * 0.26;
      const idx = (tx, ty, rot) =>
        `<g transform="translate(${tx.toFixed(2)} ${ty.toFixed(2)}) rotate(${rot})">` +
        `<text x="0" y="0" font-family="ui-serif, 'New York', Georgia, serif" font-weight="600" font-size="${fs.toFixed(2)}" fill="${ink}" text-anchor="middle">${rank}</text>` +
        pip(o.suit, -fs * 0.42, fs * 0.22, fs * 0.84, ink) + `</g>`;
      parts.push(idx(w * 0.1 + fs * 0.42, w * 0.11 + fs * 0.78, 0));
      parts.push(idx(w - (w * 0.1 + fs * 0.42), h - (w * 0.11 + fs * 0.78), 180));
      if (rank === 'A') {
        const s = w * 0.62;
        parts.push(pip(o.suit, (w - s) / 2, (h - s) / 2, s, ink));
      } else if (court) {
        const ls = w * 0.48;
        const es = w * 0.26;
        parts.push(`<g fill="${o.brassDeep}" stroke="${o.brassDeep}" transform="translate(${((w - es) / 2).toFixed(2)} ${(h / 2 - ls * 0.5 - es * 0.62).toFixed(2)}) scale(${(es / 100).toFixed(4)})">${EMBLEM[rank]}</g>`);
        parts.push(`<text x="${w / 2}" y="${(h / 2 + ls * 0.36).toFixed(2)}" font-family="ui-serif, 'New York', Georgia, serif" font-weight="600" font-size="${ls.toFixed(2)}" fill="${ink}" text-anchor="middle">${rank}</text>`);
        const ps = w * 0.16;
        parts.push(pip(o.suit, (w - ps) / 2, h / 2 + ls * 0.46, ps, ink));
      } else {
        const s = w * (o.large ? 0.7 : 0.55);
        parts.push(pip(o.suit, (w - s) / 2, (h - s) / 2, s, ink));
      }
    } else {
      parts.push(backPattern(o.back, w, h, o));
    }
    parts.push(`<rect x="0.5" y="0.5" width="${w - 1}" height="${h - 1}" rx="${r}" fill="none" stroke="${o.gilt ? COL.brass : o.ink}" stroke-opacity="${o.gilt ? 0.9 : 0.12}" stroke-width="${o.gilt ? 1.2 : 1}"/>`);
    if (o.dim > 0) parts.push(`<rect width="${w}" height="${h}" rx="${r}" fill="#0E1A2A" opacity="${o.dim}"/>`);
    const cx = o.x + w / 2, cy = o.y + h / 2;
    return `<g ${o.id ? `id="${o.id}" ` : ''}transform="translate(${o.x.toFixed(2)} ${o.y.toFixed(2)})${o.rot ? ` rotate(${o.rot} ${(w / 2).toFixed(2)} ${(h / 2).toFixed(2)})` : ''}">${parts.join('')}</g>`;
  }

  // The backs: a 3pt inset border and a pattern inside it.
  function backPattern(kind, w, h, o) {
    const inset = w * 0.06, r = w * 0.05;
    const iw = w - inset * 2, ih = h - inset * 2;
    const clip = `clip-${Math.random().toString(36).slice(2, 8)}`;
    let fill;
    switch (kind) {
      case 'brassLattice':
      case 'lattice': {
        const c = kind === 'lattice' ? o.lattice : o.brassDeep;
        const p = w * 0.15;
        fill = `<rect x="${inset}" y="${inset}" width="${iw}" height="${ih}" fill="url(#lat-${kind}-${c.slice(1)})"/>`;
        fill = `<defs><pattern id="pt-${clip}" width="${p}" height="${p}" patternUnits="userSpaceOnUse" patternTransform="rotate(45)"><path d="M0 ${p / 2} H${p} M${p / 2} 0 V${p}" stroke="${c}" stroke-width="${(w * 0.022).toFixed(2)}" stroke-opacity="0.9"/></pattern></defs>` +
          `<rect x="${inset}" y="${inset}" width="${iw}" height="${ih}" rx="${r}" fill="url(#pt-${clip})"/>` +
          `<rect x="${inset}" y="${inset}" width="${iw}" height="${ih}" rx="${r}" fill="none" stroke="${c}" stroke-width="${(w * 0.03).toFixed(2)}"/>` +
          `<path d="M${w / 2} ${h / 2 - w * 0.12} L${w / 2 + w * 0.09} ${h / 2} L${w / 2} ${h / 2 + w * 0.12} L${w / 2 - w * 0.09} ${h / 2} Z" fill="${o.stock}" stroke="${c}" stroke-width="${(w * 0.025).toFixed(2)}"/>`;
        break;
      }
      case 'chevron': {
        const p = w * 0.22;
        fill = `<defs><pattern id="pt-${clip}" width="${p}" height="${p * 0.5}" patternUnits="userSpaceOnUse"><path d="M0 ${p * 0.5} L${p / 2} 0 L${p} ${p * 0.5}" fill="none" stroke="${o.lattice}" stroke-width="${(w * 0.03).toFixed(2)}"/></pattern></defs>` +
          `<rect x="${inset}" y="${inset}" width="${iw}" height="${ih}" rx="${r}" fill="url(#pt-${clip})"/><rect x="${inset}" y="${inset}" width="${iw}" height="${ih}" rx="${r}" fill="none" stroke="${o.lattice}" stroke-width="${(w * 0.03).toFixed(2)}"/>`;
        break;
      }
      case 'houndstooth': {
        const p = w * 0.2;
        fill = `<defs><pattern id="pt-${clip}" width="${p}" height="${p}" patternUnits="userSpaceOnUse"><path d="M0 0 H${p / 2} V${p / 2} H0 Z M${p / 2} ${p / 2} H${p} V${p} H${p / 2} Z M${p / 2} 0 L${p} ${p / 2} V0 Z M0 ${p / 2} L${p / 2} ${p} H0 Z" fill="${o.ink}" fill-opacity="0.7"/></pattern></defs>` +
          `<rect x="${inset}" y="${inset}" width="${iw}" height="${ih}" rx="${r}" fill="url(#pt-${clip})"/><rect x="${inset}" y="${inset}" width="${iw}" height="${ih}" rx="${r}" fill="none" stroke="${o.ink}" stroke-opacity="0.7" stroke-width="${(w * 0.03).toFixed(2)}"/>`;
        break;
      }
      case 'stars': {
        const p = w * 0.2, s = w * 0.05;
        fill = `<rect x="${inset}" y="${inset}" width="${iw}" height="${ih}" rx="${r}" fill="${o.lattice}"/>` +
          `<defs><pattern id="pt-${clip}" width="${p}" height="${p}" patternUnits="userSpaceOnUse"><path d="M${p / 2} ${p / 2 - s} Q${p / 2} ${p / 2} ${p / 2 + s} ${p / 2} Q${p / 2} ${p / 2} ${p / 2} ${p / 2 + s} Q${p / 2} ${p / 2} ${p / 2 - s} ${p / 2} Q${p / 2} ${p / 2} ${p / 2} ${p / 2 - s} Z" fill="${COL.brass}"/></pattern></defs>` +
          `<rect x="${inset}" y="${inset}" width="${iw}" height="${ih}" rx="${r}" fill="url(#pt-${clip})"/>`;
        break;
      }
      case 'leaf': {
        fill = `<rect x="${inset}" y="${inset}" width="${iw}" height="${ih}" rx="${r}" fill="none" stroke="${o.green}" stroke-width="${(w * 0.025).toFixed(2)}"/>` +
          `<path d="M${w / 2} ${h * 0.28} C${w * 0.82} ${h * 0.4} ${w * 0.8} ${h * 0.66} ${w / 2} ${h * 0.74} C${w * 0.2} ${h * 0.66} ${w * 0.18} ${h * 0.4} ${w / 2} ${h * 0.28} Z M${w / 2} ${h * 0.3} V${h * 0.72}" fill="none" stroke="${o.green}" stroke-width="${(w * 0.03).toFixed(2)}" stroke-linejoin="round"/>`;
        break;
      }
      case 'seal': {
        const R = w * 0.3;
        const ring = ['S', 'H', 'C', 'D'].map((s, i) => {
          const a = -Math.PI / 2 + i * Math.PI / 2;
          const sz = w * 0.16;
          return pip(s, w / 2 + Math.cos(a) * R * 0.62 - sz / 2, h / 2 + Math.sin(a) * R * 0.62 - sz / 2, sz, o.brassDeep);
        }).join('');
        fill = `<rect x="${inset}" y="${inset}" width="${iw}" height="${ih}" rx="${r}" fill="none" stroke="${o.brassDeep}" stroke-width="${(w * 0.025).toFixed(2)}"/>` +
          `<circle cx="${w / 2}" cy="${h / 2}" r="${R}" fill="none" stroke="${o.brassDeep}" stroke-width="${(w * 0.03).toFixed(2)}"/>${ring}`;
        break;
      }
      default:
        fill = '';
    }
    return fill;
  }

  // A foundation's fan: 13 cards about a pivot at the bottom centre, `spread` degrees apart.
  function fan(suit, cx, cy, w, spread, baseRot, opts) {
    const ranks = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'];
    const h = w * 1.4;
    const out = [];
    ranks.forEach((rank, i) => {
      const a = baseRot + (i - 6) * spread;
      out.push(`<g transform="rotate(${a.toFixed(2)} ${cx} ${cy})">` +
        card(Object.assign({ x: cx - w / 2, y: cy - h, w, rank, suit, shadow: i === 12 ? 3 : 0 }, opts || {})) + `</g>`);
    });
    return out.join('');
  }

  // A seeded fleck field — the cloth's nap — as a <g> of tiny rects.
  function nap(x, y, w, h, seed, opacity, step) {
    let s = seed >>> 0;
    const rnd = () => { s = (s * 1664525 + 1013904223) >>> 0; return s / 4294967296; };
    const st = step || 3;
    const out = [];
    for (let yy = y; yy < y + h; yy += st) for (let xx = x; xx < x + w; xx += st) {
      if (rnd() < 0.42) out.push(`<rect x="${(xx + rnd() * st).toFixed(1)}" y="${(yy + rnd() * st).toFixed(1)}" width="1" height="1"/>`);
    }
    return `<g fill="#FFFFFF" fill-opacity="${opacity}">${out.join('')}</g>`;
  }

  const defs = `<defs>
    <filter id="cardShadow" x="-30%" y="-30%" width="160%" height="170%"><feGaussianBlur stdDeviation="1.6"/></filter>
    <filter id="cardShadowBig" x="-40%" y="-40%" width="180%" height="200%"><feGaussianBlur stdDeviation="6"/></filter>
  </defs>`;

  return { card, fan, pip, nap, defs, COL, PIP, NAME };
});
