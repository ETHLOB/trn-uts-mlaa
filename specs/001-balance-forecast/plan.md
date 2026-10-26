# Implementation Plan: SB Regression, Bank-wide Balance Forecast by Segment

**Branch**: `sb-regression/001-balance-forecast` | **Date**: 2026-10-23 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/001-balance-forecast/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

Forecast each customer segment's total balance 3 months after a cut-off, and show whether it
beats the bank's current assumption that the total stays the same. Revised at the EDA gate
(2026-10-26): account-level changes showed no signal, while income band, active loans and the
economy relate to group-level growth, so the unit is the segment (research R12), over all six
account types. The forecast is a change on top of the cut-off total, one example per segment per
month-end, split into training, validation and test periods by cut-off date with an embargo.
Quality is mean absolute error in dollars; the outcome follows the pre-set SC-001 rule. The work
fills the SB notebook templates plus the complementary EDA notebook and one experiment notebook
per hypothesis.

## Technical Context

**Language/Version**: Python 3.12 locally (uv); Colab's Python for stakeholder runs

**Primary Dependencies**: pandas, scikit-learn, scipy, altair (notebook charts),
matplotlib (report figures), joblib (cached searches); course package `uts_36106_core==0.0.3`
via the locked setup cell

**Storage**: CSV files in the stakeholder Drive folder through the locked template cells;
raw CSVs in `data/raw/` locally (gitignored)

**Testing**: integrity check cells inside each notebook, plus local execution with
`nbrun.py` before hand-over (research R11)

**Target Platform**: Google Colab (stakeholder), local Jupyter for verification

**Project Type**: notebook-based data-science pipeline (course template deliverable)

**Performance Goals**: each notebook completes in one Colab session; cached grid searches
reload without refitting when inputs are unchanged

**Constraints**: locked template cells stay byte-identical; only data available at each
cut-off; protected attributes never inputs; report chapter at most 4,000 words; Colab memory
(the locked loaders read all raw tables, about 0.8 GB of CSV)

**Scale/Scope**: at most 40 segments by 27 kept cut-offs, about 1000 examples (exact count
printed by Preparation); 7 template notebooks, 1 complementary EDA notebook, one per experiment

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Gate | Pre-research | Post-design |
| --- | --- | --- | --- |
| I. Business first | Economics and decision stated; metric follows them; no accuracy headline | Pass: MAE in dollars, SC-001 rule, early-warning economics marked [pending] until EDA (R8) | Pass |
| II. Evidence before claims | Narrative only from produced outputs; one test with effect size per question | Pass: FR-013/014 gate; provisional constants (R1, R4) | Pass |
| III. Hypotheses, not swaps | One hypothesis per experiment; rules fixed before results; same folds; one comparison method | Pass: R7, R10 | Pass |
| IV. Template integrity | Locked cells unchanged; markers replaced; only trusted sources | Pass: hand-off contract works within locked cells | Pass |
| V. Reproducible notebooks | Colab top to bottom; Utils cell; constants cell; local nbrun | Pass: R11, shared constants in contract | Pass |
| VI. Honest data handling | No leakage; train-only fitting; time split | Pass: R3 embargo, R4 current-day fields, R5 economic lag | Pass |
| VII. Fairness audit | Protected groups recovered after modelling; human decision | Pass: FR-008, data model Prediction record | Pass |
| VIII. Simplicity | No unapproved infrastructure | Pass: R9 (no DuckDB, no dashboard) | Pass |

No violations; Complexity Tracking is empty.

## Project Structure

### Documentation (this feature)

```text
specs/001-balance-forecast/
├── plan.md                       # This file
├── research.md                   # Phase 0: decisions R1-R11
├── data-model.md                 # Phase 1: source entities, forecast example, prediction record
├── quickstart.md                 # Phase 1: run order and expected outcomes
├── contracts/
│   └── notebook-handoff.md       # Phase 1: X_*/y_* schema, shared constants, alignment
├── checklists/requirements.md    # spec quality checklist
└── tasks.md                      # Phase 2 (/speckit-tasks; not created here)
```

### Source Code (repository root)

```text
notebook/1_regression/
├── 36106-26SP-AT3-student_id-SB-1-eda-transactions.ipynb            # EDA, assigned table
├── 36106-26SP-AT3-student_id-SB-2-eda-account_balance_history.ipynb # EDA, assigned table
├── 36106-26SP-AT3-student_id-SB-3-eda-economics.ipynb               # EDA, assigned table
├── 36106-26SP-AT3-student_id-SB-a-Preparation.ipynb                 # writes X_*.csv
├── 36106-26SP-AT3-student_id-SB-b-Baseline.ipynb                    # writes y_*.csv; persistence
├── 36106-26SP-AT3-student_id-SB-x<N>-<short-name>.ipynb             # one per hypothesis (new)
└── 36106-26SP-AT3-student_id-SB-c-regression.ipynb                  # final clean solution
```

Local-only companions (gitignored): `BUSINESS.md`, `STORYTELLING.md`, `EXPLAINABILITY.md`,
`doc/figures/`.

**Structure Decision**: no source package (non-package uv environment; helpers live in each
notebook's `# Utils` cell). Notebook order and file hand-off follow
[contracts/notebook-handoff.md](contracts/notebook-handoff.md).

## Phase Outline (input for /speckit-tasks)

1. **EDA (gate)**: fill the three EDA notebooks. Each provisional assumption gets explicit
   evidence: SB-A1 horizon (change size and persistence by lag), SB-A2 use (frequency and
   size of large drops), SB-A3 scope (dynamics by account type). Update spec Assumptions,
   `BUSINESS.md` and the shared constants. Nothing below starts until this gate is closed.
2. **Hypotheses**: write one hypothesis per experiment plus the ethical anchor, each citing
   EDA evidence and a success rule (FR-014).
3. **Preparation**: feature selection, cleaning, split by cut-off with embargo, feature
   engineering and transformations fitted on training rows; integrity cells; save X.
4. **Baseline**: build target and y with aligned keys; persistence and training-mean
   baselines; metric rationale; baseline MAE overall and by group.
5. **Experiments**: one notebook per hypothesis with the shared protocol (R7).
6. **Final notebook**: clean solution, test period read once, SC-001 outcome, errors by
   group, business reading with sensitivity, ethics, ranked next steps.
7. **Report and companions**: SB chapter within 4,000 words; figures, number bank,
   explainability entries.

## Complexity Tracking

No constitution violations to justify.
