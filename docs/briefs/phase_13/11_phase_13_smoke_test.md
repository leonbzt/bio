# Brief 11 — Phase 13 manual smoke test (behavior parity)

**Suggested agent**: you, on device.

Run after briefs 01–10 land and the build is green. **The goal is behavior parity** — every gameplay path that worked in Phase 12 still works after the species-first reshape. No new content; this is the proof the rework didn't break anything.

## Pre-flight

- [ ] Build runs on Android device.
- [ ] At least one v11 save exists (Phase 12 ship state) — keep a copy backed up in case of catastrophic regression.
- [ ] `docs/SPECIES_MODEL.md` Locked Decisions 11-20 understood (you'll be checking them).

## Test path A — Save migration (lossless transform)

Use a v11 save with a run in progress.

1. Launch app, load the save.
2. Confirm app loads without crash.
3. Inspect the save file directly:
   - `version: 12`.
   - `meta.species_unlocked` contains at least `"pioneer_grass"` (plus starters for any played kingdoms).
   - `meta.species_played` exists (likely empty if no prestige yet on v12).
   - `meta.niches_played` does not exist.
   - `run.starting_species_id` set (mapped from old niche or kingdom default).
   - `run.unlocked_species_in_run` contains starter.
   - `run.niche_id` does not exist.
   - `run.tiles[*].occupants` is a dict (not `surface_owner` / `subsurface_owner`).
4. The in-flight run resumes visually identical to v11 (tiles in the same positions, owned by the right kingdoms).

Repeat with v11 saves from:
- A plantae photosynth run.
- A fungi decomposer run.
- A parasitic plantae run.
- A lichen run (this is the highest-risk migration case).
- An animal herbivore run.

## Test path B — Behavior parity per starter species

For each starter species below, start a fresh run and confirm core mechanics work:

### B1 — pioneer_grass (default plantae)
- [ ] Pick from world map → starting species picker → `pioneer_grass`.
- [ ] Run starts; identity strip shows "Pioneer Grass — [ecosystem name]".
- [ ] Tap empty tile: plants a plantae tile.
- [ ] Subsequent tiles require adjacency (rule preserved).
- [ ] Biomass ticks up at the expected rate (compare to Phase 12 expectations — within 5%).
- [ ] `drought` event still fires; reduces yields as before.
- [ ] `herbivore_wave` event still fires; herbivores still eat tiles (kingdom_required check now flows via the (vestigial) `current_kingdom_id` mirror or via the upcoming Phase 14 scope rewrite — confirm the event triggers).

### B2 — mycelium_thread (default fungi)
- [ ] Pick `mycelium_thread` as starting species.
- [ ] Tap empty tile: places fungi (subsurface slot).
- [ ] Subsequent tiles require adjacency / corpse / plantae substrate.
- [ ] Decay + spores + biomass yields all tick.
- [ ] `spore_infection` event fires.
- [ ] Fungi-on-plantae symbiosis bonus (×1.30 base, ×1.50 with mutualism node) still applies.

### B3 — bramble (parasitic plantae)
- [ ] Unlock via EP if not already (`unlock_parasitic_plantae` node now grants `bramble`).
- [ ] Pick bramble from species picker. (Or start as pioneer_grass and introduce bramble mid-run.)
- [ ] Bramble can place adjacent to ANY owned tile (own or another kingdom's).
- [ ] Per-tick parasite-steal bonus fires (via `tick_effects` handler) when adjacent to plantae/fungi.
- [ ] Removing the adjacent target removes the bonus.

### B4 — mycelium_thread_mycorrhizal (new species)
- [ ] Unlock via EP (`unlock_mycorrhizal_fungi` now grants this species).
- [ ] Pick or introduce.
- [ ] Must place on or adjacent to a plantae tile.
- [ ] `mycorrhizal_bond` flag stamped on tile data when placed atop plantae.
- [ ] ×1.20 yield bonus on bonded tile.

### B5 — lichen_common (recipe)
- [ ] Unlock via EP.
- [ ] Pick lichen as starting species.
- [ ] First-tile-free behavior: tap empty tile → places both pioneer_grass AND mycelium_thread atomically.
- [ ] Cost paid = combined component costs + recipe own cost.
- [ ] Tile renders with the warm yellow-green blended fill (brief 09).
- [ ] Symbiosis bonus applies to the lichen tile (plantae + fungi both occupy).
- [ ] Try placing lichen on a tile that already has pioneer_grass → fails atomically (no partial fungi placement).

### B6 — common_grazer (animal herbivore)
- [ ] Pick.
- [ ] First animal tile places freely.
- [ ] Subsequent animals require adjacency to ANY owned tile.
- [ ] Animal tile renders with orange border (brief 09).
- [ ] Animal yields tick.

### B7 — common_predator (animal predator)
- [ ] Unlock via EP.
- [ ] Pick or introduce.
- [ ] Border renders red-brown.
- [ ] Spawn + move behavior identical to Phase 12.

## Test path C — In-run species introduction

1. Start a pioneer_grass run.
2. Accumulate enough biomass for the bramble introduce_cost (`{biomass: 80}`).
3. Open the species panel.
4. Confirm bramble appears in the "Available" section with cost shown.
5. Tap "Introduce bramble" → pays cost, bramble moves to "Introduced" section.
6. Tap bramble in the panel → it becomes the active placement target.
7. Tap a tile → places bramble (via parasitic_plantae rule).
8. Confirm: pioneer_grass tiles still tick normally; bramble tiles tick + steal.

## Test path D — Multi-species coinhabitation

1. In any plantae run, also unlock + introduce mycelium_thread (fungi).
2. Tap a tile to place mycelium_thread on a tile already holding pioneer_grass.
3. Result: both occupy the tile (plantae slot + fungi slot).
4. Tile renders with the blended fill.
5. Symbiosis bonus applies (×1.30 yields on plantae + fungi).
6. Try placing a SECOND plantae species on the same tile (e.g., bramble) → fails (slot occupied).

## Test path E — Recipe atomic placement

1. Lichen run.
2. Place lichen on empty tile → succeeds, both components placed.
3. Place lichen on a tile holding only pioneer_grass → fails (atomic; no partial fungi placement).
4. Place lichen on a tile holding only mycelium_thread → fails.
5. Cost: confirm the failed placements do not consume resources.

## Test path F — Ecosystem completion (Phase 12 parity)

For each of the 6 Phase 12 ecosystems:
- [ ] Start a run on that ecosystem.
- [ ] Meet the ecosystem's completion criterion (using species that satisfy any `completion_required_species` / `completion_required_biome` field, which after brief 03's reshape replace the old niche/kingdom gates).
- [ ] Prestige.
- [ ] Confirm `meta.ecosystem_completions[ecosystem_id] = true`.
- [ ] After completing all 3 Cryogenian ecosystems, Devonian unlocks.

## Test path G — Mass extinction narrative

After completing all 3 Cryogenian ecosystems and triggering Cryogenian → Devonian transition:
- [ ] Era transition passage shows (Phase 12 narrative beat).
- [ ] Mass extinction toast fires.
- [ ] (Phase 13 does NOT add gameplay teeth — that's Phase 14. Narrative parity only.)

## Test path H — Diversity prestige multiplier

1. Start a run; introduce 2+ species over the course of the run (e.g., pioneer_grass + mycelium_thread).
2. Prestige.
3. Confirm prestige summary shows:
   - "Species cultivated: 2"
   - "×1.1 diversity bonus"
   - EP earned = base * 1.1, rounded.
4. Repeat with 3 species: ×1.2 bonus.
5. Single-species run: no bonus shown / multiplier 1.0.

## Test path I — Discovery entries

- [ ] First introduction of each species unlocks `disc_niche_*` entry (despite the rename, entry ids stayed stable — they unlock on the species trigger now).
- [ ] First prestige of a starting species adds to `meta.species_played`.
- [ ] Discovery log denominator unchanged from Phase 12 (no entries added or removed; only re-categorized).
- [ ] Discovery log UI groups entries correctly under the new `species` category.

## Test path J — Niche cleanup verification

- [ ] `data/niches/` folder does not exist.
- [ ] `scripts/data/niche_data.gd` does not exist.
- [ ] `scripts/autoloads/multi_layer_placement.gd` does not exist.
- [ ] `scripts/systems/parasite_steal_system.gd` + `parasite_decay_system.gd` do not exist.
- [ ] `EventBus.niche_changed` signal does not exist.
- [ ] Grep `current_niche_id` returns zero hits.
- [ ] Grep `NicheData` returns zero hits.
- [ ] Grep `MultiLayerPlacement` returns zero hits.
- [ ] Project loads without `push_error` from missing files.

## Test path K — Regression sweep

- [ ] Phase 11 active interventions (Irrigate, Bundle, Cull) still trigger during their events.
- [ ] Phase 11 soft-prestige goals still appear + complete.
- [ ] Phase 12 world map era tabs + ecosystem cards still work.
- [ ] Save/load round-trip works.
- [ ] Offline progress still ticks for the time elapsed.
- [ ] Audio crossfade between kingdoms still works (now driven by starting species's kingdom_id).
- [ ] No new uncaught exceptions in the log over a 20-minute play session covering 3+ runs.

## Sign-off

- [ ] All paths A–K pass.
- [ ] Save migration is lossless for the common Phase 12 cases.
- [ ] No visible new content — the rework is invisible to the player except: species picker replaces kingdom/niche cascade, species panel exists during play, animal tiles render as borders, lichen tiles render as blended yellow-green.
- [ ] Update `docs/ROADMAP.md` Phase 13 row to ✅.
- [ ] Update `MEMORY.md` if any locked decisions changed during implementation.
- [ ] Tag commit `phase_13_species_first_complete` for rollback reference.

## If something fails

- **Save load crashes**: bisect by loading a v11 save with the migration logged. Likely a v11 → v12 transform mismatch (brief 01). Roll back to backed-up v11 save; iterate on `_migrate_v11_to_v12`.
- **Tiles invisible**: the rendering update (brief 09) needs the `set_occupant` path called from TerritorySystem (brief 04). Confirm `_repaint_tile` is invoked on `add_occupant`.
- **Tick yields wrong**: brief 05's `_apply_yields` generalization either missed a species or double-counts. Add `print(species.id, total)` to confirm which species ticks each tick.
- **Niche-keyed reference still firing**: missed a consumer in brief 06 or 08. Grep again.
- **Lichen placement failing**: recipe rule (brief 06) either misreads `recipe_components` or fails the per-component validation. Add print to `_rule_recipe` to see which sub-evaluation rejects.

---

**Phase 13 complete** = Phase 14 (content pass on the species-first foundation) is unblocked. The paused original-Phase-13 briefs (`docs/briefs/phase_13_paused/`) become the source material for Phase 14 with the translations noted in their README.
