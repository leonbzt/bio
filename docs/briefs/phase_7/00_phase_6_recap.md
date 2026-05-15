# Brief 00 — Phase 7 entry checklist

**Suggested agent**: do this yourself.

## Phase 6 status
- [ ] Phase 6 smoke test passed.
- [ ] Symbiosis run plays cleanly: layer toggle, dual yields, +30/50% bonus, wood_wide_web adjacency.
- [ ] Plantae and Fungi runs still work (regression).

## What Phase 7 is

Polish — the final phase before release. **No new mechanics.** Goal is shippability.

Eight briefs grouped into four areas:

| Area | Briefs |
|---|---|
| Cleanup of known nits + Phase 3 stubs | 01, 02 |
| Audio (currently zero — AudioManager has TODOs since Phase 1) | 03, 04 |
| Robustness | 05 (save backups), 06 (perf audit) |
| Release | 07 (balance pass), 08 (Play Console internal beta) |

## What Phase 7 is NOT
- Not a place to bolt on new features. If you find yourself wanting a new mechanic, write a "Phase 8" brief and defer.
- Not a code-quality refactor pass. Resist temptation to rewrite things that work. Touch only what the briefs touch.

## Iteration model

Unlike phases 1–6, Phase 7 briefs don't have hard dependencies. You can do them in any order, or in parallel if you have time. The order in this folder is just "easiest first → release last".

The only ordering constraint: **brief 08 (Play Console release) must come last**, after every other brief has landed. Don't ship with stub audio or missing balance.

## Out of scope
- iOS (deferred indefinitely — needs Mac + Apple dev account; the Android-first lock is in `TECHNICAL_SCOPE.md`).
- Cloud save sync. Local-only is fine for MVP.
- Localization beyond English. Already deferred.
- Tutorial / onboarding UI. The kingdom-unlock descriptions and evolution-tree tooltips are the only player-facing instruction.
