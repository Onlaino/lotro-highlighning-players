# Releasing Enemy Highlight

[Русский](releasing.md) | **English**

Releases are created automatically by GitHub Actions. The workflow is stored in
`.github/workflows/release.yml` and runs whenever a tag matching `v*`, such as
`v0.2.0`, is pushed.

## 1. Branch model

- `staging` contains development and testing changes;
- `main` contains stable versions used for releases.

Regular changes are committed to `staging` first. After manual testing in
LOTRO, they are moved to `main`. A release tag must point to the intended commit
on `main`.

## 2. One-time GitHub configuration

In the repository settings:

1. Set `main` as the default branch.
2. Open `Settings -> Actions -> General`.
3. Make sure GitHub Actions are enabled for the repository.
4. Under `Workflow permissions`, select `Read and write permissions` and save.

The workflow also declares `contents: write`, which is required to create a
GitHub Release and attach files.

## 3. Preparing a version

Before a release:

1. Finish the intended changes in `staging`.
2. Test the plugin inside LOTRO using `docs/manual-test.md`.
3. Change `<Version>` in `HighlightPlayers/HighlightPlayers.plugin` to the new
   version without the `v` prefix, for example `0.2.0`.
4. Update the README and important notes when needed.
5. Commit and push `staging`.

Example:

```powershell
git switch staging
git add -- HighlightPlayers README.md README.en.md docs
git commit -m "chore: prepare v0.2.0 release"
git push upstream staging
```

## 4. Promoting the stable version to main

If `main` has no independent commits and can be fast-forwarded:

```powershell
git switch main
git pull --ff-only upstream main
git merge --ff-only staging
git push upstream main
```

If Git reports that the branches have diverged, stop the release. Review and
merge the changes through a pull request from `staging` to `main`; do not use a
force push.

Return the local working copy to the development branch afterward:

```powershell
git switch staging
```

## 5. Creating the release tag

The tag version must exactly match the manifest version:

```text
tag:                 v0.2.0
manifest version:     0.2.0
```

Create an annotated tag on the latest `main` commit:

```powershell
git switch main
git pull --ff-only upstream main
git tag -a v0.2.0 -m "Enemy Highlight v0.2.0"
git push upstream v0.2.0
git switch staging
```

Pushing the tag starts the `Create release` workflow under the GitHub `Actions`
tab. A manual release does not need to be created in the GitHub interface.

## 6. Workflow output

The workflow:

1. checks out the commit referenced by the tag;
2. verifies that the tag and manifest versions match;
3. creates `Enemy-Highlight-v0.2.0.zip`;
4. creates `Enemy-Highlight-v0.2.0.zip.sha256`;
5. creates the GitHub Release and generates release notes;
6. attaches the ZIP archive and checksum file.

The installation directory is at the top level of the archive:

```text
Enemy-Highlight-v0.2.0.zip
└── HighlightPlayers
    ├── HighlightPlayers.plugin
    ├── Main.lua
    └── other Lua and resource files
```

Users should download the attached `Enemy-Highlight-v0.2.0.zip` from the
release `Assets` section, not GitHub's automatically generated `Source code`
archives.

### SHA-256 checksum

GitHub displays a SHA-256 digest for the archive, and the workflow also attaches
a `.sha256` file. Users can verify a downloaded archive in PowerShell:

```powershell
Get-FileHash .\Enemy-Highlight-v0.2.0.zip -Algorithm SHA256
```

The resulting hash must match the value shown on the release page. The checksum
file is optional for installation.

## 7. Verifying a published release

After the workflow completes:

1. Open `Actions` and verify that the run is green.
2. Open `Releases` and check the title and tag.
3. Download the attached ZIP.
4. Verify that `HighlightPlayers` is the archive's top-level directory.
5. Install it into a clean LOTRO Plugins directory and perform a short smoke
   test covering plugin load, `/eh`, adding a record, and the target indicator.

## 8. Troubleshooting

### Tag and manifest versions do not match

The tag and `<Version>` differ. Correct the manifest, promote the fix to `main`,
and create a new valid tag. Do not reuse or silently move a published release
tag.

### Resource not accessible by integration

The workflow cannot create a release. Check
`Settings -> Actions -> General -> Workflow permissions` and make sure
`Read and write permissions` is selected. Also verify `contents: write` in the
workflow.

### The workflow did not start

Check that:

- the tag was pushed to GitHub and does not exist only locally;
- the tag begins with `v`;
- `.github/workflows/release.yml` exists in the tagged commit;
- GitHub Actions are enabled for the repository.

### The release exists but has no installation ZIP

Open the workflow run in `Actions` and inspect the `Build installation archive`
and `Create GitHub release` steps.
