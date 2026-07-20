# Enemy Highlight

[Русский](README.md) | **English**

`Enemy Highlight` is a plugin for The Lord of the Rings Online that lets you
manually assign custom colored labels to characters. `Friend`, `Neutral`, and
`Enemy` are provided by default, but you can rename, recolor, delete, or extend
them. When a saved character is selected as your target, the assigned label is
shown next to the standard target frame.

The plugin directory and Lua namespace are named `HighlightPlayers`.

## Features

- three default labels and any number of custom labels;
- label renaming and RGB color editing in a dedicated window;
- a styled on-screen indicator for the selected target's assigned label;
- automatic indicator sizing with configurable limits and position locking;
- adding and updating players through the UI or chat commands;
- filling the player name from the current target;
- player cards with a name, label, and multiline note;
- a permanent draggable launcher icon for opening the main window;
- global player search and separate search within each label;
- shared data for characters on the same server and separate data per server.

## Installation and updates

1. Download `Enemy-Highlight-vX.Y.Z.zip` from the GitHub Release assets.
2. Extract the archive into:
   `Documents\The Lord of the Rings Online\Plugins`.
3. Verify that the manifest is located at:
   `Documents\The Lord of the Rings Online\Plugins\HighlightPlayers\HighlightPlayers.plugin`.
4. Run `/plugins refresh` in the game.
5. Open the LOTRO Plugin Manager and load `Enemy Highlight`.

To update, replace the files in the installed `HighlightPlayers` directory and
reload the plugin. Do not delete PluginData: older data formats are migrated
automatically.

After a successful load, the plugin writes this message to chat:

```text
[HighlightPlayers] Enemy Highlight v0.1.0 loaded. Click the launcher icon or use /eh to open.
```

## Target matching

1. The user manually saves a character name and assigns a label.
2. The plugin stores the displayed spelling and a normalized lookup key.
3. On `TargetChanged`, the plugin reads the selected target's name.
4. The name is normalized and looked up in the server database.
5. On a match, the assigned label name and color are displayed.
6. The indicator is hidden for unknown targets or when the target is cleared.

The plugin does not add or classify characters automatically. A label is your
personal marker, not an allegiance detected from the game.

### Name comparison

Before storage and comparison, a name is converted to a string, trimmed, and
passed through `string.lower`. `Antwyn`, `ANTWYN`, and `antwyn` therefore use
the same key: `antwyn`.

Target matching is exact after normalization. List search uses partial matching,
so `ant` finds `Antwyn`. The LOTRO Lua client does not provide full Unicode case
normalization; reliable case-insensitive matching is primarily guaranteed for
ordinary Latin character names.

## Main window

Open or hide the window with `/eh` or by clicking the floating launcher icon.
Opening the window does not automatically focus the name input, so movement
keys are not captured while you are running. The top section contains:

- the `Player name` input;
- the `Use target` button;
- a scrollable palette containing every label and its color;
- the `Add / update` button;
- the `Manage labels` button.

The left side contains a scrollable category list with player counts. `All` is
shown first and contains the total number of records. Selecting a specific label
also selects it in the add form; selecting `All` leaves the add form label
unchanged. Click a player to open the card for editing their name, label, or
note.

The player card uses the same scrollable label palette.

The `Search` field filters names while you type. Under `All`, it searches the
entire database; under a specific label, it searches only that label. Global
results include the assigned label's name and color. Each category keeps its own
query for the current plugin session. `Clear` resets the active query. Notes are
not included in search.

## Managing labels

Open `Manage labels` from the main window or with `/eh labels`. You can:

- create a label;
- rename an existing label;
- set RGB components from `0` to `255`;
- see how many players use a label;
- delete an unused label;
- configure the indicator's maximum width from `60` to `300` pixels and maximum
  height from `20` to `80` pixels.

Label names are required, case-insensitively unique, and limited to 32
characters. The final remaining label cannot be deleted. A label assigned to
players cannot be deleted until those records are reassigned or removed.

