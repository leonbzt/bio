/* Bio — Screen Mockups
 * Main Game HUD, Kingdom→Niche→Species selection, Title screen.
 * All screens at 360×640 portrait (mobile).
 */

const PHONE_W = 360;
const PHONE_H = 640;

function PhoneFrame({ k, children }) {
  return (
    <div style={{
      width: PHONE_W, height: PHONE_H,
      background: k.bg,
      border: `3px solid ${k.border}`,
      borderTopColor: k.borderHi,
      overflow: 'hidden',
      display: 'flex', flexDirection: 'column',
      fontFamily: RSUF,
      imageRendering: 'auto',
      position: 'relative',
    }}>
      {children}
    </div>
  );
}

// ═══════════════════════════════════════════
// MAIN GAME HUD — Plantae
// ═══════════════════════════════════════════

function HUDPlantae() {
  const k = K.plantae;
  return (
    <PhoneFrame k={k}>
      {/* ─── Top Resource Bar ─── */}
      <div style={{
        background: k.surface,
        borderBottom: `2px solid ${k.border}`,
        padding: '6px 10px',
        display: 'flex', justifyContent: 'space-between', alignItems: 'center',
        position: 'relative', zIndex: 10,
      }}>
        <div style={{ position:'absolute', inset:0, ...D.hLines(k.accentDim+'08', 'transparent', 4) }}></div>
        <BioResource res="biomass" value="1,240" rate="+12/t" k={k} />
        <BioResource res="nutrients" value="340" rate="+3/t" k={k} />
        <BioResource res="sunlight" value="12" k={k} />
        <div style={{ display:'flex', alignItems:'center', gap:3 }}>
          <div style={{ width:10, height:10, background:RES.ep.color, border:`1px solid ${RES.ep.color}88`, borderRadius:1 }}></div>
          <span style={{ fontSize:12, color:RES.ep.color }}>24</span>
        </div>
      </div>

      {/* ─── Niche Badge ─── */}
      <div style={{
        position: 'absolute', top: 38, left: 8, zIndex: 15,
        background: k.accent,
        border: `1px solid ${k.accentLight}`,
        padding: '1px 8px',
      }}>
        <span style={{ fontSize: 9, color: k.bg, letterSpacing: 1 }}>PHOTOSYNTHESIZER</span>
      </div>

      {/* ─── XP Bar (thin) ─── */}
      <div style={{ height: 8, background: k.bg, borderBottom: `1px solid ${k.border}`, position: 'relative' }}>
        <div style={{ position:'absolute', top:0, left:0, bottom:0, width:'42%', background:UTIL.xpBar, boxShadow:`inset 0 1px 0 ${UTIL.xpBar}88` }}></div>
        <div style={{ position:'absolute', right:4, top:0, fontSize:7, color:'#888', lineHeight:'8px' }}>860b/952b</div>
      </div>

      {/* ─── Tile Grid ─── */}
      <div style={{ flex: 1, background: '#080e06', position: 'relative', overflow: 'hidden' }}>
        {/* Grid cells */}
        <div style={{ display:'grid', gridTemplateColumns:`repeat(${Math.floor(PHONE_W/18)}, 18px)`, gap:0, padding:1 }}>
          {Array.from({length: Math.floor(PHONE_W/18) * 26}, (_, i) => {
            const cols = Math.floor(PHONE_W/18);
            const row = Math.floor(i / cols);
            const col = i % cols;
            // Owned plantae tiles (cluster in center)
            const cx = Math.floor(cols/2), cy = 12;
            const dx = Math.abs(col - cx), dy = Math.abs(row - cy);
            const owned = (dx + dy < 5) || (dx < 3 && dy < 4) || (dx < 4 && dy < 2);
            // Biome spots
            const biome = (col + row) % 7 === 0 && !owned;
            // Herbivore
            const herb = (i === Math.floor(cols*8+cx+5)) || (i === Math.floor(cols*15+cx-6));
            const bg = herb ? '#5a2a1a' : owned ? ['#1a3a1a','#2a5a2a','#1e4a1e','#2a6a2a'][i%4] : biome ? '#121a10' : '#080e06';
            return (
              <div key={i} style={{ width:18, height:18, background:bg, borderRight:'1px solid #060a04', borderBottom:'1px solid #060a04' }}>
                {herb && <div style={{ width:8, height:8, background:'#aa5a3a', margin:'5px auto 0', border:'1px solid #7a3a2a' }}></div>}
              </div>
            );
          })}
        </div>

        {/* Floating event toast */}
        <div style={{
          position: 'absolute', top: 8, left: 8, right: 8, zIndex: 10,
          ...kBorder(k), background: k.bg + 'EE', padding: '5px 8px',
          display: 'flex', gap: 8, alignItems: 'center',
        }}>
          <div style={{ position:'absolute', inset:0, ...kTex(k, 'secondary') }}></div>
          <GlowLine color={k.glow} />
          <div style={{ position:'relative', zIndex:1, width:20, height:20, background:UTIL.warning, display:'flex', alignItems:'center', justifyContent:'center', fontSize:12, color:'#000', border:`1px solid ${UTIL.warningHi}` }}>!</div>
          <div style={{ position:'relative', zIndex:1, flex:1 }}>
            <div style={{ fontSize:13, color:k.textBright }}>Herbivore Wave!</div>
            <div style={{ fontSize:10, color:k.textDim }}>They take what they take.</div>
          </div>
        </div>

        {/* Goal banner */}
        <div style={{
          position: 'absolute', bottom: 6, left: 8, right: 8, zIndex: 10,
          background: k.surface + 'DD', border: `1px solid ${k.border}`,
          padding: '4px 8px', display: 'flex', justifyContent: 'space-between', alignItems: 'center',
        }}>
          <span style={{ fontSize: 11, color: k.textDim }}>Colonize 30 tiles</span>
          <span style={{ fontSize: 13, color: k.accentLight }}>21/30</span>
        </div>
      </div>

      {/* ─── Bottom Action Bar ─── */}
      <div style={{
        background: k.surface,
        borderTop: `2px solid ${k.borderHi}`,
        padding: '8px 10px',
        display: 'flex', gap: 8, alignItems: 'center',
        position: 'relative',
      }}>
        <div style={{ position:'absolute', inset:0, ...D.crossHatch(k.accentDim+'08', 'transparent', 6) }}></div>
        {/* Menu button */}
        <div style={{ position:'relative', zIndex:1, ...kBorder(k), width:36, height:36, display:'flex', alignItems:'center', justifyContent:'center', background:k.surface }}>
          <span style={{ fontSize:16, color:k.textDim }}>☰</span>
        </div>
        {/* Ability button */}
        <div style={{ position:'relative', zIndex:1, flex:1 }}>
          <BioBtn k={k} primary glow style={{ textAlign:'center', padding:'8px 16px' }}>
            <span style={{ fontSize:16 }}>⚡ Toxin Bloom</span>
          </BioBtn>
        </div>
        {/* Prestige shortcut */}
        <div style={{ position:'relative', zIndex:1, ...kBorder(k), width:36, height:36, display:'flex', alignItems:'center', justifyContent:'center', background:k.surface }}>
          <span style={{ fontSize:14, color:RES.ep.color }}>★</span>
        </div>
      </div>

      {/* ─── Level indicator ─── */}
      <div style={{
        position: 'absolute', top: 35, right: 8, zIndex: 15,
        background: k.surface, border: `1px solid ${k.border}`, padding: '1px 6px',
      }}>
        <span style={{ fontSize: 10, color: k.textDim }}>Lv </span>
        <span style={{ fontSize: 12, color: k.text }}>121</span>
      </div>
    </PhoneFrame>
  );
}

