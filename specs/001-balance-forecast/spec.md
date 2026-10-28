# Feature Specification: SB Regression, Bank-wide Balance Forecast by Segment

**Feature Branch**: `sb-regression/001-balance-forecast`

**Created**: 2026-10-23

**Status**: Draft (revised 2026-10-26 after the EDA gate)

**Input**: User description: "SB Regression pipeline: predict future account balances, using the assigned EDA tables transactions, account_balance_history and economics (recommendation accepted when /speckit-specify was run without a new description)."

## Clarifications

### Session 2026-10-23

- Q: What should "typical dollar error" in the success criteria mean when forecasts are compared with real balances? → A: Mean absolute error in dollars (average size of the miss).
- Q: Should this regression feature also deliver an interactive stakeholder dashboard, or only the notebooks and the report chapter? → A: Out of scope here; a later separate feature covers SB and SC together.
- Q: Should each account contribute one learning example per month-end, or only one example from a single cut-off date? → A: One example per account per month-end; periods split by cut-off date. (Superseded on 2026-10-26: one example per segment per month-end, built from the accounts in the segment at the cut-off.)
- Q: How should Dormant and Closed accounts be treated, given that their status is known only as of today and not at each cut-off date? → A: Keep all accounts; report error by current status; never filter on it.
- Q: By how much must the forecast cut the baseline's mean absolute error before the hypothesis counts as confirmed? → A: At least 10% lower MAE confirms; a 0–10% gain is partial; no gain rejects.

### Session 2026-10-28

- Q: Does the target behave as a time series that the plan must account for? → A: Checked on the training cut-offs (SB-b A.4). No significant calendar pattern (30 training months; month p 0.17, quarter Holm-adjusted p 0.10), so no calendar feature. No segment-specific persistence at 3 months (rho 0.007, 95% interval -0.12 to 0.13). Bank-wide drift eased from $739 to $659 per account a quarter between the 2022 and 2024 cut-offs, not significant (p 0.11).
- Q: Does the recent-change feature measure what it claims? → A: No. Measured on the accounts in the segment at the cut-off, it carries band migration (accounts that have just fallen into a band, then recover). It is replaced by `last_quarter_change_per_account`: the change per account from `cutoff − LOOKBACK` to the cut-off of the accounts in the segment at `cutoff − LOOKBACK`; a segment with no accounts then takes the bank-wide value at the same cut-off.
- Q: Does the falling drift or the season of the validation targets weaken the average-drift reference? → A: Reported as diagnostics only in SB-b B.3: drift fitted on the last 12 training cut-offs and on the same calendar months as validation. The reference stays the drift of all training cut-offs ($686); the variants move the validation gain over persistence from 42.6% to at most 44.9%.

### Session 2026-10-27

- Q: Is "total stays the same" the only reference for the forecast? → A: It stays the reference for SC-001, because it is the bank's current assumption. A second, naive reference is reported next to it: every account grows by the bank-wide average 3-month change learned on training cut-offs ("average drift"). Balances grow on average, so persistence is biased low by construction; beating it can mean only that the model learned average growth. H1 counts as showing segment value only if it also beats average drift.
- Q: How are small or uninformative segments handled? → A: A segment stays apart only if its training drift differs from the bank-wide drift by at least 2 standard errors; otherwise it merges into its adjacent balance band. (A size rule, standard error below half the $63 loan gap, was tried first and dropped: it needed 1700 to 200000 accounts per segment, more than any segment holds.)

### Session 2026-10-26 (EDA gate)

- Q: Which forecast horizon? → A: 3 months, justified by the horizon trade-off (SB-2 B.2, B.5).
- Q: Which business use? → A: Bank-wide balance planning by customer segment. Account-level early warning is dropped: no assigned or complementary table signals a coming drop (SB-1 B.2-B.4, SB-2 B.4, SB-4 B.2-B.4), while income band, active loans and the economy relate to average growth (SB-4 B.2-B.3, SB-3).
- Q: Which accounts? → A: All six account types; they behave alike (SB-2 B.3).
- Q: Which fairness rule? → A: The proposed 1.25 ratio is dropped: it was borrowed from the four-fifths rule for classification selection rates and has no justification for a regression error, and relative error grows mechanically in small-balance segments (SB-2 B.6). Each segment is judged against "total stays the same" in that same segment, and against the overall gain (uneven-gain check).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Forecast each segment's total balance one quarter ahead (Priority: P1)

