---

description: "Task list for SB Regression, Account Balance Forecast"
---

# Tasks: SB Regression, Bank-wide Balance Forecast by Segment

**Input**: Design documents from `/specs/001-balance-forecast/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/notebook-handoff.md, quickstart.md

**Tests**: no test-suite tasks (not requested). Verification is by integrity check cells inside
the notebooks and local runs with `nbrun.py` (research R11).

**Organization**: Tasks are grouped by user story. The EDA is the foundational phase: it is a
gate (spec FR-013, FR-014) that blocks every user story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)

## Path Conventions

- SB notebooks live in `notebook/1_regression/` and start with `36106-26SP-AT3-student_id-`.
  Short names used below, each meaning that full path:
  - `SB-1` = `notebook/1_regression/36106-26SP-AT3-student_id-SB-1-eda-transactions.ipynb`
  - `SB-2` = `notebook/1_regression/36106-26SP-AT3-student_id-SB-2-eda-account_balance_history.ipynb`
  - `SB-3` = `notebook/1_regression/36106-26SP-AT3-student_id-SB-3-eda-economics.ipynb`
  - `SB-a` = `notebook/1_regression/36106-26SP-AT3-student_id-SB-a-Preparation.ipynb`
  - `SB-b` = `notebook/1_regression/36106-26SP-AT3-student_id-SB-b-Baseline.ipynb`
  - `SB-c` = `notebook/1_regression/36106-26SP-AT3-student_id-SB-c-regression.ipynb`
  - `SB-x<N>` = `notebook/1_regression/36106-26SP-AT3-student_id-SB-x<N>-<short-name>.ipynb` (new)
- Companion documents (local, gitignored): `BUSINESS.md`, `STORYTELLING.md`,
  `EXPLAINABILITY.md`, `doc/figures/`.
- Rules for every notebook task: never change locked cells; replace each `Student to fill`
  marker; rename `X.n` headers and their variable in both definition and print cell; imports
  by name in cell 0.b; one `# Utils` cell after imports; one constants cell after Utils;
  narrative only from outputs the developer has run; a chart for every finding; read
  `.blueprint/LANDMINES.md` before editing.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: confirm the local verification loop and the starting state before any edit.

- [X] T001 Run `uv sync`, then run the unedited `SB-1` with `uv run python ~/.claude/skills/data-science-project-andres-ethorimn/scripts/nbrun.py <SB-1> --data data/raw --scratch .nbrun` to confirm the stubs load `transactions.csv` from `data/raw/`
- [X] T002 [P] Record the starting landmine count for the SB notebooks with the detection command in `.blueprint/LANDMINES.md` (expected: 7 in SB) and the locked-cell sources of `SB-1`, `SB-2`, `SB-3`, `SB-a`, `SB-b`, `SB-c` at commit `47cb337`, as the reference for the T041 quality gate
- [ ] T003 Ask the developer for `group_name`, `student_name`, `student_id` and fill the Student Information cell of `SB-1`, `SB-2`, `SB-3`, `SB-a`, `SB-b`, `SB-c`

---

## Phase 2: Foundational (EDA gate, blocks all user stories)

**Purpose**: explicit EDA evidence (tables, visuals, hypothesis tests) that confirms or revises
the provisional assumptions SB-A1 (horizon), SB-A2 (business use) and SB-A3 (scope), and
the hypotheses built from it.

**⚠️ CRITICAL**: no user-story task starts until T014 and T015 are done. Write each EDA cell,
the developer runs it on Colab, then write the `*_insights` text from the real outputs.

