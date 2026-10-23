# Feature Specification: SB Regression, Account Balance Forecast

**Feature Branch**: `sb-regression/001-balance-forecast`

**Created**: 2026-10-23

**Status**: Draft

**Input**: User description: "SB Regression pipeline: predict future account balances, using the assigned EDA tables transactions, account_balance_history and economics (recommendation accepted when /speckit-specify was run without a new description)."

## Clarifications

### Session 2026-10-23

- Q: What should "typical dollar error" in the success criteria mean when forecasts are compared with real balances? → A: Mean absolute error in dollars (average size of the miss).
- Q: Should this regression feature also deliver an interactive stakeholder dashboard, or only the notebooks and the report chapter? → A: Out of scope here; a later separate feature covers SB and SC together.
- Q: Should each account contribute one learning example per month-end, or only one example from a single cut-off date? → A: One example per account per month-end; periods split by cut-off date.
- Q: How should Dormant and Closed accounts be treated, given that their status is known only as of today and not at each cut-off date? → A: Keep all accounts; report error by current status; never filter on it.
- Q: By how much must the forecast cut the baseline's mean absolute error before the hypothesis counts as confirmed? → A: At least 10% lower MAE confirms; a 0–10% gain is partial; no gain rejects.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Forecast each account's future month-end balance (Priority: P1)

A bank planner needs to know, for every active account, what its month-end balance is
likely to be a fixed number of months after the last known month-end (provisional
working assumption: 3 months, see Assumptions; confirmed or revised only from EDA results). Today the bank assumes "the balance stays where it is". The planner wants a
forecast that is measurably closer to what actually happens, expressed in dollars, so the
bank can plan funding and spot accounts that are drifting.

**Why this priority**: it is the regression deliverable the brief requires. Without a
forecast that beats the bank's current assumption, no downstream use has value.

**Independent Test**: on months the forecast never saw, compare the forecast with the real
month-end balances and with the "balance stays the same" assumption; the forecast is useful
only if its mean absolute error in dollars is smaller.

**Acceptance Scenarios**:

1. **Given** an account's history up to a cut-off month-end, **When** the forecast is made,
   **Then** it uses only information that was available at that cut-off (no later balances,
   transactions or economic figures).
2. **Given** the held-out final months, **When** forecasts are compared with real balances,
   **Then** the mean absolute error in dollars and its change relative to the "balance stays
   the same" assumption are both reported.
3. **Given** the forecast results, **When** the stakeholder reads the outcome section,
   **Then** it states one of "Hypothesis Confirmed", "Hypothesis Partially Confirmed" or
   "Hypothesis Rejected" by the rule in SC-001, fixed before the results were read.

---

### User Story 2 - Translate forecast quality into a business decision (Priority: P2)

An executive wants to know what the forecast is worth for the business decision that the
EDA results support (provisional working assumption: account-level early warning of large
balance drops for proactive customer outreach, see Assumptions).
The executive needs the forecast's errors turned into money and risk terms, including which
kind of error costs the bank more (over-forecasting vs under-forecasting a balance).

**Why this priority**: the brief requires business impact and a final recommendation; a
forecast with no decision attached cannot be recommended for use.

**Independent Test**: from the held-out forecasts alone, produce the business reading
(dollar impact and the action it supports) without retraining anything.

**Acceptance Scenarios**:

1. **Given** held-out forecasts, **When** errors are summarised, **Then** the summary
   separates over-forecasts from under-forecasts and states the business cost of each.
2. **Given** the business reading, **When** assumptions are uncertain, **Then** results are
   shown across a range of those assumptions, not a single point.

---

### User Story 3 - Show the forecast is fair and explainable (Priority: P3)

A risk and compliance reviewer needs to see that forecast quality does not fall
disproportionately on particular customer groups (age, gender, location, vulnerable
customers), and which drivers move the forecast, in plain language.

**Why this priority**: responsible-AI discussion is a brief requirement; it depends on a
working forecast, so it comes third.

**Independent Test**: group the held-out errors by protected attributes recovered after
modelling and compare each group's error with the overall error.

**Acceptance Scenarios**:

1. **Given** held-out forecasts, **When** errors are grouped by protected attribute,
   **Then** each group's mean absolute error is reported next to the overall one.
2. **Given** the final forecast, **When** the stakeholder asks why a balance is forecast to
   fall, **Then** the main drivers are named in business terms.

---

### Edge Cases

- Accounts whose open date falls after the first balance month-end: balances before opening
  must not be treated as real history.
- Dormant or Closed accounts: their status is a current-day value with no change date, so
  filtering on it would use future knowledge. They stay in every period, and their error is
  reported separately by status.
- Transaction history starts one year after balance history: early months have balances but
  no transactions, which must not be read as "no spending".
- Economic figures are dated at the start of each month while balances are month-end: the
  alignment must never let a forecast see an economic figure published after its cut-off.
- Very large balances (private-banking accounts) can dominate a dollar error: results are
  also reported by balance segment so a few accounts do not hide the rest.
