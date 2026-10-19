# Life game (working title)

A UI-driven life sim set in a fictional northern UK town, present day.

You're dealt a starting life. You don't choose where you start, only what you do with it. Day by day you take cab fares, work shifts, look after the people around you and put your money into things that last. The town remembers what you did, and the people in it build their own lives off yours.

> A life made of small choices, in a town full of other people making theirs.

## Status

**Stage 1: web prototype.** Proving the design, not shipping. Visuals are deliberately plain.

| Stage | Goal | Tech |
| --- | --- | --- |
| 1. Prototype | Prove the day loop, jobs and people system are fun | TypeScript, Svelte, Electron |
| 2. Production | Full game for Steam, with Steam Deck support | Godot |

Stage 1 is complete when a full in-game week is playable, two jobs work by hand and automated, and memories and relationships visibly change outcomes.

## What makes it different

- **Grounded.** Ordinary work, believable people, nothing happens without a cause.
- **The world remembers.** People keep memories of you and act on them, years later if need be.
- **Tending, not autopilot.** Businesses and relationships drift if you ignore them.
- **Every part of life.** Honest, criminal or both; no moralising, just consequences.
- **Play or automate.** Learn a job by hand, then earn the right to automate it, at the cost of the people and rumours you'd miss.

The full design lives in [`docs/design.md`](docs/design.md).

## How it's built

The simulation is separate from the screens:

- **Simulation core** (`packages/sim`): pure, deterministic TypeScript. Same seed and choices always give the same result.
- **Content as data**: jobs, traits, life cards and places are YAML files validated by JSON Schema. Dialogue is written in [Ink](https://www.inklestudios.com/ink/). Player-facing text lives in CSV string tables.
- **UI** (`packages/ui`): Svelte components that read from the simulation and send choices back.
- **App shell** (`packages/app`): Electron, saves, and Steam integration.

This split is what lets the Stage 2 Godot build reuse all content, dialogue, strings and saves, and check its simulation against the same conformance tests.

## Repository layout

```
docs/          design document
schema/        JSON Schema for content and saves
content/       YAML game content
dialogue/      Ink dialogue
strings/       CSV string tables
balance/       balancing data (CSV)
tokens/        shared design tokens
packages/
  sim/         simulation core
  ui/          Svelte UI
  app/         Electron shell, saves, Steam
tests/
  conformance/ data-driven simulation tests
tools/         content validation, baking and type generation
```

## Getting started

Setup scripts are still to be written. The intended workflow:

```bash
npm install
npm run content     # validate and bake YAML content to JSON
npm run dev         # run the prototype in the browser
npm run app         # run it in Electron
npm test            # simulation and conformance tests
```

## Saves

Saves live in your user data folder (`%APPDATA%\CappyTech\<game>` on Windows, `~/.local/share/<game>` on Linux and Steam Deck). Each life is one save, created when its cards are dealt, and keeps its full history.

## Working on this repo

Development is mostly done with Claude Code. See [`CLAUDE.md`](CLAUDE.md) for the architecture rules, conventions and current priorities. In short: keep the simulation pure and deterministic, keep content in data files, keep player-facing text in string tables, and update `docs/design.md` when a decision changes.

## Licence

To be decided.
