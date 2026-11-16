# Deepesh Mobile Studio — Advanced Upgrade Plan

**Target:** Android/Termux + Windows  
**Development:** Direct GitHub implementation  
**Priority:** Complete advanced production studio  
**Base:** `main@7e804ffdf50851428492c0b651c9a589fbc449d5`  
**Working branch:** `upgrade/deepesh-studio-advanced`

## Product objective

Evolve Deepesh Mobile Studio into a cross-platform, AI-assisted video production engine while preserving all working V1 and V2 projects. The upgrade must improve reliability, creative capability, throughput, and measurable output quality—not merely add menu items or claim unsupported integrations.

## Target architecture

- **Canonical project pipeline:** V2 project schema and `studio.py` orchestration.
- **Compatibility layer:** retain V1 `SCENES.tsv` / `core/render.py` path for old projects.
- **Core services:** project manager, job queue, checkpoint/recovery, provider adapters, resource manager, render coordinator, and QC/reporting.
- **Visual engine:** procedural 2D/2.5D composition, keyframe/tween system, camera paths, parallax/depth layers, typography, data graphics, maps, timelines, and style packs.
- **AI provider adapters:** Google Flow for visual assets; Cartesia and ElevenLabs as configurable voice providers. Provider credentials remain outside source control.
- **Platform adapters:** Android/Termux and Windows with platform-specific dependencies and resource policies.
- **AntiGem integration:** truthful MCP health/status, actual bridge-aware operations, schema-validated inputs, and complete package exports.

## Phased delivery

### Phase 0 — Baseline, backup, and compatibility contract
- Keep main unchanged; work only on the upgrade branch.
- Record baseline commit, file inventory, current CLI commands, style list, schemas, and output fixtures.
- Build sample projects for V1 and V2 (16:9 and 9:16).
- Capture golden frame sheets, audio metadata, output dimensions/FPS, and known-good render hashes where deterministic.
- Define a migration and rollback policy.

**Exit gate:** baseline fixtures and command compatibility tests exist before production code refactors.

### Phase 1 — Platform and reliability hardening
- Repair Windows/Unix locking in Flow Guard.
- Enforce Android worker/thread caps even when users request higher counts; add RAM-aware profiles.
- Separate Termux, Windows, and optional desktop dependency groups.
- Replace silent installer success with required/optional dependency reports and exit codes.
- Add structured logs, actionable provider errors, retry/backoff policies, and resumable job state.
- Preserve existing Flow pacing/unusual-activity safeguards; do not bypass provider limits.
- Make audio fallback explicit and add strict/lenient modes.

**Exit gate:** mocked Windows/Unix locking tests, Termux dependency checks, Windows dependency checks, and failure-injection tests pass.

### Phase 2 — Canonical orchestration and project model
- Make V2 the canonical pipeline for new work.
- Add a versioned project manifest with schema validation and migration helpers.
- Keep V1 projects executable; add an explicit compatibility adapter rather than deleting old modules.
- Add project-level configuration for aspect ratio, FPS, quality preset, voice provider, visual provider, and resource profile.
- Add deterministic job IDs, checkpoints, resume/retry, cancellation, and clean output manifests.

**Exit gate:** existing V1/V2 sample projects still render and new project creation is reproducible.

### Phase 3 — Advanced visual and animation engine
- Add reusable keyframe tracks and easing/spring curves with explicit units and bounds.
- Add layered 2.5D scenes, depth maps/parallax, camera paths, focus/blur controls, and compositing.
- Add procedural SVG/Pillow/FFmpeg graphics: charts, maps, timelines, money flows, comparison panels, labels, and callouts.
- Add reusable motion-graphics recipes and style presets with central schema validation.
- Add subtitle-safe layout constraints for Hindi, Marathi, and English.
- Add preview-quality rendering and partial rerender support.

**Exit gate:** golden-frame tests for each new effect, text-fit tests, and both aspect-ratio test fixtures.

### Phase 4 — AI visual asset pipeline
- Formalize provider adapters and capability discovery.
- Retain Google Flow bridge and existing generation pacing/duplicate prevention.
- Add asset provenance, prompt hash, provider/model, generation state, dimensions, and license/source metadata.
- Add asset validation, transparent cutout checks, image dimension checks, duplicate detection, and recovery.
- Keep a manual-review path for generated assets.

