# Enemy Highlight roadmap

[Русский](roadmap.md) | **English** · [Documentation index](README.md)

This document describes development directions after `v0.3.0`. Priorities may
change after in-client testing and user feedback. A milestone number is not a
release-date promise: work may be split or moved when a prototype reveals an
API limitation.

## Milestone status

| Milestone | Status | Primary goal |
|---|---|---|
| `v0.1` | Released | Custom labels, notes, search, and target indicator |
| `v0.2` | Released | Localization and faster access to target information |
| `v0.3` | Released | Alternate-character links |
| Next milestone | Planned | Import/export, notifications, and history |
| `v0.4` | Research | Profiles and an extended player model |

The backlog contains unassigned ideas. Deferred items cannot currently be
implemented reliably with the available LOTRO Lua API.

## Product direction

Enemy Highlight is intended to be a personal player directory and a source of
quick actions for the current target:

- the user decides who to label and how;
- saved information should be available during active gameplay;
- the UI must not interfere with character controls;
- data must survive upgrades and be safe to move or restore;
- features should work in regular play and PvMP within the limits of the API.

The plugin is not a radar, a nearby-player scanner, or an automatic Free
People/Monster Player classifier.

## Engineering principles

1. Prefer events over per-frame processing.
2. Every PluginData schema change must include a backward-compatible migration.
3. Searchable collections should use session indexes.
4. Every notification feature must be optional.
5. Hidden windows must not intercept keyboard or mouse input.
6. Visual changes must be tested at different resolutions and UI scales.
7. A release requires manual verification inside LOTRO.

## v0.2 — information access and localization

Goal: support four interface languages and reduce the number of steps needed to
work with the current target.

### EN/FR/DE/RU localization

Status: released in `v0.2.0`.

- user-facing strings are stored in locale tables;
- `Locale/en.lua`, `fr.lua`, `de.lua`, and `ru.lua` are available;
- `Automatic` detects the client through `Turbine.Engine.GetLanguage()`;
- manual selection is available in plugin options and `/eh language`;
- windows, buttons, tooltips, messages, and `/eh help` update without reload;
- user-facing text uses fonts with Cyrillic support.

Completion requires in-client verification without deleting PluginData, no
mixed languages, usable layouts for longer strings, and unchanged Latin-name
matching.

### Notes on the target indicator

Status: released in `v0.2.0`.

The label remains visible. In every mode, hovering shows the full player name,
label, and non-empty note. A short click without dragging opens a dedicated
note editor, and saving refreshes the tooltip immediately. `Show note tooltip`
is configured in `Manage labels`. `/eh move` enables dragging, while `/eh lock`
only fixes the indicator position. A short second note line remains a separate
follow-up after the primary interaction is verified.

### Candidates for `v0.2.x`

The following improvements were not included in `v0.2.0`. They may ship in a
separate patch or move to the next milestone after prototyping.

#### Current-target commands

Planned commands:

```text
/eh target <label name>
/eh note target <text>
/eh info target
/eh remove target
```

They must reject a missing or unnamed target, preserve notes when changing a
label, support multiword labels and notes, and report destructive results
clearly.

#### Small UI settings

- hide and restore the floating launcher;
- indicator opacity;
- indicator preview in `Manage labels`;
- reset window and indicator positions;
- recover elements moved outside the visible screen.

## v0.3 — alternate-character links

Status: released in `v0.3.0`.

An alternate character remains an independent record but can be linked from
any character card. A new nickname inherits that card's label; an existing
record is never overwritten. One record can belong to multiple groups, and
removing one link does not delete the alternate record or its other links. A
card shows every character reachable through a chain of links.

## Next milestone — portability and quick reactions

Goal: protect user data and make labels more useful during frequent target
changes.

### Import and export

Add a window with a multiline transfer field. Export should contain a format
version, labels, player records, notes, and optionally display settings.

Import should provide:

- `Merge` and confirmed `Replace` modes;
- full validation before changing PluginData;
- a report of added, updated, skipped, and invalid records;
- no partial write when the input structure is damaged;
- predictable handling of label conflicts.

### Label notifications

Per-label reactions may include no notification, a chat message, a temporary
frame highlight, a short animation, and a sound only if a stable API and
suitable resource are confirmed.

Notifications must be globally switchable, must not spam on repeated events for
the same target, and must not require a permanent per-frame handler.

### Recent-target history

Add a session-only list with the target name, assigned label or `Unknown`, last
selection time, and `Add`, `Edit`, and `Info` actions. Persistent history will
be evaluated separately for privacy and PluginData size.

## v0.4 — extended player model

Goal: support long-term databases and multiple gameplay contexts.

### Extended player aliases

- multiple names for one record;
- exact target matching by primary name or alias;
- uniqueness across records;
- primary-name display in lists;
- migration without changing existing user keys.

### Profiles

Candidate profiles are global, PvMP, raid, and custom. Before implementation,
the project must decide whether profiles inherit labels, how records move, what
loads at startup, and whether separation is per character or only inside a
server database.

### Search and sorting

- optional note search;
- sorting by name, label, and modification time;
- a `Has note` filter;
- favorite players;
- persisted sort mode.

### LOTRO context actions

Prototype an `EntityControl` interaction for the current target, covering the
game context menu, target assignment, Free People, Monster Players and NPCs,
and interaction with the locked indicator. It will ship only after stable
in-client behavior is confirmed.

## Backlog

- `/eh stats` label statistics;
- record creation and modification dates;
- favorite labels for faster assignment;
- indicator border, text color, and theme settings;
- backups of previous imports;
- delete confirmations in the UI;
- richer PluginData diagnostics;
- screenshots and GIFs for the GitHub README;
- a curated changelog if generated release notes stop being sufficient.

## Deferred because of API limits

### Nearby-player scanning

Not planned unless an official API exposes a safe nearby-character list.
`TargetChanged` only describes a target the user has already selected.

### Automatic PvMP allegiance detection

Not planned as required behavior. A PvMP target may be exposed as an `Actor`
without `GetAlignment()`, so the result is not reliable.

### New Window-based Lua UI scaling

Deferred until the API is stable. The plugin continues to use its own sizes,
limits, and on-screen position checks.

## Selecting the next feature

Before starting a major feature:

1. document the user scenario;
2. prototype relevant LOTRO Lua API limits;
3. define PluginData changes and migration;
4. add cases to `docs/manual-test.md`;
5. implement and test in `staging`;
6. verify performance and UI inside LOTRO;
7. promote to `main` and release only after verification.
