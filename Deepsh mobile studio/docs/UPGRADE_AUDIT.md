# Deepesh Mobile Studio — Baseline Technical Audit

**Audit date:** 2026-11-16  
**Repository:** https://github.com/sk8097/Architect-Engine  
**Scope:** `Deepsh mobile studio/`  
**Baseline branch:** `main`  
**Baseline commit:** `7e804ffdf50851428492c0b651c9a589fbc449d5`  
**Audit branch:** `upgrade/deepesh-studio-advanced`

## 1. Audit method and limits

This is a repository-backed static audit of the source tree, documentation, installer, CLI entry points, rendering modules, plugin metadata, and test scripts. It is not a runtime certification. No Android device, Windows host, Google Flow session, Cartesia account, or full render environment was available to execute the production pipeline during this audit. Findings below distinguish directly verified source defects from risks that require runtime confirmation.

The audit tree contains 1,127 entries, including 83 Python files, 279 Markdown/text documentation files, 325 media/font/image assets, and 26 Python cache entries. These counts include the nested plugin export and skill/reference assets.

## 2. Current architecture inventory

### Production paths
- **V2 project workflow:** `studio.py` dispatches voice, asset planning, linting, prompt generation, Flow generation, keying, audio mixing, preview, render, and QC commands.
- **V2 renderer:** `core/engine/render.py`, supported by `core/engine/layouts.py`, `styles.py`, `timeline.py`, `character.py`, `collage.py`, `kit.py`, and `variety.py`.
- **Legacy workflow:** `mobile_run.py` and `core/render.py` retain the SCENES.tsv-based pipeline for older projects.
- **AI visual generation:** `core/flow_safe.py`, `flow_guard.py`, `flow_harvest.py`, `flow_bridge.py`, and prompt/asset planners.
- **Voice and audio:** Cartesia TTS, alignment modules, `core/mix.py`, and related sound-design skills.
- **AntiGem integration:** `manifest.json`, `worker.js`, `plugin.json`, and `antigem-plugins.json`.
- **Test coverage:** `scripts/test_all_features.py`, `scripts/stress_test.py`, and `core/selftest.py`.

### Preservation rule
Do not delete or rewrite the legacy renderer during the upgrade. V2 is the canonical path for new projects. Existing V1 projects must remain runnable through an explicit compatibility path until migration tests prove parity.

## 3. Findings

### P1 — Windows Flow Guard lock release is broken
**File:** `core/flow_guard.py`

The module defines an `msvcrt` locking implementation when `fcntl` is unavailable, but the `_ledger()` context manager ends by calling `fcntl.flock(...)` directly rather than the platform-neutral `_unlock()` helper. On Windows, `fcntl` is undefined, so a normal ledger context exit can raise `NameError`. This affects Flow guard status/acquisition paths. Replace direct release calls with the selected platform adapter and guarantee release in a `finally` block. Add Windows-specific lock/unlock tests.

### P1 — Explicit worker count bypasses mobile safety caps
**File:** `core/mobile_config.py`

`get_safe_workers(requested)` returns any positive requested count before checking whether the process is running on Android. A caller can therefore request an unsafe worker count on a low-memory phone, bypassing the documented mobile clamp. Clamp requested values to the platform maximum and preferably to a free-memory budget; expose an explicit unsafe override only if deliberately requested.

### P1 — Installer masks dependency and hook failures
**File:** `setup_mobile.sh`

The installer uses `|| true` for pip installation, static FFmpeg setup, rule copies, skill copies, and hook installation. Some are optional, but required dependency installation failures can be hidden. The script can proceed with a partial environment and its success banner can overstate readiness. Split required and optional packages, use platform-specific install groups, verify imports and FFmpeg/ffprobe, report skipped optional integrations, and return non-zero for missing required dependencies.

The current dependency install combines Pillow, NumPy, SciPy, SoundFile, faster-whisper, OpenCV headless, and static FFmpeg into one pip transaction. This is not a reliable universal dependency set for Termux and Windows. No Python requirements lock/constraints file was found in the studio root.

### P1 — Audio fallback can hide failed sound design
**Files:** `mobile_run.py`, `core/engine/render.py`

The legacy runner returns success from `run_audio_mix()` when mixing fails and continues with direct voiceover. The V2 renderer invokes audio-mix subprocesses with `check=False` and catches broad exceptions without surfacing a structured failure. Fallback to clean voiceover may be a valid user-selected mode, but it must not be indistinguishable from a successful broadcast mix. Add an explicit fallback state, render warnings, and strict/lenient modes; QC must fail when the project requires a mix that was not produced.

### P1 — Plugin packaging path appears incomplete
**Files:** `antigem-plugins.json`, nested `2d-video-editing-studio/`

The plugin index points to `2d-video-editing-studio`. The nested directory currently contains only six files (AGENTS.md, GEMINI.md, three core integration files, and one skill document); it does not contain the parent directory's `manifest.json`, `worker.js`, `studio.py`, README, or complete engine. Verify the AntiGem repository-index contract, then package the complete required plugin payload or point the index at the correct package. Do not blindly copy the full 1,100+ entry source tree into the plugin export without checking its intended package size and contract.

