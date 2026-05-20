/* Bio — Visual Identity System
 * Definitive design tokens, color palettes, textures, typography, base primitives.
 * Consolidates explorations from Button Styles + Organic Primitives + Box Explorer v3.
 */

// ═══════════════════════════════════════════
// DESIGN TOKENS
// ═══════════════════════════════════════════

const RSUF = "'RuneScape UF', sans-serif";

// ─── KINGDOM PALETTES ───
const K = {
  plantae: {
    id: 'plantae',
    name: 'Plantae',
    identity: 'Light-driven · Slow compounding · Surface layer',
    bg:         '#14100a',
    surface:    '#1e2818',
    surfaceMid: '#242e1c',
    border:     '#3a4a2a',
    borderHi:   '#4a5a38',
    borderLo:   '#1a2a12',
    accent:     '#5a9a3a',
    accentLight:'#7eba5a',
    accentBright:'#a8e078',
    accentDim:  '#3a6a2a',
    text:       '#8aaa5a',
    textDim:    '#4a6a2a',
    textBright: '#b8d87a',
    glow:       '#4a8a3a',
  },
  fungi: {
    id: 'fungi',
    name: 'Fungi',
    identity: 'Decay-driven · Network spreader · Subsurface',
    bg:         '#0e0a14',
    surface:    '#16121e',
    surfaceMid: '#1c1826',
    border:     '#3a2a44',
    borderHi:   '#4a3a54',
    borderLo:   '#1a1228',
    accent:     '#7a4a9a',
    accentLight:'#aa7aca',
    accentBright:'#d0a8f0',
    accentDim:  '#4a2a5a',
    text:       '#9a7aba',
    textDim:    '#5a4a6a',
    textBright: '#c8a8e8',
    glow:       '#6a3a8a',
  },
  animals: {
    id: 'animals',
    name: 'Animals',
    identity: 'Mobile · Range-based · Protein-driven',
    bg:         '#12100a',
    surface:    '#2a2218',
    surfaceMid: '#302818',
    border:     '#4a3a22',
    borderHi:   '#5a4a2a',
    borderLo:   '#2a1e12',
    accent:     '#ba8a4a',
    accentLight:'#daa85a',
    accentBright:'#f0c878',
    accentDim:  '#6a4a2a',
    text:       '#c8a858',
    textDim:    '#7a6a3a',
    textBright: '#f0d880',
    glow:       '#8a6a2a',
  },
  hybrid: {
    id: 'hybrid',
    name: 'Symbiosis',
    identity: 'Layered lifeforms · Cross-kingdom composites',
    bg:         '#0a1010',
    surface:    '#121e1e',
    surfaceMid: '#182424',
    border:     '#1a3a34',
    borderHi:   '#2a4a44',
    borderLo:   '#0a1a18',
    accent:     '#3a8a7a',
    accentLight:'#5aaa98',
    accentBright:'#88d8c8',
    accentDim:  '#1a4a4a',
    text:       '#5a9a8a',
    textDim:    '#3a6a5a',
    textBright: '#88c8b8',
    glow:       '#3a7a6a',
  },
};

// ─── RESOURCE COLORS (shared across all kingdoms) ───
const RES = {
  biomass:    { color: '#7eba5a', label: 'Biomass',    icon: '●' },
  nutrients:  { color: '#d8b858', label: 'Nutrients',   icon: '◆' },
  sunlight:   { color: '#88ccee', label: 'Sunlight',    icon: '☀' },
  decay:      { color: '#aa7aca', label: 'Decay',       icon: '◎' },
  spores:     { color: '#7a9aba', label: 'Spores',      icon: '○' },
  protein:    { color: '#daa85a', label: 'Protein',     icon: '▲' },
  lifeforce:  { color: '#c85a5a', label: 'Lifeforce',   icon: '♥' },
  pollination:{ color: '#b8c84a', label: 'Pollination', icon: '✿' },
  cellulose:  { color: '#8aaa6a', label: 'Cellulose',   icon: '▬' },
  chitin:     { color: '#9a8a6a', label: 'Chitin',      icon: '◇' },
  phosphate:  { color: '#6a9aba', label: 'Phosphate',   icon: '△' },
  ep:         { color: '#e8d070', label: 'EP',          icon: '★' },
};