// ═══════════════════════════════════════════
// MAIN GAME HUD — Fungi
// ═══════════════════════════════════════════

function HUDFungi() {
  const k = K.fungi;
  return (
    <PhoneFrame k={k}>
      {/* Top Resource Bar */}
      <div style={{
        background: k.surface,
        borderBottom: `2px solid ${k.border}`,
        padding: '6px 10px',
        display: 'flex', justifyContent: 'space-between', alignItems: 'center',
        position: 'relative', zIndex: 10,
      }}>
        <div style={{ position:'absolute', inset:0, ...D.stipple(k.accentDim+'10', 'transparent') }}></div>
        <BioResource res="decay" value="890" rate="+8/t" k={k} />
        <BioResource res="spores" value="45" k={k} />
        <BioResource res="nutrients" value="210" rate="+3/t" k={k} />
        <div style={{ display:'flex', alignItems:'center', gap:3 }}>
          <div style={{ width:10, height:10, background:RES.ep.color, border:`1px solid ${RES.ep.color}88`, borderRadius:1 }}></div>
          <span style={{ fontSize:12, color:RES.ep.color }}>18</span>
        </div>
      </div>

      {/* Niche Badge */}
      <div style={{
        position: 'absolute', top: 38, left: 8, zIndex: 15,
        background: k.accent, border: `1px solid ${k.accentLight}`, padding: '1px 8px',
      }}>
        <span style={{ fontSize: 9, color: k.bg, letterSpacing: 1 }}>DECOMPOSER</span>
      </div>

      {/* XP Bar */}
      <div style={{ height: 8, background: k.bg, borderBottom: `1px solid ${k.border}`, position: 'relative' }}>
        <div style={{ position:'absolute', top:0, left:0, bottom:0, width:'65%', background:UTIL.xpBar }}></div>
        <div style={{ position:'absolute', right:4, top:0, fontSize:7, color:'#888', lineHeight:'8px' }}>620/952</div>
      </div>

      {/* Tile Grid — fungi underground feel */}
      <div style={{ flex: 1, background: '#08060e', position: 'relative', overflow: 'hidden' }}>
        <div style={{ display:'grid', gridTemplateColumns:`repeat(${Math.floor(PHONE_W/18)}, 18px)`, gap:0, padding:1 }}>
          {Array.from({length: Math.floor(PHONE_W/18) * 26}, (_, i) => {
            const cols = Math.floor(PHONE_W/18);
            const row = Math.floor(i / cols);
            const col = i % cols;
            const cx = Math.floor(cols/2), cy = 13;
            const dx = Math.abs(col - cx), dy = Math.abs(row - cy);
            // Fungi spread — more network-like
            const owned = (dx + dy < 4) || (dx < 2 && dy < 6) || (col === cx && dy < 7);
            // Corpse tiles
            const corpse = (i === Math.floor(cols*6+cx+3)) || (i === Math.floor(cols*18+cx-4));
            const bg = corpse ? '#2a1a1a' : owned ? ['#1a1228','#22183a','#1e1432','#261a40'][i%4] : '#08060e';
            return (
              <div key={i} style={{ width:18, height:18, background:bg, borderRight:'1px solid #06040a', borderBottom:'1px solid #06040a' }}>
                {corpse && <div style={{ width:6, height:6, background:'#5a3a3a', margin:'6px auto 0', borderRadius:1 }}></div>}
              </div>
            );
          })}
        </div>

        {/* Goal */}
        <div style={{
          position: 'absolute', bottom: 6, left: 8, right: 8, zIndex: 10,
          background: k.surface + 'DD', border: `1px solid ${k.border}`,
          padding: '4px 8px', display: 'flex', justifyContent: 'space-between',
        }}>
          <span style={{ fontSize: 11, color: k.textDim }}>Spread to 25 tiles</span>
          <span style={{ fontSize: 13, color: k.accentLight }}>18/25</span>
        </div>
      </div>

      {/* Bottom Bar */}
      <div style={{
        background: k.surface, borderTop: `2px solid ${k.borderHi}`,
        padding: '8px 10px', display: 'flex', gap: 8, alignItems: 'center', position: 'relative',
      }}>
        <div style={{ position:'absolute', inset:0, ...D.stipple(k.accentDim+'06', 'transparent') }}></div>
        <div style={{ position:'relative', zIndex:1, ...kBorder(k), width:36, height:36, display:'flex', alignItems:'center', justifyContent:'center', background:k.surface }}>
          <span style={{ fontSize:16, color:k.textDim }}>☰</span>
        </div>
        <div style={{ position:'relative', zIndex:1, flex:1 }}>
          <BioBtn k={k} primary glow style={{ textAlign:'center', padding:'8px 16px' }}>
            <span style={{ fontSize:16 }}>○ Spore Burst</span>
          </BioBtn>
        </div>
        <div style={{ position:'relative', zIndex:1, ...kBorder(k), width:36, height:36, display:'flex', alignItems:'center', justifyContent:'center', background:k.surface }}>
          <span style={{ fontSize:14, color:RES.ep.color }}>★</span>
        </div>
      </div>
    </PhoneFrame>
  );
}