A bank planner needs the total balance each customer segment will hold 3 months after the
last known month-end. Today the bank assumes "the total stays where it is". The planner
wants a forecast measurably closer to what happens, in dollars, to plan funding and liquidity
by segment.

**Why this priority**: it is the regression deliverable the brief requires. Without a forecast
that beats the bank's current assumption, no downstream use has value.

**Independent Test**: on cut-offs the forecast never saw, compare forecast segment totals with
real totals and with the "total stays the same" assumption; the forecast is useful only if
its mean absolute error in dollars is smaller.

**Acceptance Scenarios**:

1. **Given** a segment's history up to a cut-off month-end, **When** the forecast is made,
   **Then** it uses only information available at that cut-off (no later balances,
   transactions, loans or economic figures).
2. **Given** the held-out final cut-offs, **When** forecasts are compared with real totals,
   **Then** the mean absolute error in dollars and its change relative to the "total stays
   the same" assumption are both reported.
3. **Given** the forecast results, **When** the stakeholder reads the outcome section,
   **Then** it states one of "Hypothesis Confirmed", "Hypothesis Partially Confirmed" or
   "Hypothesis Rejected" by the rule in SC-001, fixed before the results were read.

---

### User Story 2 - Translate forecast quality into a planning decision (Priority: P2)

An executive wants to know what the forecast is worth for funding and liquidity planning:
how far off the bank-wide total would be, and which kind of error costs more
(over-forecasting deposits leaves a funding gap; under-forecasting leaves idle funding).

**Why this priority**: the brief requires business impact and a final recommendation.

**Independent Test**: from the held-out forecasts alone, produce the bank-wide and per-segment
dollar impact without retraining anything.

**Acceptance Scenarios**:

1. **Given** held-out forecasts, **When** errors are summarised, **Then** the summary separates
   over-forecasts from under-forecasts and states the business cost of each.
2. **Given** the business reading, **When** assumptions are uncertain, **Then** results are shown
   across a range of those assumptions, not a single point.

---

### User Story 3 - Show the forecast is fair and explainable (Priority: P3)

A risk and compliance reviewer needs to see that forecast quality does not fall
disproportionately on segments with more vulnerable or lower-income customers, and which
drivers move the forecast, in plain language.

**Why this priority**: responsible-AI discussion is a brief requirement; it depends on a working
forecast, so it comes third.

**Independent Test**: compare each segment's forecast error with the error of "total stays the
same" in that segment, next to the segment's share of vulnerable customers and mean age.

**Acceptance Scenarios**:

1. **Given** held-out forecasts, **When** errors are grouped by segment, **Then** each segment's
   MAE ratio (forecast over "total stays the same") is reported with its 95% interval, next to the
   overall ratio and the segment's protected-attribute mix.
2. **Given** the final forecast, **When** the stakeholder asks why a segment total is forecast to
   change, **Then** the main drivers are named in business terms.

---

### Edge Cases

- Segment membership changes over time (balance band moves): a segment's target is the total, 3
  months later, of the accounts that were in it at the cut-off, so no account is counted twice.
- Month-ends dated before an account's open date are not history and are excluded.
- Loans and repayments dated after a cut-off are never used at that cut-off.
- Economic figures dated at the start of each month are used with a one-month lag.
- Small segments (for example the Low balance band) give unstable totals: results are also read
  in relative terms, and segments below a minimum size are merged or reported separately.
- Large segments dominate a dollar error: results are reported per segment as well as overall.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The pipeline MUST explore each assigned table (transactions,
  account_balance_history, economics) in its own EDA notebook, plus a complementary EDA notebook
  for other tables, each finding with one chosen test and an effect size.
- **FR-002**: The pipeline MUST forecast the total balance of each customer segment `HORIZON`
  (3) months ahead, over all six account types. Segments are defined from EDA evidence
  (research R12).
- **FR-003**: Every forecast MUST use only information available at its cut-off month-end.
- **FR-004**: Each segment MUST contribute one forecast example per month-end cut-off whose target
  month-end is observed; examples are assigned to training, validation and test by cut-off date,
  consecutive in time, test most recent and used once. No example's target may fall inside a
  later period's cut-offs used for evaluation.
