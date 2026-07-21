# Enemy Highlight user guide

[Русский](user-guide.md) | **English** · [Documentation index](README.md)

## What the plugin does

Enemy Highlight stores character records that you create in LOTRO. Each record
has a name, a colored label, and an optional note. When a saved character is
selected as your target, the assigned label appears next to the standard target
frame.

The plugin does not scan or classify characters automatically. Labels are your
personal annotations.

## Installation and updates

1. Download `Enemy-Highlight-vX.Y.Z.zip` from the `Assets` section of the
   appropriate [GitHub Release](https://github.com/Onlaino/lotro-highlighning-players/releases).
   Do not use an automatically generated `Source code` archive.
2. Extract it into `Documents\The Lord of the Rings Online\Plugins`.
3. Verify this manifest path:
   `Documents\The Lord of the Rings Online\Plugins\HighlightPlayers\HighlightPlayers.plugin`.
4. Run `/plugins refresh` in the game.
5. Open the LOTRO Plugin Manager and load `Enemy Highlight`.

To update, replace the files in `HighlightPlayers` and reload the plugin. Keep
your PluginData: older formats are migrated automatically.

A successful load writes a version message to chat. If the plugin does not
appear in the manager, first check that extracting the archive did not create a
double `HighlightPlayers\HighlightPlayers` directory.

## Quick start

1. Run `/eh` or click the floating launcher.
2. Enter a character name, or select a target and click `Use target`.
3. Select a label and click `Add / update`.
4. If needed, click the name in the list and add a note in the player card.
5. Select that character again to see the label next to the target frame.

## Main window

The top area contains `Player name`, `Use target`, the label selector,
`Add / update`, and `Manage labels`.

Categories with player counts appear on the left. `All` contains the entire
database. Selecting a label filters the list and selects that label for a new
record; selecting `All` does not change the form's current label.

`Search` matches part of a name and is case-insensitive for ordinary Latin
names. Under `All`, it searches the entire database; under a label, only that
category. Notes are not searched. Click a player name to edit its name, label,
or note, or to remove the record.

## Managing labels

Open the window with `Manage labels` or `/eh labels`. You can:

- create, rename, and recolor labels;
- enter RGB components from `0` to `255`;
- view the number of assigned players;
- remove an unused label;
- set the indicator's maximum width and height;
- enable or disable `Show note tooltip`.

A label name is required, limited to 32 characters, and case-insensitively
unique. The final label cannot be removed. A label in use can only be removed
after its players are reassigned or deleted.

## Target indicator

The indicator appears only for a known target. Its size follows the label text
and the limits configured in `Manage labels`.

To reposition it:

1. run `/eh move`;
2. drag the indicator marked `[click / drag]` with the left mouse button;
3. run `/eh lock`.

After `/eh lock`, dragging is disabled but the indicator remains interactive.
Its position and size limits are saved automatically.

In every mode:

- when `Show note tooltip` is enabled, hovering shows the full player name,
  label name, and non-empty note;
- a short click without dragging opens a dedicated note window;
- the note can be edited and saved with `Save note`;
- after saving, the tooltip updates immediately without changing targets.

An empty note does not produce a tooltip, but clicking still opens an empty
editor. `/eh move` additionally enables dragging, while `/eh lock` fixes the
indicator position again.

## Floating launcher

The floating launcher is always available, regardless of the current target. A
short click opens or hides the main window. Hold the left mouse button and drag
to move it. The position is saved when you release the button.

## Chat commands

| Command | Action |
|---|---|
| `/eh`, `/eh toggle` | Open or hide the main window |
| `/eh show` | Open the main window |
| `/eh hide` | Hide the main window |
| `/eh move` | Show and unlock the indicator |
| `/eh lock` | Lock the indicator position |
| `/eh labels` | Open label management |
| `/eh add <nickname>` | Open a card with a prefilled name |
| `/eh add <nickname> <label name>` | Assign the specified label immediately |
| `/eh info <nickname>` | Print the saved note to chat |
| `/eh probe` | Print current-target diagnostics |
| `/eh help` | Show a short command reference |

The label name passed to `/eh add` may contain spaces. Adding an existing name
again changes its label but preserves its note.

## Name and target matching

Before storage, a name is trimmed and passed through `string.lower`. `Antwyn`,
`ANTWYN`, and `antwyn` therefore share one key. Target matching is exact after
this normalization, while list search supports partial matches.

LOTRO Lua has no complete Unicode case normalization. Reliable
case-insensitive matching is primarily guaranteed for ordinary Latin names. An
NPC with the same name is technically indistinguishable from a saved player.

## Data storage

Labels, player records, notes, window positions, and settings are stored in
LOTRO PluginData at server scope. Your characters on the same server share a
database; different servers remain isolated.

Back up PluginData before manual experiments or installing a test build. A
normal plugin update does not require deleting saved data.

## Troubleshooting

### The plugin is missing from the manager

- verify the path to `HighlightPlayers.plugin`;
- run `/plugins refresh` after extraction;
- make sure you downloaded the release asset rather than a source archive.

### A saved target has no indicator

- check the saved name for a typo;
- run `/eh probe` and compare the reported target name with the record;
- confirm that the target is the saved character rather than a similarly named
  NPC.

### A window or indicator obstructs the UI

- reposition the indicator with `/eh move`, then run `/eh lock`;
- drag the floating launcher while holding the left mouse button;
- adjust indicator limits in `Manage labels`.

When reporting a bug, include the plugin version, server, reproduction steps,
and the complete Lua error text.
