# Phase 0 Research: SB Regression, Account Balance Forecast

Each entry: Decision, Rationale, Alternatives considered. Items marked **provisional** are
working assumptions that the EDA confirms or revises (spec FR-013, FR-014); the plan makes
them parameters so a revision changes a constant, not the design.

Facts measured before planning (2026-10-23, `data/raw/`):

| Fact | Value |
|---|---|
| Balance history | 1,850,976 rows; 38,562 accounts; 48 month-ends, 2022-01-31 to 2025-12-31; every account has all 48 |
| Transactions | 1,532,009 rows; 2023-01-01 to 2025-12-30 |
| Economics | 72 monthly rows, 2020-01-01 to 2025-12-01, dated first of month |
| Accounts by type | Savings 13,650; Transaction 11,502; Term Deposit 5,846; Offset 3,796; Business 1,901; Youth 1,867 |
| Accounts by current status | Active 34,603; Dormant 2,758; Closed 1,201 |
| Opened after first month-end | 22.5% of accounts |
| CSV columns vs `doc/36106-26SP-AT3.sql` | CSVs carry extra columns (for example `balance_band`, `stress_indicator`, merchant fields, `aml_risk`); the DDL is a subset |

## R1. Forecast horizon (provisional)

- **Decision:** `HORIZON = 3` month-ends, held as one constant shared by the Preparation,
  Baseline and regression notebooks.
- **Rationale:** developer's likely answer (spec Assumptions); quarterly planning cadence.
  Confirmed or revised from the balance-history EDA (autocorrelation and size of change by
  lag 1, 3, 6).
- **Alternatives:** 1 month (persistence very strong, little room to add value); 6 months
  (fewer cut-offs, larger economic effect).

## R2. Forecast target

- **Decision:** model the balance change `balance(t+H) - balance(t)`; the forecast balance is
  `balance(t) + predicted change`. Evaluate MAE on the balance, which equals MAE on the change.
- **Rationale:** the persistence baseline is exactly "predicted change = 0", so every model
  is read as a correction to the bank's current assumption; change is closer to stationary
  than level across balance segments.
- **Alternatives:** model the level directly (dominated by the current balance; models
  relearn persistence); model the percentage change (unstable near zero balances, spec edge
  case).

## R3. Cut-offs, periods and the embargo

- **Decision:** one forecast example per account per month-end cut-off `t` with
  `t + H <= 2025-12-31`. First cut-off is the first month-end with a full transaction
  look-back window (transactions start 2023-01). Periods by cut-off date, most recent last:
  test = the last 6 cut-offs, validation = the 6 before, training = the rest. Embargo: a
  cut-off `t` stays in its period only if `t + H` is on or before the first cut-off of the
  next period, which drops the last `H - 1` cut-offs of training and of validation. No
  training target month-end then falls after the first validation cut-off, and likewise for
  validation and test.
- **Rationale:** spec FR-003, FR-004 and Q3; the embargo stops overlapping targets from
  leaking the next period's outcomes. With `H = 3` and a 3-month transaction look-back:
  cut-offs 2023-03-31 to 2025-09-30 (31); test 2025-04-30 to 2025-09-30 (6); validation
  2024-10-31 to 2025-01-31 (4 of 6 kept); training 2023-03-31 to 2024-07-31 (17 of 19 kept). Exact boundaries are
  printed by the Preparation notebook and re-derived if `HORIZON` changes.
- **Alternatives:** random split (rejected: leaks the future); single cut-off (rejected in
  clarification Q3); no embargo (rejected: overlapping targets).

## R4. Accounts in scope and current-day fields (provisional scope)

- **Decision:** `IN_SCOPE_TYPES = {Savings, Transaction, Offset, Youth}` (provisional, R1
  style constant). Account type is fixed at opening, so it may select examples. Current
  status and current balance are never used for selection or inputs (FR-015); status is used
  only to group errors. Months before an account's open date are not history: a cut-off is
  used only when the account was open for the whole look-back window.
- **Rationale:** spec Q4 and FR-015 (no future knowledge); edge case on late openings
  (22.5% of accounts).
- **Alternatives:** all types (Term Deposits inflate accuracy); filter on status (leaks).

## R5. Economic alignment

