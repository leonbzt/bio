/* Bio — Visual Identity Artboard Content
 * Color palettes, typography, component library, screen mockups.
 */

// ═══════════════════════════════════════════
// SECTION 1: COLOR SYSTEM
// ═══════════════════════════════════════════

function ColorSwatch({ color, label, hex, size=40 }) {
  return (
    <div style={{ display:'flex', flexDirection:'column', alignItems:'center', gap:2 }}>
      <div style={{ width:size, height:size, background:color, border:'1px solid #ffffff10' }}></div>
      {label && <div style={{ fontFamily:RSUF, fontSize:9, color:'#888', textAlign:'center', lineHeight:1.1 }}>{label}</div>}
      <div style={{ fontFamily:RSUF, fontSize:8, color:'#555', textAlign:'center' }}>{hex || color}</div>
    </div>
  );
}

function KingdomPaletteCard({ k }) {
  return (
    <div style={{ background:k.bg, border:`2px solid ${k.border}`, padding:12, width:260 }}>
      {/* Header */}
      <div style={{ fontFamily:RSUF, fontSize:22, color:k.text, marginBottom:2 }}>{k.name}</div>
      <div style={{ fontFamily:RSUF, fontSize:11, color:k.textDim, marginBottom:12 }}>{k.identity}</div>

      {/* Backgrounds */}
      <div style={{ fontFamily:RSUF, fontSize:10, color:k.textDim, marginBottom:4 }}>BACKGROUNDS</div>
      <div style={{ display:'flex', gap:6, marginBottom:10, flexWrap:'wrap' }}>
        <ColorSwatch color={k.bg} label="bg" size={32} />
        <ColorSwatch color={k.surface} label="surface" size={32} />
        <ColorSwatch color={k.surfaceMid} label="surfaceMid" size={32} />
      </div>

      {/* Borders */}
      <div style={{ fontFamily:RSUF, fontSize:10, color:k.textDim, marginBottom:4 }}>BORDERS</div>
      <div style={{ display:'flex', gap:6, marginBottom:10, flexWrap:'wrap' }}>
        <ColorSwatch color={k.borderLo} label="borderLo" size={32} />
        <ColorSwatch color={k.border} label="border" size={32} />
        <ColorSwatch color={k.borderHi} label="borderHi" size={32} />
      </div>

      {/* Accents */}
      <div style={{ fontFamily:RSUF, fontSize:10, color:k.textDim, marginBottom:4 }}>ACCENTS</div>
      <div style={{ display:'flex', gap:6, marginBottom:10, flexWrap:'wrap' }}>
        <ColorSwatch color={k.accentDim} label="dim" size={32} />
        <ColorSwatch color={k.accent} label="accent" size={32} />
        <ColorSwatch color={k.accentLight} label="light" size={32} />
        <ColorSwatch color={k.accentBright} label="bright" size={32} />
        <ColorSwatch color={k.glow} label="glow" size={32} />
      </div>

      {/* Text */}
      <div style={{ fontFamily:RSUF, fontSize:10, color:k.textDim, marginBottom:4 }}>TEXT</div>
      <div style={{ display:'flex', gap:6, marginBottom:10 }}>
        <ColorSwatch color={k.textDim} label="dim" size={32} />
        <ColorSwatch color={k.text} label="text" size={32} />
        <ColorSwatch color={k.textBright} label="bright" size={32} />
      </div>

      {/* Sample button + box */}
      <div style={{ fontFamily:RSUF, fontSize:10, color:k.textDim, marginBottom:6 }}>IN CONTEXT</div>
      <div style={{ display:'flex', gap:6 }}>
        <BioBtn k={k} primary glow>Begin Run</BioBtn>
        <BioBtn k={k} secondary>Settings</BioBtn>
      </div>
    </div>
  );
}

function ColorSystemArtboard() {
  return (
    <div style={{ padding:20, background:'#0c0a08', height:'100%' }}>
      <div style={{ fontFamily:RSUF, fontSize:14, color:'#888', marginBottom:16 }}>Each kingdom has a complete palette. UI shifts color temperature when the active kingdom changes — same structure, different hues.</div>
      <div style={{ display:'flex', gap:12, flexWrap:'wrap' }}>
        {[K.plantae, K.fungi, K.animals, K.hybrid].map(k => (
          <KingdomPaletteCard key={k.id} k={k} />
        ))}
      </div>
    </div>
  );
}

