# Data Model: SB Regression, Account Balance Forecast

Source tables are the raw CSVs in the stakeholder data folder. Only columns this feature
uses are listed; the CSVs carry more than `doc/36106-26SP-AT3.sql`.

## Source entities

### Account (`accounts.csv`)

| Field | Use | Rule |
|---|---|---|
| `account_id` | key | unique |
| `customer_id` | join to Customer | |
| `account_type` | selection (`IN_SCOPE_TYPES`), input, error group | fixed at opening |
| `open_date` | tenure input; validity of history | cut-off allowed only if open for the full look-back window |
| `account_status` | error group only | current-day value: never a selection rule or input (FR-015) |
| `current_balance` | not used | current-day value (FR-015) |

### Monthly balance snapshot (`account_balance_history.csv`)

| Field | Use | Rule |
|---|---|---|
| `account_id`, `balance_date` | key | unique pair; 48 month-ends per account |
| `balance` | target source; lag inputs | value at `cutoff_date` and earlier only as input |
| `balance_change` | lag inputs | must equal month-on-month difference (checked in EDA) |
| `balance_band` | error group (balance segment) | taken at the cut-off, not today |
| `stress_indicator` | candidate input after EDA | meaning confirmed in EDA before use |

### Transaction (`transactions.csv`)

| Field | Use | Rule |
|---|---|---|
| `account_id`, `transaction_timestamp` | aggregation key | only transactions on or before `cutoff_date` |
| `amount`, `transaction_type`, `channel`, `international_transaction_flag` | monthly behaviour aggregates | sign convention (inflow vs outflow) confirmed in EDA |
| merchant fields, `aml_risk` | not used unless an EDA finding justifies them | |

### Economic indicator (`economics.csv`)

| Field | Use | Rule |
|---|---|---|
| `economic_date` | key | row used for cut-off `t` is the month before `t`'s month (research R5) |
| `inflation_rate`, `interest_rate`, `unemployment_rate`, `consumer_sentiment`, `economic_cycle`, others | candidate inputs after EDA | lagged one month |

### Customer (`customers.csv`)

| Field | Use | Rule |
|---|---|---|
| `customer_id` | join from Account | |
| `age`, `gender`, `state`, `vulnerable_customer_flag` | fairness audit only | never inputs (FR-008); joined after predictions |

## Derived entity: Forecast example

One row per in-scope account per cut-off month-end.

| Field | Type | Definition |
|---|---|---|
| `account_id` | int | key part; not an input |
| `cutoff_date` | date (month-end) | key part; not an input |
| `period` | `train` / `val` / `test` | from `cutoff_date` (research R3), embargo applied |
| feature columns | numeric / encoded | built only from data dated on or before `cutoff_date` |
| `balance_at_cutoff` | float | balance at `cutoff_date`; input and baseline forecast |
| `target_change` | float | `balance(cutoff_date + HORIZON) - balance_at_cutoff`; lives only in `y_*.csv` |

Validation rules:

- `(account_id, cutoff_date)` is unique within and across periods.
- `cutoff_date + HORIZON <= 2025-12-31` (target observed).
- Every training target month-end is on or before the first validation cut-off; same for
  validation against test (embargo).
- No feature is computed from a row dated after `cutoff_date`.
- Account was open for the whole look-back window at `cutoff_date`.
- `account_type` in `IN_SCOPE_TYPES`; no filter on `account_status`.

Lifecycle: an example has no state transitions. It is created in Preparation (X side) and
in Baseline (y side) by the same deterministic rule, then read by the experiment and final
notebooks (see `contracts/notebook-handoff.md`).

## Derived entity: Prediction record (in memory, for evaluation)

| Field | Definition |
|---|---|
| `account_id`, `cutoff_date`, `period` | from the example |
| `y_true`, `y_pred` | target change and predicted change |
| `abs_error` | `abs(y_true - y_pred)` in dollars |
| `direction` | over-forecast (`y_pred > y_true`) or under-forecast |
| group fields | `account_type`, `balance_band` at cut-off, current `account_status`, protected attributes joined from Customer |
