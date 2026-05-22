# Development Guardrails

Practices and pitfalls for Bio's solo dev journey. Each entry has a directive, rationale, and signal — read each as a rule of thumb, not a hard law. Created 2026-05-22.

---

## Things to actively avoid

### G1. Don't lock visual style before the gameplay loop is proven

**Why**: Commissioning a beautiful asset library for systems that get cut is the most expensive form of waste. Phase 16 is at exactly this risk point — multiple commission briefs are written before extensive external playtesting at the chosen visual scale.

**Signal**: About to commission >5 assets in a style direction with <10 hours of external playtest behind that direction.

**Mitigation**: Prototype with procedural placeholders or AI-gen drafts. Validate the loop feels right at the chosen visual scale before commissioning canonical art. The current cluster-in-biome direction (2026-05-22 lock) explicitly waits for prototype validation before commissioning.

### G2. Don't ship without a written alpha gate

**Why**: Solo devs without a documented "MUST ship" vs "WILL cut" list rarely ship. Scope creep is the default state when nothing forces the cut.

**Signal**: Cannot list in one sentence what alpha includes and excludes.

**Mitigation**: Write `docs/ALPHA_GATE.md` listing 5-10 features that MUST be in alpha. Everything else is cuttable. Re-read it before every commission decision and every "while I'm in here" expansion.

### G3. Don't pre-build for features you haven't validated

**Why**: Building engine flexibility for theoretical future features is the silent killer of solo projects. Each abstraction makes immediate work harder for hypothetical benefit.

**Specific items deferred as of 2026-05-22** — do not architect current code to support these:

- **β path (CA growth overlay)** — explicitly NOT planned. Confirmed 2026-05-22: do not preserve hooks, scaffolding, or "future-friendly" abstractions for β. If it ever becomes worth revisiting post-alpha, design it fresh against the codebase as it stands. Cluster-in-biome is the committed direction.
- **Hex grid** — multi-week engine refactor, not justified by current design needs.
- **Layer toggles** (kingdom filter, over/underground) — pure addition, build only after core ships.
- **Per-species sprites** (vs the kingdom density variants) — post-alpha unless budget allows. Cluster slot is designed so per-species drops in later without engine change.

**Signal**: Any code branch that exists only to support a feature you haven't shipped is suspect. Remove until the feature actually ships.

### G4. Don't ignore mobile touch-target minimums

**Why**: UI elements smaller than 44 logical pixels (iOS) / 48 dp (Android) are statistically unusable. Fail accessibility, fail real-finger QA, cost players.

**Signal**: Any button, tab, or interactive icon below the threshold.

**Mitigation**: Audit HUD against 44 px minimum. Specifically: kingdom tabs, biome legend chips, ability buttons, resource label taps, structure banner dismiss, prestige confirm. Add invisible padding around small visual targets when needed.

---

## Things to actively do

### G5. Maintain save versioning + explicit migration

**Why**: The data model will change repeatedly during development (e.g. the imminent multi-occupant → single-occupant transition). Without versioning, each change either breaks player saves or freezes the data model.

**How**: Every save file includes `save_version: int`. Each version bump has a migration function (`migrate_vN_to_vN1(data) -> data`). SaveSystem chains migrations on load.

**Concrete first use**: the single-species-per-tile transition (currently planned) requires `save_version` bump and a migration that flattens per-tile occupant arrays to singletons, picking the dominant occupant if multiple exist.

### G6. Build asset pipeline automation early

**Why**: Solo dev tools that save 10 min/day pay for themselves in a week. Manual atlas packing, import settings, re-tinting are constant tax.

**Worth building**:
- One command to re-import all art with correct settings (NEAREST filter, no compression)
- One command to validate asset filenames + sizes against the commission spec in `docs/VISUAL_DIRECTION.md`
- One command to generate atlases from individual PNGs once an asset class is finalized

### G7. Establish + enforce a shared color palette

**Why**: Cohesion across commissioned assets is mostly palette discipline. A limited palette (~24-32 colors) used consistently makes disparate assets feel like one world. Free atmospheric cohesion.

**How**: Define palette in code (e.g. `scripts/visual/palette.gd` exporting all hex codes). Every commission brief references it. Incoming art that uses off-palette colors gets quantized via Aseprite's remap-palette before integration.

**Signal**: An asset that looks "wrong" next to others — almost always a palette mismatch, not a style mismatch.

### G8. Drip-feed onboarding pacing

**Why**: Incremental games are built on slowly-revealed depth. 30-60 min of new concepts is typical genre pacing. The current 7 tips up front is fine for core verbs, but additional concepts should appear contextually as the player unlocks them — not all at start.

**Signal**: A player who quits within the first 10 minutes is probably not getting enough drip-feed (or facing too much front-load).

**Mitigation**: Audit which concepts surface at what wall-clock or progression milestone. Goal: never face the player with more than 2 new concepts at once. Symbiosis, structures, prestige, ecosystem unlocks — each should announce itself just before it becomes usable.

### G9. Build the daily / idle retention hook

**Why**: The incremental genre depends on "come back later" — players form a return habit only if idle gains exist and are surfaced on return.

**Mitigation**: Confirm Bio has an offline-progress mechanic (partial via `nutrient_system` accumulation). Surface explicitly on return: "While you were away: X biomass produced" toast. Possibly daily resource caps or first-of-day bonuses to reward consecutive-day returns.

---

## Open commitments to track

- [ ] Write `docs/ALPHA_GATE.md` (G2)
- [ ] Implement save versioning in `scripts/autoloads/save_system.gd` before single-species-per-tile transition (G5)
- [ ] Audit HUD touch targets against 44 px minimum (G4)
- [ ] Define shared palette in `scripts/visual/palette.gd` (G7)
- [ ] Plan onboarding drip-feed beyond the 7 initial tips (G8)
- [ ] Confirm + surface offline-progress hook (G9)
