# Bio-Fantasy RPG

A retro-style 2D mobile RPG built on evolutionary biology, interconnected ecosystems, and prestige-based replayability.

## Locked technical decisions
- **Engine**: Godot 4 (latest stable)
- **Language**: GDScript
- **Orientation**: Portrait
- **World**: Fixed 32×48 tile grid
- **MVP platform**: Android only (iOS deferred to Phase 7)

## Repository layout

```
2_bio/
├── README.md                  # this file
├── project.godot              # generated when you create the Godot project (not yet committed)
├── docs/                      # design + architecture + handoff
│   ├── GAME_VISION.md
│   ├── DESIGN_PILLARS.md
│   ├── CORE_LOOP.md
│   ├── KINGDOMS.md
│   ├── SYSTEMS.md
│   ├── ROADMAP.md
│   ├── TECHNICAL_SCOPE.md
│   ├── ARCHITECTURE.md        # authoritative spec — every agent reads this first
│   ├── HANDOFF_GUIDE.md       # multi-model workflow (Claude / ChatGPT / Kilo)
│   ├── AI_PROMPTS.md          # prompt library
│   └── briefs/                # ready-to-paste task briefs by phase
├── scenes/                    # .tscn files (UI, world, organisms, events)
├── scripts/                   # .gd files
│   ├── autoloads/             # singleton services (EventBus, TickClock, ...)
│   ├── systems/               # gameplay systems (growth, territory, ...)
│   ├── entities/              # organism/tile scripts
│   ├── ui/                    # UI controllers
│   ├── data/                  # Resource schema scripts (class definitions)
│   └── utils/
├── data/                      # .tres content files (species, traits, events, biomes)
├── assets/                    # art, audio, fonts, shaders
└── tests/                     # GUT-based unit tests
```

## Multi-model workflow

This project uses three AI tiers:

| Tier | Used for |
|---|---|
| Claude (you) | Architectural decisions, contracts (signals/Resources), risky reviews, brief authoring |
| ChatGPT 5.2 via Copilot | Implementation of spec'd modules (systems, UI controllers, scenes) |
| Kilo Code free models | Boilerplate, content generation (`.tres` files, item descriptions), simple refactors |

Workflow:
1. Read `docs/ARCHITECTURE.md` once (in any agent) to ground context.
2. Pick a brief from `docs/briefs/`.
3. Paste into the appropriate agent following `docs/HANDOFF_GUIDE.md`.
4. Bring output back to Claude only when blocked or for architectural review.

## Getting started (first time)

1. Install Godot 4 (latest stable) for Linux.
2. Open Godot → Import → select this folder. Godot will create `project.godot`.
3. In **Project Settings** set:
   - Display → Window → Stretch Mode = `canvas_items`, Aspect = `keep`
   - Display → Window → Orientation = `portrait`
   - Display → Window → Handheld → Orientation = `portrait`
4. Install Android export template, sign with debug keystore.
5. Read `docs/ARCHITECTURE.md`, then start with `docs/briefs/phase_1/`.