function ResourceColorsArtboard() {
  const resources = ['biomass','nutrients','sunlight','decay','spores','protein','lifeforce','pollination','cellulose','chitin','phosphate','ep'];
  return (
    <div style={{ padding:20, background:'#0c0a08', height:'100%' }}>
      <div style={{ fontFamily:RSUF, fontSize:14, color:'#888', marginBottom:16 }}>Resource colors are shared across all kingdoms. Each resource has a fixed color that never changes regardless of which kingdom is active.</div>

      <div style={{ display:'grid', gridTemplateColumns:'repeat(6, 1fr)', gap:8, marginBottom:20 }}>
        {resources.map(rid => {
          const r = RES[rid];
          return (
            <div key={rid} style={{ background:'#14120e', border:'1px solid #2a2820', padding:8, textAlign:'center' }}>
              <div style={{ width:28, height:28, background:r.color, border:`2px solid ${r.color}44`, borderTopColor:r.color+'cc', margin:'0 auto 6px' }}></div>
              <div style={{ fontFamily:RSUF, fontSize:12, color:r.color }}>{r.label}</div>
              <div style={{ fontFamily:RSUF, fontSize:9, color:'#666' }}>{r.color}</div>
              <div style={{ fontFamily:RSUF, fontSize:14, color:'#888', marginTop:2 }}>{r.icon}</div>
            </div>
          );
        })}
      </div>

      {/* Utility colors */}
      <div style={{ fontFamily:RSUF, fontSize:16, color:'#aaa', marginBottom:8 }}>Utility Colors</div>
      <div style={{ display:'flex', gap:8 }}>
        {[
          { c:UTIL.danger, l:'Danger' }, { c:UTIL.warning, l:'Warning' },
          { c:UTIL.success, l:'Success' }, { c:UTIL.disabled, l:'Disabled' },
          { c:UTIL.xpBar, l:'XP Bar' }, { c:UTIL.black, l:'True Black' },
        ].map(u => (
          <div key={u.l} style={{ background:'#14120e', border:'1px solid #2a2820', padding:8, textAlign:'center', width:80 }}>
            <div style={{ width:28, height:28, background:u.c, margin:'0 auto 4px' }}></div>
            <div style={{ fontFamily:RSUF, fontSize:11, color:u.c }}>{u.l}</div>
            <div style={{ fontFamily:RSUF, fontSize:9, color:'#555' }}>{u.c}</div>
          </div>
        ))}
      </div>
    </div>
  );
}

// ═══════════════════════════════════════════
// SECTION 2: TYPOGRAPHY
// ═══════════════════════════════════════════

function TypographyArtboard() {
  const k = K.plantae;
  const sizes = [
    { size:28, role:'Screen Title', sample:'Evolution Tree', color:k.textBright },
    { size:22, role:'Section Header', sample:'Plantae Buttons', color:k.text },
    { size:18, role:'Button / Card Title', sample:'Begin Run', color:k.text },
    { size:16, role:'Subtitle / Label', sample:'Biomass', color:k.text },
    { size:14, role:'Body Text', sample:'Unleash spores that damage all herbivores in range.', color:k.textDim },
    { size:12, role:'Caption / Rate', sample:'+12/tick · Costs 50 Biomass', color:k.textDim },
    { size:11, role:'Badge / Tag', sample:'PHOTOSYNTHESIZER', color:k.textDim },
    { size:9,  role:'Micro / Hint', sample:'Discoveries: 23/57', color:k.textDim+'aa' },
  ];
  return (
    <div style={{ padding:20, background:'#0c0a08', height:'100%' }}>
      <div style={{ fontFamily:RSUF, fontSize:14, color:'#888', marginBottom:6 }}>
        RuneScape UF — the sole typeface. No bold/italic variants. Hierarchy is established through size, color intensity, and spacing alone.
      </div>
      <div style={{ fontFamily:RSUF, fontSize:11, color:'#555', marginBottom:16 }}>
        Font loads from cdnfonts.com + onlinewebfonts.com fallback. In Godot, use the .ttf directly.
      </div>
      <div style={{ display:'flex', flexDirection:'column', gap:2 }}>
        {sizes.map(s => (
          <div key={s.size} style={{ display:'flex', alignItems:'baseline', gap:12, padding:'6px 0', borderBottom:'1px solid #1a1814' }}>
            <div style={{ width:32, fontFamily:RSUF, fontSize:11, color:'#555', textAlign:'right', flexShrink:0 }}>{s.size}px</div>
            <div style={{ width:120, fontFamily:RSUF, fontSize:10, color:'#666', flexShrink:0 }}>{s.role}</div>
            <div style={{ fontFamily:RSUF, fontSize:s.size, color:s.color, lineHeight:1.2 }}>{s.sample}</div>
          </div>
        ))}
      </div>

      {/* Kingdom text color samples */}
      <div style={{ fontFamily:RSUF, fontSize:16, color:'#aaa', margin:'20px 0 8px' }}>Kingdom Text Colors</div>
      <div style={{ display:'flex', gap:16 }}>
        {[K.plantae, K.fungi, K.animals, K.hybrid].map(kk => (
          <div key={kk.id} style={{ background:kk.bg, border:`1px solid ${kk.border}`, padding:10, width:140 }}>
            <div style={{ fontFamily:RSUF, fontSize:18, color:kk.textBright, marginBottom:2 }}>{kk.name}</div>
            <div style={{ fontFamily:RSUF, fontSize:14, color:kk.text }}>Primary text</div>
            <div style={{ fontFamily:RSUF, fontSize:12, color:kk.textDim }}>Secondary text</div>
          </div>
        ))}
      </div>
    </div>
  );
}

