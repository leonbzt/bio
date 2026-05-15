# Data directory

This is where designer-facing content lives as Godot `.tres` resource files. Each subdirectory holds instances of one Resource schema defined in `scripts/data/`.

Adding content here changes the game **without touching scripts** — that's the data-driven principle from `docs/ARCHITECTURE.md` section 2.

| Folder | Schema (in `scripts/data/`) | Contains |
|---|---|---|
| `kingdoms/` | `kingdom_data.gd` | One file per playable kingdom (plantae, fungi, …) |
| `species/` | `species_data.gd` | Individual species belonging to a kingdom |
| `traits/` | `trait_data.gd` | Reusable traits applied to organisms via composition |
| `events/` | `event_data.gd` | Ecological pressure events (drought, herbivore wave, …) |
| `biomes/` | `biome_data.gd` | Tile biome definitions + per-tick yields |
| `evolution_tree/` | `evolution_node_data.gd` | Meta-progression tree nodes |

## File naming
Lowercase snake_case matching the resource's `id` field. Example: `data/traits/thick_bark.tres` has `id = &"thick_bark"`.

## Generating content
Use the **Content generation prompt** in `docs/AI_PROMPTS.md` with a Kilo Code free model. The output should be valid `.tres` text that loads in Godot 4.
