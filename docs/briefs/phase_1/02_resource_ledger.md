# Brief 02 — ResourceLedger implementation

**Suggested agent**: ChatGPT 5.2 via Copilot.

You are working on the Bio-Fantasy RPG project. Before writing any code, read:
1. `docs/ARCHITECTURE.md` — section 3 (`ResourceLedger` contract).
2. `scripts/autoloads/resource_ledger.gd` — existing stub. Implement against this.
3. `scripts/autoloads/event_bus.gd` — for `resource_changed`.

## Goal
Implement `ResourceLedger` so resources can be added, spent, and queried. Every mutation must emit `EventBus.resource_changed(id, new_amount)`. Bundle spends must be atomic.

## Outputs (modify)
- `scripts/autoloads/resource_ledger.gd`

## Implementation notes
- Backing store: `var _amounts: Dictionary[StringName, float] = {}`. Unknown ids return `0.0` from `get_amount`.
- `add()` never goes below 0 (`max(0, ...)`).
- `spend(id, n)` returns `false` and does **not** mutate if `get_amount(id) < n`.
- `can_afford(costs)` returns `true` iff every entry is satisfied.
- `spend_bundle(costs)` is the atomic version: check all, then subtract all. If any fails, mutate nothing and return `false`. Emit one `resource_changed` per modified resource on success.
- Provide `reset_run()` that clears all amounts to 0 and emits `resource_changed` for each known id. This will be called by `PrestigeSystem` later.

## Acceptance criteria
- [ ] All six resource constants from the contract are present and exported.
- [ ] `spend_bundle` is atomic — verified by a unit test in `tests/test_resource_ledger.gd`.
- [ ] `resource_changed` fires exactly once per mutation (zero times on failed spends).
- [ ] `reset_run()` zeroes everything.
- [ ] Tests pass with the GUT addon installed.

## Tests to write
In `tests/test_resource_ledger.gd`:
```gdscript
extends GutTest
# - test_add_emits_signal
# - test_spend_insufficient_returns_false_no_mutation
# - test_spend_bundle_atomic_failure
# - test_reset_run_zeroes_all_known_resources
```

## Out of scope
- Resource generation from systems — that's `GrowthSystem` later.
- Persisting balances — `SaveSystem` handles in brief 03.
