# Brief 07 — Visual niche differentiation (HUD + tile variants)

**Suggested agent**: ChatGPT for the wiring, Kilo for any icon variants.

Read first:
1. `scenes/ui/hud.tscn` — current resource bar and corner buttons.
2. `scripts/ui/hud.gd`.
3. `scripts/entities/tile_grid.gd` (post brief 04 + 05) — should have 5 atlas tile variants by now: base, plantae, fungi, parasite_plantae, mycorrhizal_fungi.

## Goal
Make the player **always know what niche they're playing**. Visual signals at two levels:
1. **HUD badge**: a small label/icon top-center that shows the current niche name. Hides between runs.
2. **Tile color variants** are already in place (briefs 04 + 05). This brief verifies they render correctly and adds an optional legend.

## HUD niche badge

Add a small `Label` to `hud.tscn` anchored top-center:

```
NicheBadge (Label, top-center, anchor_left=0.5, anchor_right=0.5, offset_top=4, offset_bottom=20)
  text = "Photosynthesizer"
  visible = false
```

In `hud.gd`:
- `@onready var _niche_badge: Label = $NicheBadge`.
- Subscribe to `EventBus.niche_changed`, `run_started`, `run_loaded`.
- `_refresh_niche_badge()`: look up the current niche's `display_name`, set the label text, set visible based on whether a run is active.

```gdscript
const NICHE_INDEX_PATH := "res://data/niches/_index.tres"
var _niches_by_id: Dictionary[StringName, NicheData] = {}


func _build_niche_index() -> void:
    var index := load(NICHE_INDEX_PATH) as NicheIndex
    if index == null:
        return
    for n in index.niches:
        _niches_by_id[n.id] = n


func _refresh_niche_badge() -> void:
    var niche_id: StringName = GameState.current_niche_id
    if niche_id == &"" or not _niches_by_id.has(niche_id):
        _niche_badge.visible = false
        return
    _niche_badge.text = _niches_by_id[niche_id].display_name
    _niche_badge.visible = true
```

Call `_build_niche_index()` from `_ready` and `_refresh_niche_badge()` from each of: `_ready`, `_on_niche_changed`, `_on_run_started`, `_on_run_loaded`.

## Tile color sanity

Verify each niche renders the intended atlas tile:

| Niche | Layer | Atlas coord | Color |
|---|---|---|---|
| Photosynthesizer plantae | Surface | (1, 0) | Bright green `#6cb86c` |
| Parasite plantae | Surface | (3, 0) | Crimson `#a8425f` |
| Decomposer fungi | Subsurface | (2, 0) | Violet `#7a5fa8` |
| Mycorrhizal fungi | Subsurface | (4, 0) | Teal `#5fa888` |

If the tile_grid still references the old `set_owned()` API anywhere, replace with the niche-variant-aware versions per briefs 04 + 05.

## Legend (optional)

In the pause menu, add a small "Legend" tab or expander showing the four tile colors with names. Useful for new players and discovery-log-style completionists. If short on time, skip — the niche badge alone is enough for navigation.

## Acceptance criteria
- [ ] Niche badge appears top-center during a run, hidden between runs.
- [ ] Badge text matches the current niche's `display_name`.
- [ ] Each niche's tiles render in the spec'd color when placed.
- [ ] Switching niches across prestiges: badge updates correctly.
- [ ] HUD layout doesn't break on portrait 360×640 (badge doesn't overlap with the tick indicator or the toxin button).

## Out of scope
- Niche icons (textures). Color-only is fine for v1; icons are Phase 9+ polish.
- Animated transitions on niche change.
- Tile-overlay shimmer for symbiotic/mycorrhizal-boosted tiles. Phase 10 may add this.