- **Decision:** at cut-off month-end `t`, use the economic row of the previous month
  (`economic_date` = first day of the month before `t`'s month).
- **Rationale:** macro figures are published after their reference month; a one-month lag is
  the conservative reading of "available at the cut-off" (FR-003, edge case). Revisit only if
  the EDA shows the dataset is contemporaneous by construction, and say so in the notebook.
- **Alternatives:** same-month row (possible look-ahead); two-month lag (loses signal).

## R6. Feature families (selected by EDA, not fixed here)

- **Decision:** the Preparation notebook may build only these families, each kept only when
  the EDA shows evidence for it: balance history (lags, recent change, volatility over the
  look-back window); transaction behaviour per account and month (inflow, outflow, count,
  share by type and channel, international share); account attributes fixed at opening
  (type, tenure); economics (lagged level and recent change). Customer protected attributes
  (age, gender, state, vulnerable flag) are excluded from inputs and joined back only for the
  audit (FR-008).
- **Rationale:** constitution II and VI; the hypothesis must cite EDA evidence (FR-014).
- **Alternatives:** wide automatic feature generation (rejected: not explainable, no
  evidence per feature).

## R7. Model families and comparison protocol

- **Decision:** the baseline is persistence (change = 0), plus a training-mean change as a
  second trivial reference. Model families are chosen by the hypotheses written after the
  EDA; the expected candidates are a regularised linear model on the change (explainable
  default) and a gradient-boosted tree model with an absolute-error loss (only if a
  hypothesis implies non-linear or interaction effects). Comparison uses expanding-window
  folds by cut-off date inside the training period (same folds for every arm), MAE per fold,
  and the Bayesian correlated t-test with a ROPE of 1% of the baseline MAE. Hyperparameter
  grids are small and each parameter has a business reading. Searches are cached with joblib
  next to the data.
- **Rationale:** constitution III (one hypothesis per experiment, one comparison method,
  simpler model wins ties); an absolute-error loss optimises the agreed metric (Q1).
- **Alternatives:** shopping many algorithms (rejected by III); frequentist and Bayesian tests
  together (rejected: one method).

## R8. Decision rule and business reading

- **Decision:** SC-001 rule from clarification Q5 (>= 10% lower MAE confirms, 0-10% partial,
  no gain rejects), on the test period, read once. The early-warning reading (provisional
  use) needs a "large drop" threshold and the outreach economics; both are set after the EDA
  and marked **[pending]** until then, with sensitivity across their uncertain values.
- **Rationale:** constitution I and VII; spec User Story 2.
- **Alternatives:** threshold chosen after seeing model results (rejected: post-hoc).

## R9. Storage and joins

- **Decision:** plain CSV through the locked template cells and pandas joins; no DuckDB,
  feature store or dashboard in this feature.
- **Rationale:** constitution VIII (approval after benefit shown) and spec Q2; the locked
  cells read and write CSV regardless. Volumes fit Colab memory (largest working frame is
  about 0.9 million examples by tens of columns). The DuckDB question in the developer's
  notes stays open for a later feature.
- **Alternatives:** embedded DuckDB for monthly aggregation (deferred, not rejected).

## R10. Experiment notebooks

- **Decision:** each experiment (one hypothesis) gets its own notebook copied from the
  regression template without the hidden template comments, named
  `36106-26SP-AT3-student_id-SB-x<N>-<short-name>.ipynb`. The template's
  `SB-c-regression.ipynb` holds only the final clean solution (brief, FR-010).
- **Rationale:** brief ("wrap the solution pipeline in a single clean notebook"); skill
  convention for added experiments.
- **Alternatives:** all experiments inside `SB-c-regression` (rejected: not clean).

## R11. Verification

- **Decision:** each notebook carries integrity check cells (row counts per period, unique
  `(account_id, cutoff_date)` keys, X/y key alignment, no target column in X, no cut-off later
  than its target, no protected attribute in `features_list`). Before hand-over each notebook
  runs locally with `nbrun.py` on `data/raw`; numbers re-checked against the Colab run.
- **Rationale:** constitution II and V; no test framework is needed for notebooks.
- **Alternatives:** pytest suite (rejected: overengineering for notebook deliverables).
