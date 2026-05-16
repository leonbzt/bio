# Brief 08 — Release readiness: Play Console internal beta

> **Status (skipped — deferred)**: internal-beta release deferred until Tier 1 ships. Releasing the pre-niche MVP would invite testers to a play loop that's about to change substantially. Revisit after Phase 10 (Lichen + Animal foundation). The keystore generation, version bumping, and Play Console listing steps remain valid when you do come back. See `docs/ROADMAP.md` for rationale.

**Suggested agent**: do this yourself. ChatGPT for any error troubleshooting.

Read first:
1. `docs/ROADMAP.md` Phase 7 exit criterion: "stable build on Play Console internal track, 5 testers complete one full plant → fungi → symbiosis loop."
2. Earlier briefs — make sure 01–07 are all done.

## Goal
Get the game on the Play Console internal-test track. Five testers run through the full kingdom cycle. No critical bugs found.

## Pre-flight (run these first; abort if any fails)
- [ ] Brief 01 (cleanup) shipped.
- [ ] Brief 02 (drought/cool_spell handlers) shipped.
- [ ] Briefs 03 + 04 (audio) shipped — no missing-stream warnings in logcat.
- [ ] Brief 05 (save robustness) shipped. Tested with hand-corrupted primary save.
- [ ] Brief 06 (perf) all thresholds met on the test device.
- [ ] Brief 07 (balance) feels good in a fresh run.

## Step 1 — Pre-release housekeeping

### Bump version
In `project.godot`:
```
[application]
config/version="1.0.0"
```

(Or check Godot's export preset for the version_code / version_name fields.)

### Set release-quality icon
Replace `icon.svg` with a real icon (512×512 PNG ideal). The default Godot icon is a tell.

### Strip debug
- In `_smoke_*.gd` files (if any remain): delete.
- In `prestige_screen.gd` or anywhere: remove debug print statements.
- Ensure no `_smoke_growth` references remain (`grep -ri smoke scripts/` should be empty).

### Verify export preset
- Application/Package = a sensible domain reverse (e.g. `com.leon.bio`).
- Signing = release keystore (NOT the debug keystore from Phase 1's brief 00).
  - Generate a release keystore with `keytool` or Android Studio.
  - **Back up the keystore + password somewhere safe.** Losing it means you can never push updates to this APK on the Play Store.
- Min SDK = 24 (from `TECHNICAL_SCOPE.md`).
- Target SDK = whatever the Play Console currently requires (check today).

## Step 2 — Create the Play Console listing

1. Sign in at https://play.google.com/console. One-time $25 dev fee.
2. Create a new app. Title: "Bio-Fantasy" or whatever you settle on. English. Free.
3. Fill the minimum store-listing fields:
   - Short description (1 sentence).
   - Full description (a paragraph from `GAME_VISION.md` works).
   - 2 screenshots (just `adb screencap` from your device, edit out the status bar).
   - A 1024×500 feature graphic. Can be a quick mockup.
   - Privacy policy URL — needed even for offline games. Use a free generator (e.g. termly.io) and host on GitHub Pages.

## Step 3 — Build & upload

### Build the release APK/AAB
- Use App Bundle (.aab) — Play Store requires it for new apps.
- Export from Godot's Android preset with the release keystore.

### Upload to internal testing
- Play Console → Testing → Internal testing → Create new release → upload the AAB.
- Add release notes (one paragraph).
- Roll out to internal testing.
- Add 5 tester email addresses (Google accounts) to the internal-test allowlist.
- Send them the opt-in URL.

## Step 4 — Tester instructions (paste into the email)

```
Hi — thanks for testing Bio-Fantasy!

Opt-in: <play store opt-in URL>
Install: search "Bio-Fantasy" in Play Store after opting in.

What to do:
1. Open the app. Start a Plantae run.
2. Play until you've prestiged once and gotten some EP.
3. Keep playing until you've unlocked Fungi, then unlocked Symbiosis.
   (Total play time expected: ~2 hours, fine to do across multiple sessions.)
4. Try a Symbiosis run — toggle the layer button bottom-left.

What I need from you:
- Did anything crash? (If yes, please send a screenshot and what you were doing.)
- Did anything feel boring or frustrating? Where exactly?
- Did you understand what to do, or were you confused at any step?
- Whatever else you noticed.

Send feedback to <your email or a feedback form>. Thanks!
```

## Step 5 — Track feedback

Keep a `docs/tester_feedback.md` (gitignored or shared, your call). For each tester:
- Date, version installed.
- Crashes encountered.
- Stuck-points / confusion.
- Quotes about what felt good or bad.

## Exit criterion
- 5 testers complete the full plant → fungi → symbiosis loop without crashing.
- No P0 bugs (data loss, save corruption, hard crash on launch).
- Tester sentiment is at least "interesting, would play more" — exact words don't matter; vibe does.

## What comes after Phase 7

You're done with the MVP. The choices for what's next:

1. **Public soft launch** — promote from internal → closed testing → public. Take the feedback into account.
2. **Phase 8 content expansion** — more biomes, more species, more events, more evolution nodes. Same engine, all data-driven.
3. **iOS port** — needs Mac + Apple dev account. Bigger lift than the rest of Phase 7 combined.
4. **Stop** — you proved you can ship a complete vertical slice solo. That's a valid endpoint.

No briefs for the post-MVP. When you have a direction picked, ping me and I'll write Phase 8.