**Exit gate:** mocked provider tests, retry/resume tests, duplicate-generation tests, and no credential leakage.

### Phase 5 — Professional audio and voice system
- Normalize provider interfaces for Cartesia and ElevenLabs.
- Preserve exact provider timestamps where available; mark estimated alignment honestly.
- Add multi-speaker tracks, emotion/style controls, room tone, ambience, Foley/SFX layering, ducking, loudness measurement, true-peak checks, and silence detection.
- Provide explicit voice-only fallback and required-mix failure states.
- Add audio rights and attribution inventory for bundled assets.

**Exit gate:** known sample tracks meet configured loudness/true-peak/sync thresholds; failed mixes cannot be reported as successful.

### Phase 6 — Intelligent editing and production automation
- Build a queue for multiple projects with concurrency limits per device/provider.
- Add script-to-shot planning, coverage checks, visual density checks, pacing analysis, scene variety, and human approval checkpoints.
- Add batch production with resumable jobs and rate-limit-aware scheduling.
- Support high-volume production as a workload target, not a guaranteed throughput claim; measure actual device, provider, and render bottlenecks.

**Exit gate:** repeatable batch test, safe pause/resume, no duplicate jobs, and resource limit enforcement.

### Phase 7 — Quality-control and export validation
- Visual checks: missing media, black/frozen frames, unexpected aspect ratio, safe-zone violations, text overflow, low resolution, and duplicate/repetitive visuals.
- Audio checks: missing track, clipping, loudness, true peak, silence/dead air, and voice/music balance.
- Timeline checks: audio/video duration, frame rate, cue alignment, subtitle coverage, and gaps.
- Export checks: codec, dimensions, FPS, duration, stream presence, file size, and playable output.
- Generate a machine-readable JSON report and readable HTML/Markdown report.
- Add policy-aware YouTube checklist for copyright/asset rights, reused/repetitive content risks, disclosures where applicable, and advertiser suitability. Never claim automatic approval or guaranteed monetization.

**Exit gate:** deliberately broken fixtures are detected; clean fixtures pass; QC report is saved with every master export.

### Phase 8 — AntiGem plugin and MCP integration
- Validate the expected AntiGem plugin repository contract.
- Correct nested package layout and include every required runtime file.
- Generate plugin metadata from the canonical version/style registry.
- Make status report actual engine/bridge/provider availability rather than a hard-coded ready state.
- Distinguish static suggestions from real project planning and rendering operations.
- Validate MCP input schemas and return structured errors/progress.

**Exit gate:** install, status, style listing, planning, and command generation tested in AntiGem.

### Phase 9 — CI, performance, and release
- Add Windows and Ubuntu CI for Python syntax, import checks, unit tests, packaging, and mocked provider workflows.
- Add deterministic render fixtures and stress tests.
- Run manual Android/Termux regression on representative low-, mid-, and high-memory devices.
- Benchmark preview/final render speed, peak RAM, CPU, disk use, and thermal throttling.
- Maintain release notes, migration notes, known limitations, and rollback instructions.
- Remove generated cache files from version control and maintain an asset-license manifest.

**Exit gate:** CI green, V1/V2 compatibility matrix green, Android and Windows test reports attached, no unresolved critical/high defects.

## Compatibility and quality policy

1. Do not delete or silently rewrite V1 modules.
2. Do not change default output behavior without golden-render comparisons.
3. Every new feature needs unit tests plus at least one integration or fixture test.
4. Every provider operation must report success/failure accurately and preserve resumability.
5. Secrets must never be committed or printed in logs.
6. No fake progress, fake provider availability, or fake 100% completion.
7. YouTube policy/monetization checks are advisory and cannot guarantee channel or video approval.

## First implementation batch

The first code batch should be limited to the confirmed reliability defects:
1. Cross-platform Flow Guard lock/unlock.
2. Worker cap enforcement.
3. Installer dependency/error handling.
4. Explicit audio fallback/QC state.
5. Tests for the above.

Do not begin large renderer rewrites until this batch is green.