// ═══════════════════════════════════════════
// KINGDOM → NICHE → SPECIES SELECTION
// ═══════════════════════════════════════════

function SelectionFlow() {
  const bg = '#0c0a08';
  return (
    <div style={{ display:'flex', gap:16, alignItems:'flex-start' }}>
      {/* Step 1: Kingdom */}
      <div style={{ width:PHONE_W, height:PHONE_H, background:bg, border:'3px solid #2a2820', display:'flex', flexDirection:'column', fontFamily:RSUF, overflow:'hidden' }}>
        <div style={{ padding:'16px 16px 8px', borderBottom:`1px solid #2a2820` }}>
          <div style={{ fontSize:10, color:'#666', marginBottom:4 }}>STEP 1 OF 3</div>
          <div style={{ fontSize:22, color:'#d8c898' }}>Choose Kingdom</div>
          <div style={{ fontSize:12, color:'#777', marginTop:4 }}>Your kingdom determines which layer of the world you inhabit.</div>
        </div>
        <div style={{ flex:1, padding:12, display:'flex', flexDirection:'column', gap:8, overflowY:'auto' }}>
          {/* Plantae card */}
          {[
            { k:K.plantae, desc:'Surface layer. Light-driven. Slow but compounding.', unlocked:true },
            { k:K.fungi, desc:'Subsurface. Decay-driven. Network spreader.', unlocked:true },
            { k:K.animals, desc:'Mobile. Range-based. Protein-driven.', unlocked:false },
          ].map(({ k: kk, desc, unlocked }) => (
            <div key={kk.id} style={{
              position:'relative', overflow:'hidden',
              ...kBorder(kk), padding:12,
              opacity: unlocked ? 1 : 0.35,
              cursor: unlocked ? 'pointer' : 'default',
            }}>
              <div style={{ position:'absolute', inset:0, ...kTex(kk, 'primary') }}></div>
              {unlocked && <GlowLine color={kk.glow} />}
              <div style={{ position:'relative', zIndex:1 }}>
                <div style={{ display:'flex', justifyContent:'space-between', alignItems:'center' }}>
                  <div style={{ fontSize:20, color:kk.textBright }}>{kk.name}</div>
                  {!unlocked && <BioBadge k={kk} label="LOCKED" />}
                  {unlocked && <span style={{ fontSize:14, color:kk.accent }}>→</span>}
                </div>
                <div style={{ fontSize:12, color:kk.textDim, marginTop:4, lineHeight:1.3 }}>{desc}</div>
                {unlocked && <div style={{ fontSize:10, color:kk.textDim+'88', marginTop:6 }}>
                  {kk.id === 'plantae' ? '3 niches · 5 species' : kk.id === 'fungi' ? '3 niches · 4 species' : '2 niches · 3 species'}
                </div>}
              </div>
            </div>
          ))}
        </div>
        {/* Generations counter */}
        <div style={{ padding:'8px 16px', borderTop:'1px solid #1a1814', textAlign:'center' }}>
          <span style={{ fontSize:10, color:'#555' }}>Generation 14 · </span>
          <span style={{ fontSize:10, color:'#888' }}>Settled Colonies</span>
        </div>
      </div>

      {/* Step 2: Niche */}
      <div style={{ width:PHONE_W, height:PHONE_H, background:K.plantae.bg, border:`3px solid ${K.plantae.border}`, display:'flex', flexDirection:'column', fontFamily:RSUF, overflow:'hidden' }}>
        <div style={{ padding:'16px 16px 8px', borderBottom:`1px solid ${K.plantae.border}` }}>
          <div style={{ fontSize:10, color:K.plantae.textDim, marginBottom:4 }}>STEP 2 OF 3 · PLANTAE</div>
          <div style={{ fontSize:22, color:K.plantae.textBright }}>Choose Niche</div>
          <div style={{ fontSize:12, color:K.plantae.textDim, marginTop:4 }}>Your niche determines how you colonize and what resources you generate.</div>
        </div>
        <div style={{ flex:1, padding:12, display:'flex', flexDirection:'column', gap:8 }}>
          {[
            { name:'Photosynthesizer', desc:'Sunlight-dependent yields. Slow, compounding growth. Default.', unlocked:true, active:true },
            { name:'Carnivore', desc:'Attracts and consumes wandering herbivores. Protein + Biomass.', unlocked:true, active:false },
            { name:'Parasite', desc:'Colonizes on other organisms. Steals yield. Cannot exist on bare ground.', unlocked:false, active:false },
          ].map(n => (
            <div key={n.name} style={{
              position:'relative', overflow:'hidden',
              ...(n.active ? kBorder(K.plantae) : kBorderSimple(K.plantae)),
              padding:12, opacity: n.unlocked ? 1 : 0.35,
              background: n.active ? K.plantae.surface : 'transparent',
            }}>
              {n.active && <div style={{ position:'absolute', inset:0, ...kTex(K.plantae) }}></div>}
              {n.active && <GlowLine color={K.plantae.glow} />}
              <div style={{ position:'relative', zIndex:1 }}>
                <div style={{ display:'flex', justifyContent:'space-between', alignItems:'center' }}>
                  <div style={{ fontSize:18, color: n.active ? K.plantae.textBright : n.unlocked ? K.plantae.text : K.plantae.textDim }}>{n.name}</div>
                  {!n.unlocked && <BioBadge k={K.plantae} label="LOCKED" />}
                </div>
                <div style={{ fontSize:11, color:K.plantae.textDim, marginTop:4, lineHeight:1.3 }}>{n.desc}</div>
              </div>
            </div>
          ))}
        </div>
        <div style={{ padding:'8px 16px', borderTop:`1px solid ${K.plantae.border}`, display:'flex', justifyContent:'space-between' }}>
          <BioBtn k={K.plantae} secondary style={{ fontSize:14 }}>← Back</BioBtn>
          <BioBtn k={K.plantae} primary glow style={{ fontSize:14 }}>Next →</BioBtn>
        </div>
      </div>

      {/* Step 3: Species */}
      <div style={{ width:PHONE_W, height:PHONE_H, background:K.plantae.bg, border:`3px solid ${K.plantae.border}`, display:'flex', flexDirection:'column', fontFamily:RSUF, overflow:'hidden' }}>
        <div style={{ padding:'16px 16px 8px', borderBottom:`1px solid ${K.plantae.border}` }}>
          <div style={{ fontSize:10, color:K.plantae.textDim, marginBottom:4 }}>STEP 3 OF 3 · PHOTOSYNTHESIZER</div>
          <div style={{ fontSize:22, color:K.plantae.textBright }}>Choose Species</div>
        </div>
        <div style={{ flex:1, padding:12, display:'flex', flexDirection:'column', gap:8 }}>
          {[
            { name:'Pioneer Grass', latin:'Herba prima', desc:'Fast initial growth. Low yield ceiling. Good for short runs.', unlocked:true },
            { name:'Bramble', latin:'Rubus spinosus', desc:'Slower start. Higher yield ceiling. Thorns reduce herbivore damage.', unlocked:true },
          ].map(s => (
            <BioBox key={s.name} k={K.plantae} glow={s.unlocked} style={{ opacity: s.unlocked ? 1 : 0.35 }}>
              <div style={{ display:'flex', justifyContent:'space-between', alignItems:'flex-start' }}>
                <div>
                  <div style={{ fontSize:18, color:K.plantae.textBright }}>{s.name}</div>
                  <div style={{ fontSize:10, color:K.plantae.textDim+'88', fontStyle:'italic' }}>{s.latin}</div>
                </div>
                {/* Placeholder sprite area */}
                <div style={{ width:40, height:40, background:K.plantae.surface, border:`1px solid ${K.plantae.border}`, display:'flex', alignItems:'center', justifyContent:'center' }}>
                  <span style={{ fontSize:8, color:K.plantae.textDim, textAlign:'center', lineHeight:1 }}>sprite</span>
                </div>
              </div>
              <div style={{ fontSize:11, color:K.plantae.textDim, marginTop:6, lineHeight:1.3 }}>{s.desc}</div>
              {/* Stats preview */}
              <div style={{ display:'flex', gap:12, marginTop:8 }}>
                <div><span style={{ fontSize:9, color:K.plantae.textDim }}>Growth </span><span style={{ fontSize:12, color:RES.biomass.color }}>★★★</span></div>
                <div><span style={{ fontSize:9, color:K.plantae.textDim }}>Defense </span><span style={{ fontSize:12, color:RES.biomass.color }}>★☆☆</span></div>
              </div>
            </BioBox>
          ))}
        </div>
        <div style={{ padding:'12px 16px', borderTop:`1px solid ${K.plantae.border}` }}>
          <BioBtn k={K.plantae} primary glow rivets style={{ textAlign:'center', padding:'10px 16px', width:'100%' }}>
            <span style={{ fontSize:20 }}>Begin Run</span>
          </BioBtn>
          <div style={{ textAlign:'center', marginTop:6 }}>
            <span style={{ fontSize:10, color:K.plantae.textDim }}>Devonian · Bare Mineral Plain</span>
          </div>
        </div>
      </div>
    </div>
  );
}