// ═══════════════════════════════════════════
// SECTION 3: COMPONENT LIBRARY
// ═══════════════════════════════════════════

function ButtonLibraryArtboard() {
  const k = K.plantae;
  const kf = K.fungi;
  return (
    <div style={{ padding:20, background:'#0c0a08', height:'100%' }}>
      <div style={{ fontFamily:RSUF, fontSize:14, color:'#888', marginBottom:16 }}>Definitive button set. Three tiers: Primary (glow + texture), Standard, Secondary (subtle). Each adapts per kingdom.</div>

      <div style={{ display:'flex', gap:24 }}>
        {/* Plantae column */}
        <div style={{ flex:1 }}>
          <div style={{ fontFamily:RSUF, fontSize:16, color:k.text, marginBottom:8 }}>Plantae</div>
          <div style={{ display:'flex', flexDirection:'column', gap:6, background:k.bg, padding:10, border:`1px solid ${k.border}` }}>
            <div style={{ fontFamily:RSUF, fontSize:10, color:k.textDim }}>PRIMARY</div>
            <BioBtn k={k} primary glow rivets>Begin Run</BioBtn>
            <div style={{ fontFamily:RSUF, fontSize:10, color:k.textDim, marginTop:4 }}>STANDARD</div>
            <div style={{ display:'flex', gap:6 }}>
              <BioBtn k={k}>Grow</BioBtn>
              <BioBtn k={k}>Evolve</BioBtn>
              <BioBtn k={k}>Toxin</BioBtn>
            </div>
            <div style={{ fontFamily:RSUF, fontSize:10, color:k.textDim, marginTop:4 }}>SECONDARY</div>
            <div style={{ display:'flex', gap:6 }}>
              <BioBtn k={k} secondary>Settings</BioBtn>
              <BioBtn k={k} secondary>Back</BioBtn>
            </div>
            <div style={{ fontFamily:RSUF, fontSize:10, color:k.textDim, marginTop:4 }}>LARGE ACTION</div>
            <BioBtn k={k} primary glow style={{ textAlign:'center' }}>Evolution Tree</BioBtn>
          </div>
        </div>

        {/* Fungi column */}
        <div style={{ flex:1 }}>
          <div style={{ fontFamily:RSUF, fontSize:16, color:kf.text, marginBottom:8 }}>Fungi</div>
          <div style={{ display:'flex', flexDirection:'column', gap:6, background:kf.bg, padding:10, border:`1px solid ${kf.border}` }}>
            <div style={{ fontFamily:RSUF, fontSize:10, color:kf.textDim }}>PRIMARY</div>
            <BioBtn k={kf} primary glow rivets>Begin Run</BioBtn>
            <div style={{ fontFamily:RSUF, fontSize:10, color:kf.textDim, marginTop:4 }}>STANDARD</div>
            <div style={{ display:'flex', gap:6 }}>
              <BioBtn k={kf}>Spread</BioBtn>
              <BioBtn k={kf}>Infect</BioBtn>
              <BioBtn k={kf}>Network</BioBtn>
            </div>
            <div style={{ fontFamily:RSUF, fontSize:10, color:kf.textDim, marginTop:4 }}>SECONDARY</div>
            <div style={{ display:'flex', gap:6 }}>
              <BioBtn k={kf} secondary>Settings</BioBtn>
              <BioBtn k={kf} secondary>Back</BioBtn>
            </div>
            <div style={{ fontFamily:RSUF, fontSize:10, color:kf.textDim, marginTop:4 }}>LARGE ACTION</div>
            <BioBtn k={kf} primary glow style={{ textAlign:'center' }}>Spore Burst</BioBtn>
          </div>
        </div>

        {/* Utility */}
        <div style={{ flex:1 }}>
          <div style={{ fontFamily:RSUF, fontSize:16, color:'#aaa', marginBottom:8 }}>Utility</div>
          <div style={{ display:'flex', flexDirection:'column', gap:6, background:'#12100a', padding:10, border:'1px solid #2a2820' }}>
            <div style={{ fontFamily:RSUF, fontSize:10, color:'#666' }}>WARNING</div>
            <BioBtn k={{...k, accent:'#aa7a2a', accentDim:'#5a3a1a', glow:'#aa7a2a', text:'#c89a3a', textBright:'#e8ba5a', surface:'#1e1a14', border:'#4a3a1a', borderHi:'#5a4a2a', borderLo:'#2a1e0a'}} glow>Prestige (24 EP)</BioBtn>
            <div style={{ fontFamily:RSUF, fontSize:10, color:'#666', marginTop:4 }}>DANGER</div>
            <BioBtn k={{...k, accent:'#7a3a3a', accentDim:'#4a2a2a', text:'#9a5a5a', textBright:'#ba6a6a', surface:'#1e1418', border:'#4a2a2a', borderHi:'#5a3a3a', borderLo:'#2a1a1a'}} >Reset Save</BioBtn>
            <div style={{ fontFamily:RSUF, fontSize:10, color:'#666', marginTop:4 }}>DISABLED</div>
            <BioBtn k={{...k, text:'#555', textDim:'#444', surface:'#1a1a1a', border:'#2a2a2a', borderHi:'#333', borderLo:'#1a1a1a', accentDim:'#2a2a2a'}}>Locked</BioBtn>
          </div>
        </div>
      </div>
    </div>
  );
}