### P2 — Mobile runner forces mobile mode on every host
**File:** `mobile_run.py`

The module sets `IS_MOBILE=1` unconditionally and defaults `VOX_ASPECT=9:16`. That is appropriate for a Termux-specific runner, but it misrepresents a Windows host if this entry point is used there. Keep `mobile_run.py` as an explicitly mobile compatibility runner; use `studio.py` as the cross-platform entry point, and document/test that boundary. If Windows support is required through this runner, add actual platform detection rather than forcing mobile mode.

### P2 — Platform/resource model is CPU-only
**File:** `core/mobile_config.py`

Automatic worker selection is based primarily on CPU count, not measured available RAM, storage pressure, thermal state, or device class. The requested-worker bypass compounds this. Add a resource profile abstraction with conservative Android defaults and configurable Windows profiles; never promise a fixed peak-RAM ceiling without measurements on representative hardware.

### P2 — Style metadata is inconsistent
**Files:** `manifest.json`, `worker.js`, `styles/`, `core/engine/styles.py`

The manifest advertises eight supported styles, while the worker's static registry exposes six. The Python styles directory contains additional style modules. The plugin's list/status output can therefore disagree with the actual Python renderer. Establish one canonical registry/schema and generate or validate the manifest and worker metadata from it.

### P2 — Version metadata is inconsistent
**Files:** `README.md`, `studio.py`, `ENGINE_V2.md`, `setup_mobile.sh`, `manifest.json`, `plugin.json`, `antigem-plugins.json`, `worker.js`

Documentation describes V2 with V3 additions, the installer banner says V3, and plugin metadata/worker identify 3.1.0. Introduce one authoritative version file and validate all shipped metadata against it. Do not bump version strings independently.

### P2 — MCP planning/status tools overstate their implementation
**File:** `worker.js`

`studio_status` returns a hard-coded `ready` status rather than checking Python engine, FFmpeg, or provider connectivity. `studio_plan_project` maps supplied lines to rotating static recipes/layouts; it is not equivalent to the full Python asset planner. The tool descriptions should distinguish a quick suggestion from a real production plan. Add explicit health states (available, unavailable, not checked) and bridge-backed planning where supported.

### P2 — Test suite is not wired into CI for the studio
The repository's visible workflow is an Architect Engine Flutter APK build. No dedicated Windows/Linux Python test workflow for Deepesh Mobile Studio was found. Existing scripts provide useful feature and stress tests, but the full test suite was not executed in this static audit. Add CI for syntax/import checks, deterministic unit tests, mocked provider tests, packaging validation, and safe render fixtures. Keep hardware-specific Android performance tests as a separate manual/device matrix.

### P2 — Tracked Python cache artifacts
The source tree contains 26 Python cache entries even though the repository-level `.gitignore` ignores `*.pyc`. Existing tracked artifacts are not removed merely by adding an ignore rule. Remove tracked cache artifacts from the index after confirming they are generated files; preserve source files.

### P2 — Audio asset rights are not evidenced by filenames
The repository contains music files with names such as “Million Dollar Baby” instrumental, “Revolution” acoustic cover, and “Stranger Things Type Music”. A filename or “no copyright” label is not proof of a commercial-use license. Create a source/license/attribution inventory for every bundled music and SFX asset. Exclude assets with unverified rights from monetized export presets until documentation is available.

## 4. Validation status

| Check | Status | Notes |
|---|---|---|
| Repository/tree inventory | Completed | Git tree inspection |
| V2/V1 entry-point review | Completed | Static source review |
| Windows Flow Guard defect | Confirmed | Direct code path |
| Worker cap bypass | Confirmed | Direct code path |
| Installer error masking | Confirmed | Shell source review |
| Audio fallback behavior | Confirmed | Direct code path |
| Plugin package completeness | Confirmed as a structural mismatch | Runtime contract still needs AntiGem validation |
| Python syntax compilation | Not run | No local runtime checkout in this audit |
| Feature suite | Not run | Requires project runtime/dependencies |
| Full stress render | Not run | Requires FFmpeg and media dependencies |
| Android Termux test | Not run | Physical/device runtime required |
| Windows test | Not run | Windows runtime required |
| Google Flow / Cartesia live test | Not run | Authenticated providers required |

## 5. Immediate remediation order

1. Fix cross-platform Flow Guard locking and add deterministic tests.
2. Enforce hard worker/resource limits.
3. Make installer failures explicit and split platform-specific dependencies.
4. Make audio fallback explicit and enforce QC.
5. Correct AntiGem plugin package layout and validate its installation contract.
6. Unify style and version registries.
7. Add Windows/Linux CI and Android device regression instructions.
8. Establish media-license provenance.
9. Only then begin larger animation, motion-graphics, and AI automation feature work.

## 6. Non-negotiable compatibility gates

- Preserve the current `main` branch and existing project files.
- Keep V1 renderer available for legacy projects.
- Do not change default output dimensions, frame rate, typography, audio behavior, or style recipes without golden-output comparisons.
- Every migration must be reversible and documented.
- No success message may be emitted unless the required operation and validation actually succeeded.
- YouTube policy/monetization checks are advisory validation, never a guarantee of monetization or policy approval.
