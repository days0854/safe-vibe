# Secure Installer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace mutable `main` branch remote execution with a versioned, checksum-pinned, transactional Safe Vibe installer and publish `v0.1.0`.

**Architecture:** A tracked payload manifest verifies local files before installation. The installer copies verified files into same-filesystem staging directories, locks each target and rolls back replacements on failure. A deterministic release builder packages the verified tree; documentation publishes a fixed outer archive hash.

**Tech Stack:** Bash 3.2+, curl, POSIX utilities, SHA-256 (`sha256sum` or `shasum`), Python 3 standard library for reproducible release builds, GitHub Actions

## Global Constraints

- PIPA catalog remains `0.2.0`; KISA catalog remains `0.3.0`.
- Remote `curl | bash` execution must fail closed.
- Release installation runs only after a fixed expected SHA-256 matches.
- Existing non-Safe-Vibe skills must never be modified.
- Existing `.cursor/rules/safe-vibe.mdc` must not be overwritten.
- Original PDFs and legal text must not be added.
- Website assets and links remain relative except approved external URLs.

---

### Task 1: Payload Integrity Contract

**Files:**
- Create: `manifest.sha256`
- Modify: `.gitattributes`
- Create: `tests/test-installer.sh`

**Interfaces:**
- Produces: a six-entry SHA-256 manifest for `SKILL.md`, `catalog.json` and `logo.png` in both skill directories.

- [ ] **Step 1: Add a failing manifest test**

Add a test that selects `sha256sum` or `shasum -a 256`, runs verification from the repository root and requires exactly six manifest entries.

- [ ] **Step 2: Verify RED**

Run: `bash tests/test-installer.sh manifest`

Expected: failure because `manifest.sha256` does not exist.

- [ ] **Step 3: Normalize payload line endings and generate the manifest**

Add `*.md text eol=lf` and `*.json text eol=lf` to `.gitattributes`; keep PNG files binary. Generate hashes in deterministic path order.

- [ ] **Step 4: Verify GREEN**

Run: `bash tests/test-installer.sh manifest`

Expected: one passing test and six verified files.

### Task 2: Transactional Local Installer

**Files:**
- Modify: `install.sh`
- Modify: `tests/test-installer.sh`

**Interfaces:**
- Consumes: `manifest.sha256` and packaged `skills/`.
- Produces: atomic installs into `$HOME/.cursor/skills` and optional `$HOME/.claude/skills`.

- [ ] **Step 1: Add failing integration cases**

Cover Cursor success, Claude success, manifest mismatch with untouched destination, lock rejection, rollback after `SAFE_VIBE_TESTING=1 SAFE_VIBE_TEST_FAIL_AFTER_FIRST_REPLACE=1`, preserved existing rule file and stdin execution refusal.

- [ ] **Step 2: Verify RED**

Run: `bash tests/test-installer.sh installer`

Expected: old installer fails integrity, locking, rollback and refusal assertions.

- [ ] **Step 3: Implement the minimum secure installer**

Use `umask 077`, fixed payload paths, manifest verification, atomic `mkdir` locks, same-filesystem staging/backups, explicit rollback and cleanup traps. Remove all remote file fetching. Create the rule through a temporary file only when absent.

- [ ] **Step 4: Verify GREEN**

Run: `bash tests/test-installer.sh installer`

Expected: all installer integration cases pass.

### Task 3: Deterministic Release Artifact

**Files:**
- Create: `scripts/build-release.sh`
- Modify: `tests/test-installer.sh`
- Modify: `.gitignore`

**Interfaces:**
- Command: `bash scripts/build-release.sh v0.1.0 dist`
- Produces: `dist/safe-vibe-v0.1.0.tar.gz` and `dist/safe-vibe-v0.1.0.tar.gz.sha256`.

- [ ] **Step 1: Add failing build tests**

Build twice in separate temporary directories, compare archive hashes, verify the outer checksum and verify the internal manifest after extraction.

- [ ] **Step 2: Verify RED**

Run: `bash tests/test-installer.sh release`

Expected: failure because the builder is absent.

- [ ] **Step 3: Implement deterministic packaging**

Validate `vMAJOR.MINOR.PATCH`, verify the manifest, copy only approved files, and emit canonical USTAR/gzip bytes with sorted entries, epoch timestamps and numeric owner/group.

- [ ] **Step 4: Verify GREEN**

Run: `bash tests/test-installer.sh release`

Expected: both builds have the same SHA-256.

### Task 4: CI and User Documentation

**Files:**
- Create: `.github/workflows/release.yml`
- Modify: `README.md`
- Modify: `tests/test-installer.sh`

**Interfaces:**
- Tag `v*` invokes the complete test suite, builds assets and publishes a GitHub release without third-party actions.

- [ ] **Step 1: Add documentation/workflow assertions**

Require no `raw.githubusercontent.com/.../main/install.sh | bash`, require HTTPS-only curl flags, fixed version and expected hash placeholders, and ensure workflow invokes tests before release.

- [ ] **Step 2: Verify RED**

Run: `bash tests/test-installer.sh docs`

Expected: current README and missing workflow fail.

- [ ] **Step 3: Implement workflow and documentation**

Document the verified multi-line installation and local clone path. Build `v0.1.0` once and insert its generated 64-character lowercase archive hash.

- [ ] **Step 4: Verify all repository checks**

Run: `bash tests/test-installer.sh all && bash -n install.sh scripts/build-release.sh && git diff --check`

Expected: all checks pass and no checksum placeholder remains.

### Task 5: Release and Website Cutover

**Files:**
- Modify: `README.md`
- Modify: `../mcp-hook/install.html`

**Interfaces:**
- Published release: `days0854/safe-vibe` tag `v0.1.0`.
- Website command uses the exact SHA from the published archive.

- [ ] **Step 1: Rebuild and confirm the final archive checksum**

Run: `bash scripts/build-release.sh v0.1.0 dist`

Confirm the generated hash exactly matches the value already published in README.

- [ ] **Step 2: Update the website installation command**

Replace the pipe command with the approved verified download block and explain checksum verification before execution.

- [ ] **Step 3: Run final local verification**

Run: `bash tests/test-installer.sh all`, JSON parsing for both catalogs, website local HTTP smoke tests and `git diff --check` in both repositories.

- [ ] **Step 4: Commit and publish**

Merge the feature branch to `main`, push both repositories, create and push annotated tag `v0.1.0`, and let the workflow publish the release.

- [ ] **Step 5: Verify public artifacts**

Download the public release asset, verify its SHA-256, run it with a temporary HOME, and confirm the deployed website serves the new command.
