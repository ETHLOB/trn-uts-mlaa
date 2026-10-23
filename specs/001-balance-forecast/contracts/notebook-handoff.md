# Contract: SB notebook hand-off files

The template's locked cells fix the file names and the folder (`at.folder_path`). This
contract fixes their content so the SB notebooks agree with each other. All four
archetypes share these names, so the SB chain runs contiguously (constitution, H03 in the
local landmine registry).

## Producers and consumers

| File | Written by (locked cell) | Read by |
|---|---|---|
| `X_train.csv`, `X_val.csv`, `X_test.csv` | `SB-a-Preparation` section G | `SB-b-Baseline` B, `SB-x<N>` experiments, `SB-c-regression` B |
| `y_train.csv`, `y_val.csv`, `y_test.csv` | `SB-b-Baseline` A.5 | same as above |

## Shared constants

Identical in every SB notebook's constants cell; any change is made in all of them.

| Constant | Provisional value | Source |
|---|---|---|
| `HORIZON` | 3 | research R1 |
| `IN_SCOPE_TYPES` | Savings, Transaction, Offset, Youth | research R4 |
| `LOOKBACK` | 3 month-ends | research R3 |
| `N_TEST_CUTOFFS`, `N_VAL_CUTOFFS` | 6, 6 | research R3 |
| `SEED` | 42 | constitution V |

## `X_*.csv` schema

| Column | Rule |
|---|---|
| `account_id` | first column; key, excluded from `features_list` |
| `cutoff_date` | second column, ISO `YYYY-MM-DD`; key, excluded from `features_list` |
| `balance_at_cutoff` | always present (baseline forecast) |
| feature columns | as selected in Preparation A.z; numeric after section E transformations |

Forbidden in X: any target or future column, `account_status`, `current_balance`,
`customer_id`, `age`, `gender`, `state`, `vulnerable_customer_flag`.

Transformations learned from data (scaling, encodings) are fitted on `X_train` rows only.

## `y_*.csv` schema

| Column | Rule |
|---|---|
| `account_id`, `cutoff_date` | same values and same row order as the matching `X_*.csv` |
| `target_change` | `balance(cutoff_date + HORIZON) - balance_at_cutoff`, dollars |

Consumers squeeze `target_change` after checking key alignment.

## Ordering and alignment

- Rows in every X and y file are sorted by `cutoff_date`, then `account_id`.
- Baseline rebuilds the example keys with the same rule as Preparation and asserts that its
  keys equal the X keys row by row before saving y.
- Every consumer asserts `X[["account_id","cutoff_date"]]` equals
  `y[["account_id","cutoff_date"]]` before fitting or scoring.

## Outcome variables (final notebook)

`SB-c-regression` section D sets `experiment_outcome` to exactly one of
`'Hypothesis Confirmed'`, `'Hypothesis Partially Confirmed'`, `'Hypothesis Rejected'`, by
the SC-001 rule on the test period.