// ─── UTILITY COLORS ───
const UTIL = {
  danger:   '#9a4a4a',
  dangerHi: '#ba5a5a',
  warning:  '#c89a3a',
  warningHi:'#e8ba5a',
  disabled: '#4a4a4a',
  disabledText: '#555',
  success:  '#5a9a4a',
  xpBar:    '#5888b8',
  black:    '#0c0a08',
};

// ─── DITHER TEXTURES ───
const D = {
  crossHatch: (c, bg, g=5) => ({ backgroundImage: `repeating-linear-gradient(0deg,${c} 0px,${c} 1px,transparent 1px,transparent ${g}px),repeating-linear-gradient(90deg,${c} 0px,${c} 1px,transparent 1px,transparent ${g}px)`, backgroundColor: bg }),
  dots: (c, bg, s=4) => ({ backgroundImage: `radial-gradient(circle,${c} 1px,transparent 1px)`, backgroundSize: `${s}px ${s}px`, backgroundColor: bg }),
  stipple: (c, bg) => ({ backgroundImage: `radial-gradient(circle at 20% 30%,${c} .5px,transparent .5px),radial-gradient(circle at 60% 10%,${c} .5px,transparent .5px),radial-gradient(circle at 40% 70%,${c} .5px,transparent .5px),radial-gradient(circle at 80% 50%,${c} .5px,transparent .5px),radial-gradient(circle at 10% 80%,${c} .5px,transparent .5px),radial-gradient(circle at 90% 90%,${c} .5px,transparent .5px),radial-gradient(circle at 30% 50%,${c} .5px,transparent .5px),radial-gradient(circle at 70% 30%,${c} .5px,transparent .5px)`, backgroundSize: '8px 8px', backgroundColor: bg }),
  hLines: (c, bg, g=4) => ({ backgroundImage: `repeating-linear-gradient(0deg,${c} 0px,${c} 1px,transparent 1px,transparent ${g}px)`, backgroundColor: bg }),
  checker: (a, b) => ({ backgroundImage: `linear-gradient(45deg,${a} 25%,transparent 25%),linear-gradient(-45deg,${a} 25%,transparent 25%),linear-gradient(45deg,transparent 75%,${a} 75%),linear-gradient(-45deg,transparent 75%,${a} 75%)`, backgroundSize: '4px 4px', backgroundPosition: '0 0,0 2px,2px -2px,-2px 0px', backgroundColor: b }),
};

// ─── PIXEL MICRO-BACKGROUNDS ───
const PBG = {
  grass: (bg) => ({ backgroundImage: `url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='16' height='16'%3E%3Crect x='7' y='4' width='2' height='8' fill='%233a6a2a' opacity='.1'/%3E%3Crect x='5' y='6' width='2' height='2' fill='%234a8a3a' opacity='.08'/%3E%3Crect x='9' y='5' width='2' height='2' fill='%232a5a1a' opacity='.09'/%3E%3C/svg%3E")`, backgroundSize: '16px 16px', backgroundColor: bg }),
  mushroom: (bg) => ({ backgroundImage: `url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='28' height='28'%3E%3Crect x='10' y='8' width='8' height='4' fill='%235a3a7a' opacity='.09'/%3E%3Crect x='12' y='6' width='4' height='2' fill='%236a4a8a' opacity='.07'/%3E%3Crect x='13' y='12' width='2' height='6' fill='%233a2a4a' opacity='.08'/%3E%3C/svg%3E")`, backgroundSize: '28px 28px', backgroundColor: bg }),
  spore: (bg) => ({ backgroundImage: `url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='20' height='20'%3E%3Ccircle cx='5' cy='5' r='1' fill='%236a4a8a' opacity='.1'/%3E%3Ccircle cx='15' cy='8' r='1' fill='%235a3a7a' opacity='.08'/%3E%3Ccircle cx='8' cy='16' r='1' fill='%237a5a9a' opacity='.06'/%3E%3Ccircle cx='18' cy='18' r='1' fill='%234a2a6a' opacity='.09'/%3E%3C/svg%3E")`, backgroundSize: '20px 20px', backgroundColor: bg }),
  bone: (bg) => ({ backgroundImage: `url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='20' height='20'%3E%3Crect x='3' y='8' width='6' height='3' fill='%236a5a3a' opacity='.06'/%3E%3Crect x='12' y='14' width='5' height='2' fill='%235a4a2a' opacity='.05'/%3E%3C/svg%3E")`, backgroundSize: '20px 20px', backgroundColor: bg }),
  lichen: (bg) => ({ backgroundImage: `url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='24' height='24'%3E%3Ccircle cx='6' cy='8' r='3' fill='%232a6a5a' opacity='.06'/%3E%3Ccircle cx='18' cy='16' r='4' fill='%233a7a6a' opacity='.05'/%3E%3C/svg%3E")`, backgroundSize: '24px 24px', backgroundColor: bg }),
};

