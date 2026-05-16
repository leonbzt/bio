# Brief 07 — Balance pass

> **Status (skipped — deferred)**: balancing the pre-niche game would tune numbers about to change in Tier 1. Revisit after Phase 10 (post-Lichen + Animal foundation) when the play loop is closer to its shipping shape. See `docs/ROADMAP.md` for rationale.

**Suggested agent**: do this yourself. Kilo can be used to suggest numeric variations from a rubric, but the actual "does this feel good" decision is yours.

Read first:
1. `data/species/`, `data/traits/`, `data/biomes/`, `data/events/`, `data/evolution_tree/` — every tunable number lives here.
2. `docs/DESIGN_PILLARS.md` — Pillar #5: "2 minute check-ins, 10 minute active play sessions".

## Goal
Tune the difficulty/tempo curve so a fresh player:
- Hits their first prestige within ~10 minutes of active play (plantae run).
- Earns enough EP across 2–3 plantae prestiges to afford `unlock_fungi`.
- Reaches symbiosis within 8–12 prestiges of total play (~2 hours of active time).
- Doesn't feel forced to grind any single run for >15 minutes.

Make all changes **in `.tres` files only**. No code changes in this brief.

## Method: structured iteration

### 1. Play a fresh plantae run for 15 minutes
Take notes:
- How quickly can you afford the second tile? (cost: 5 biomass)
- When does the first herbivore wave fire? Is it surprising or expected?
- Is Toxin Bloom (50 biomass) expensive enough to feel like a choice, or trivial?
- At 15 minutes, how much biomass have you earned? (target: 1000–3000)
- What's the pending EP at that point? (target: 10–17 with formula `sqrt(earned/10)`)

### 2. Adjust the obvious outliers

Tunables in priority order:

| File | Field | Default | If too fast | If too slow |
|---|---|---|---|---|
| `data/species/pioneer_grass.tres` | `tick_yield.biomass` | 0.5 | lower (e.g. 0.3) | raise (e.g. 0.8) |
| `data/biomes/grassland.tres` | `sunlight_per_tick` | 1.0 | lower | raise |
| `data/events/herbivore_wave.tres` | `payload.spawn_count` | 3 | raise | lower |
| `data/events/herbivore_wave.tres` | `payload.chew_ticks` | 4 | lower (faster eating) | raise |
| `data/evolution_tree/unlock_fungi.tres` | `meta_cost.evolution_points` | 10 | lower | raise |
| `data/evolution_tree/unlock_symbiosis.tres` | `meta_cost.evolution_points` | 15 | lower | raise |
| `data/evolution_tree/*` | `meta_cost.evolution_points` | varies | shift the whole tier down | shift up |

### 3. Re-test after every change
Don't batch multiple tuning changes — you'll lose the ability to attribute the result. Change one number, test 5 minutes, decide.

### 4. Cross-kingdom check
After plantae feels right, replay through to fungi and symbiosis. Check:
- Fungi feels different (not just plantae with violet tiles).
- Spore_infection event feels rewarding, not chaotic.
- Symbiosis bonus (1.30/1.50) is noticeable — co-occupied tiles visibly outpace single-layer.

## Common tuning pitfalls

- **Don't reduce numbers to make grind feel longer.** Long ≠ rewarding. If a run takes too long, the formula or yield is off.
- **Resist asymmetric kingdom buffs.** Plantae feels "best" right now because the wave is well-tuned. If you buff fungi to compete, you'll buff out of balance.
- **Test on a real device, not the editor.** Editor framerate and touch responsiveness lie.

## Acceptance criteria
- [ ] First prestige reachable in 8–12 minutes of fresh play.
- [ ] `unlock_fungi` affordable in 2–4 prestiges.
- [ ] `unlock_symbiosis` affordable in 6–10 cumulative prestiges.
- [ ] Symbiosis runs measurably outpace single-kingdom runs (Phase 6 exit criterion).
- [ ] No single run requires >15 minutes of active engagement.
- [ ] All five HUD numbers have meaningful spending sinks across the kingdoms.

## Out of scope
- Code changes. If you find yourself wanting one, write a follow-up brief.
- New content (more species, more events, more nodes). Polish, not addition.
