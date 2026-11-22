# Architect Engine — Project Status

**Active Branch:** `arena/dd917060-architect-engine`
**Platform:** Flutter / Dart (`lib/`, `test/`, `android/`, `.github/workflows/build_apk.yml`)
**Storage:** Local-first (`SharedPreferences` `ae_projects_v1`)

## Completed
- 8-category taxonomy (`lib/data/project_taxonomy.dart`) with 34 groups and 476 named types.
- Dynamic `ProjectWizardScreen` with dependent field filtering, category icons/subcategory counts, optional step badges, and **Skip to Review** shortcut.
- `ConceptZoningGenerator`, `EnclosedCadGenerator`, `TypologyBayCadGenerator` (shared parametric bay & circulation CAD), `TowerPlannerScreen`, and specialist CAD modes.
- `FinishScheduleScreen` (measured face/linear takeoff + CSV export) and `ScenarioLibraryScreen` (type coverage matrix + CSV).
- 168 calculation tools, Vastu guide, Unit Converter, and CI APK build.

## Pending
- Unified `GenerationGateway` boundary and explicit `ValidationState` enum across all generators.
- Dedicated `Property / Land Records` and `Utilities` top-level sections.
- Remaining master documentation files (`MASTER_CONTEXT.md`, `CATEGORY_TAXONOMY.md`, `DATA_MODEL.md`, `GENERATION_ENGINE.md`, `API_CONTRACTS.md`, `TEST_REPORT.md`, `IMPLEMENTATION_MATRIX.md`).
