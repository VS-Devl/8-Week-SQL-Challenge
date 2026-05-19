# Week 4 — Data Bank 🏦

## The Story

Data Bank is a digital bank with a twist — cloud storage is tied directly to account balance. More money, more storage. The bank runs across 5 regions through a network of nodes that customers get randomly reassigned to over time.

The analysis covers three things: how nodes and regions behave, how customers actually use their accounts, and how to estimate monthly cloud storage needs under three different models.

---

## The Data

| Table | What it holds |
|-------|--------------|
| `regions` | Five regions: Australia, America, Africa, Asia, Europe |
| `customer_nodes` | Customer-to-node assignments with start and end dates |
| `customer_transactions` | Every deposit, purchase, and withdrawal with date and amount |

---

## What We Found

### 🌐 Nodes & Regions
- Customers get reassigned to a new node every **~15 days** on average
- One data issue worth flagging: `end_date = '9999-12-31'` was used as a placeholder for active assignments — filtering it out was necessary before any duration math

### 💳 Transactions
- Deposits are the most frequent and highest in value
- Average customer makes **~5 deposits** totalling **~$2,718**
- Most "active months" — more than 1 deposit plus at least 1 purchase or withdrawal — happened in **March**

### 🗄️ Storage Allocation — 3 Options
- **Option 1:** Closing balance at month-end
- **Option 2:** Average running balance across the month
- **Option 3:** Total transaction volume regardless of direction

Each gives a different storage estimate — Option 2 is the most stable signal.

### 📈 Interest Model
Daily interest at 6% annually was calculated on running balances. Compound interest by April was **~100x higher** than simple interest — small daily rate, big difference over 100+ days.

---

## How the Hard Problems Were Solved

**The `9999-12-31` trap**
It looked like a real date but was just a placeholder. Left in, it would've broken every average. Filtered before any calculation.

**Percentiles in MySQL**
No built-in percentile function. Used `PERCENT_RANK()` to rank durations, then pulled values at the 0.5, 0.8, and 0.95 thresholds using conditional aggregation.

**Running balance from raw transactions**
All amounts are positive in the raw data. Assigned signs first (deposits +, everything else −), then used `SUM() OVER()` ordered by date to build a live running balance.

**Daily interest with no daily rows**
Data only has rows on transaction dates. A recursive CTE filled every missing day by adding one day at a time, carrying the last known balance forward until the next transaction.

---

## SQL Skills Demonstrated

| Skill | What It Did Here |
|-------|-----------------|
| Recursive CTEs | Filled every calendar day per customer for daily interest calculation |
| SUM() OVER() | Built a cumulative running balance after each transaction |
| PERCENT_RANK() | Calculated median and percentiles without native MySQL support |
| ROW_NUMBER() | Found each customer's first and last active month |
| LEAD() + COALESCE | Got the next transaction date; defaulted to April 30 for the last row |
| Conditional Aggregation | Counted types, extracted percentiles, flagged growth — in single queries |
| POWER() | Calculated compound interest using exponential growth |

---

## 🧠 Mental Model Forge

| Model | The Pattern |
|-------|------------|
| Sentinel values break time math | Always profile date columns — placeholders like `9999-12-31` must be filtered before any DATEDIFF |
| Sign before you sum | Assign +/− to transaction types first — then all running totals just work with SUM() |
| Running balance = SUM() OVER() by date | Standard pattern for any "balance after each event" problem |
| Percentiles without native functions | PERCENT_RANK() + MAX(CASE WHEN rank <= threshold) reconstructs any percentile |
| Fill time gaps with recursive CTEs | No daily rows? Recursive CTE adds 1 day per step, stopping at the next event |