- **FR-005**: The pipeline MUST include a baseline equal to "the segment total stays the same as at
  the cut-off", and report every model against it. It MUST also report an average-drift reference
  (every account changes by the bank-wide mean 3-month change of the training cut-offs), used to
  read whether a model adds more than average growth; SC-001 is unchanged.
- **FR-006**: Each experiment MUST state one hypothesis, the evidence it rests on, and a success
  rule fixed before results are read.
- **FR-007**: Forecast quality MUST be reported as mean absolute error (MAE) in dollars overall and
  per segment, and as relative error (MAE divided by the mean segment total) per segment.
- **FR-008**: Protected attributes (age, gender, vulnerable-customer flag, country of birth,
  citizenship) MUST NOT be forecast inputs or segment keys; they are recovered per segment only
  for the fairness audit.
- **FR-009**: Each notebook MUST include an ethics section naming the concrete risk and the
  business action that mitigates it.
- **FR-010**: The final regression notebook MUST hold the clean solution and end with the
  experiment outcome and ranked next steps.
- **FR-011**: Every notebook MUST run top to bottom in the stakeholder's environment using
  documented setup steps only.
- **FR-012**: The archetype's report chapter MUST stay within 4000 words.
- **FR-013**: Horizon, business use and scope were confirmed or revised only after the EDA
  notebooks produced their conclusions (closed 2026-10-26, Clarifications); later revisions MUST
  cite new evidence.
- **FR-014**: The regression business hypothesis MUST be written after the EDA conclusions and MUST
  cite only evidence those conclusions produced.
- **FR-015**: Fields known only as of today (such as current account status or current balance)
  MUST NOT be used to select examples or as forecast inputs.

### Key Entities

- **Account**: a bank account with a type, open date and balance history; grouped into segments.
- **Customer**: owner of the account; source of the income band used for segments and of
  protected attributes used only for the fairness audit.
- **Segment**: a group of accounts sharing the segment keys at a cut-off (research R12).
- **Forecast example**: one segment at one cut-off month-end, holding what was known at the cut-off
  and the total balance of its cut-off accounts at the target month-end; identified by segment
  and cut-off date.
- **Loan**: a loan on an account; counts at a cut-off only if it started on or before it.
- **Economic indicator**: monthly macro figures shared by all segments, used with a one-month lag.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: On the held-out test cut-offs, the forecast's mean absolute error in dollars across
  segment totals is compared with that of "the total stays the same": at least 10% lower is
  "Hypothesis Confirmed"; lower by more than 0% but less than 10% is "Hypothesis Partially
  Confirmed"; equal or higher is "Hypothesis Rejected".
- **SC-002**: For each segment, the MAE ratio is the forecast's MAE over that of "total stays the
  same", with a 95% bootstrap interval (test cut-offs resampled). A segment fails when its interval
  lies entirely above 1 (worse off than under the bank's current assumption) or entirely above the
  overall ratio (it gains clearly less than the bank as a whole). SC-002 holds when no segment
  fails; every segment that fails is named with its protected-attribute mix and a mitigation.
- **SC-003**: A stakeholder can re-run every SB notebook from the documented instructions, with no
  undocumented step, and reproduce the reported numbers.
- **SC-004**: Every number quoted in the notebooks' narrative and the report matches an output the
  notebooks actually produced.
- **SC-005**: An executive can state, after reading the chapter, how far off the bank-wide total
  forecast is expected to be one quarter ahead and what that is worth for funding planning.

## Assumptions

- Decided at the EDA gate (2026-10-26): horizon 3 months; bank-wide planning by segment; all six
  account types. Evidence and justification are recorded per decision.
- The SC-001 rule was agreed in clarification (2026-10-23) and the SC-002 rule at the EDA gate
  (2026-10-26); both are fixed before any model result is read. SC-002's references, 1 and the
  overall ratio, are the status quo and the overall result, so no threshold is borrowed.
- Balance history covers 48 consecutive month-ends (January 2022 to December 2025) for every
  account; transactions cover January 2023 to December 2025; economics are monthly from January
  2020; 17.0% of loans start after the history ends.
- The forecast supports planning decisions made by bank staff; it never triggers an action on an
  individual customer's account.
- The stakeholder runs the notebooks in the course's hosted notebook environment with data in the
  stakeholder's storage folder.
- Anomaly Detection (SC) is a separate feature specification.
- Out of scope: an interactive stakeholder dashboard, and account-level early warning (no signal
  found at the EDA gate).
