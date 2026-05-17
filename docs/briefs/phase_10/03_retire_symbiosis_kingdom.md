# Brief 03 — Retire `&"symbiosis"` kingdom from code + data

**Suggested agent**: ChatGPT 5.2 via Copilot. Route diff to Claude — refactor blast radius is wide.

Read first:
1. `docs/briefs/phase_10/01_save_v10_migration.md` (data migration; must land first).
2. `scripts/systems/prestige_system.gd` — special-cases `&"symbiosis"` in `start_run` + `_resolve_niche`.
3. `scripts/systems/growth_system.gd` — `_tick_symbiosis()` path.
4. `scripts/ui/prestige_screen.gd` — kingdom-button display.
5. Search the whole codebase: `grep -rn '&"symbiosis"' scripts/`.

## Goal
Remove `&"symbiosis"` as a kingdom from code. The save migration handles existing data; this brief is the code cleanup. After it lands, no script references symbiosis as a kingdom; the in-flight runs that migrated to fungi-lichen still function (mechanic-wise) because brief 04 + 05 will build out the layered placement they now use.

**This brief is destructive**: it removes the symbiosis kingdom path entirely. Until brief 04 (multi-layer engine) + brief 05 (Lichen content) land, the fungi-lichen runs migrated by brief 01 will fall back to plain fungi behavior (which is fine — just not the layered experience yet). Lichen properly works after brief 05.

## Concrete changes

### `scripts/systems/prestige_system.gd`

Current `start_run`:
```gdscript
func start_run(kingdom_id: StringName, niche_id: StringName = &"") -> void:
    if not is_kingdom_unlocked(kingdom_id):
        return
    var resolved_niche: StringName = _resolve_niche(kingdom_id, niche_id)
    # Symbiosis has no niches of its own; sub-systems fall back to defaults
    # per kingdom (plantae→photosynthesizer, fungi→decomposer). Phase 10 removes
    # the symbiosis kingdom entirely; until then, allow empty niche_id through.
    if resolved_niche == &"" and kingdom_id != &"symbiosis":
        push_error("PrestigeSystem: no valid niche for kingdom %s" % String(kingdom_id))
        return
    # ...
    if kingdom_id == &"symbiosis":
        GameState.placement_target = &"plantae"
    else:
        GameState.placement_target = kingdom_id
    # ...
    if kingdom_id == &"symbiosis" and MetaModifiers.is_unlocked(&"symbiotic_generosity"):
        ResourceLedger.add(ResourceLedger.BIOMASS, 10.0)
        ResourceLedger.add(ResourceLedger.NUTRIENTS, 5.0)
    # ...
```

Refactor to:
```gdscript
func start_run(kingdom_id: StringName, niche_id: StringName = &"") -> void:
    if not is_kingdom_unlocked(kingdom_id):
        return
    var resolved_niche: StringName = _resolve_niche(kingdom_id, niche_id)
    if resolved_niche == &"":
        push_error("PrestigeSystem: no valid niche for kingdom %s" % String(kingdom_id))
        return
    # ...
    GameState.placement_target = kingdom_id
    # Multi-layer placement target rotation is owned by brief 04's MultiLayerPlacementSystem.
    # ...
    # symbiotic_generosity bonus moves to the Lichen niche's onstart hook (brief 05).
    # Remove the kingdom_id == &"symbiosis" check here.
```

The symbiotic_generosity start-bonus needs a new home. Brief 05 (Lichen niche) lifts it into a niche-start hook that fires whenever the run niche is Lichen.

### `scripts/systems/growth_system.gd`

Remove the `_tick_symbiosis()` function entirely. The corresponding entry in `_on_tick`:
```gdscript
elif kingdom_id == &"symbiosis":
    _tick_symbiosis()
```
becomes unreachable and is deleted. The multi-layer engine (brief 04) replaces this code path; for now (between brief 03 and brief 04 landing), symbiosis-migrated runs will fall back to the `_tick_single_kingdom(&"fungi")` path because their kingdom_id is now `&"fungi"`. That's the temporary behavior.

Also remove the symbiosis-specific branches in `_apply_yields` (e.g., `apply_symbiosis_bonus`, `_is_tile_symbiotic`, `_is_adjacent_to_symbiotic`, `_get_symbiosis_bonus`). These are getting reworked into the layer-aware code path in brief 04. Stage their removal here for a clean diff.

### `scripts/ui/prestige_screen.gd`

`_refresh_kingdoms` iterates `meta_save["unlocked_kingdoms"]` and creates a button per kingdom. Since brief 01 migration strips `"symbiosis"` from that list, no UI change should be needed — the symbiosis button just no longer renders.

Verify:
- [ ] Open prestige screen on a migrated v10 save. Kingdom buttons: Plantae, Fungi. No Symbiosis.

Also remove any symbiosis-specific UI code paths (e.g., the `if niches.is_empty()` symbiosis-no-niche path in `_on_kingdom_button_pressed`). With brief 04 + 05, every kingdom has at least one niche; the empty-niches branch becomes dead.

### `data/evolution_tree/unlock_symbiosis.tres`

The node still exists but its semantics are about to change. Brief 05 redirects this node to `unlock_lichen` (grants the Lichen niche under Fungi, not the symbiosis kingdom). Do not delete the node — that would invalidate `meta.evolution_tree.unlock_symbiosis: true` flags from existing saves.

Edit the node in-place (brief 05 will overwrite the content; this brief just ensures the node still parses):
- Keep id = `&"unlock_symbiosis"` for save compatibility
- The display_name / description / grants_kingdoms / etc. are rewritten in brief 05

Optionally rename the id to `&"unlock_lichen"` and add a migration entry — but the brief 01 migration already touches save state for symbiosis; doing the node rename there too would be cleaner. Decision: **leave the node id as `unlock_symbiosis`** — display text changes are user-visible; id changes propagate through save migrations and are more disruptive. Lichen-as-niche label is a content concern.

### Searched references

Run a final grep:
```bash
grep -rn '&"symbiosis"' scripts/ data/
```

For every hit, decide: keep (if it's a backwards-compat path used by save migration), delete, or replace.

Acceptable remaining hits after this brief:
- `scripts/autoloads/save_system.gd` migration arm (the v9 → v10 migration in brief 01)
- Any documentation comment referencing "symbiosis kingdom (retired in Phase 10)"

Unacceptable remaining hits:
- Any runtime code path that branches on `current_kingdom_id == &"symbiosis"`
- Any UI that shows "Symbiosis" as a selectable kingdom

## Acceptance criteria
- [ ] `grep -rn '&"symbiosis"' scripts/` returns only save-migration references.
- [ ] No prestige-screen button for Symbiosis (verified on a migrated save).
- [ ] Plantae and Fungi runs play unchanged (regression).
- [ ] A migrated `kingdom_id == &"fungi"` + `niche_id == &"lichen"` run loads without crash. It plays as plain fungi until brief 04 + 05 land — that's expected.
- [ ] `unlock_symbiosis.tres` still loads (we'll repurpose it in brief 05).
- [ ] Symbiotic_generosity meta-modifier bonus relocation noted as a TODO for brief 05 (Lichen niche start hook).

## Out of scope
- Multi-layer placement engine (brief 04).
- Lichen content + niche-start hook for symbiotic_generosity bonus (brief 05).
- Mutualism / wood_wide_web evolution nodes — these still work on plantae+fungi tiles and don't need symbiosis-kingdom-specific code (the brief 04 multi-layer engine will respect them).
