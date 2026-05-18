# Week 3 — Foodie-Fi 🍜

## The Story

Danny saw a gap — no streaming platform existed purely for food content. So he built **Foodie-Fi**: a subscription service for cooking shows and food documentaries, structured exactly like Netflix. Customers start with a free 7-day trial, then choose between Basic Monthly ($9.90), Pro Monthly ($19.90), Pro Annual ($199), or cancel entirely.

With 1,000 customers and a full year of data, the goal was to track how customers move through plans, measure business health, simulate a full payment history, and reason about what the numbers mean strategically.

---

## The Data

| Table | What it holds |
|-------|--------------|
| `plans` | The five plan types — trial, basic monthly, pro monthly, pro annual, and churn — with prices |
| `subscriptions` | Every plan event per customer: who moved to which plan, and when |

---

## What We Found

### 🛤️ Customer Journeys
Every customer's path was reconstructed two ways — manually by reading raw plan rows, then automated using string aggregation to generate readable journey descriptions like *"Customer 7 started trial Feb 5, upgraded to Basic Monthly Feb 12, upgraded to Pro Monthly May 22."*

### 📊 Subscription Metrics
- **1,000 total customers** — March had the highest trial sign-ups
- After trial, **Basic Monthly** was the most common first paid step
- **195 customers** upgraded to an annual plan by end of 2020
- Most annual upgraders decided within the first 60 days — after that, the tail stretches past 300 days

### ⚠️ Churn
- Overall churn rate: **~30.7%** — well above the healthy 5–7% benchmark
- A segment churned **immediately after their free trial** without ever paying
- **Zero customers** downgraded from Pro Monthly to Basic in 2020 — when unhappy, they leave entirely

### 💳 Payment Simulation
A full 2020 payments table was built from scratch: monthly charges recurring on the same day each month, mid-cycle upgrade deductions, annual plan timing, and churn as a hard stop — all simulated using a recursive query.

---

## How the Hard Problems Were Solved

**Finding what customers did right after their trial**
Row numbers were assigned per customer ordered by date, then row 2 was filtered. If plan_id = 4 at row 2, they churned immediately. This pattern generalises to any "nth event" question.

**Snapshotting the business at a specific date**
Plans were ranked per customer by date descending, then rank 1 was kept — automatically picking the most recent active plan before December 31, no matter how many changes came before it.

**Simulating monthly payment dates without a loop**
A recursive CTE acted as a loop: base case loaded the plan start date, the recursive step added one month, and the stop condition was either the next plan's start date or year-end — whichever came first.

**Calculating upgrade deductions mid-cycle**
LAG retrieved the previous plan's price for each customer. When a plan change was detected, the old price was subtracted from the new one to produce the correct partial-month charge.

---

## SQL Skills Demonstrated

| Skill | What It Did Here |
|-------|-----------------|
| Recursive CTEs | Simulated monthly billing dates by iterating forward one month at a time |
| ROW_NUMBER | Isolated each customer's "nth plan event" for post-trial analysis |
| DENSE_RANK | Snapshotted each customer's active plan at a specific calendar date |
| LAG / LEAD | Detected plan transitions and set billing stop dates per customer |
| GROUP_CONCAT | Assembled individual plan rows into a single readable journey string |
| DATEDIFF / DATE_ADD | Measured days between events and generated future billing dates |
| Conditional Aggregation | Calculated churn rates and plan percentages inside a single query |
| COALESCE | Defaulted missing next-plan dates to December 31 as the billing cutoff |

---

## 🧠 Mental Model Forge

| Model | The Pattern |
|-------|------------|
| Churn is just another row | `plan_id = 4` is an event like any other — no special-casing needed in queries |
| nth event = ROW_NUMBER + filter | Number rows per customer by date, filter on row N to isolate any specific action in a sequence |
| Point-in-time snapshot = RANK DESC + rank 1 | Filter to the cutoff date, rank newest-first, keep rank 1 — works for any "state as of date X" question |
| Recursive CTE = a loop | Base case → step → stop condition: the same three-part structure for any sequence generation |
| LEAD as a kill switch | The next plan's start date tells you exactly when to stop generating recurring events |
| LAG to detect change | Compare current row to LAG(value) — covers downgrades, transitions, and deduction logic |
