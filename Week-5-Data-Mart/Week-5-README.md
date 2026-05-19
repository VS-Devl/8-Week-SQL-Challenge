# Week 5 — Data Mart 🛒

## The Story

Data Mart is Danny's retail operation selling across 7 regions through both physical stores (Retail) and online (Shopify). In June 2020, the business switched to sustainable packaging — and Danny needed to know: **did that change hurt sales?**

Before answering that, the raw data needed a full cleanup. Then came exploration, before-vs-after analysis across every dimension, and business recommendations for Danny.

---

## The Data

| Table | What it holds |
|-------|--------------|
| `weekly_sales` | Every week's transactions and sales — by region, platform, segment, and customer type |

One table. All the complexity comes from what's inside it.

---

## What We Found

### 🧹 The Data Needed Work First
`week_date` was stored as a VARCHAR string in `DD/MM/YY` format — useless for any date math. The `segment` column had `"null"` strings instead of real NULLs. A clean table was built from scratch with proper date types, and four new derived columns: `week_number`, `month_number`, `calendar_year`, `demographic`, `age_band`, and `avg_transaction`.

### 📊 Exploration
- All week dates fall on a **Monday** — consistent and clean
- Weeks 1–12 and 37–52 are missing — the dataset only covers the middle of each year
- **2020** had the highest transaction volume across all three years
- **Africa** and **Oceania** lead in total sales by region
- **Retail** accounts for ~97% of all transactions — Shopify is growing but still small

### 📦 Did the Packaging Change Hurt Sales?
The change went live on **June 15, 2020**. Sales were compared in 4-week and 12-week windows before and after.

- Overall: **−2.14%** in the 12-week window — a real drop, but not a collapse
- **Retail fell −2.43%** | **Shopify grew +7.18%** — the shift to online is accelerating
- **Asia −3.26%** and **Oceania −3.03%** took the biggest regional hits
- **Europe +4.73%** — bucked the trend, likely higher environmental awareness
- **Families −1.82%** | **Couples −0.87%** — bulk buyers felt it more
- **Guest customers −3.00%** | **New customers +1.01%** — new buyers had no old packaging to compare against

---

## How the Hard Problems Were Solved

**Converting a VARCHAR date in a non-standard format**
`STR_TO_DATE(week_date, '%d/%m/%y')` parsed the string into a real DATE. A new column was added, populated, then the old one was dropped — direct ALTER would've thrown a data type error.

**Deriving two columns from one coded field**
The segment column encoded both demographic (`C`/`F`) and age band (`1`–`4`) in a single string like `"C2"`. `LEFT()` extracted the letter, `RIGHT()` extracted the number, and CASE statements mapped each to its label.

**Finding missing weeks in a sequence**
A recursive CTE generated all 52 week numbers, then a LEFT JOIN against the actual data found the gaps. The "Gaps and Islands" technique grouped consecutive missing weeks into ranges for clean output.

**Isolating the packaging change impact**
Two CTEs — `before_cte` and `after_cte` — summed sales in equal windows either side of June 15. Joining them and calculating the percentage difference gave a clean before-vs-after comparison for every dimension.

---

## SQL Skills Demonstrated

| Skill | What It Did Here |
|-------|-----------------|
| STR_TO_DATE | Converted non-standard VARCHAR dates into proper DATE type |
| ALTER TABLE | Added, populated, dropped, and renamed columns during data cleaning |
| CASE + LEFT / RIGHT | Decoded a compound segment field into two separate readable columns |
| Recursive CTEs | Generated a full 1–52 week sequence to find missing weeks |
| Gaps and Islands | Grouped consecutive missing week numbers into ranges |
| Before/After CTEs | Isolated sales windows either side of June 15 for impact analysis |
| Conditional Aggregation | Counted and compared values across dimensions in a single query |
| ROUND / CONCAT | Formatted percentages and ranges for clean readable output |

---

## 🧠 Mental Model Forge

| Model | The Pattern |
|-------|------------|
| Always fix dates before anything else | A VARCHAR date can't be filtered, sorted, or used in date functions — it's not a date |
| Decode compound columns with LEFT / RIGHT | When one column encodes two things (letter + number), extract each part separately before deriving meaning |
| Before/After = two CTEs + one JOIN | Any impact analysis is just: CTE for before window, CTE for after window, join on the dimension, subtract |
| Generate sequences with recursive CTEs | Need every number from 1–N? Recursive CTE with anchor 1 and step +1 is the standard approach |
| Gaps and Islands = value minus ROW_NUMBER | Consecutive values share the same `value - ROW_NUMBER` result — group by it to find ranges |
| "Unknown" is a business problem, not just dirty data | 3,024 unknown segments caused the biggest sales drop — missing data has a real cost |