// ─── TEXTURE PRESETS PER KINGDOM ───
function kTex(k, variant) {
  const v = variant || 'default';
  if (k.id === 'plantae') {
    if (v === 'primary') return { ...D.crossHatch(k.accentDim+'12', k.surface, 5), ...PBG.grass('transparent') };
    if (v === 'secondary') return D.stipple(k.accentDim+'28', k.surface);
    return D.crossHatch(k.accentDim+'12', k.surface, 5);
  }
  if (k.id === 'fungi') {
    if (v === 'primary') return { ...D.stipple(k.accentDim+'28', k.surface), ...PBG.mushroom('transparent') };
    if (v === 'secondary') return D.crossHatch(k.accentDim+'10', k.surface, 5);
    return D.stipple(k.accentDim+'28', k.surface);
  }
  if (k.id === 'animals') {
    if (v === 'primary') return { ...D.crossHatch('#5a4a2a10', k.surface, 5), ...PBG.bone('transparent') };
    if (v === 'secondary') return D.dots('#5a4a2a18', k.surface, 3);
    return D.crossHatch('#5a4a2a10', k.surface, 5);
  }
  // hybrid
  if (v === 'primary') return { ...D.crossHatch('#1a4a4a10', k.surface, 5), ...PBG.lichen('transparent') };
  if (v === 'secondary') return D.stipple('#2a5a5a28', k.surface);
  return D.crossHatch('#1a4a4a10', k.surface, 5);
}

// ─── BORDER HELPER ───
function kBorder(k) {
  return { border: '2px solid '+k.border, borderTopColor: k.borderHi, borderLeftColor: k.borderHi, borderBottomColor: k.borderLo, borderRightColor: k.borderLo };
}
function kBorderSimple(k) {
  return { border: '2px solid '+k.border, borderTopColor: k.borderHi, borderLeftColor: k.borderHi };
}

// ─── VINE/SPORE GLOW (top accent line) ───
function GlowLine({ color }) {
  return <div style={{ position:'absolute',top:-1,left:0,right:0,height:2,background:`linear-gradient(90deg,transparent,${color}44,${color}77,${color}44,transparent)` }}></div>;
}

// ─── CORNER RIVETS ───
function Rivets({ color, size=3 }) {
  const s = { position:'absolute', width:size, height:size, background:color };
  return <React.Fragment>
    <div style={{...s,top:1,left:1}}></div><div style={{...s,top:1,right:1}}></div>
    <div style={{...s,bottom:1,left:1}}></div><div style={{...s,bottom:1,right:1}}></div>
  </React.Fragment>;
}

// ═══════════════════════════════════════════
// BASE COMPONENTS
// ═══════════════════════════════════════════