function ComponentLibraryArtboard() {
  const k = K.plantae;
  const kf = K.fungi;
  return (
    <div style={{ padding:20, background:'#0c0a08', height:'100%' }}>
      <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:16 }}>

        {/* Progress Bars */}
        <div>
          <div style={{ fontFamily:RSUF, fontSize:16, color:'#aaa', marginBottom:8 }}>Progress Bars</div>
          <BioBox k={k} style={{ marginBottom:8 }}>
            <BioBar k={k} value={750} max={1000} color={RES.biomass.color} label="Biomass 750/1,000" />
            <div style={{ height:6 }}></div>
            <BioBar k={k} value={340} max={500} color={RES.nutrients.color} label="Nutrients 340/500" />
            <div style={{ height:6 }}></div>
            <BioBar k={k} value={180} max={952} color={UTIL.xpBar} label="XP 180/952" height={6} />
          </BioBox>
          <BioBox k={kf} style={{ marginBottom:8 }}>
            <BioBar k={kf} value={890} max={1200} color={RES.decay.color} label="Decay 890/1,200" />
            <div style={{ height:6 }}></div>
            <BioBar k={kf} value={45} max={100} color={RES.spores.color} label="Spores 45/100" />
          </BioBox>
        </div>

        {/* Resource Counters */}
        <div>
          <div style={{ fontFamily:RSUF, fontSize:16, color:'#aaa', marginBottom:8 }}>Resource Counters</div>
          <BioBox k={k} style={{ marginBottom:8 }}>
            <div style={{ display:'flex', gap:12, flexWrap:'wrap' }}>
              <BioResource res="biomass" value="1,240" rate="+12/tick" k={k} />
              <BioResource res="nutrients" value="340" rate="+3/tick" k={k} />
              <BioResource res="sunlight" value="12" k={k} />
            </div>
          </BioBox>
          <BioBox k={kf} style={{ marginBottom:8 }}>
            <div style={{ display:'flex', gap:12, flexWrap:'wrap' }}>
              <BioResource res="decay" value="890" rate="+8/tick" k={kf} />
              <BioResource res="spores" value="45" k={kf} />
              <BioResource res="nutrients" value="210" rate="+3/tick" k={kf} />
            </div>
          </BioBox>
          <div style={{ fontFamily:RSUF, fontSize:12, color:'#666', marginBottom:6 }}>Stub resources (greyed, coming soon)</div>
          <BioBox k={k}>
            <div style={{ display:'flex', gap:12, flexWrap:'wrap', opacity:0.35 }}>
              <BioResource res="protein" value="—" k={k} />
              <BioResource res="cellulose" value="—" k={k} />
              <BioResource res="chitin" value="—" k={k} />
              <BioResource res="phosphate" value="—" k={k} />
            </div>
          </BioBox>
        </div>

        {/* Tabs & Badges */}
        <div>
          <div style={{ fontFamily:RSUF, fontSize:16, color:'#aaa', marginBottom:8 }}>Tabs & Badges</div>
          <div style={{ background:K.plantae.bg, border:`1px solid ${K.plantae.border}`, padding:8, marginBottom:8 }}>
            <div style={{ display:'flex', gap:0, borderBottom:`1px solid ${K.plantae.border}`, marginBottom:8 }}>
              <BioTab k={K.plantae} label="Evolution" active />
              <BioTab k={K.plantae} label="Discovery" />
              <BioTab k={K.plantae} label="Settings" />
            </div>
            <div style={{ display:'flex', gap:6, flexWrap:'wrap' }}>
              <BioBadge k={K.plantae} label="Photosynthesizer" bright />
              <BioBadge k={K.plantae} label="Tier 1" />
              <BioBadge k={K.plantae} label="Pioneer" />
            </div>
          </div>
          <div style={{ background:K.fungi.bg, border:`1px solid ${K.fungi.border}`, padding:8 }}>
            <div style={{ display:'flex', gap:0, borderBottom:`1px solid ${K.fungi.border}`, marginBottom:8 }}>
              <BioTab k={K.fungi} label="Evolution" active />
              <BioTab k={K.fungi} label="Discovery" />
              <BioTab k={K.fungi} label="Settings" />
            </div>
            <div style={{ display:'flex', gap:6, flexWrap:'wrap' }}>
              <BioBadge k={K.fungi} label="Decomposer" bright />
              <BioBadge k={K.fungi} label="Tier 1" />
            </div>
          </div>
        </div>

        {/* Tooltips & Toasts */}
        <div>
          <div style={{ fontFamily:RSUF, fontSize:16, color:'#aaa', marginBottom:8 }}>Tooltips & Event Toasts</div>
          <div style={{ display:'flex', flexDirection:'column', gap:8 }}>
            <BioTooltip k={K.plantae} title="Toxin Bloom">Unleash spores that damage all herbivores in range. Costs 50 Biomass.</BioTooltip>
            <BioTooltip k={K.fungi} title="Spore Infection">Your network pulses. Infection spreads to adjacent tiles.</BioTooltip>
            <BioToast k={K.plantae} title="Herbivore Wave!" body="Bodies move through your light. They take what they take." icon="!" />
            <BioToast k={K.fungi} title="Spore Burst Ready" body="Colony cost: 45 spores" icon="○" />
            <BioToast k={K.animals} title="Migration Event" body="The herd moves south. Follow or starve." icon="▲" />
          </div>
        </div>
      </div>
    </div>
  );
}

