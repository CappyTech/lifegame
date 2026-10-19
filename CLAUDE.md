# CLAUDE.md

Guidance for Claude Code working in this repository.

## What this is

A UI-driven life sim set in a fictional northern UK town, present day. The player is dealt a starting life, then builds it one day at a time through ordinary work, relationships and investments. The town remembers what they did.

Launch target: **Steam** (Windows first, then Linux and Steam Deck). Consoles may follow later.

**Read `docs/design.md` before any design or gameplay work.** It is the source of truth for what the game is. If a request conflicts with it, say so and ask before changing course. When a decision changes, update `docs/design.md` in the same piece of work.

## Current stage

**Stage 1: web prototype.** Its job is to prove the design, not to ship. Keep visuals plain; spend effort on the simulation and the choices.

Stage 1 is done when:

- [ ] A full in-game week is playable
- [ ] Two jobs work (cab, burger shop), by hand and automated
- [ ] Memories and relationships visibly change outcomes
- [ ] Jack has played it enough to know what's fun and what isn't

Stage 2 rebuilds the presentation in Godot. Everything in Stage 1 should be written so it can be ported (see "Porting rules").

## Stack (Stage 1)

| Layer | Choice |
| --- | --- |
| Language | TypeScript, `strict: true` |
| Simulation core | Pure TS package, no DOM, no Node APIs |
| UI | Svelte |
| Interactive work | HTML/CSS; Pixi.js only where game feel needs it |
| Dialogue | Ink via inkjs |
| Content | YAML, validated by JSON Schema, baked to JSON at build |
| Saves | Node `fs` + gzip; better-sqlite3 for the history index |
| Desktop / Steam | Electron + steamworks.js |
| Tests | Vitest (simulation), Playwright (UI) |
| CI | Forgejo Actions; Steam upload via steamcmd |

## Proposed layout

```
/docs
  design.md               design source of truth
/schema                   JSON Schema for all content and save data
/content                  hand-written YAML (jobs, traits, life cards, places)
/dialogue                 Ink source files
/strings                  CSV string tables (key, en, ...)
/balance                  CSV exports of balancing spreadsheets
/tokens/design-tokens.json  colours, spacing, type sizes (shared with Godot later)
/packages
  /sim                    simulation core: pure, deterministic, no UI
  /ui                     Svelte components and screens
  /app                    Electron shell, saves, Steam integration
/tests
  /conformance            data-driven tests: seed + choices -> expected events/state
/tools                    build scripts: validate + bake content, generate types
```

Create structure as it's needed; don't scaffold empty folders for the sake of it.

## Architecture rules

These are non-negotiable because the Godot port depends on them.

1. **The simulation core never touches the UI.** `packages/sim` takes state + a player choice and returns new state + events. No DOM, no `fs`, no Electron, no Svelte imports.
2. **Deterministic.** Same seed + same choices = same result, always. Never use `Math.random()`, `Date.now()` or iteration order of unordered collections inside the sim. Use the seeded RNG passed in with state.
3. **Events are the source of truth.** Everything that happens is recorded as an `Event`. Memories reference event IDs. The overnight report is built from the day's events. History is append-only.
4. **Content is data.** Jobs, activities, traits, life cards and places live in `/content` as YAML. Adding a job should mean writing a file, not code. The game loads only baked JSON, never the raw YAML.
5. **No hard-coded player-facing text.** All text goes through string keys in `/strings`. British English for the `en` column.
6. **The schema is the single source of truth for data shapes.** Generate TS types from `/schema`; don't hand-write duplicate interfaces.
7. **Saves are versioned.** Every save carries a version number. Any change to the save shape needs a migration and a test.
8. **Relationships run between anyone,** not just the player and an NPC.

## Simulation rules: people system (v0, numbers provisional)

People are independent agents driven by needs (utility AI). Numbers below are first guesses for tuning, not final.

- **Needs** (money, belonging, ambition, rest): 0–100, drift each day. Low = unmet.
- **Traits** (loyal, proud, cautious, ...): 0–1, fixed. Weight how options are scored.
- **Relationships:** trust −100..100, resentment 0..100.
- **Memories:** `{holder, about, event_id, tag, weight}`, fading slowly; emotional ones fade slower.
- **Urgency:** `urgency(need) = (100 - need)^2 / 100`
- **Scoring:** each option a person has gets a score from urgencies, traits, relationships, memories, plus small seeded noise (about ±3). "Carry on as normal" scores a flat 30.
- **Pressure (inertia):** each option accumulates `pressure = pressure * 0.75 + max(0, score - 30)` nightly.
- **Thresholds:** small 8 (late, short with customers), medium 20 (asks for a raise), big 45 (quits, leaves to start a business).
- **Warnings:** at half a big threshold, a visible behaviour appears in the overnight report before the act.
- **Player actions change inputs, never outcomes directly.**

## Porting rules (for Stage 2)

- **Conformance tests as data.** Each test in `/tests/conformance` is a seed, a list of choices, and the expected events and key state. The TS sim must pass them; the Godot sim must later pass the same files. Add a conformance case for every sim behaviour you add.
- **Shared design tokens.** UI styles read from `/tokens/design-tokens.json` (converted to CSS variables). Don't hard-code colours or sizes in components.
- **Stable component names and inputs.** UI components map one-to-one to future Godot scenes. Core components: `Map`, `SpeakerCard`, `ContextPanel`, `Conversation`, `Work` (per job: `RouteWork`, `TicketWork`), `Outcome`. Keep their props small and data-shaped, e.g. `SpeakerCard {name, role, relationship, traits, memories}`.

## Design guardrails

Before adding a feature, check it against the design pillars in `docs/design.md`. In short:

- **Grounded:** no drama from nowhere; every event has a traceable cause.
- **Choices leave traces,** including doing nothing.
- **Tending, not autopilot:** nothing runs itself forever.
- **The world remembers,** at a believable scale.
- **Adapt and overcome:** success is distance travelled from the start.
- **Somewhere to come back to:** a low-pressure job always exists.
- **Every part of life:** no moralising, just consequences.

If a change would break one of these, flag it rather than building it.

## Saves

- One save slot per life, created when the life cards are dealt.
- Save on sleep. Write to a temp file, then rename. Write `manifest.json` last.
- Keep full history: monthly log files for the current year, packed into one file per closed year.
- `index.db` is local-only and rebuildable; never treat it as the source of truth.
- Settings are per machine and never cloud-synced.

## Working with Jack

- Most development is done with Claude, across many sessions. Leave the repo in a state the next session can pick up: tests passing, docs current.
- Ask before big or hard-to-reverse decisions (new dependencies, changing the save format, changing the stack). Small, reversible choices: make the call and mention it.
- Keep summaries short: what changed, what's next.
- Don't mark exit criteria as done without Jack confirming.