// ─── BUTTON ───
function BioBtn({ k, children, primary, secondary, glow, rivets, tex, style: extra }) {
  const t = tex || (primary ? kTex(k, 'primary') : secondary ? kTex(k, 'secondary') : kTex(k));
  const b = primary ? kBorder(k) : kBorderSimple(k);
  const color = primary ? k.textBright : secondary ? k.textDim : k.text;
  return (
    <div style={{ position:'relative', overflow:'hidden', ...b, padding:'5px 16px', cursor:'pointer', ...extra }}>
      <div style={{ position:'absolute', inset:0, ...t }}></div>
      {glow && <GlowLine color={k.glow} />}
      {rivets && <Rivets color={k.accentDim} />}
      <span style={{ position:'relative', zIndex:1, fontFamily:RSUF, fontSize:18, color }}>{children}</span>
    </div>
  );
}

// ─── BOX / PANEL ───
function BioBox({ k, children, glow, rivets, tex, style: extra }) {
  const t = tex || kTex(k);
  return (
    <div style={{ position:'relative', overflow:'hidden', ...kBorder(k), padding:10, ...extra }}>
      <div style={{ position:'absolute', inset:0, ...t }}></div>
      {glow && <GlowLine color={k.glow} />}
      {rivets && <Rivets color={k.accentDim} />}
      <div style={{ position:'relative', zIndex:1 }}>{children}</div>
    </div>
  );
}

// ─── PROGRESS BAR ───
function BioBar({ k, value, max, color, label, height=8, style: extra }) {
  const pct = Math.min(100, (value / max) * 100);
  const c = color || k.accent;
  return (
    <div style={{ ...extra }}>
      {label && <div style={{ fontFamily:RSUF, fontSize:11, color:k.textDim, marginBottom:2 }}>{label}</div>}
      <div style={{ position:'relative', height, background:k.bg, border:`1px solid ${k.border}`, overflow:'hidden' }}>
        <div style={{ position:'absolute', top:0, left:0, bottom:0, width:pct+'%', background:c, boxShadow:`inset 0 1px 0 ${c}88` }}></div>
        <div style={{ position:'absolute', inset:0, ...D.hLines(k.borderLo+'22', 'transparent', 3) }}></div>
      </div>
    </div>
  );
}

// ─── RESOURCE COUNTER ───
function BioResource({ res, value, rate, k }) {
  const r = RES[res] || { color:'#888', label:res, icon:'?' };
  return (
    <div style={{ display:'flex', alignItems:'center', gap:4 }}>
      <div style={{ width:12, height:12, background:r.color, border:`2px solid ${r.color}44`, borderTopColor:r.color+'cc', borderLeftColor:r.color+'cc', boxShadow:`inset 1px 1px 0 ${r.color}88`, borderRadius: r.icon === '◆' ? 0 : 2, transform: r.icon === '◆' ? 'rotate(45deg) scale(0.8)' : 'none' }}></div>
      <div>
        <div style={{ fontFamily:RSUF, fontSize:14, color:r.color, lineHeight:1.1 }}>{value}</div>
        {rate && <div style={{ fontFamily:RSUF, fontSize:9, color:r.color+'88', lineHeight:1 }}>{rate}</div>}
      </div>
    </div>
  );
}

// ─── DIVIDER ───
function BioDivider({ k }) {
  return (
    <div style={{ position:'relative', height:4, margin:'6px 0' }}>
      <div style={{ position:'absolute', top:1, left:0, right:0, height:2, background:k.border }}></div>
      <div style={{ position:'absolute', top:0, left:0, right:0, height:1, background:k.borderHi, opacity:0.4 }}></div>
    </div>
  );
}

// ─── TAB ───
function BioTab({ k, label, active }) {
  return (
    <div style={{
      padding:'4px 12px',
      fontFamily:RSUF, fontSize:14,
      color: active ? k.textBright : k.textDim,
      background: active ? k.surface : 'transparent',
      borderBottom: active ? `2px solid ${k.accent}` : '2px solid transparent',
      cursor:'pointer',
    }}>{label}</div>
  );
}

