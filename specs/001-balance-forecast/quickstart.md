# Quickstart: validate the SB balance forecast end to end

## Prerequisites

- Google Colab with access to the stakeholder Drive folder `36106/assignment/AT3/data/`
  holding the raw CSVs.
- For local verification: `uv sync` in the repository and the raw CSVs in `data/raw/`.

## Run order (Colab)

Run each notebook top to bottom, in this order, with no other archetype run in between
(shared hand-off file names, see `contracts/notebook-handoff.md`):

1. `notebook/1_regression/...-SB-1-eda-transactions.ipynb`
2. `notebook/1_regression/...-SB-2-eda-account_balance_history.ipynb`
3. `notebook/1_regression/...-SB-3-eda-economics.ipynb`
4. `notebook/1_regression/...-SB-a-Preparation.ipynb` (writes `X_*.csv`)
5. `notebook/1_regression/...-SB-b-Baseline.ipynb` (writes `y_*.csv`, scores persistence)
6. `notebook/1_regression/...-SB-x<N>-<name>.ipynb`, one per experiment
7. `notebook/1_regression/...-SB-c-regression.ipynb` (final solution and outcome)

## Local verification (before hand-over)

```bash
uv run python ~/.claude/skills/data-science-project-andres-ethorimn/scripts/nbrun.py \
  "notebook/1_regression/<notebook>.ipynb" --data data/raw --charts --scratch .nbrun
```

Run in the same order as above; `nbrun.py` points `at.folder_path` at `data/raw`, so the
hand-off CSVs land there (gitignored).

## Expected outcomes

| Check | Expected |
|---|---|
| Every notebook | runs top to bottom with no error; no template markers left |
| EDA notebooks | each assigned table has its insights, one test with effect size per feature of interest, a chart per finding, an ethics section; provisional assumptions SB-A1 to SB-A3 confirmed or revised with cited evidence |
| Preparation | prints period boundaries and example counts; integrity cells pass (unique keys, no future data, embargo, no forbidden column) |
| Baseline | y keys equal X keys; persistence MAE in dollars on validation, overall and by group |
| Experiments | each states one hypothesis and its pre-set rule, reports fold MAE, posterior vs baseline with ROPE, validation MAE |
| Final notebook | test MAE vs persistence, outcome set by the SC-001 rule, errors by type, balance band, status and protected group, business reading with sensitivity, ranked next steps |
| Local vs Colab | same numbers for the same seed and data; any library-version difference named |
