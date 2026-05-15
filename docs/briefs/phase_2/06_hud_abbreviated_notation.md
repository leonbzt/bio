# Brief 06 — HUD abbreviated notation

**Suggested agent**: ChatGPT 5.2 via Copilot. Cosmetic polish → Kilo.

Read first:
1. `scripts/ui/hud.gd` — current `_format_resource()`.

## Goal
Replace plain `%d` formatting with abbreviated notation: `1.2K`, `3.4M`, `7.8B`. Keeps the HUD readable at endgame.

## Outputs (modify)
- `scripts/ui/hud.gd` — add a `_abbreviate(amount: float) -> String` helper and route `_format_resource` through it.

## Format rules
| Range | Format |
|---|---|
| < 1000 | `"%d"` (integer) |
| 1,000 – 999,999 | `"%.1fK"` (one decimal) |
| 1,000,000 – 999,999,999 | `"%.1fM"` |
| 1,000,000,000 – 999,999,999,999 | `"%.1fB"` |
| ≥ 1 trillion | `"%.1fT"` |

Examples:
- `847` → `"847"`
- `1499` → `"1.5K"` (rounded)
- `12_345` → `"12.3K"`
- `1_500_000` → `"1.5M"`
- `999_999` → `"1.0M"` (acceptable rounding)

Implementation pattern:
```gdscript
func _abbreviate(amount: float) -> String:
    var abs_amount := abs(amount)
    if abs_amount < 1_000.0:
        return "%d" % int(amount)
    if abs_amount < 1_000_000.0:
        return "%.1fK" % (amount / 1_000.0)
    if abs_amount < 1_000_000_000.0:
        return "%.1fM" % (amount / 1_000_000.0)
    if abs_amount < 1_000_000_000_000.0:
        return "%.1fB" % (amount / 1_000_000_000.0)
    return "%.1fT" % (amount / 1_000_000_000_000.0)
```

Then in `_format_resource`:
```gdscript
return "%s: %s" % [name, _abbreviate(amount)]
```

## Tests
Add `tests/test_hud_format.gd` with a few `assert_eq` cases for the abbreviation helper. Extract it to a static method or `utils/format_utils.gd` if you want to call it without instancing HUD (recommended — that lets the test skip scene setup).

## Acceptance criteria
- [ ] Resources under 1K display as integers.
- [ ] Resources ≥ 1K display with one decimal and unit suffix.
- [ ] No flickering between formats during normal play (the threshold transition at 999→1.0K is acceptable).
- [ ] HUD still updates on `resource_changed` (test by manually calling `ResourceLedger.add(BIOMASS, 1500)` from the debugger).

## Out of scope
- Locale-aware separators (`1,234` vs `1.234` vs `1 234`).
- Color coding for resource thresholds.
