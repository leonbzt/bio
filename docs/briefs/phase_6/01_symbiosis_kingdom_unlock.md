# Brief 01 — Symbiosis kingdom + unlock evolution node

**Suggested agent**: Kilo for .tres content, ChatGPT for the unlock-flow integration.

Read first:
1. `data/evolution_tree/unlock_fungi.tres` — the pattern to mirror.
2. `scripts/systems/prestige_system.gd` — `purchase_node`, `_unlock_kingdom`, `start_run`.
3. `scripts/ui/prestige_screen.gd` — how the kingdom-select UI iterates `meta.unlocked_kingdoms`.

## Goal
Add a new evolution node `unlock_symbiosis` that, when purchased, adds `&"symbiosis"` to `meta.unlocked_kingdoms`. The kingdom-select UI then offers it as a third choice.

## Outputs (create)

### `data/evolution_tree/unlock_symbiosis.tres`
- `id = &"unlock_symbiosis"`
- `display_name = "Symbiotic Awakening"`
- `description = "Plant and fungal kingdoms can grow as one."`
- `prerequisites = [&"unlock_fungi"]` (must already have fungi unlocked)
- `meta_cost = {"evolution_points": 15}`
- `grants_traits = []`
- `grants_kingdoms = [&"symbiosis"]`

### Update `data/evolution_tree/_index.tres`
Add `unlock_symbiosis.tres` as a new ExtResource and append to the `nodes` array.

## Acceptance criteria
- [ ] After purchasing `unlock_fungi` AND `unlock_symbiosis`, `meta.unlocked_kingdoms` contains `["plantae", "fungi", "symbiosis"]`.
- [ ] The prestige screen shows three "Begin run as ..." buttons.
- [ ] Starting a symbiosis run sets `GameState.current_kingdom_id = &"symbiosis"` and emits `run_started`.

## No code changes required if everything is data-driven
The existing `purchase_node` flow already calls `_unlock_kingdom(kingdom_id)` for each entry in `grants_kingdoms`. The kingdom-select UI iterates `meta.unlocked_kingdoms` and produces a button per entry. So this brief is mostly content + maybe a tiny label fix.

### One label change might be needed
If `prestige_screen.gd` hard-codes labels like `"Begin run as Plantae"` per kingdom_id, add a case for `&"symbiosis"` → `"Begin run as Symbiosis"`. Look for a `match` or `if/elif` chain on kingdom_id.

## Out of scope
- The actual symbiosis run mechanics (briefs 02–04 handle that).
- Hybrid evolution nodes beyond the unlock (brief 05).
- A custom prestige formula for symbiosis runs. Use the existing formula for now.
