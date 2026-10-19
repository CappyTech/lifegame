# Life game: core loop and screens

19 Oct 2026 · Jack

## Overview

A UI-driven life sim: a life made of small choices, in a town full of other people making theirs. You're dealt a starting situation, then build from it one day at a time through ordinary work, relationships and investments, and the town remembers what you did.

**Setting:** a fictional northern UK town, present day. Estates, high street, a council, a cab firm, a chippy, a burger shop, pubs.

**Platforms:** PC via Steam (Windows first, then Linux and Steam Deck). Consoles may follow. Mobile is not a target. Every screen is built from shared components that sit side by side on a desktop display and stack on narrow or handheld screens.

**Who it's for:** players who want effort to turn into something lasting, a world that reacts believably, and a game that keeps needing them. Not players after spectacle or random drama.

**What it isn't:** no wanted stars that reset, no raids out of nowhere, no fully passive empire. Everything that happens has a cause you could trace.

## Design pillars

Every feature should serve at least one of these. If it works against one, it doesn't go in.

1. **Grounded.** Ordinary work, believable people, events with causes. When the world stops making sense, players stop caring.
2. **Choices leave traces.** Every action, and every non-action, marks money, relationships or the town. Silence is an answer.
3. **Tending, not autopilot.** Income rewards you but never runs itself. Businesses drift if ignored; people notice neglect.
4. **The world remembers.** People keep memories of you and act on them. Other characters build on what you start. Consequences persist at a sensible scale.
5. **Adapt and overcome.** You don't choose where you start, you choose what you do with it. Success is measured by how far you came.
6. **Somewhere to come back to.** There's always a low-pressure job to fall back on when you just want to potter and earn.
7. **Every part of life.** The game doesn't decide what kind of life you lead; it makes every kind real. Honest, criminal or both, every path uses the same systems and is judged by the same measure. No moralising, just consequences.

## The starting hand

You're dealt three lives, pick one, or roll for a fresh three. Rolls are limited; once they're gone, you're stuck with what's in front of you.

**How it works**

- Three life cards are dealt at the start of a new game.
- Each card shows the surface only: family, home, a key relationship, starting money. For example: "Single mum, council estate, uncle with a chippy."
- Hidden details (the uncle's about to retire, Mum's friend works at the council) are discovered by living.
- Three rerolls. Each replaces all three cards. Restarts are not tracked or shown to the player.
- The save is created the moment the cards are dealt. Closing the game returns you to the same cards and remaining rolls.

**Rules for the hands**

- Every hand is playable. Hard starts are hard, never hopeless.
- Every start has its own pressures and quiet advantages. Poor but known on the estate; comfortable but judged by family expectations.
- Every start gives an early small win, someone kind, and a clear first step, so the first hour is good whatever you're dealt.
- Success is scored by distance travelled from the start, so hard hands carry the best stories and scores.

## The day loop

The game advances one day at a time. Time and energy are the real currencies: you can't do everything, so every day is a trade-off.

1. **Wake.** The day opens on the overnight report.
2. **Overnight report.** What changed while you slept: business takings, what people did, what's new in town, deadlines approaching. This is the heart of the game, where you see money working and your influence spreading.
3. **Plan.** Three slots: morning, afternoon, evening. Each takes one activity.
4. **Live it.** Each activity runs as its own screen, following the four beats below.
5. **Sleep.** Ends the day, and the report is written from what you did.

**Core stats on the day screen**

| Stat | What it tracks | Moves when |
| --- | --- | --- |
| Money | Cash in hand | Work, spending, business takings |
| Energy | What you can do today | Work and gym drain it; rest and sleep restore it |
| Relationships | One value per person who matters | Time spent, choices in conversation, neglect |
| Known in town | How many people know your name | Social activities, jobs with customers |

**Example activities:** cab shift, burger shift, gym, rest at home, visit family, pub, wander town. Unchosen slots slip by, and the report notes it.

