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

- **Decision:** one forecast example per segment per month-end cut-off `t` (research R12) with
  `t + H <= 2025-12-31`. First cut-off is the first month-end with `LOOKBACK` (3) month-ends of
  balance history before it, 2022-04-30; transactions are not used (no signal, SB-1), so their
  later start no longer limits the cut-offs (decided 2026-10-27). Periods by cut-off date, most recent last:
  test = the last 6 cut-offs, validation = the 6 before, training = the rest. Embargo: a
  cut-off `t` stays in its period only if `t + H` is on or before the first cut-off of the
  next period, which drops the last `H - 1` cut-offs of training and of validation. No
  training target month-end then falls after the first validation cut-off, and likewise for
  validation and test.
- **Rationale:** spec FR-003, FR-004 and Q3; the embargo stops overlapping targets from
  leaking the next period's outcomes. With `H = 3` and a 3-month balance look-back:
  cut-offs 2022-04-30 to 2025-09-30 (42); test 2025-04-30 to 2025-09-30 (6); validation
  2024-10-31 to 2025-01-31 (4 of 6 kept); training 2022-04-30 to 2024-07-31 (28 of 30 kept). Exact boundaries are
  printed by the Preparation notebook and re-derived if `HORIZON` changes.
- **Alternatives:** random split (rejected: leaks the future); single cut-off (rejected in
  clarification Q3); no embargo (rejected: overlapping targets).

## R4. Accounts in scope and current-day fields (decided 2026-10-26)

- **Decision:** all six account types (`IN_SCOPE_TYPES` = Savings, Transaction, Term Deposit,
  Offset, Business, Youth). Current status and current balance are never used for selection or
  inputs (FR-015). Months before an account's open date are not history: an account enters a
  segment at a cut-off only when it was open for the whole look-back window.
- **Rationale:** types move alike (SB-2 B.3: epsilon squared 0.000004), so excluding any has no
  behavioural basis; spec Q4 and FR-015 (no future knowledge); 15.0% of month-ends predate the
  open date (SB-2 B.1).
