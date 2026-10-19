# Life game (working title)

A UI-driven life sim set in a fictional northern UK town, present day.

You're dealt a starting life. You don't choose where you start, only what you do with it. Day by day you take cab fares, work shifts, look after the people around you and put your money into things that last. The town remembers what you did, and the people in it build their own lives off yours.

> A life made of small choices, in a town full of other people making theirs.

## Status

**Stage 1: proving the design.** Built in Godot from the start, with deliberately plain visuals.

| Stage | Goal |
| --- | --- |
| 1. Prove | The day loop, two jobs and the people system are fun |
| 2. Production | Finished presentation, controller polish, Steam Deck, Steam release |

Stage 1 is complete when a full in-game week is playable, two jobs work by hand and automated, and memories and relationships visibly change outcomes.

## What makes it different

- **Grounded.** Ordinary work, believable people, nothing happens without a cause.
- **The world remembers.** People keep memories of you and act on them, years later if need be.
- **Tending, not autopilot.** Businesses and relationships drift if you ignore them.
- **Every part of life.** Honest, criminal or both; no moralising, just consequences.
- **Play or automate.** Learn a job by hand, then earn the right to automate it, at the cost of the people and rumours you'd miss.

The full design lives in [`docs/design.md`](docs/design.md).

## How it's built

Godot 4.7 and GDScript throughout. The simulation is separate from the screens:

- **Simulation core** (`sim/`): plain scripts with no scene access. Deterministic: the same seed and choices always give the same result.
- **Content as data** (`content/`): jobs, traits, life cards, places and conversations are Godot Resources, typed by their classes. Player-facing text lives in CSV translation tables.
- **UI** (`ui/`): one scene per component, styled from a shared tokens file.
- **Saves**: versioned binary with full history, in the user data folder.
- **Steam**: GodotSteam.

## Repository layout

```
project.godot
docs/          design document
sim/           simulation core
content/       Resource classes and .tres content
strings/       CSV translation tables
tokens/        shared design tokens
ui/            component scenes
tests/         headless unit tests and data-driven conformance cases
tools/         content validation, Theme generation, balance import
```

## Getting started

Open `project.godot` in Godot 4.7.2. To run the tests headless:

```bash
godot --headless --path . -s tests/run_tests.gd
```

## Saves

Saves live in Godot's user data folder (`%APPDATA%\Godot\app_userdata\<game>` on Windows, `~/.local/share/godot/app_userdata/<game>` on Linux and Steam Deck). Each life is one save, created when its cards are dealt, and keeps its full history.

## Working on this repo

Development is mostly done with Claude Code. See [`CLAUDE.md`](CLAUDE.md) for the architecture rules, conventions and current priorities. In short: keep the simulation pure and deterministic, keep content in Resources, keep player-facing text in string tables, and update `docs/design.md` when a decision changes.

## Licence

To be decided.