## On-screen indicator

To move the indicator:

1. run `/eh move`;
2. hold the left mouse button over the indicator marked with `[drag]`;
3. move it next to the standard target frame;
4. run `/eh lock`.

The position is saved automatically. Width is calculated from the label text,
including UTF-8 characters. Long text wraps without exceeding the configured
maximum width and height. Once locked, the indicator no longer intercepts
clicks intended for the game UI. Its color is shown as a single vertical accent
inside a dark frame, and the text uses a high-contrast supported LOTRO font.

## Floating launcher

The eye-and-label launcher icon is always visible and does not depend on the
current target. A short click opens or hides the main window. Hold and drag it
to change its position; the new position is saved on release. A gold border on
hover indicates that the button is active.

## Chat commands

- `/eh` or `/eh toggle` — open or hide the main window;
- `/eh show` — open the main window;
- `/eh hide` — hide the main window;
- `/eh move` — show and unlock the indicator;
- `/eh lock` — lock the indicator and let clicks pass through it;
- `/eh labels` — open label and indicator-limit management;
- `/eh add <nickname>` — open a card with the name already filled in;
- `/eh add <nickname> <label name>` — assign the specified label immediately;
- `/eh info <nickname>` — print the saved note to chat;
- `/eh probe` — print current-target diagnostics;
- `/eh help` — print a short command reference.

A label name passed to `/eh add` may contain spaces. Adding an existing player
again changes the label while preserving the note. Player and label lookups in
commands are case-insensitive for ordinary Latin text.

## Storage and migration

Data is stored with `Turbine.PluginData.Load/Save`, using
`Turbine.DataScope.Server` and the `HighlightPlayers` key.

Stored data includes:

- stable label IDs, names, and RGB colors;
- displayed and normalized player names;
- the label ID assigned to each player;
- notes;
- window, launcher, and indicator positions;
- indicator size limits and lock state;
- the data format version.

Data format version 2 migrates the old `status` field to `labelId`. Existing
default labels, players, and notes are preserved. Version 3 migrates the former
fixed width and height into limits for the automatically sized indicator.

Data is shared by the user's characters on the current server but is not mixed
between servers.

## Performance

The plugin has no per-frame update handler. It reads the target only on
`TargetChanged`. Exact target lookup uses a normalized-name hash table with
amortized `O(1)` access. Lists use a sorted global session index and indexes by
label ID; they are rebuilt only after records change.

There is no periodic cache clearing. Deterministic invalidation after mutations
avoids stale data and unnecessary background work.

## LOTRO Lua API limitations

A PvMP character may be exposed as an `Actor` without `GetAlignment()`. The
plugin therefore cannot automatically determine whether a target belongs to
the Free Peoples or Monster Players. Records are matched only by name; an NPC
with the same name is technically indistinguishable from a saved player.

## Project structure

- `HighlightPlayers/HighlightPlayers.plugin` — LOTRO plugin manifest;
- `Main.lua` and `App.lua` — startup and lifecycle;
- `Storage.lua`, `Labels.lua`, and `Relationships.lua` — PluginData and models;
- `TargetTracker.lua` and `Indicator.lua` — target tracking and indicator;
- `MainWindow.lua`, `PlayerCardWindow.lua`, and `LabelsWindow.lua` — UI;
- `Launcher.lua` and `Resources/launcher.jpg` — floating launcher;
- `Commands.lua` — `/eh` commands.

No third-party Lua libraries are required. Final UI, target-event, and
PluginData verification must be performed inside the LOTRO client.

- [Manual test checklist (Russian)](docs/manual-test.md)
- [Dynamic-label design notes (Russian)](docs/tasks/dynamic-labels.md)
- [Target API research (Russian)](docs/prototype-test.md)
- [Development roadmap (Russian)](docs/roadmap.md)
- [Release instructions](docs/releasing.en.md)
