# Task Briefs

Self-contained, paste-into-an-agent task instructions for the project.

## How to use

1. Pick the next unfinished brief from the lowest-numbered phase folder.
2. Open the brief and follow the routing recommendation at the top (Claude / ChatGPT / Kilo).
3. Paste the brief content into the chosen agent's chat. **Always include `docs/ARCHITECTURE.md` in the agent's context** — it's the contract source of truth.
4. Review the output against the brief's acceptance criteria.
5. If the brief touches a contract (signal, Resource schema, save format) hand the diff to Claude before merging.

## Phase status (see `docs/ROADMAP.md` for tier framing)

### MVP — Phases 1–7
- `phase_1/` — Foundation. **Complete.** 9 briefs (00–08).
- `phase_2/` — Plant prototype. **Complete.** 9 briefs (00–08).
- `phase_3/` — Active gameplay. **Complete.** 9 briefs (00–08).
- `phase_4/` — Prestige. **Complete.** 9 briefs (00–08).
- `phase_5/` — Fungi. **Complete.** 9 briefs (00–08).
- `phase_6/` — Symbiosis. **Complete.** 8 briefs (00–07).
- `phase_7/` — Polish + release. **Partially complete (deferred).** 9 briefs (00–08). Shipped: 01 cleanup, 02 drought/cool_spell, 03 audio SFX, 04 audio music, 05 save robustness. **Brief 06 (perf) partial.** **Briefs 07 (balance) + 08 (release readiness) skipped** — release readiness deferred until Tier 1 lands; balance pass deferred to a post-Tier-1 polish window.

### Tier 1 — Make the MVP a real game
- `phase_8/` — Niche system. **Complete.** 9 briefs (00–08). Smoke test passed 2026-05-16. Symbiosis-kingdom regression fix landed in `prestige_system.gd` + `prestige_screen.gd`.
- `phase_9/` — Interconnected progression web + discovery log scaffold. **In progress.** 10 briefs (00–09). Brief 07 (28 discovery entries) implemented + integration audit landed (parasitic_plantae canonical id + run_started kingdom fire). Locked: single scrollable canvas tree UI, hard `requires_kingdom_played` gate, discovery log with all 4 trigger sources, locked entries hidden (denominator-only), Claude authors entry voice text directly in brief 07.
- `phase_10/` — Symbiosis reframe + Animal foundation + niche signatures + stub resources. **13 briefs written 2026-05-17.** Layered foundation (Lichen as Fungi niche, hybrid niche+species model), retire symbiosis kingdom (v9→v10 migration), parasite biomass-steal + mycorrhizal substrate-claim signatures, Animal Herbivore + Predator (Predator placeholder; insects deferred to Phase 14), 6 stub resources with visible-but-greyed HUD display. Largest phase to date with two internal checkpoints (after brief 05 Lichen + after brief 09 animals).

### Tier 2 — World feedback + eras
- `phase_11/` — **World feedback layer**. **10 briefs written 2026-05-17.** Active-event interventions (Irrigate/Bundle/Cull), tile history persistence + faint pre-existing tint, soil_memory tile-local refactor, soft prestige goal + banner, generations counter on title screen.
- `phase_12/` — Era system + ecosystem selector (was Phase 11).
- `phase_13/` — Ecosystem-specific biomes + events + graphics (was Phase 12). Includes axis-scoped events (`EventData.scope`).
- `phase_14/` — Predator + Scavenger niches; Cordyceps; Coral (first 3-layer pack) (was Phase 13).
- `phase_15/` — More layered species packs (Termite Mound, Mycorrhizal Forest) (was Phase 14).

### Tier 3 — Aspirational
See `docs/ROADMAP.md`. Briefs only after Tier 2 ships.

## Briefs are written one phase at a time
This keeps contracts adjustable. Claude writes briefs for phase N+1 only after phase N's smoke test passes and any contract drift is folded into `ARCHITECTURE.md`.
