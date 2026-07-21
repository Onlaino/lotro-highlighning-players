# Contributing to Enemy Highlight

[Русский](CONTRIBUTING.md) ·
[Development guide](docs/development.en.md)

Thank you for your interest in the project. Small fixes may be proposed directly
through a pull request. For a substantial feature, open an issue first so the
user scenario, LOTRO Lua API limits, and any PluginData changes can be agreed on
before implementation.

## Before starting

1. Check existing issues and the [roadmap](docs/roadmap.en.md).
2. Create a focused branch from the latest `staging`.
3. Never commit local material from `tasks/` or `docs/tasks/`.
4. Keep a pull request limited to one logical change when practical.

## Change requirements

- avoid per-frame processing when LOTRO events are sufficient;
- preserve PluginData compatibility and add an idempotent migration for schema
  changes;
- discuss new third-party dependencies before adding them;
- update user documentation and the roadmap when behavior changes;
- add new checks to `docs/manual-test.md`;
- never commit user data, local logs, or internal task files.

## Verification

There are no automated integration tests for the LOTRO UI. Before opening a
pull request:

1. syntax-check changed Lua files with an available parser;
2. verify the manifest and module paths;
3. run relevant items from the [manual checklist](docs/manual-test.md) in LOTRO;
4. verify loading and reloading after data is saved;
5. check local links in changed Markdown files.

Explicitly list any check that could not be performed.

## Pull requests

The description should explain:

- the problem being solved;
- the user-visible change;
- the verification performed;
- whether PluginData changes and how migration works;
- screenshots for visible UI changes.

Release tags are created by the maintainer from stable `main`. See the
[release guide](docs/releasing.en.md) for details.