// ═══════════════════════════════════════════
// TITLE SCREEN
// ═══════════════════════════════════════════

function TitleScreen() {
  return (
    <div style={{ width:PHONE_W, height:PHONE_H, background:'#0c0a08', border:'3px solid #2a2820', display:'flex', flexDirection:'column', fontFamily:RSUF, overflow:'hidden', position:'relative' }}>
      {/* Background texture */}
      <div style={{ position:'absolute', inset:0, ...D.crossHatch('#1a1a1208', 'transparent', 8), ...PBG.grass('#0c0a0800') }}></div>

      {/* Centered content */}
      <div style={{ flex:1, display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center', position:'relative', zIndex:1 }}>
        {/* Title */}
        <div style={{ fontSize:64, color:'#7eba5a', textShadow:'0 2px 0 #1a2a12, 0 4px 8px #00000088', letterSpacing:8 }}>BIO</div>
        <div style={{ fontSize:14, color:'#4a6a2a', letterSpacing:4, marginTop:4 }}>YOU PLAY LIFE ITSELF</div>

        {/* Generations counter */}
        <div style={{ marginTop:24, textAlign:'center' }}>
          <div style={{ fontSize:11, color:'#555' }}>Generation</div>
          <div style={{ fontSize:28, color:'#d8c898' }}>14</div>
          <div style={{ fontSize:12, color:'#888', marginTop:2 }}>Settled Colonies</div>
        </div>

        {/* Discovery counter */}
        <div style={{ marginTop:16, padding:'4px 12px', background:'#14120e', border:'1px solid #2a2820' }}>
          <span style={{ fontSize:11, color:'#888' }}>Discoveries: </span>
          <span style={{ fontSize:13, color:RES.ep.color }}>23</span>
          <span style={{ fontSize:11, color:'#555' }}> / 57</span>
        </div>
      </div>

      {/* Bottom buttons */}
      <div style={{ padding:'0 24px 32px', display:'flex', flexDirection:'column', gap:8, position:'relative', zIndex:1 }}>
        <BioBtn k={K.plantae} primary glow rivets style={{ textAlign:'center', padding:'10px 16px' }}>
          <span style={{ fontSize:20 }}>Continue Run</span>
        </BioBtn>
        <div style={{ display:'flex', gap:8 }}>
          <BioBtn k={K.plantae} style={{ flex:1, textAlign:'center' }}>New Run</BioBtn>
          <BioBtn k={K.plantae} style={{ flex:1, textAlign:'center' }}>Evolution</BioBtn>
        </div>
        <div style={{ display:'flex', gap:8 }}>
          <BioBtn k={K.plantae} secondary style={{ flex:1, textAlign:'center' }}>Discovery</BioBtn>
          <BioBtn k={K.plantae} secondary style={{ flex:1, textAlign:'center' }}>Settings</BioBtn>
        </div>
      </div>

      {/* Version */}
      <div style={{ textAlign:'center', padding:'0 0 8px', position:'relative', zIndex:1 }}>
        <span style={{ fontSize:9, color:'#333' }}>v0.10.0 · Tier 1</span>
      </div>
    </div>
  );
}

// ═══════════════════════════════════════════
// PRESTIGE SCREEN
// ═══════════════════════════════════════════

function PrestigeScreen() {
  const k = K.plantae;
  return (
    <div style={{ width:PHONE_W, height:PHONE_H, background:k.bg, border:`3px solid ${k.border}`, display:'flex', flexDirection:'column', fontFamily:RSUF, overflow:'hidden', position:'relative' }}>
      <div style={{ position:'absolute', inset:0, ...D.stipple(k.accentDim+'08', 'transparent') }}></div>

      {/* Header */}
      <div style={{ padding:'20px 16px 12px', textAlign:'center', position:'relative', zIndex:1 }}>
        <div style={{ fontSize:12, color:k.textDim, letterSpacing:2 }}>RUN COMPLETE</div>
        <div style={{ fontSize:28, color:k.textBright, marginTop:4 }}>Prestige</div>
        <div style={{ fontSize:12, color:k.textDim, marginTop:4, lineHeight:1.4 }}>
          "The biomass cycles back. The substrate remembers everything you grew."
        </div>
      </div>

      <BioDivider k={k} />

      {/* Run stats */}
      <div style={{ padding:'0 16px', position:'relative', zIndex:1 }}>
        <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:8 }}>
          <BioBox k={k}>
            <div style={{ fontSize:10, color:k.textDim }}>Tiles Owned</div>
            <div style={{ fontSize:20, color:k.textBright }}>34</div>
          </BioBox>
          <BioBox k={k}>
            <div style={{ fontSize:10, color:k.textDim }}>Peak Biomass</div>
            <div style={{ fontSize:20, color:RES.biomass.color }}>2,840</div>
          </BioBox>
          <BioBox k={k}>
            <div style={{ fontSize:10, color:k.textDim }}>Events Survived</div>
            <div style={{ fontSize:20, color:k.textBright }}>5</div>
          </BioBox>
          <BioBox k={k}>
            <div style={{ fontSize:10, color:k.textDim }}>Ticks Elapsed</div>
            <div style={{ fontSize:20, color:k.textBright }}>1,247</div>
          </BioBox>
        </div>
      </div>

      <BioDivider k={k} />

      {/* EP earned */}
      <div style={{ padding:'0 16px', textAlign:'center', position:'relative', zIndex:1 }}>
        <div style={{ fontSize:12, color:k.textDim }}>Evolution Points Earned</div>
        <div style={{ fontSize:36, color:RES.ep.color, marginTop:4 }}>+24 ★</div>
        <div style={{ fontSize:11, color:'#666', marginTop:4 }}>
          Base: 18 · Goal bonus: +4 · Soil Memory: +2
        </div>
      </div>

      {/* New discovery? */}
      <div style={{ padding:'12px 16px', position:'relative', zIndex:1 }}>
        <BioBox k={k} glow>
          <div style={{ fontSize:12, color:RES.ep.color, marginBottom:2 }}>New Discovery!</div>
          <div style={{ fontSize:14, color:k.textBright }}>#12 — Deep Roots</div>
          <div style={{ fontSize:11, color:k.textDim, fontStyle:'italic', lineHeight:1.3, marginTop:4 }}>
            "The roots go deeper than the light ever reached. They found water in the dark."
          </div>
        </BioBox>
      </div>

      {/* Actions */}
      <div style={{ flex:1 }}></div>
      <div style={{ padding:'0 16px 20px', display:'flex', flexDirection:'column', gap:8, position:'relative', zIndex:1 }}>
        <BioBtn k={k} primary glow rivets style={{ textAlign:'center', padding:'10px 16px' }}>
          <span style={{ fontSize:18 }}>Start New Run</span>
        </BioBtn>
        <div style={{ display:'flex', gap:8 }}>
          <BioBtn k={k} style={{ flex:1, textAlign:'center' }}>Evolution Tree</BioBtn>
          <BioBtn k={k} secondary style={{ flex:1, textAlign:'center' }}>Main Menu</BioBtn>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, {
  PhoneFrame, HUDPlantae, HUDFungi, SelectionFlow, TitleScreen, PrestigeScreen,
});