- [X] T004 [P] In `SB-1` section B.1, profile `transactions.csv`: shape, types, missing values, duplicate `transaction_id`, date coverage (expected 2023-01-01 to 2025-12-30), columns beyond `doc/36106-26SP-AT3.sql`, and the sign convention of `amount` by `transaction_type` (inflow vs outflow); one chart; fill `dataset_insights`
- [X] T005 [P] In `SB-1` sections B.2 to B.4, explore three features of interest aggregated per account and month (monthly spend, transaction count, `international_transaction_flag` share; net flow is not computable because amounts carry no sign, and type and channel carry little information, both shown in B.1); for each, a chart, one test chosen from its distribution with an effect size, and its relation to the account's balance change over the next `HORIZON` month-ends (complementary load of `account_balance_history.csv` in a student cell); rename each header to the feature; fill `feature_1_insights`, `feature_2_insights`, `feature_n_insights`
- [X] T006 [P] In `SB-1` section C, fill `ethical_considerations` (merchant location and spending categories as proxies for protected traits; mitigation)
- [X] T007 [P] In `SB-2` section B.1, profile `account_balance_history.csv`: rows (expected 1,850,976), accounts (38,562), 48 month-ends per account, check that `balance_change` equals the month-on-month difference, meaning and range of `stress_indicator` (not binary; mean 7.8), `balance_band` levels, negative or zero balances, and month-ends before each account's `open_date` (join `accounts.csv`); one chart; fill `dataset_insights`
- [X] T008 [P] In `SB-2` section B.2 (evidence for SB-A1, horizon), measure how well "balance stays the same" holds at lags 1, 3 and 6 month-ends (persistence MAE in dollars and autocorrelation of change by lag); chart; one test with effect size; fill `feature_1_insights`
- [X] T009 [P] In `SB-2` section B.3 (evidence for SB-A3, scope), compare balance-change dynamics by `account_type` (volatility, share of zero-change months, Term Deposit and Business vs personal types); chart; one test with effect size (for example Kruskal-Wallis with epsilon squared); fill `feature_2_insights`
- [X] T010 [P] In `SB-2` section B.4 (evidence for SB-A2, business use), measure frequency and size of large balance drops over `HORIZON` month-ends (relative to the cut-off balance) and their link with `stress_indicator` and `balance_band`; chart; one test with effect size; fill `feature_n_insights`
- [X] T011 [P] In `SB-2` section C, fill `ethical_considerations` (balance and stress as signals of financial vulnerability; outreach must not become exclusion)
- [X] T012 [P] In `SB-3` sections B.1 to B.4, profile `economics.csv` (72 monthly rows dated first of month, columns, `economic_cycle`, `recession_flag`), state the publication-lag reading used in research R5, and relate three indicators (for example `interest_rate`, `unemployment_rate`, `consumer_sentiment`) to the monthly mean balance change across accounts (complementary load); charts; one test each with effect size and a note on the small number of months; fill the insight variables and rename headers
- [X] T013 [P] In `SB-3` section C, fill `ethical_considerations` (macro conditions affect groups unequally; no group-level inputs from economics)
- [X] T042 [P] In `SB-2`, add B.5 (horizon trade-off: usable cut-offs, drop shares, miss by horizon) and B.6 (balance-level study: log-binned spread and drop share, logistic fit for a data-derived threshold), with narratives from outputs
- [X] T043 [P] Create `notebook/1_regression/36106-26SP-AT3-student_id-SB-4-eda-complementary.ipynb` (complementary EDA: customer financial profile, loans active at the cut-off, repayment stress before the cut-off) from the EDA template without template comments
- [X] T014 Close the EDA gate (2026-10-26): SB-A1 keep 3 months (SB-2 B.2, B.5); SB-A2 revised to bank-wide planning by segment (no drop signal in SB-1, SB-2 B.4, SB-4; group-level signals in SB-3, SB-4); SB-A3 all six types (SB-2 B.3); spec, research R4 and R12, data model, contract, `BUSINESS.md` and memory updated
- [X] T015 Write the hypotheses in `BUSINESS.md` section "Hypotheses": one falsifiable hypothesis per planned experiment (H1, H2, ...) plus one ethical anchor hypothesis, each with its business objective, the EDA evidence it rests on (notebook and section), the model family it implies, and its decision rule fixed now (replacement only if the posterior mean MAE gain exceeds a ROPE of 1% of baseline MAE); define the "large drop" threshold for the early-warning reading from T010 evidence (depends on T014)
- [X] T016 [P] Fill the EDA sections of `EXPLAINABILITY.md` with each test choice, its formula, the effect size and a worked example on the real outputs; add the cited papers to `doc/figures/REFERENCES.bib` (depends on T014)

**Checkpoint**: EDA gate closed; constants and hypotheses fixed before any model result exists.

---