- Balances that are negative or zero: kept if real, and handled by any relative-error
  measure without division by zero.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The pipeline MUST explore each assigned table (transactions,
  account_balance_history, economics) in its own EDA notebook, describing shape, quality
  issues and the features of interest, each with one chosen test and an effect size.
- **FR-002**: The pipeline MUST forecast the month-end balance of each in-scope account,
  with the scope justified by EDA results (provisional working assumption: personal
  behaviour-driven accounts, excluding Term Deposit and Business, see Assumptions).
- **FR-003**: Every forecast MUST use only information available at its cut-off month-end.
- **FR-004**: Each account MUST contribute one forecast example per month-end cut-off whose
  target month-end is observed. Examples are assigned to training, validation and test by
  cut-off date; the three periods MUST be consecutive in time, with test the most recent
  and used once, for the final result. No example's target may fall inside a later period's
  cut-offs used for evaluation.
- **FR-005**: The pipeline MUST include a baseline equal to "the balance stays the same as at
  the cut-off", and report every model against it.
- **FR-006**: Each experiment MUST state one hypothesis, the evidence it rests on, and a
  success rule fixed before results are read.
- **FR-007**: Forecast quality MUST be reported as mean absolute error (MAE) in dollars,
  overall and by balance segment, account type and current account status.
- **FR-015**: Fields known only as of today (such as current account status or current
  balance) MUST NOT be used to select examples or as forecast inputs.
- **FR-008**: The pipeline MUST report forecast errors by protected group (age band, gender,
  state, vulnerable-customer flag) recovered after modelling; protected attributes MUST NOT
  be forecast inputs.
- **FR-009**: Each notebook MUST include an ethics section naming the concrete risk and the
  business action that mitigates it.
- **FR-010**: The final regression notebook MUST hold the clean solution and end with the
  experiment outcome and ranked next steps.
- **FR-011**: Every notebook MUST run top to bottom in the stakeholder's environment using
  documented setup steps only.
- **FR-012**: The archetype's report chapter MUST stay within 4,000 words.
- **FR-013**: The forecast horizon, business use and account scope MUST be confirmed or
  revised only after the EDA notebooks have produced their conclusions, and each final
  choice MUST cite the EDA evidence (table, visual or test result) that supports it.
- **FR-014**: The regression business hypothesis MUST be written after the EDA conclusions
  and MUST cite only evidence those conclusions produced; no conclusion may precede the
  evidence that supports it.

### Key Entities

- **Account**: a bank account with a type, status, open date and value segment; the unit
  being forecast.
- **Monthly balance snapshot**: an account's balance and change at a month-end; the target
  comes from a future snapshot.
- **Forecast example**: one account at one cut-off month-end, holding what was known at the
  cut-off and the balance at the target month-end; identified by account and cut-off date.
- **Transaction**: an account's dated money movement with type, channel and merchant
  details; summarised per account and month as behaviour signals.
- **Economic indicator**: monthly macro figures (inflation, interest, unemployment,
  sentiment, cycle) shared by all accounts.
- **Customer**: owner of the account; source of protected attributes used only for the
  fairness audit.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: On the held-out test months, the forecast's mean absolute error in dollars is
  compared with that of the "balance stays the same" baseline: at least 10% lower is
  "Hypothesis Confirmed"; lower by more than 0% but less than 10% is "Hypothesis Partially
  Confirmed"; equal or higher is "Hypothesis Rejected".
- **SC-002**: No protected group's mean absolute error exceeds 1.25 times the overall mean
  absolute error, or every group that does is named with a mitigation.
- **SC-003**: A stakeholder can re-run every SB notebook from the documented instructions,
  with no undocumented step, and reproduce the reported numbers.
- **SC-004**: Every number quoted in the notebooks' narrative and the report matches an
  output the notebooks actually produced.
- **SC-005**: An executive can state, after reading the chapter, which accounts or totals
  the forecast supports decisions on, and what it is worth to the bank.

## Assumptions

- **Provisional working assumptions (pending EDA, not decisions):** forecast horizon of 3
  months; primary business use is account-level early warning of large balance drops for
  proactive outreach; scope is personal accounts (Savings, Transaction, Offset, Youth),
  excluding Term Deposit and Business. The stakeholder requires each to be confirmed or
  revised from explicit EDA results (tables, visuals, hypothesis tests) before it shapes the
  hypothesis or the conclusion.
- The SC-001 rule was agreed in clarification (2026-10-23). The fairness ratio of SC-002
  (1.25) is a proposed default; both are fixed before any model result is read.
- Balance history covers 48 consecutive month-ends (January 2022 to December 2025) for
  every account; transactions cover January 2023 to December 2025; economics are monthly
  from January 2020.
- Complementary tables (accounts, customers) may supply account type, status, open date and
  protected attributes; each use is tied to a stated hypothesis.
- The forecast supports planning and outreach decisions made by bank staff; it never
  triggers an automatic action on a customer's account.
- The stakeholder runs the notebooks in the course's hosted notebook environment with data
  in the stakeholder's storage folder.
- Anomaly Detection (SC) is a separate feature specification.
- Out of scope: an interactive stakeholder dashboard. Deliverables are the SB notebooks and
  the SB report chapter; a later separate feature may present SB and SC results together.
