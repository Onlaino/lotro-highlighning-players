# Enemy Highlight

[Русский](README.md) | **English**

`Enemy Highlight` is a plugin for The Lord of the Rings Online that acts as a
personal character directory. Assign colored labels and notes to players, and
the plugin displays the saved label next to the standard frame of your selected
target.

> The plugin does not scan nearby characters or classify players
> automatically. Every record is created by the user.

## Features

- custom labels with editable names and RGB colors;
- notes and search across saved characters;
- a label indicator for the current target;
- player management through the UI and `/eh` chat commands;
- one shared database per server, isolated from other servers;
- automatic data migration when the storage format changes.

## Installation

1. Download `Enemy-Highlight-vX.Y.Z.zip` from
   [Releases](https://github.com/Onlaino/lotro-highlighning-players/releases).
2. Extract it into `Documents\The Lord of the Rings Online\Plugins`.
3. Verify that
   `Plugins\HighlightPlayers\HighlightPlayers.plugin` exists.
4. In LOTRO, run `/plugins refresh`, open the Plugin Manager, and load
   `Enemy Highlight`.

After loading, use `/eh` or the floating launcher. When updating, replace the
`HighlightPlayers` directory but keep your PluginData.

## Documentation

### For users

- [Complete user guide](docs/user-guide.en.md): installation, updates, UI,
  commands, data storage, and troubleshooting.
- [Руководство на русском](docs/user-guide.md).

### For contributors

- [Development guide](docs/development.en.md): architecture, local workflow,
  data migration rules, and testing.
- [Contributing guidelines](CONTRIBUTING.en.md).
- [Roadmap](docs/roadmap.en.md).
- [Documentation index](docs/README.md).

## Feedback

Check existing issues before opening a new one. Bug reports should include the
plugin version, reproduction steps, expected and actual behavior, and any Lua
error text. Check the [roadmap](docs/roadmap.en.md) before proposing a feature,
although new use cases are always welcome.

## Limitations

The LOTRO Lua API cannot reliably distinguish every PvMP player from an NPC or
determine the allegiance of every target. Records are therefore matched only
by the selected target's name.

## License

This project is distributed under the [MIT License](LICENSE).