// ─── BADGE ───
function BioBadge({ k, label, bright }) {
  return (
    <span style={{
      display:'inline-block', padding:'2px 8px',
      fontFamily:RSUF, fontSize:11,
      color: bright ? k.bg : k.text,
      background: bright ? k.accent : k.surface,
      border:`1px solid ${bright ? k.accentLight : k.border}`,
    }}>{label}</span>
  );
}

// ─── TOOLTIP / INFO BOX ───
function BioTooltip({ k, title, children }) {
  return (
    <div style={{ position:'relative', ...kBorder(k), background:k.bg+'EE', padding:8, maxWidth:200, boxShadow:`0 4px 12px #00000088` }}>
      <div style={{ position:'absolute', inset:0, ...D.dots(k.border+'10', 'transparent', 6) }}></div>
      <div style={{ position:'relative', zIndex:1 }}>
        {title && <div style={{ fontFamily:RSUF, fontSize:14, color:k.textBright, marginBottom:4 }}>{title}</div>}
        <div style={{ fontFamily:RSUF, fontSize:12, color:k.textDim, lineHeight:1.4 }}>{children}</div>
      </div>
    </div>
  );
}

// ─── EVENT TOAST ───
function BioToast({ k, title, body, icon }) {
  return (
    <div style={{ position:'relative', overflow:'hidden', ...kBorder(k), padding:'6px 10px', display:'flex', gap:8, alignItems:'center' }}>
      <div style={{ position:'absolute', inset:0, ...kTex(k, 'secondary') }}></div>
      <GlowLine color={k.glow} />
      {icon && <div style={{ position:'relative', zIndex:1, width:24, height:24, background:k.accent, border:`2px solid ${k.accentLight}`, borderBottomColor:k.borderLo, borderRightColor:k.borderLo, display:'flex', alignItems:'center', justifyContent:'center', fontFamily:RSUF, fontSize:14, color:k.bg }}>{icon}</div>}
      <div style={{ position:'relative', zIndex:1, flex:1 }}>
        <div style={{ fontFamily:RSUF, fontSize:14, color:k.textBright }}>{title}</div>
        {body && <div style={{ fontFamily:RSUF, fontSize:11, color:k.textDim, lineHeight:1.3 }}>{body}</div>}
      </div>
    </div>
  );
}

// ─── EVOLUTION NODE ───
function BioEvoNode({ k, label, cost, purchased, locked }) {
  const bg = purchased ? k.accent : locked ? k.bg : k.surface;
  const borderC = purchased ? k.accentLight : locked ? k.border+'66' : k.border;
  const textC = purchased ? k.bg : locked ? k.textDim+'66' : k.text;
  return (
    <div style={{ width:72, textAlign:'center' }}>
      <div style={{
        width:40, height:40, margin:'0 auto 4px',
        background:bg, border:`2px solid ${borderC}`,
        borderTopColor: purchased ? k.accentBright : borderC,
        borderLeftColor: purchased ? k.accentBright : borderC,
        display:'flex', alignItems:'center', justifyContent:'center',
        opacity: locked ? 0.4 : 1,
      }}>
        <span style={{ fontFamily:RSUF, fontSize:16, color:textC }}>{purchased ? '✓' : locked ? '?' : '◆'}</span>
      </div>
      <div style={{ fontFamily:RSUF, fontSize:10, color:textC, lineHeight:1.2 }}>{label}</div>
      {cost && !purchased && <div style={{ fontFamily:RSUF, fontSize:9, color:RES.ep.color+'88' }}>★{cost}</div>}
    </div>
  );
}

// Export everything
Object.assign(window, {
  RSUF, K, RES, UTIL, D, PBG,
  kTex, kBorder, kBorderSimple, GlowLine, Rivets,
  BioBtn, BioBox, BioBar, BioResource, BioDivider,
  BioTab, BioBadge, BioTooltip, BioToast, BioEvoNode,
});
