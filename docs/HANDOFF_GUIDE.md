# Multi-Model Handoff Guide

This project is built using three AI tiers. The goal is to use Claude (the most expensive) only where it pays off: architecture, contracts, risky reviews. Everything else goes to ChatGPT or Kilo.

## Tier routing

| Tier | Model | Strengths | Use for | Do NOT use for |
|---|---|---|---|---|
| **A** | Claude (you) | Architecture, judgment, contract design | New systems' interfaces, save migrations, risky refactors, reviewing AI-generated code that touches contracts | Boilerplate, content text, tedious file generation |
| **B** | ChatGPT 5.2 via GitHub Copilot | Strong Godot/GDScript implementation, decent reasoning | Implementing a system from a brief, writing UI controllers, writing one-off scenes, writing tests | Inventing architecture, deciding signal names |
| **C** | Kilo Code free models | Cheap, fine for templated work | Generating `.tres` content from a spec, writing item/trait descriptions, simple find-and-replace refactors, comment/docstring passes | Anything requiring multi-file reasoning |

## Workflow

1. **Brief authoring (Tier A)** — Claude writes a self-contained brief into `docs/briefs/`. The brief names the files to read, the files to produce, and the acceptance criteria.
2. **Grounding (Tier B/C)** — paste the brief into the chosen agent. The brief itself tells the agent which files in `docs/` to read. Always include `docs/ARCHITECTURE.md` in the agent's context.
3. **Implementation (Tier B/C)** — the agent produces the code or content.
4. **Review (you, with Tier A spot-check)** — you eyeball the result against the acceptance criteria. If the change touches a contract (signals, Resource schemas, save format), run it past Claude before merging.
5. **Loop close (Tier A)** — once Phase N is done, Claude updates `ARCHITECTURE.md` if any contract drifted, and writes Phase N+1 briefs.

## Brief template

Every brief in `docs/briefs/` follows this shape. Copy it verbatim into the agent.

```
# Brief: <short title>

You are working on the Bio-Fantasy RPG project. Before you write any code,
read these files in order:
1. docs/ARCHITECTURE.md  (contracts — must not violate)
2. docs/GAME_VISION.md   (intent)
3. <any system-specific docs>

## Goal
<one-paragraph goal>

## Inputs (read-only)
- <file paths the agent should reference but not change>

## Outputs (create or modify)
- <file paths the agent should produce, with one-line descriptions>

## Constraints
- Godot 4, GDScript only.
- No new autoloads without explicit instruction.
- No new EventBus signals without listing them in ARCHITECTURE.md first.
- Composition over inheritance.
- Tick-driven simulation, never `_process`.

## Acceptance criteria
- [ ] <concrete, testable bullets>
- [ ] Code runs without errors in the editor.
- [ ] No direct system-to-system imports (only EventBus + autoloads).

## Out of scope
- <things the agent should NOT do>
```

## Token-conservative habits

- **Don't paste the whole repo into context.** The brief should name the 2–4 files the agent needs. ARCHITECTURE.md is small enough to always include.
- **One brief = one PR-sized change.** If a brief produces more than ~300 lines of new code, split it.
- **Run reviews on diffs, not full files.** When sanity-checking with Claude, paste only the diff and ask "does this violate any contract in ARCHITECTURE.md?"
- **Push content generation to Kilo.** Trait/species/event descriptions burn tokens elsewhere unnecessarily.
- **Cache the spec in your editor.** Keep `ARCHITECTURE.md` open in a split pane. Quote-and-paste the relevant section rather than dumping the whole doc.

## When to come back to Claude

| Situation | Action |
|---|---|
| You hit an architectural fork (e.g. "should this be one system or two?") | Ask Claude |
| Output from ChatGPT/Kilo violates a contract | Ask Claude how to fix without breaking the contract |
| You're about to add a new signal or change a Resource schema | Ask Claude to update `ARCHITECTURE.md` first, then proceed |
| You're starting a new phase | Ask Claude to write that phase's briefs |
| You hit a save-migration scenario | Always Claude — getting this wrong destroys player saves |
| Routine implementation from an existing brief | Don't — use ChatGPT |

## Example: handing off Phase 1, Brief 03 (ResourceLedger)

In Copilot chat, paste:

```
[contents of docs/briefs/phase_1/03_resource_ledger.md]
[contents of docs/ARCHITECTURE.md sections 3 and 4]
```

Then say: "Implement this. Show me the diff against the existing stub at scripts/autoloads/resource_ledger.gd."

After review, if it's clean, commit. If it added a new signal, route to Claude first.
