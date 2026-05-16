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
- `phase_7/` — Polish + release. **In progress.** 9 briefs (00–08).

### Tier 1 — Make the MVP a real game
- `phase_8/` — Niche system. *Not yet written. Awaiting Phase 7 completion + open-question answers in ROADMAP.md.*
- `phase_9/` — Interconnected progression web. *Not yet written.*
- `phase_10/` — Symbiosis reframe + Animal kingdom foundation. *Not yet written.*

### Tier 2 — Era + ecosystem progression
- `phase_11/`–`phase_14/` — Eras, ecosystems, more niches and symbiotic species. *Not yet written.*

### Tier 3 — Aspirational
See `docs/ROADMAP.md`. Briefs only after Tier 2 ships.

## Briefs are written one phase at a time
This keeps contracts adjustable. Claude writes briefs for phase N+1 only after phase N's smoke test passes and any contract drift is folded into `ARCHITECTURE.md`.