## Phase 3: User Story 1 - Forecast each account's future month-end balance (Priority: P1) 🎯 MVP

**Goal**: forecasts that use only data available at each cut-off, scored against "balance
stays the same" with MAE in dollars, and the SC-001 outcome on the test period.

**Independent Test**: on the held-out test cut-offs, MAE in dollars of the forecast vs the
persistence baseline, with the outcome set by the SC-001 rule.

- [ ] T017 [US1] In `SB-a`, fill cell 0.a (installs only if Colab lacks a package) and 0.b (imports by name), add the `# Utils` cell (helpers with explicit parameters: cut-off list, period assignment with embargo, monthly transaction aggregation, lag features, integrity checks) and the constants cell with the values from `specs/001-balance-forecast/contracts/notebook-handoff.md` (`HORIZON`, `IN_SCOPE_TYPES`, `LOOKBACK`, `N_TEST_CUTOFFS`, `N_VAL_CUTOFFS`, `SEED`)
- [ ] T018 [US1] In `SB-a` section B, implement cleaning, one subsection per issue with header and variable renamed: drop month-ends before `open_date` ("An account belongs to one segment per cut-off and was open for the whole look-back window"); recompute balance changes from balances; no filter on `account_status`; count loans only from `loan_start_date`; fill each `data_cleaning_*_explanations` (depends on T017)
- [ ] T019 [US1] In `SB-a` section C, assign accounts to segments at each cut-off by `SEGMENT_KEYS`, merge segments under `MIN_SEGMENT_ACCOUNTS` into the nearest balance band (print counts and merges), build one example per segment per cut-off with "`cutoff_date + HORIZON <= 2025-12-31` (target observed)", assign periods by cut-off date with the embargo "Every training target month-end is on or before the first validation cut-off; same for validation against test", set `training_df`, `validation_df`, `testing_df`, print boundaries and counts (expected with `HORIZON = 3`: training 2023-03-31 to 2024-07-31, 17 cut-offs; validation 2024-10-31 to 2025-01-31, 4; test 2025-04-30 to 2025-09-30, 6); assert "`(segment_id, cutoff_date)` is unique within and across periods"; fill `data_splitting_explanations` (depends on T018)
- [ ] T020 [US1] In `SB-a` section A, run the feature-selection approaches on training cut-offs only (A.1 EDA-evidence screening, A.2 one data-driven ranking such as mutual information; rename A.n or delete its cells if unused), set `features_list` in A.z excluding keys and every column forbidden by the contract, fill the `feature_selection_*` variables (depends on T019)
- [ ] T021 [US1] In `SB-a` section D, engineer the segment features kept in T020: segment total and account count at the cut-off, recent change of the total over `LOOKBACK`, segment composition (share by account type), economics from the month before the cut-off (research R5); each must satisfy "No feature is computed from a row dated after `cutoff_date`"; one subsection per feature with header and variables renamed (depends on T020)
- [ ] T022 [US1] In `SB-a` section E, apply transformations fitted on training rows only, order X columns per the contract (`segment_id`, `cutoff_date` first; `total_at_cutoff` present), sort rows by `cutoff_date` then `segment_id`, add an integrity cell (no target column, no forbidden column, no future-dated input, unique keys, embargo holds), fill the `data_transformation_*` variables (depends on T021)
- [ ] T023 [US1] In `SB-a` section F, fill `ethical_considerations` for the prepared dataset; leave the locked save cell G unchanged; developer runs `SB-a` to write `X_train.csv`, `X_val.csv`, `X_test.csv` (depends on T022)
- [ ] T024 [US1] In `SB-b`, fill 0.a, 0.b, Utils and constants (same values as `SB-a`); in A.2 set `target_name = 'target_change'` defined as "total at `cutoff_date + HORIZON` of the segment's cut-off accounts minus `total_at_cutoff`" and fill `target_definition_explanations` (depends on T023)
- [ ] T025 [US1] In `SB-b` A.3, rebuild the segment example keys with the same rule as `SB-a`, build `y_train`, `y_val`, `y_test` with columns `segment_id`, `cutoff_date`, `target_change`, assert their keys equal the `X_*.csv` keys row by row, fill `data_splitting_explanations`; in A.4 chart and describe the target distribution (`target_distribution_explanations`); leave the locked save cell A.5 unchanged (depends on T024)
- [ ] T026 [US1] In `SB-b` section B, score the persistence baseline (segment total stays the same) and the training-mean change on validation; B.2 justify MAE in dollars (`performance_metrics_explanations`); B.3 report baseline MAE overall and per segment, and relative error per segment, with a chart (`baseline_performance_explanations`) (depends on T025)
- [ ] T027 [US1] For each hypothesis Hn from T015, create `SB-x<N>` by copying `SB-c` without its hidden template comments; implement the shared protocol: load splits and check key alignment, pipelines with scaling inside, expanding-window folds by cut-off date inside training (same folds for every arm), a small grid with a business reading per parameter, `cached_grid_search` with `MODEL_DIR` next to the data, fold MAE table, Bayesian correlated t-test against persistence with the ROPE fixed in T015, validation MAE overall and by group, verdict and ranked next step (depends on T026)
- [ ] T028 [US1] In `SB-c`, fill A (business understanding from `BUSINESS.md`, no claims beyond the EDA), B (`features_list` of the selected model), C.1 to C.3 (algorithm and hyperparameters chosen by the experiments in T027, with explanations), C.4 (fit on training plus validation, read the test period once, MAE vs persistence with chart); in D set `experiment_outcome` by the SC-001 rule and fill `experiment_results_explanations` (depends on T027)
- [ ] T029 [US1] Run `SB-a`, `SB-b`, every `SB-x<N>`, `SB-c` locally in that order with `nbrun.py --data data/raw --charts --scratch .nbrun`; confirm every integrity cell passes and numbers match the developer's Colab run; record verified numbers in the number bank of `STORYTELLING.md` (depends on T028)