- **Alternatives:** exclude Term Deposit and Business (rejected: no evidence they differ).

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
  folds by cut-off date inside the training period (same folds for every arm, `HORIZON − 1`
  cut-offs embargoed between each fold's training and validation cut-offs), MAE per fold,
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
  `36106-26SP-AT3-26029165-SB-x<N>-<short-name>.ipynb`. The template's
  `SB-c-regression.ipynb` holds only the final clean solution (brief, FR-010).
- **Rationale:** brief ("wrap the solution pipeline in a single clean notebook"); skill
  convention for added experiments.
- **Alternatives:** all experiments inside `SB-c-regression` (rejected: not clean).

## R13. Baselines (decided 2026-10-27)

- **Decision:** two references, both scored on validation in `SB-b` and on test in `SB-c`.
  Persistence ("the segment total stays the same") is the bank's current assumption and the
  reference for SC-001. Average drift predicts, for a segment, its accounts at the cut-off times
  the mean per-account 3-month change of the training examples (fitted on training only).
- **Rationale:** balances grow on average (about $700 per account per quarter, SB-2 B.2), so
  persistence errs low by construction and any model that learns the average growth beats it.
  Average drift isolates that effect: H1's claim that segment keys and the last-quarter change forecast
  better is supported only if H1 also beats average drift. If it does not, the cheaper and more
  explainable drift rule is the recommendation.
- **Alternatives:** persistence only (rejected: a "confirmed" result could reflect growth alone);
  segment-specific drift as the second reference (rejected: it already uses the segment keys, so
  it is a simple version of H1, not a naive reference).

## R12. Segments (decided 2026-10-26)

- **Decision:** forecast the total balance per segment. Provisional segment keys, each kept only
  with EDA evidence: `income_band` (average growth rises from about $100 Low to $1510 Affluent,
  SB-4 B.2), active loan at the cut-off (growth $480 against $750, SB-4 B.3) and `balance_band` at
  the cut-off (the spread and the drop share depend on the balance, SB-2 B.1 and B.6): at most
  4 x 2 x 5 = 40 segments. Account type, credit score and hardship are not keys (no difference,
  SB-2 B.3, SB-4 B.2). Income and balance band overlap (Cramer's V 0.456), but income still orders
  growth within every balance band and a loan still lowers it (SB-4 B.5), so each key adds its own
  information; the overlap leaves a sparse grid that Preparation merges. A segment's target is
  the total, `HORIZON` months later, of the accounts in it at the cut-off (a cohort), so accounts moving between bands are not counted twice. Segments
  that carry no distinct drift are merged with the nearest balance band of the same income
  band and loan status. Revised 2026-10-27: a segment stays apart only if its per-account drift on
  the training cut-offs differs from the bank-wide drift by at least `Z_MIN` = 2 standard errors
  (pooled as non-overlapping quarters); otherwise it merges into the adjacent band with the closer
  mean, smallest first. The size rule first proposed (standard error below half the $63 loan gap)
  needed 1700 to 200000 accounts per segment and cut-off and could not be met. The merge map is
  fixed on training and applied unchanged to every period; SB-a C prints it (23 segments).
- **Rationale:** account-level changes are close to independent month to month and no table
  signals them (SB-1, SB-2 B.2, SB-4); averaging within segments keeps the group-level signals
  (income, loans, economy) and cancels individual noise (an account's 3-month change varies by
  about $8550; the bank-wide monthly mean moves within $181 to $293, SB-3).
- **Alternatives:** one bank-wide series (rejected: 47 monthly points are too few to learn and
  test on); account-level forecast (rejected at the gate: no signal).

## R14. Time-series properties of the target (decided 2026-10-28)

- **Decision:** the forecast is a direct 3-month regression on a panel of 23 segment series,
  not a per-segment time-series model. `SB-b` A.4 checks three properties on the training
  cut-offs, each with an effective sample size because consecutive 3-month targets overlap
  (cut-offs / `HORIZON`, as in R12): calendar (Kruskal-Wallis on the bank-wide change per
  account of each single training month, by month and by quarter, Holm over the two);
  persistence (Spearman at lags `HORIZON` and `2 × HORIZON`, bank-wide and on each segment's
  deviation with segment and cut-off means removed, intervals by resampling segments); and
  stability (Spearman trend over the cut-offs, bank-wide and per segment, Holm across segments).
  No calendar feature is added. The recent-change feature is redefined on a fixed group
  (`last_quarter_change_per_account`, accounts in the segment `LOOKBACK` month-ends earlier),
  because the group at the cut-off carries band migration. `SB-b` B.3 reports two drift
  variants (last 12 training cut-offs; same calendar months as validation) as diagnostics.
- **Rationale:** 28 training cut-offs per segment are too few for ARIMA or exponential smoothing
  per segment; the signal is between segments (income, loan, balance band, size) and in the
  economy, which one pooled regression shares. The checks found no dynamic signal to model: no
  significant season, no segment-specific persistence, and a bank-wide easing that the
  overlapping cut-offs cannot confirm.
- **Alternatives:** a calendar-month feature (rejected: 12 effects from 2.5 years would overfit,
  and the pattern is not significant); dropping the recent-change feature (rejected: on a fixed
  group it is a time-varying estimate of the segment's drift that H1 can test); a seasonal or
  recent-window drift as the reference (rejected: post-hoc choice; kept as a diagnostic).

## R11. Verification

- **Decision:** each notebook carries integrity check cells (row counts per period, unique
  `(segment_id, cutoff_date)` keys, X/y key alignment, no target column in X, no cut-off later
  than its target, no protected attribute in `features_list`). Before hand-over each notebook
  runs locally with `nbrun.py` on `data/raw`; numbers re-checked against the Colab run.
- **Rationale:** constitution II and V; no test framework is needed for notebooks.
- **Alternatives:** pytest suite (rejected: overengineering for notebook deliverables).
