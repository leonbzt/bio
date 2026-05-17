# Brief 06 — Generations counter on title screen

**Suggested agent**: ChatGPT 5.2 via Copilot. Route diff to Claude — small UI add.

Read first:
1. `scenes/ui/title_screen.tscn` (or wherever the title/main-menu lives — verify path).
2. `scripts/ui/title_screen.gd`.
3. `scripts/systems/prestige_system.gd:200` — `prestige_count` is tracked in `meta.statistics`.
4. `docs/briefs/phase_11/00_phase_11_entry.md` decision 8 (descriptor thresholds).

## Goal
Display the player's total prestige count on the title screen with an evolving descriptor:

| Threshold | Descriptor |
|---|---|
| 0 | (no descriptor shown — pristine save) |
| 1–5 | "Pioneers" |
| 6–20 | "Settled Colonies" |
| 21–100 | "Networked Life" |
| 101+ | "The Anthropocene Watches" |

Final display: `BIO — Networked Life · 47 generations` (or similar, depending on title-screen layout).

Cheap to ship; sells the long-arc identity. Per the Phase 9 mechanics-vs-vision review.

## Implementation

### `scripts/ui/title_screen.gd`

Add at the end of existing `_ready` (or wherever the title text is set):

```gdscript
const _DESCRIPTOR_THRESHOLDS: Array = [
    [101, "The Anthropocene Watches"],
    [21,  "Networked Life"],
    [6,   "Settled Colonies"],
    [1,   "Pioneers"],
]


func _ready() -> void:
    # ... existing wiring ...
    _refresh_generations_label()


func _refresh_generations_label() -> void:
    var generations: int = _read_prestige_count()
    if generations <= 0:
        $GenerationsLabel.visible = false
        return
    $GenerationsLabel.visible = true
    var descriptor: String = _get_descriptor(generations)
    $GenerationsLabel.text = "%s · %d generations" % [descriptor, generations]


func _read_prestige_count() -> int:
    # Title screen runs before SaveSystem.load_or_create on some paths.
    # Read the save file directly if GameState isn't yet populated.
    if GameState.meta_save is Dictionary and not (GameState.meta_save as Dictionary).is_empty():
        var stats: Dictionary = (GameState.meta_save as Dictionary).get("statistics", {})
        return int(stats.get("prestige_count", 0))
    # Fall back to reading the save file directly.
    if not FileAccess.file_exists(SaveSystem.SAVE_PATH):
        return 0
    var file := FileAccess.open(SaveSystem.SAVE_PATH, FileAccess.READ)
    if file == null:
        return 0
    var text := file.get_as_text()
    file.close()
    var parser := JSON.new()
    if parser.parse(text) != OK:
        return 0
    var data: Variant = parser.data
    if not (data is Dictionary):
        return 0
    var meta: Variant = (data as Dictionary).get("meta", {})
    if not (meta is Dictionary):
        return 0
    var stats: Variant = (meta as Dictionary).get("statistics", {})
    if not (stats is Dictionary):
        return 0
    return int((stats as Dictionary).get("prestige_count", 0))


func _get_descriptor(count: int) -> String:
    for entry in _DESCRIPTOR_THRESHOLDS:
        if count >= int(entry[0]):
            return String(entry[1])
    return "Pioneers"   # safety fallback
```

### `scenes/ui/title_screen.tscn`

Add a `GenerationsLabel` (Label) below the title text or in a corner. Style:
- Smaller than title text (e.g., title is 32pt, generations is 14pt).
- Slightly faded (Color(1.0, 1.0, 1.0, 0.7)).
- Centered or right-aligned, depending on existing layout.

Example node tree addition:
```
TitleScreen
├── TitleLabel ("BIO")
└── GenerationsLabel ("Networked Life · 47 generations")
```

## Acceptance criteria
- [ ] Fresh save → no GenerationsLabel visible (0 prestiges).
- [ ] After 1 prestige → "Pioneers · 1 generations" displays.
- [ ] After 6 prestiges → descriptor flips to "Settled Colonies".
- [ ] After 21 → "Networked Life".
- [ ] After 101 → "The Anthropocene Watches".
- [ ] Returning to title screen after each prestige re-reads the count and updates the descriptor.
- [ ] No crashes when save file is missing or corrupted (label just hides).

## Out of scope
- Animation when descriptor transitions to a new tier (e.g., a one-time celebration on hitting "Networked Life" threshold). Polish.
- Per-tier title-screen background or music change. Big scope; consider for Tier 3 polish.
- Generations entry in the discovery log triggered at each threshold flip. Could add discovery_log entries for `&"milestone"` category with `trigger_id = &"generations_networked_life"`, etc. Defer to Phase 12 content pass.
- Right-grammar singular ("1 generation" vs "47 generations"). Acceptable to always say "generations"; English-only at launch.
