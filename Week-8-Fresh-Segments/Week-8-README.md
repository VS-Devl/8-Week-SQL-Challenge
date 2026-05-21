# Week 8 — Fresh Segments 🧠

## The Story

Fresh Segments is a digital marketing agency that maps customer interests using online behaviour data. Clients buy access to interest segments — like "Vacation Planners" or "Techies" — to target their ads more precisely.

The data tracks how each interest segment performs month by month: composition (what % of customers have this interest), index value (how it compares to the average), ranking, and percentile. The job was to clean the data, analyse interest trends, and tell clients which segments are worth targeting — and when.

---

## The Data

| Table | What it holds |
|-------|--------------|
| `interest_metrics` | Monthly performance per interest — composition, index, ranking, percentile |
| `interest_map` | Interest ID to name and description |
| `json_data` | Raw JSON blobs — used to demonstrate JSON extraction into structured tables |

---

## What We Found

### 🧹 Data Had Real Problems
**1,194 NULL strings** across date and ID columns — not real NULLs, just the text `"NULL"`. All were converted and rows without dates were deleted (time-series data with no date is useless). **30 exact duplicates** were removed. After cleaning, referential integrity between both tables was confirmed.

### 📊 Interest Analysis
- **480 interests** appear consistently across all 14 months — these are the reliable ones
- Cumulative percentage analysis showed that interests appearing in **fewer than 6 months** fall below the 90% quality threshold — **400 rows (~3%)** were removed as low-quality segments
- The cutoff decision was data-driven, not arbitrary

### 📈 Segment Performance
- **Winter Apparel Shoppers** had the best average ranking — consistently near the top every month
- **Techies** and **Entertainment Industry Decision Makers** had the highest standard deviation in percentile ranking — volatile, event-driven segments that spike then drop
- **Tampa Trip Planners** swung from 75th percentile (July 2018) down to 5th (March 2019) — a textbook seasonal pattern

### 🔍 Index Analysis
A `average_composition` column was added as a **generated stored column** — auto-calculated from `composition / index_value`, stored on disk so it never needs recalculating on every query.

- Top interests by average composition were ranked per month using DENSE_RANK
- A **3-month rolling average** of the max composition was built to smooth out monthly noise
- LAG was used to add the previous 1-month and 2-month top interest names alongside the rolling average

### 💡 The Business Insight
Customer segments follow seasons and events. The right product at the wrong time gets ignored. Timing is everything — show travel ads before summer, gift promotions before holidays, winter apparel before cold season.

---

## How the Hard Problems Were Solved

**NULL strings masquerading as real NULLs**
`"NULL"` as text counts as a valid value — it won't be caught by `IS NULL`. The fix was `WHERE column = 'NULL'` to find them, then `UPDATE SET column = NULL` to fix them. SELECT before UPDATE to verify row count first.

**Converting a partial date string to a proper DATE**
`month_year` was stored as `"07-2018"` — no day, so MySQL couldn't parse it directly. `CONCAT('01-', month_year)` prepended a day, then `STR_TO_DATE` converted it. The 188 records where `month_year < created_at` looked like errors but were valid — just the 1st-of-month artefact from the conversion.

**Cumulative percentage to find a quality cutoff**
No hardcoded threshold. A window `SUM() OVER(ORDER BY month_count DESC)` built a running total of interests from highest to lowest month count, then divided by the grand total. The point where it crossed 90% became the cutoff — 6 months.

**3-month rolling average**
`AVG(max_composition) OVER(ORDER BY month_year ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)` — the `ROWS BETWEEN` clause is what makes it a fixed 3-row window, not a cumulative sum.

**Getting the dot-in-key-name out of JSON**
The JSON key `"a.attribute_interest_id"` contains a dot. Without quotes in the path, SQL reads it as a nested object. The fix: `'$."a.attribute_interest_id"'` — double quotes inside the path treat the whole string as one key name.

---

## SQL Skills Demonstrated

| Skill | What It Did Here |
|-------|-----------------|
| JSON_TABLE | Extracted structured columns from raw JSON blobs |
| Generated Stored Column | Auto-calculated `average_composition` and stored it permanently on disk |
| DENSE_RANK() OVER(PARTITION BY) | Ranked interests by composition within each month |
| AVG() OVER(ROWS BETWEEN) | Built a fixed 3-month rolling average window |
| LAG(col, 1) / LAG(col, 2) | Pulled the previous 1 and 2 months' top interest into the current row |
| Cumulative SUM() OVER() | Built a running percentage to find the quality cutoff point |
| STDDEV_SAMP | Measured volatility of interest rankings across months |
| DELETE with subquery | Removed low-quality interests using a filtered subquery |
| SELECT before UPDATE/DELETE | Verified affected rows before making any destructive change |

---

## 🧠 Mental Model Forge

| Model | The Pattern |
|-------|------------|
| NULL strings ≠ real NULLs | `= 'NULL'` catches text NULLs; `IS NULL` doesn't — always profile for both |
| SELECT before UPDATE or DELETE | Never modify data blind — confirm the row count first |
| Data-driven cutoffs beat guessing | Use cumulative percentage windows to find natural quality thresholds instead of hardcoding a number |
| Rolling window = ROWS BETWEEN | `ROWS BETWEEN 2 PRECEDING AND CURRENT ROW` is a fixed 3-row window — without it you get a cumulative sum |
| Dots in JSON keys need double quotes | `'$."key.with.dot"'` treats the whole string as one key — without quotes SQL reads it as a nested path |
| Generated columns for repeated formulas | If the same calculation runs on every query, make it a STORED generated column — computed once, retrieved forever |
| Partial dates need a day prepended | `CONCAT('01-', month_year)` makes `STR_TO_DATE` work when only month and year exist |
| Standard deviation = segment volatility | High STDDEV on ranking means the segment spikes and crashes — seasonal or event-driven, not a stable audience |
