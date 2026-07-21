# Enemy Highlight development guide

[Русский](development.md) | **English** · [Documentation index](README.md)

This document describes the plugin architecture and a safe change workflow.
See [CONTRIBUTING.md](../CONTRIBUTING.en.md) for contribution rules and the
[roadmap](roadmap.en.md) for planned work.

## Environment

- an installed LOTRO client with Lua plugin support;
- the `Documents\The Lord of the Rings Online\Plugins` directory;
- Git and a text editor;
- optionally, a Lua parser or linter for quick syntax checks.

There is no build step or third-party dependency: LOTRO loads the sources under
`HighlightPlayers/` directly. Final UI, event, and PluginData verification can
only be performed inside the game client.

## Repository layout

| Path | Purpose |
|---|---|
| `HighlightPlayers/HighlightPlayers.plugin` | Manifest and plugin version |
| `HighlightPlayers/Main.lua` | Entry point |
| `HighlightPlayers/__init__.lua` | Module import order |
| `HighlightPlayers/Localization.lua` | Language selection, fallback, and change listeners |
| `HighlightPlayers/Locale/*.lua` | EN/FR/DE/RU dictionaries |
| `HighlightPlayers/App.lua` | Component creation and lifecycle |
| `HighlightPlayers/Constants.lua` | Data version and shared limits |
| `HighlightPlayers/Storage.lua` | PluginData load, normalization, migration, and save |
| `HighlightPlayers/Labels.lua` | Label operations |
| `HighlightPlayers/Relationships.lua` | Player records and session indexes |
| `HighlightPlayers/TargetTracker.lua` | Current-target event and state |
| `HighlightPlayers/Indicator.lua` | On-screen indicator |
| `HighlightPlayers/PlayerNoteWindow.lua` | Quick note editing for the current target |
| `HighlightPlayers/*Window.lua` | Main window, player card, and label management |
| `HighlightPlayers/Launcher.lua` | Floating launcher |
| `HighlightPlayers/Commands.lua` | `/eh` commands |
| `docs/` | Public user and development documentation |

## Lifecycle

`Main.lua` creates `App` and registers load and unload behavior. `App:Start()`
initializes components in this order:

1. Storage loads and normalizes PluginData.
2. Localization resolves the saved or automatic language.
3. Labels and Relationships construct the data model.
4. TargetTracker subscribes to target changes.
5. Indicator and windows receive their dependencies through constructors.
6. Launcher and Commands expose the user entry points.

`App:Stop()` removes subscriptions in reverse order and saves through Storage.
A new component should have an explicit lifecycle and must not leave event
handlers active after unload.

## PluginData and migrations

Data is stored under the `HighlightPlayers` key in
`Turbine.DataScope.Server`. The current schema version is defined by
`Constants.DataVersion`.

When changing persisted data:

1. increment `DataVersion`;
2. add normalization for old values in `Storage.lua`;
3. preserve valid existing records and settings;
4. make the conversion idempotent;
5. test empty, partially damaged, and previous-version data;
6. update the user guide and manual test checklist.

Never assume every field or type is valid: PluginData may come from an older
version or may have been edited manually. Do not change a label's stable ID
when changing its display name.

Version 4 adds the `noteWindow` position and
`settings.indicator.showNoteTooltip`. When version 3 is loaded, missing fields
receive safe defaults and player records remain unchanged.

Version 5 adds `settings.language` with `auto`, `en`, `fr`, `de`, or `ru`.
Invalid values fall back to `auto`; all other persisted data remains unchanged.

## Localization

English is the fallback dictionary. Every other dictionary must contain the
same keys and the same template parameters. Do not place user-facing strings
directly in UI or model code; use
`HighlightPlayers.Localization.Get(key, values)`.

Windows subscribe with `Localization.AddListener` and unsubscribe in `Stop`.
Changing language must not clear unsaved form input. User-facing text uses
Verdana-family fonts that support diacritics and Cyrillic. Label names are user
data and are not translated.

## Events and performance

- Target reads happen on `TargetChanged`, not every frame.
- Exact name matching uses a table keyed by the normalized name.
- Lists use session indexes rebuilt after mutations.
- Hidden UI must not take keyboard focus or intercept the mouse.
- The indicator always participates in hit testing, so hover and short clicks
  work in every mode. `/eh move` enables dragging, while `/eh lock` only
  prevents position changes.
- A background timer or `Update` handler requires a specific justification and
  in-client performance testing.

When changing a hot path, test fast target changes and databases with 100, 500,
and, when practical, 1,000 records.

## Local development workflow

1. Create a branch from the latest `staging`.
2. Link the working `HighlightPlayers` directory into the game plugin directory
   or copy it there after changes.
3. Run `/plugins refresh` after changing the manifest or module set.
4. Reload the plugin after Lua changes.
5. Watch for Lua errors and messages prefixed with `[HighlightPlayers]`.
6. Run the relevant parts of the [manual checklist](manual-test.md).

Do not test against real user data without a backup. Keep migration fixtures
for older versions outside the repository.

## Code changes

- use the `HighlightPlayers` namespace;
- declare temporary functions and values with `local`;
- pass dependencies into constructors instead of creating hidden global
  instances;
- keep shared limits and versions in `Constants.lua`;
- centralize user-facing messages and provide context for technical errors;
- update `__init__.lua` when adding a module;
- never commit generated archives or local task files.

Follow the surrounding style: four spaces, one module per file, early returns
for invalid states, and explicit `Start`/`Stop` methods for subscriptions.

## Verification

Every change should at least cover:

1. syntax checking for all changed Lua files;
2. plugin load without Lua errors;
3. reload after saved data is written;
4. the primary user flow affected by the change;
5. no regression in current-target matching;
6. valid links in changed Markdown files.

Use the full [manual test checklist](manual-test.md) for UI, target events, and
migrations. The API limitation and target-matching decision are documented in
the [prototype results](prototype-test.md).

## Branches and releases

- `staging` contains development and test changes;
- `main` contains stable versions;
- a `vX.Y.Z` tag must point to `main` and match the manifest `<Version>`.

GitHub Actions builds the installation ZIP and SHA-256 file after a tag is
pushed. See the [release guide](releasing.en.md) for the complete procedure.

## Documentation

A behavior change is complete when the relevant documents are updated:

- README for positioning or installation changes;
- user guide for UI or command changes;
- development guide for architecture or process changes;
- roadmap when a feature is delivered, moved, or dropped;
- manual checklist for new critical behavior.

Internal decisions and draft decompositions must not be committed or linked
from public documentation.