**Delayed payoffs:** some activities cost now and pay later. The gym drains energy today but raises your energy ceiling over weeks.

## The four beats

Every action follows the same four beats, and each beat is a screen.

1. **Choose.** Pick what you take on, weighing money against people and risk.
2. **Engage.** Talk, or don't. Always optional, so any activity can stay quiet when you want it to.
3. **Do the work.** The activity's own mechanic, with small choices and the occasional event.
4. **Outcome.** Money, relationship changes, and anything you learned. All of it feeds the overnight report.

The same loop runs at every scale:

| Scale | Choose | Engage | Do | Outcome |
| --- | --- | --- | --- | --- |
| Conversation | What to say | Saying it | Their reaction | A memory |
| Job | Which fare or shift | Talking to the person | The work | Pay, trust, rumours |
| Day | Three slots | Who you spend it with | Living it | Overnight report |
| Life | Your hand | The town | Years of days | How far you came |

## Jobs

Each job is a fallback way to earn, and each teaches you something different about the town.

### Cab shift: you learn the town

1. **Choose a fare.** Three dispatch cards, each with passenger, destination, fare and a trait. A regular builds a relationship; a long trip pays best; late-night lads are a risk.
2. **The ride.** The passenger may talk. Chat back, ask about them, or put the radio on and stay quiet.
3. **The drive.** Pick a route. The main road is quick and tips better; a detour lets you see something (a rival's queue). Occasional events: roadworks, a hail.
4. **Drop-off.** Fare and tip, the relationship change, and anything you overheard.

Regular passengers open up over rides. A council clerk might hint that a property is going cheap.

### Burger shop shift: you learn a business

1. **Choose a shift.** The lunch rush pays more but is chaotic; a quiet evening gives time with the owner.
2. **Engage.** Customers, co-workers, the owner. Or keep your head down.
3. **The work.** Order tickets assembled against the clock, on a shop-floor map.
4. **Outcome.** Wages, tips, the owner's trust, and what you learned about running the place.

You see how the owner runs it, what goes wrong in a rush, and what customers complain about. An ageing owner might one day ask if you'd take it on.

### Pattern for future jobs

| Job | Teaches | The work component |
| --- | --- | --- |
| Cab | Information, rumours | Route |
| Burger shop | Business know-how | Order ticket |
| Labouring (future) | Contacts, trades | Task list or toolbox |

### Play or automate

The work is interactable: you play the shift yourself. Once you've learned a job, you can automate it for a loss of control, like auto-resolving a battle in Total War.

**Automation is earned, not given**

- Locked at the start, so every job teaches the player what automating gives up.
- Unlocked per job: mastering the cab doesn't unlock the burger shop.
- Unlocked by competence (few mistakes, decent tips), not a fixed shift count.
- Unlocked in the world, as character growth: "You could drive this route in your sleep now."

**What automating costs**

| Lost | Detail |
| --- | --- |
| Pay | Slightly lower: fewer tips, a few small mistakes |
| People | No conversations, so relationships don't move |
| Information | No rumours or overheard tips |
| Control | Small choices are made from how you usually play |

**What decides how well it goes**

- Skill: starts at roughly your level when it unlocked, improving slowly. Playing by hand improves it faster.
- Energy and mood: tired you automates badly.

**Big moments interrupt.** If something truly matters (the owner asks for a word, police flag you down), automation pauses and hands you control. The game never makes a life-changing choice for you.

The intended rhythm: play jobs by hand early for skill and contacts, automate routine ones once you're running things, and dive back in when you want to hear what the town is saying.

### Walking away mid-job

You can always walk away halfway through. It will likely cost you the job, your reputation, or both, scaled to the situation:

- **Who you let down, and how badly.** Leaving the owner alone in a rush is far worse than leaving a quiet shift. Dropping a cab passenger halfway costs that fare and that regular.
- **Whether you had a reason.** A family emergency is understood, at least the first time. Leaving for something better is remembered differently.
- **Whether it's a pattern.** Once is a warning and a dent in trust; repeated, you're let go.
- **Word gets around.** Employers talk, so it can follow you to the next job in a small town.

## UI components

Six shared components build every screen. A job is just a different mix of them, fed different data.

| Component | Shows | Takes |
| --- | --- | --- |
| Map | Where you are | Position, destination, route options, places (owned, rival, opportunity). Zooms from town streets to a shop floor. |
| Speaker card | Who you're dealing with | Name, role, relationship value, traits, memories of you |
| Context panel | Why this moment matters | Activity, time and place, speaker's mood, active opportunities or pressures |
| Conversation | What's said | Their line, your choices, optional timer, what silence means |
| The work | The job's own mechanic | Swapped per job: route (cab), order ticket (burger shop), task list (labouring) |
| Outcome | What changed | Money, relationship changes, memories written, things learned |

**How the components feed each other**

```
Map ──(where it happens)──▶ The work ──────────┐
                                               ▼
Context panel ──(sets the stakes)──▶ Conversation ──▶ Outcome ──▶ Overnight report
                                         │               │
                                         ▼               │
                         Speaker card (writes memories)  │
                                                         │
Map ◀──────────────────(adds new places)─────────────────┘
```

The context sets what's at stake, the conversation writes memories to the speaker, and anything learned adds a place to the map. That loop is how the town comes to remember you.

**Which components each screen uses**

| Screen | Map | Speaker | Context | Conversation | Work | Outcome |
| --- | --- | --- | --- | --- | --- | --- |
| Cab: choose a fare | Yes | Yes |  |  |  |  |
| Cab: the ride |  | Yes | Yes | Yes |  |  |
| Cab: the drive | Yes |  |  |  | Yes |  |
| Talking to staff |  | Yes | Yes | Yes |  |  |
| Stopped by police | Yes | Yes | Yes | Yes |  |  |
| Any drop-off or end of shift |  |  |  |  |  | Yes |

**Wide and narrow layout**

- **Wide (desktop):** components sit side by side. Map and work on the left, speaker, context and conversation on the right, a status bar across the top.
- **Narrow (Steam Deck at 1280×800, small windows):** fewer components per view, stacked in beat order. The conversation takes the full screen when a timer is running, so a choice is never off-screen.
- **Both:** the status bar (day, time, money, energy) stays visible everywhere, and everything is reachable with a controller.

## Conversations and timers

Real conversations don't wait, so moments that matter run on a timer. Everyday chat doesn't.

**When a timer appears**

- Promotions, confrontations, a police officer asking questions, someone asking for your help or your answer.
- Not in routine chat, shop transactions or small talk. Overused timers make the game stressful and push players away.

**Silence is an answer**

- Letting the timer run out is a choice, and each line defines what silence means ("you didn't take him seriously", "you kept your mouth shut").
- "Stay quiet" is also offered as a deliberate option in non-timed moments.

**Slower countdowns**

The same idea at day scale: a bid closing Friday, a manager's patience wearing thin over a week. The world moves on if you don't act.

**Memories**

- Meaningful choices write a memory to the speaker ("remembers: covered his shift", "remembers: the car park").
- Memories shift relationship values, unlock or close options, and show as tags on the speaker card.
- Pushing too hard has a cost: a chatty regular may clam up for the next few rides.

## People and how they decide

The town is dynamic because it's full of people pursuing their own lives, and the player is one of them. Change comes from people reacting to each other, not from a script or a dice roll.

| Kind of change | Why it happens | Use in this game |
| --- | --- | --- |
| Scripted | A writer said so | Rarely; only for authored arc shapes |
| Random | A dice roll said so | Avoided; it breaks believability |
| Dynamic | People and systems react to each other | The default |

### Three layers of people

1. **Anchors (a handful per life).** Family, first boss, a mentor, a rival. They come from the life card, built from authored templates ("ageing owner who wants out", "ambitious youngster") with generated names, quirks and secrets.
2. **Townsfolk (dozens).** Generated from archetypes, with their own goals and relationships. They open rival businesses, fall out with each other, step in when you're away.
3. **Passers-by (everyone else).** Cab passengers, customers, faces at the pub. Light, but they can be **promoted**: keep picking up the same passenger and she becomes a townsperson with full memory and goals.

### How a person decides (v0, numbers provisional)

People are independent agents driven by needs, using utility AI. Each person keeps a set of numbers; those numbers weigh on a scale for each possible action; when one scale stays heavy enough for long enough, they act.

| Part | Range | Behaviour |
| --- | --- | --- |
| Needs (money, belonging, ambition, rest) | 0–100 | Drift each day; low means unmet |
| Traits (loyal, proud, cautious) | 0–1 | Fixed; weight how options are scored |
| Relationships | trust −100 to 100, resentment 0–100 | Change with events and memories |
| Memories | tag, about, event, weight | Fade slowly; emotional ones fade slower |

**Urgency.** A need barely matters until it's low, then it matters a lot:

```
urgency = (100 − need)² / 100
```

A need at 80 has urgency 4; at 50, 25; at 20, 64.

**Scoring.** Every option gets a score from urgencies, traits, relationships and memories, plus small seeded noise (about ±3) so two people in the same spot don't act identically. "Carry on as normal" scores a flat 30. Example, a manager weighing a rival's job offer:

```
score = 20 + urgency(money) × 0.35 + urgency(belonging) × 0.4
      + resentment(colleague) × 0.2 + 15 if an offer exists
      − loyal × 25 − trust(you) × 0.15 ± noise
```

**Pressure and inertia.** Each option builds pressure over days, like a bucket with a small leak: a quarter drains each night, and the person acts when it overflows. Brief upsets fade; sustained ones build to a decision.

```
pressure = pressure × 0.75 + max(0, score − 30)
```

| Size | Threshold | Examples |
| --- | --- | --- |
| Small | 8 | Late to work, short with customers |
| Medium | 20 | Asks for a raise, asks for more responsibility |
| Big | 45 | Quits, leaves to start their own business |

**Warnings.** At half a big threshold, behaviour shows in the overnight report ("seemed distracted all shift"), so the player can read people, not numbers.

**Player actions change inputs, never outcomes.** Talking to someone raises belonging and trust and drains some pressure; the memory of what caused it stays.

### Dynamics this produces

- **Drift:** needs wear down on their own, so doing nothing is never neutral.
- **Slow burn:** pressure builds over days, giving time to notice and react.
- **Trade-offs between people:** promoting one person can write "passed over" into another's memory.
- **Repair, not erasure:** a relationship can be mended; what happened stays remembered.
- **Emergence:** nobody writes "she leaves on day 10"; it comes from small rules interacting.

### Keeping it believable

- Every change has a cause recorded in the history.
- Changes are mostly small; big shifts are many small ones adding up.
- Characters act within their nature: a loyal, cautious person doesn't betray you without pressure building first.
- A pace limit stops the town having three crises in one week.
- Arc templates only start when their conditions are met ("owner wants to sell" needs an owner who is old, tired and trusts someone).

### Next to add

- [ ] People affecting each other without the player (a promotion changes how colleagues treat each other)
- [ ] Information spreading through gossip, at believable speed and with some distortion
- [ ] Good spirals, so a happy, well-run place lifts itself rather than just holding steady

## Data and storage

The data is the game; the engine is a viewer. Content is authored as Godot Resources, saves are versioned binary files, and the simulation is deterministic: the same seed and choices always give the same result.

**Formats**

| Data | Format | Notes |
| --- | --- | --- |
| Content (jobs, activities, traits, life cards, places) | Custom `Resource` classes saved as `.tres` | Typed by the class, edited in the inspector, validated by a check script on load |
| Dialogue | `Conversation` resources: lines, choices, conditions, timer, what silence means | Small and choice-shaped, so no external dialogue runtime. Lives in the sim so it stays deterministic |
| Balancing numbers | Spreadsheet, exported to CSV, imported into the resources by a tool script | Pay, energy costs and odds side by side |
| Player-facing text | CSV translation tables (`key,en,...`) | Imported by Godot's translation system |
| Mods | JSON, converted to Resources at load | Safe to load from untrusted sources; never `ResourceLoader` on mod files |
| Saves | Binary via `store_var`, gzip-compressed, versioned header | Migration code for every version step |

The Resource classes under `content/defs/` are the single source of truth for data shapes. Mod JSON and CSV imports are validated against them.

**Core entities**

```
CONTENT (authored, shared)
  JobDef        id, beats[], work_type, pay_range, teaches, auto_unlock_rule
  ActivityDef   id, slot_cost, energy, money, effects[]
  LifeCard      id, surface_facts[], hidden_facts[], start_stats
  TraitDef      id, effects on conversation and behaviour
  PlaceDef      id, type, map_zone
  Conversation  id, lines[], choices[], conditions, timer, silence_means

STATE (per save)
  World         seed, day, slot, rerolls_left, rng_state
  Player        money, energy, fitness, job_skills{}, auto_unlocked[]
  Person        id, role, traits{}, needs{}, options[], pressure{}
  Relationship  from, to, trust, resentment
  Memory        holder, about, event_id, tag, weight
  Place         def_id, owner, condition, takings
  Opportunity   id, place, deadline_day, status
  Event         id, day, slot, type, actors[], place, data
```

- Events are the source of truth: memories point at events, the overnight report is built from them.
- Relationships run between anyone, not just the player, so characters can branch off each other.
- State classes are plain `RefCounted` scripts with no node references, so the sim can run headless.

**Save layout (full history kept)**

```
user:// (%APPDATA%\Godot\app_userdata\<game> or ~/.local/share/godot/app_userdata/<game>)
  saves/
    life-001/
      manifest.json      which state and history files are current, written last
      meta.json          load-screen info
      state.sav.gz       the town now, rewritten each night
      history/
        y01.log.gz       closed years packed into one file
        y02-m01.log.gz   current year, one file per month
      index.db           SQLite index, local only, rebuildable
      backups/           last 3 snapshots
  settings.cfg           per machine, not cloud-synced
  mods/
```

- Save on sleep; write to a temp file then rename, so a crash never corrupts a life.
- One save slot per life, created when the cards are dealt.
- Rough size: a 50-year life is in the region of 20 MB compressed.
- The SQLite index needs a GDExtension (godot-sqlite). Until it is in, history is searched by scanning the logs.

**Steam**

- Steamworks through the GodotSteam GDExtension.
- Steam Cloud via Auto-Cloud syncs `saves/` (quota around 100 MB per player). Closed history files upload once.
- Achievements and stats through the Steamworks API, not the save.
- Steam Workshop: mods are JSON and CSV loaded from `mods/`, overriding by ID.
- Steam Deck: controller navigation and 1280×800 from the start.

## Tech stack and stages

One engine from the start: Godot 4.7 with GDScript. The game is built in two stages inside the same project, so nothing is thrown away between them.

| Layer | Choice |
| --- | --- |
| Engine | Godot 4.7.2 (standard build, not .NET) |
| Language | GDScript with static typing enforced (untyped declarations are errors) |
| Simulation core | Plain scripts under `sim/`, no node or scene access, seeded `RandomNumberGenerator` carried in state |
| UI | Godot scenes, one per component, built from a Theme generated from the tokens file |
| Content | Custom Resources (`.tres`) under `content/`, checked by a validation script |
| Dialogue | `Conversation` resources (see Data and storage) |
| Saves | `FileAccess` with `store_var` and gzip, versioned |
| Steam | GodotSteam GDExtension |
| Tests | Headless runner (`godot --headless -s tests/run_tests.gd`) over `tests/test_*.gd`; conformance cases as JSON data |
| CI | Forgejo Actions: headless tests, export templates, steamcmd upload |

**Why GDScript, not C#:** the GDScript runtime ships on every console port, while C# support there depends on the porting partner. The cost is losing Ink; dialogue here is small and choice-shaped, so a data format covers it.

### Stage 1: prove the design

Plain visuals, default controls, no art. Time goes on the simulation and the choices.

**Exit criteria**

- [ ] A full in-game week is playable
- [ ] Two jobs work, by hand and automated
- [ ] Memories and relationships visibly change outcomes
- [ ] Played enough to know what's fun and what isn't

### Stage 2: production

Same project. Replace the placeholder scenes with finished presentation, game feel, controller polish and Steam Deck verification. The sim, content, strings, saves and tests carry through untouched.

### Working approach (development mostly done with Claude)

1. **Conformance tests as data.** Each test is a seed, a list of choices, and the expected events and state. They pin the sim's behaviour across refactors and tuning.
2. **Shared design tokens.** Colours, spacing and type sizes in one JSON file, turned into a Godot Theme by a tool script. Scenes never hard-code them.
3. **Stable components.** Six component scenes with small, data-shaped inputs: `SpeakerCard` takes `{name, role, relationship, traits, memories}`.
4. **One component at a time,** with a screenshot in the pull request.
5. **One repo with a `CLAUDE.md`** pointing to this doc, the content classes and the tests, so every session picks up where the last left off.

Releases build through Forgejo Actions and upload to Steam with steamcmd.

## Planned update: Crime and Punishment

Crime arrives after launch, into a town players already care about. Any character can be taken into any part of life, including a fully criminal one.

**A ladder of crime**

| Scale | Examples |
| --- | --- |
| Small | Cash-in-hand work, fare dodging, knock-off goods, looking the other way at work |
| Middle | Handling stolen goods, an unlicensed cab, cooking the books, pub fights |
| Serious | Organised dealing, burglary, protection rackets |
| Guns | Rare and a massive escalation, as in the real UK. The whole town reacts. |

**Criminal paths use the same systems**

- Criminal jobs follow the four beats. Automation comes from building a crew you trust.
- Each path has its own ladder: runner, trusted, running things. Many players are on legitimate and criminal ladders at once.
- Paths cross: a record makes legitimate work harder, a legitimate business makes a good front, and going straight is possible but old contacts don't forget.

**Police as people**

- Local officers are characters with memories and relationships.
- Investigations run on evidence and witnesses: someone saw you, a passenger remembers your cab, the books don't add up.
- Reputation is split: how the police see you, and how the street sees you.

**Punishment that persists**

- Warnings, fines, community service, a criminal record, prison.
- A record closes doors: some employers won't hire you, the council won't sell to you.
- Prison means days pass without you. Businesses drift, relationships cool, others step into your place.

**Hooks in the base game from day one**

- [ ] Police exist as characters
- [ ] The event schema can record illegal acts
- [ ] Reputation split into official and street
- [ ] Characters can hold secrets about you

**Rating:** drugs, weapons and organised crime raise the age rating. Fine on Steam if tagged properly; it matters for consoles later.

## Open questions

- [x] Walking away mid-job: decided, see Jobs.
- [x] Rerolls and restarts: decided (three rerolls, restarts untracked), see The starting hand.
- [x] Crime and punishment: planned as a post-launch update, see Planned update.
- [ ] How you go from employee to owner: buying, inheriting, being offered.
- [x] What a "memory" and a "relationship" store as data: decided (v0), see Data and storage.
- [x] Engine and language: decided, Godot 4.7 with GDScript and native Resources, see Tech stack and stages.
- [x] How other characters make their own choices: decided (v0), see People and how they decide.
- [ ] Same town with the same core people each life, or a freshly generated town?
- [ ] How the game ends, or whether it does: retirement, a set number of years, open-ended.
- [ ] The balance between dashboard view and written story moments.
- [ ] Working title.
