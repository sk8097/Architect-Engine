# Feasibility reports

Run the checker from the repository root:

```bash
python tools/architect_engine_feasibility_check.py path/to/plan.json
```

Each run writes:
- `reports/architect_engine_feasibility_report.txt` — latest report
- `reports/history/feasibility_YYYYMMDD_HHMMSS.txt` — timestamped history copy

The script saves reports in the current Codespace workspace. To preserve them in GitHub, review and commit the generated report files:

```bash
git add reports/architect_engine_feasibility_report.txt reports/history/
git commit -m "Save feasibility validation report"
git push
```

A report with no basic geometry blockers is still **not** construction approval. Room connectivity, real wall openings, local building rules, ventilation, parking access and structural design require separate checks.