function EvoTreeArtboard() {
  return (
    <div style={{ padding:20, background:'#0c0a08', height:'100%' }}>
      <div style={{ fontFamily:RSUF, fontSize:14, color:'#888', marginBottom:16 }}>Evolution tree nodes — three states: purchased, available, locked. Nodes are colored by their kingdom wing. Connecting lines (in Godot: draw via Control._draw) link prerequisites.</div>

      <div style={{ display:'flex', gap:24 }}>
        {/* Plantae wing */}
        <div>
          <div style={{ fontFamily:RSUF, fontSize:14, color:K.plantae.text, marginBottom:8 }}>Plantae Wing</div>
          <div style={{ display:'flex', gap:8 }}>
            <BioEvoNode k={K.plantae} label="Root Network" purchased />
            <BioEvoNode k={K.plantae} label="Deep Roots" cost="15" />
            <BioEvoNode k={K.plantae} label="Insectivory" cost="30" locked />
          </div>
          {/* Connection line representation */}
          <div style={{ display:'flex', alignItems:'center', gap:4, margin:'8px 0', paddingLeft:20 }}>
            <div style={{ width:40, height:2, background:K.plantae.accent }}></div>
            <div style={{ width:6, height:6, background:K.plantae.accent, transform:'rotate(45deg)' }}></div>
            <div style={{ width:40, height:2, background:K.plantae.border }}></div>
            <div style={{ width:6, height:6, background:K.plantae.border, transform:'rotate(45deg)' }}></div>
            <div style={{ width:40, height:2, background:K.plantae.border+'44' }}></div>
          </div>
          <div style={{ fontFamily:RSUF, fontSize:9, color:'#555' }}>purchased ——→ available ——→ locked</div>
        </div>

        {/* Fungi wing */}
        <div>
          <div style={{ fontFamily:RSUF, fontSize:14, color:K.fungi.text, marginBottom:8 }}>Fungi Wing</div>
          <div style={{ display:'flex', gap:8 }}>
            <BioEvoNode k={K.fungi} label="Mycelium Spread" purchased />
            <BioEvoNode k={K.fungi} label="Cordyceps" cost="25" />
            <BioEvoNode k={K.fungi} label="Lichen Heritage" cost="40" locked />
          </div>
        </div>

        {/* Cross-kingdom */}
        <div>
          <div style={{ fontFamily:RSUF, fontSize:14, color:K.hybrid.text, marginBottom:8 }}>Cross-Kingdom</div>
          <div style={{ display:'flex', gap:8 }}>
            <BioEvoNode k={K.hybrid} label="Symbiotic Bond" purchased />
            <BioEvoNode k={K.hybrid} label="Soil Memory" cost="20" />
          </div>
        </div>
      </div>

      {/* Discovery log entry example */}
      <div style={{ fontFamily:RSUF, fontSize:16, color:'#aaa', margin:'20px 0 8px' }}>Discovery Log Entry</div>
      <div style={{ display:'flex', gap:12 }}>
        <BioBox k={K.plantae} glow style={{ maxWidth:280 }}>
          <div style={{ fontFamily:RSUF, fontSize:14, color:K.plantae.textBright, marginBottom:2 }}>Discovery #01</div>
          <div style={{ fontFamily:RSUF, fontSize:12, color:K.plantae.textDim, lineHeight:1.4, fontStyle:'italic' }}>"You unfurl. The light meets the chlorophyll meets the carbon and the carbon stays. This is the first deal you made with the world."</div>
          <div style={{ fontFamily:RSUF, fontSize:9, color:K.plantae.textDim+'88', marginTop:6 }}>Unlocked: First colonized tile</div>
        </BioBox>
        <BioBox k={K.fungi} glow style={{ maxWidth:280 }}>
          <div style={{ fontFamily:RSUF, fontSize:14, color:K.fungi.textBright, marginBottom:2 }}>Discovery #07</div>
          <div style={{ fontFamily:RSUF, fontSize:12, color:K.fungi.textDim, lineHeight:1.4, fontStyle:'italic' }}>"The decomposers were already here, waiting. They wait for everything."</div>
          <div style={{ fontFamily:RSUF, fontSize:9, color:K.fungi.textDim+'88', marginTop:6 }}>Unlocked: Fungi kingdom</div>
        </BioBox>
        <BioBox k={K.animals} style={{ maxWidth:280, opacity:0.4 }}>
          <div style={{ fontFamily:RSUF, fontSize:14, color:K.animals.textBright, marginBottom:2 }}>Discovery #??</div>
          <div style={{ fontFamily:RSUF, fontSize:12, color:K.animals.textDim, lineHeight:1.4 }}>???</div>
          <div style={{ fontFamily:RSUF, fontSize:9, color:K.animals.textDim+'88', marginTop:6 }}>Locked</div>
        </BioBox>
      </div>
    </div>
  );
}

