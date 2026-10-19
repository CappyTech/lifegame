# CLAUDE.md

Guidance for Claude Code working in this repository.

## What this is

A UI-driven life sim set in a fictional northern UK town, present day. The player is dealt a starting life, then builds it one day at a time through ordinary work, relationships and investments. The town remembers what they did.

Launch target: **Steam** (Windows first, then Linux and Steam Deck). Consoles may follow later. Mobile is not a target.

**Read `docs/design.md` before any design or gameplay work.** It is the source of truth for what the game is. If a request conflicts with it, say so and ask before changing course. When a decision changes, update `docs/design.md` in the same piece of work.

## Current stage

**Stage 1: prove the design.** Built in the final engine, with plain visuals, default controls and no art. Spend effort on the simulation and the choices, not presentation.

Stage 1 is done when:

- [ ] A full in-game week is playable
- [ ] Two jobs work (cab, burger shop), by hand and automated
- [ ] Memories and relationships visibly change outcomes
- [ ] Jack has played it enough to know what's fun and what isn't

Stage 2 replaces the placeholder scenes with finished presentation in the same project. Nothing under `sim/`, `content/`, `strings/` or `tests/` should need to change for that.

## Stack

| Layer | Choice |
| --- | --- |
| Engine | Godot 4.7.2, standard build (not .NET) |
| Language | GDScript, static typing enforced (`untyped_declaration` is an error in project settings) |
| Simulation core | Plain `RefCounted` scripts under `sim/`, no node or scene access |
| UI | Godot scenes under `ui/`, one per component, styled from a Theme generated from `tokens/design-tokens.json` |
| Content | Custom `Resource` classes under `content/defs/`, instances as `.tres` under `content/` |
| Dialogue | `Conversation` resources, run by the sim |
| Strings | CSV translation tables under `strings/` |
| Saves | `FileAccess` + `store_var`, gzip, versioned header |
| Steam | GodotSteam GDExtension |
| Tests | Headless runner: `godot --headless --path . -s tests/run_tests.gd` |
| CI | Forgejo Actions; Steam upload via steamcmd |

## Tooling on this machine

Godot 4.7.2 is installed through winget. The `godot` / `godot_console` aliases only work in a shell opened after the install, so scripts use the full path:

```
C:\Users\user\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe
```

Run the tests (on a fresh clone, run `--import` once first so the class_name cache exists):

```bash
"$LOCALAPPDATA/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe" --headless --path . -s tests/run_tests.gd
```

Rebuild the Theme after changing tokens:

```bash
"$LOCALAPPDATA/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe" --headless --path . -s tools/build_theme.gd
```

`.mcp.json` registers the `godot` MCP server (`@coding-solo/godot-mcp`), which can launch the editor, run the project, capture its debug output and stop it. Use it to check a scene actually runs; use the headless test command for everything in `sim/`. `.claude/settings.json` pre-allows the Godot executables so headless runs don't prompt.

## Layout

```
project.godot
docs/design.md            design source of truth
sim/                      simulation core: pure, deterministic, no UI
content/
  defs/                   Resource classes (the data shapes)
  jobs/, cards/, ...      .tres instances
strings/                  CSV translation tables (key, en, ...)
tokens/design-tokens.json colours, spacing, type sizes
ui/                       component scenes (Stage 1: placeholders)
tests/
  run_tests.gd            headless runner
  test_*.gd               unit tests
  conformance/*.json      seed + choices -> expected events/state
tools/                    tool scripts: validate content, build Theme from tokens, import balance CSV
```

Create structure as it's needed; don't scaffold empty folders for the sake of it.

## Architecture rules

These are non-negotiable.

1. **The simulation core never touches the UI.** Scripts under `sim/` take state + a player choice and return new state + events. No `Node`, no `get_tree()`, no scene access, no `preload` of scenes, no autoload use. Anything that `extends Node` does not belong in `sim/`.
2. **Deterministic.** Same seed + same choices = same result, always. Never call `randi()`, `randf()`, `Time.*` or `OS.*` inside the sim. Use the `RandomNumberGenerator` carried in `WorldState`. Dictionaries keep insertion order in Godot, so iteration is deterministic as long as insertion order is; when in doubt, iterate sorted keys.
3. **Events are the source of truth.** Everything that happens is recorded as a `SimEvent`. Memories reference event IDs. The overnight report is built from the day's events. History is append-only.
4. **Content is data.** Jobs, activities, traits, life cards, places and conversations are Resources under `/content`. Adding a job should mean adding a `.tres`, not code. Resource classes carry a `validate()` that the tests run over every instance.
5. **No hard-coded player-facing text.** All text goes through keys in `/strings` and `tr()`. British English for the `en` column.
6. **The Resource classes are the single source of truth for data shapes.** Mod JSON is converted to those classes at load and never loaded with `ResourceLoader`.
7. **Saves are versioned.** Every save carries a version number. Any change to the save shape needs a migration and a test.
8. **Relationships run between anyone,** not just the player and an NPC.

## Simulation rules: people system (v0, numbers provisional)

People are independent agents driven by needs (utility AI). Numbers below are first guesses for tuning, not final. The implementation is `sim/people.gd`.

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

## Testing rules

- **Conformance tests as data.** Each case in `/tests/conformance` is a seed, a list of choices, and the expected events and key state. Add a case for every sim behaviour you add. Update expected values only when the behaviour change is intended, and say so in the commit.
- **Every content instance is validated** by `tests/test_content.gd`.
- Tests must pass headless. Nothing in the test suite may need a display.

## UI rules

- **Shared design tokens.** Scenes read from the Theme built from `/tokens/design-tokens.json`. Don't hard-code colours or sizes in scenes.
- **Stable component names and inputs.** Core component scenes: `Map`, `SpeakerCard`, `ContextPanel`, `Conversation`, `Work` (per job: `RouteWork`, `TicketWork`), `Outcome`. Keep their inputs small and data-shaped, e.g. `SpeakerCard {name, role, relationship, traits, memories}`.
- **Controller-navigable from the start.** Steam Deck is 1280×800; check layouts there.

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
- Ask before big or hard-to-reverse decisions (new addons or GDExtensions, changing the save format, changing the stack). Small, reversible choices: make the call and mention it.
- Keep summaries short: what changed, what's next.
- Don't mark exit criteria as done without Jack confirming.
