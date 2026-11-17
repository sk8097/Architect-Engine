# Legacy migration scripts

The following root-level Python files are historical source-generation or one-off migration scripts. They are **not runtime dependencies** of the Flutter app or Deepesh Mobile Studio:

- `add_images.py`
- `fix.py`
- `fix_ui.py`
- `update_app.py`
- `update_cad.py`
- `update_layout.py`

They contain embedded copies of older Dart source and may overwrite files under `lib/`. Do not run them against the current working tree unless the exact intended changes have been reviewed and a clean backup/branch exists.

The current authoritative Flutter source is under `lib/`. The current Android build and validation path is defined by `.github/workflows/build_apk.yml`.

`fix_and_update.py` is an incomplete stub and has no supported role in the build.

When a migration is genuinely needed, prefer a small targeted patch to the current source over replaying an old whole-file generator.
