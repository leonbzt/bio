# UI Polish Roadmap

> Translates `docs/user_ressources/bio-identity-system.jsx` into a Godot rollout plan. Phase 1 shipped 2026-05-19; later phases are scoped for future polish passes.

## Source of truth

The identity design lives in `docs/user_ressources/bio-identity-system.jsx` — kingdom palettes, resource colors, dither textures, pixel micro-backgrounds, base components (BioBtn, BioBox, BioBar, BioResource, BioToast, BioEvoNode).

In code, the palette tokens are translated to GDScript in `scripts/autoloads/kingdom_theme.gd`. Query `KingdomTheme.resource_color(id)`, `KingdomTheme.kingdom_palette(kingdom_id)`, `KingdomTheme.panel_stylebox(kingdom_id)` from consumers.

## Phase 1 — Foundation ✅ (2026-05-19)

- `KingdomTheme` autoload with full palette + resource colors.
- HUD resource labels colored per `RES[*].color`: biomass green, nutrients gold, sunlight blue, decay violet, spores blue-grey.
- Stub resource labels hide when both inactive AND zero (Protein/Lifeforce/Blood Cohesion/Gray Matter/Mycelial Stability).
- HUD `Bar` + `IdentityStrip` panel apply per-kingdom `panel_stylebox` on run start.
- Species panel widened (128 → 156) + per-kingdom panel styling + Latin names autowrap.
- Evolution tree spacing increased (COL_WIDTH 110→140, ROW_HEIGHT 96→120, node 100×76 → 124×92). Wing tabs at top scroll to each wing.
- Evolution tree nodes use 2px chunky borders, sharp corners, per-state bg colors (purchasable affordable = bright, locked = darkened, owned = full saturation with ✓).
- Biome legend chip row under goal banner — one chip per biome on the map, with impact pips.
- Tile rendering: thin (1px) per-species cluster outlines (plantae outermost, fungi inset 3.5px); animal as inner diamond; biome shows as 3px frame around species fills.

## Phase 2 — Pixel font + glyph icons (font ✅ 2026-05-20)

**Fonts** ✅ shipped — dual-font system:
- **Default** (chunky pixel): `assets/ui/fonts/PressStart2P-Regular.ttf` at size 8. Wired into `assets/ui/theme.tres` as `default_font`. Buttons + labels inherit it. Use for headers, primary buttons, identity strip, balance numbers.
- **Small** (compact pixel): `assets/ui/fonts/Tiny5-Regular.ttf` at size 8. Exposed via `KingdomTheme.SMALL_FONT` + `KingdomTheme.SMALL_FONT_SIZE`. Apply per-label when needed:
  ```gdscript
  label.add_theme_font_override("font", KingdomTheme.SMALL_FONT)
  label.add_theme_font_size_override("font_size", KingdomTheme.SMALL_FONT_SIZE)
  ```
- Both fonts use SIL Open Font License — redistributable, no in-game attribution required.
- Currently applied to: species panel Latin labels, starting-species picker Latin labels, biome legend chips (name + impact pips).
- Good candidates for Tiny5 later: tooltip body, evolution node sub-labels (cost + state badge), event toast body, discovery log entry rows — anywhere dense + small.

**Resource glyph icons**: replace `Biomass: 100` text with `[●] 100` chip showing a colored swatch. Update `resource_label.gd` to render an inline `ColorRect` + text. Identity system maps glyphs:
- biomass `●` filled circle, nutrients `◆` diamond, sunlight `☀`, decay `◎`, spores `○`, protein `▲`, EP `★`.

## Phase 3 — Panel chrome polish (planned)

**Dither textures** behind major panels (HUD bar, species panel, prestige screen). Translate identity system's `D.crossHatch` / `D.dots` / `D.stipple` to Godot:

- **Easy path**: pre-render 8×8 PNG dither tiles per kingdom, apply as `TextureRect` underneath panel content with `mouse_filter = IGNORE` and `stretch_mode = TILE`. One tile per kingdom × pattern combo (~12 tiles).
- **Flexible path**: write a single `dither.gdshader` that takes a `pattern` enum + `color` uniform, apply to `ColorRect` behind panel. Cleaner but slightly more setup.

**Pixel micro-backgrounds** (`PBG.grass`, `PBG.mushroom`, etc.) — author 16×16 / 20×20 / 24×24 PNG tiles per kingdom and same approach.

**Border styles**:
- Identity uses light-on-top / dark-on-bottom for chunky pixel-aesthetic depth.
- StyleBoxFlat doesn't natively support per-edge color; use 4 `Panel`s as edges, or a custom `_draw()` override on a Control.
- Simpler: keep single-color border but darken via `K.borderLo` on bottom-right via Polygon2D overlay. Defer until visual gap is felt.

**Glow accent line** (`GlowLine` in JSX) — a 2px gradient at the top of buttons/toasts. In Godot, place a thin `Polygon2D` with `vertex_colors` interpolating along the x-axis (transparent → glow color → transparent).

## Phase 4 — Evolution tree visual identity (planned)

- Replace node `Button` with `Polygon2D` + `Label` so we can use custom node shapes (hexagons, diamonds, octagons per the JSX `BioEvoNode` design).
- Wing tabs gain texture/dither backgrounds matching wing identity.
- Connection lines: thicker (3px instead of 2px) + slight gradient from prereq to destination wing color.
- "Owned" indicator: replace text `(Owned)` with a small ✓ corner badge at top-right of the node.
- "Locked" indicator: replace `(Locked)` with `🔒` glyph, dim background by 40%.

## Phase 5 — Animations + feel (long-tail)

- Tile placement: small flash (`scale 1.2 → 1.0` over 100ms + alpha 0 → 1).
- Resource gain: floating `+5 biomass` label that drifts up + fades.
- Era transition: full-screen flash + slow fade through era colors.
- Wildfire / mass extinction: tile-by-tile darken cascade.
- Toast events: slide-in from top + fade-out.

## Phase 6 — Sprite art replacement (Tier 3+)

Replace flat-color atlas tiles with authored pixel art per species. Each species gets a 16×16 PNG; tile_grid renders the sprite at center, biome border stays underneath. Likely needs an artist or AI-generated tile pack.

## Recommended order

For an alpha release on Reddit:

1. Ship Phase 1 (done).
2. Get smoke-test feedback. Most "looks rough" issues come from font + tile sprites; address either or both before posting.
3. **Phase 2 font** is the highest-impact low-cost addition. ~30 min to download Tiny5 and wire into theme.
4. **Phase 4 evolution tree** is the next visual ROI — fixes the most "programmer art" looking surface.
5. Phase 3 + 5 for beta polish.
6. Phase 6 (sprite art) is content-pipeline scale, usually mid-development if the game proves out.

## Field reference (KingdomTheme palette tokens)

Per-kingdom (`plantae` / `fungi` / `animals` / `hybrid`):
- `bg` — deepest background, full-screen behind everything
- `surface` — panel default background
- `surface_mid` — secondary surface, dropdowns / nested panels
- `border` — main border (2px)
- `border_hi` — top-left highlight edge
- `border_lo` — bottom-right shadow edge
- `accent` — primary action color (buttons, links)
- `accent_light` — hover state
- `accent_bright` — focused / active state
- `accent_dim` — disabled state
- `text` — primary body text
- `text_dim` — secondary / locked text
- `text_bright` — headers / highlighted text
- `glow` — accent glow line color

Resources (15 keyed colors): biomass, nutrients, sunlight, decay, spores, protein, lifeforce, pollination, cellulose, chitin, phosphate, blood_cohesion, gray_matter, mycelial_stability, ep.