**Checkpoint**: MVP: the forecast and its SC-001 outcome stand on their own.

---

## Phase 4: User Story 2 - Translate forecast quality into a business decision (Priority: P2)

**Goal**: the forecast's errors in money and risk terms for the decision the EDA supports.

**Independent Test**: from the held-out test forecasts alone, produce the dollar impact and
the action it supports, without retraining.

- [ ] T030 [US2] In `BUSINESS.md` section "Business objective and economics", write the planning economics: cost of an over-forecast (funding gap) and of an under-forecast (idle funding) per dollar, and a known-values table marking each parameter measured, given, derived or assumed
- [ ] T031 [US2] In `SB-c` section C.5, split test errors into over-forecasts and under-forecasts with the business cost of each, bank-wide and per segment; compute cost across a range of the assumed parameters (sensitivity table and chart); fill `business_impacts_explanations` (depends on T028, T030)

**Checkpoint**: US1 and US2 both readable without US3.

---

## Phase 5: User Story 3 - Show the forecast is fair and explainable (Priority: P3)

**Goal**: forecast quality checked by protected group, and drivers named in business terms.

**Independent Test**: test-period MAE by protected group next to the overall MAE, checked
against the SC-002 ratio.

- [ ] T032 [US3] In `SB-c` section C.6, join per segment the share of vulnerable customers and mean age from `customers.csv` after prediction ("fairness audit only; never inputs"), report each segment's relative error next to the overall relative error, flag any segment above 1.25 times (SC-002) with a mitigation, chart; fill `ethical_considerations` (depends on T028)
- [ ] T033 [US3] In `SB-c`, add a sub-cell after C.4 that names the main forecast drivers in business terms (coefficients for a linear model, or permutation importance on validation for a tree model), with a chart (depends on T028)
- [ ] T034 [P] [US3] Re-read the ethics sections of `SB-1`, `SB-2`, `SB-3`, `SB-a` and `SB-c` and align them with the audit result of T032 (each states a concrete risk and the business action that mitigates it)

