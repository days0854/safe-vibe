# Safe Vibe Secure Installer Design

## Goal

Replace the mutable `main` branch `curl | bash` flow with a versioned, checksum-pinned release installation that verifies all payload files and cannot leave a partial installation.

## Threat Model

The installer must handle interrupted or truncated downloads, mixed-version files, accidental release corruption, concurrent installer runs, and failures while replacing an existing installation. SHA-256 verification does not protect against full compromise of both the GitHub account and the independently deployed website; signed releases remain a possible later enhancement.

## Distribution

- The first installer release is `v0.1.0`.
- A release asset named `safe-vibe-v0.1.0.tar.gz` contains `install.sh`, both skill directories, and a generated `manifest.sha256`.
- The website and README publish the release URL and the archive's exact SHA-256 value.
- The copied command downloads the archive with HTTPS-only curl options, retries and timeouts; compares it with the fixed expected hash; extracts it to a temporary directory; and runs the local installer.
- `install.sh` refuses stdin/remote-pipe execution when it cannot locate the packaged skill payload beside itself.

## Installer Transaction

1. Validate the supported OS, required commands, payload layout, and `manifest.sha256`.
2. Acquire an atomic lock directory under the destination skill directory.
3. Copy both verified skills into a staging directory on the same filesystem as the destination.
4. Move any existing skill directories to a transaction backup directory.
5. Rename both staged skill directories into place.
6. On any failure after backup begins, remove partial replacements and restore both backups.
7. Remove the backup, staging and lock directories only after success.
8. Apply the same transaction independently to Cursor and Claude Code when present.

`--with-init` creates `.cursor/rules/safe-vibe.mdc`. If the file already exists, installation leaves it unchanged instead of overwriting user configuration.

## Build and Release

- `scripts/build-release.sh <version> <output-dir>` validates the version, generates the internal manifest, and creates the release archive plus a checksum file.
- The build uses sorted file order and normalized metadata so repeated builds from the same source produce the same archive hash.
- A GitHub Actions workflow runs tests, builds the asset on a `v*` tag, and publishes both release files.
- The release is created only from a clean, tested commit.

## Website and Documentation

- Remove every `curl .../main/install.sh | bash` instruction.
- Show a copyable multi-line command containing the fixed version, release URL and expected archive SHA-256.
- Explain that the checksum must match before execution.
- Keep local-clone installation documented as `bash install.sh`.

## Tests

Shell integration tests use temporary HOME directories and cover:

- successful Cursor installation;
- optional Claude Code installation;
- manifest mismatch rejection before destination changes;
- concurrent-install lock rejection;
- rollback after an injected replacement failure;
- preservation of an existing `.cursor/rules/safe-vibe.mdc`;
- refusal to run without a local packaged payload;
- deterministic release build and outer checksum verification.

The existing JSON catalogs are parsed during the test suite. `bash -n` and `git diff --check` remain required release gates.

## Non-goals

- Installing the Python MCP servers;
- changing PIPA `0.2.0` or KISA `0.3.0` catalog versions;
- requiring GPG, Cosign or another verification client;
- deploying or modifying the NCP server directly.