// ═══════════════════════════════════════════
// SECTION 4: TEXTURE LIBRARY
// ═══════════════════════════════════════════

function TextureLibraryArtboard() {
  const k = K.plantae;
  const kf = K.fungi;
  const textures = [
    { name:'crossHatch', fn: (kk) => D.crossHatch(kk.accentDim+'12', kk.surface, 5) },
    { name:'stipple', fn: (kk) => D.stipple(kk.accentDim+'28', kk.surface) },
    { name:'dots', fn: (kk) => D.dots(kk.accentDim+'18', kk.surface, 3) },
    { name:'hLines', fn: (kk) => D.hLines(kk.accentDim+'10', kk.surface, 4) },
    { name:'checker', fn: (kk) => D.checker(kk.borderLo+'33', kk.surface) },
  ];
  const pixbgs = [
    { name:'grass', fn: PBG.grass },
    { name:'mushroom', fn: PBG.mushroom },
    { name:'spore', fn: PBG.spore },
    { name:'bone', fn: PBG.bone },
    { name:'lichen', fn: PBG.lichen },
  ];

  return (
    <div style={{ padding:20, background:'#0c0a08', height:'100%' }}>
      {/* Dither textures */}
      <div style={{ fontFamily:RSUF, fontSize:16, color:'#aaa', marginBottom:8 }}>Dither Textures</div>
      <div style={{ fontFamily:RSUF, fontSize:11, color:'#666', marginBottom:12 }}>CSS-only textures applied to button/panel backgrounds. Vary opacity and grid size per kingdom.</div>
      <div style={{ display:'flex', gap:8, marginBottom:20, flexWrap:'wrap' }}>
        {textures.map(t => (
          <div key={t.name}>
            <div style={{ fontFamily:RSUF, fontSize:10, color:'#666', marginBottom:4 }}>{t.name}</div>
            <div style={{ display:'flex', gap:4 }}>
              {[K.plantae, K.fungi, K.animals, K.hybrid].map(kk => (
                <div key={kk.id} style={{ width:56, height:40, ...t.fn(kk), border:`1px solid ${kk.border}` }}></div>
              ))}
            </div>
          </div>
        ))}
      </div>

      {/* Pixel micro-backgrounds */}
      <div style={{ fontFamily:RSUF, fontSize:16, color:'#aaa', marginBottom:8 }}>Pixel Micro-Backgrounds</div>
      <div style={{ fontFamily:RSUF, fontSize:11, color:'#666', marginBottom:12 }}>Faint SVG-based pixel organisms. Layer behind dither textures for depth. Kingdom-specific.</div>
      <div style={{ display:'flex', gap:8, flexWrap:'wrap' }}>
        {pixbgs.map(p => (
          <div key={p.name}>
            <div style={{ fontFamily:RSUF, fontSize:10, color:'#666', marginBottom:4 }}>{p.name}</div>
            <div style={{ width:120, height:60, ...p.fn('#14120e'), border:'1px solid #2a2820' }}></div>
          </div>
        ))}
      </div>

      {/* Combination examples */}
      <div style={{ fontFamily:RSUF, fontSize:16, color:'#aaa', margin:'16px 0 8px' }}>Layered Combinations</div>
      <div style={{ display:'flex', gap:8 }}>
        <div>
          <div style={{ fontFamily:RSUF, fontSize:10, color:'#666', marginBottom:4 }}>crossHatch + grass</div>
          <div style={{ width:120, height:50, ...D.crossHatch(k.accentDim+'10', k.surface, 5), ...PBG.grass('transparent'), border:`1px solid ${k.border}` }}></div>
        </div>
        <div>
          <div style={{ fontFamily:RSUF, fontSize:10, color:'#666', marginBottom:4 }}>stipple + mushroom</div>
          <div style={{ width:120, height:50, ...D.stipple(kf.accentDim+'20', kf.surface), ...PBG.mushroom('transparent'), border:`1px solid ${kf.border}` }}></div>
        </div>
        <div>
          <div style={{ fontFamily:RSUF, fontSize:10, color:'#666', marginBottom:4 }}>dots + bone</div>
          <div style={{ width:120, height:50, ...D.dots(K.animals.accentDim+'18', K.animals.surface, 3), ...PBG.bone('transparent'), border:`1px solid ${K.animals.border}` }}></div>
        </div>
        <div>
          <div style={{ fontFamily:RSUF, fontSize:10, color:'#666', marginBottom:4 }}>crossHatch + lichen</div>
          <div style={{ width:120, height:50, ...D.crossHatch(K.hybrid.accentDim+'10', K.hybrid.surface, 5), ...PBG.lichen('transparent'), border:`1px solid ${K.hybrid.border}` }}></div>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, {
  ColorSystemArtboard, ResourceColorsArtboard, TypographyArtboard,
  ButtonLibraryArtboard, ComponentLibraryArtboard, EvoTreeArtboard,
  TextureLibraryArtboard,
});