**Checkpoint**: all three user stories complete.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [ ] T035 [P] Write `README.md`: purpose, dependencies (Colab, the course package, extra `%pip` packages), data folder, SB run order from `specs/001-balance-forecast/quickstart.md`, local verification; no mention of internal documents
- [ ] T036 [P] Complete `EXPLAINABILITY.md` for preparation, experiments, decision and fairness (formulas, worked examples, numbered figures), and keep its references in sync with `doc/figures/REFERENCES.bib`
- [ ] T037 [P] Create `doc/figures/make_figures.py` producing the SB report figures (PDF and PNG, no baked titles) and tables (`.tex` booktabs and `.csv`) from notebook outputs with source comments; list each in `doc/figures/MANIFEST.md` with its LaTeX caption, chapter and source
- [ ] T038 Fill the SB chapter arc and evidence-strength table in `STORYTELLING.md`, then write the SB chapter (at most 4,000 words) in `doc/36106-26SP-AT3-group_id-student_id-z-project_report.docx` using only numbers from the verified number bank (depends on T029, T031, T032, T037)
- [ ] T039 Run the alignment pass across `BUSINESS.md`, `STORYTELLING.md`, `EXPLAINABILITY.md`, `doc/figures/MANIFEST.md` and the notebooks: same hypothesis IDs, numbers, figure list and references
- [ ] T040 Run `specs/001-balance-forecast/quickstart.md` validation end to end on Colab (developer) and locally; record any number that differs and the library version behind it
- [ ] T041 Quality gate for every SB notebook: no `Student to fill` markers and no `.n` headers left; locked cells identical to the T002 reference; landmine count unchanged from T002; every narrative number matches its printed output; then commit with a `[FEATURE]` message after the secret scan and ask before pushing

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: none.
- **Foundational (Phase 2, EDA gate)**: after Setup; blocks every user story. T014 needs
  T004 to T013; T015 and T016 need T014.
- **US1 (Phase 3)**: after T015. Strictly sequential, because each notebook reads the files
  the previous one wrote: `SB-a` (T017 to T023), then `SB-b` (T024 to T026), then
  experiments (T027), then `SB-c` (T028), then local verification (T029).
- **US2 (Phase 4)**: T030 after T015; T031 after T028 and T030.
- **US3 (Phase 5)**: after T028; T032 and T033 edit the same notebook, so run them in
  sequence; T034 after T032.
- **Polish (Phase 6)**: T035 to T037 can start after T029; T038 after T029, T031, T032, T037;
  T039 to T041 last.

### User Story Dependencies

- **US1 (P1)**: depends only on the EDA gate.
- **US2 (P2)**: reads the US1 test forecasts; does not change them.
- **US3 (P3)**: reads the US1 test forecasts; does not change them.

### Within Each Notebook

- Cells in template order; the developer runs each finished section on Colab before its
  narrative variable is written.

### Parallel Opportunities

- T002 alongside T001.
- T004 to T013 across the three EDA notebooks (`SB-1`: T004 to T006; `SB-2`: T007 to T011;
  `SB-3`: T012, T013); inside one notebook, keep section order.
- T016 alongside T015.
- T030 alongside the US1 notebook work after T015.
- T034, T035, T036, T037 once their inputs exist.

---

## Parallel Example: Foundational EDA

```bash
Task: "T004 Profile transactions.csv in SB-1 section B.1"
Task: "T007 Profile account_balance_history.csv in SB-2 section B.1"
Task: "T012 Profile economics.csv and relate indicators in SB-3 sections B.1 to B.4"
```

## Parallel Example: User Story 1

```bash
# US1 notebooks hand files to each other, so they run in sequence.
# In parallel with them, once T015 is done:
Task: "T030 Write the early-warning economics in BUSINESS.md"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1 Setup.
2. Phase 2 EDA gate: close T014 and T015 before any model work.
3. Phase 3 US1: preparation, baseline, experiments, final notebook, local verification.
4. **Stop and validate**: test MAE vs persistence and the SC-001 outcome.

### Incremental Delivery

1. Setup and EDA gate: evidence and hypotheses fixed.
2. US1: forecast and outcome (MVP).
3. US2: business reading on the same test forecasts.
4. US3: fairness audit and drivers.
5. Polish: README, companions, figures, report chapter, quality gate.

---

## Notes

- [P] tasks touch different files and have no unfinished dependencies.
- Commit after each logical group with a `[FEATURE]`, `[UPDATE]` or `[CHORE]` message; ask
  before every push.
- Never write a hypothesis, conclusion or narrative number ahead of the output that supports it.
