# Week 7 — Balanced Tree Clothing Co. 👕

## The Story

Balanced Tree is a clothing brand selling 12 products across two categories — Mens and Womens — each broken into segments and styles. Danny needs a full sales report covering high-level numbers, transaction behaviour, and product performance.

The twist at the end: wrap everything into a **stored procedure** so the team can run the entire monthly report with a single call.

---

## The Data

| Table | What it holds |
|-------|--------------|
| `sales` | Every transaction line — product, quantity, price, discount, member flag |
| `product_details` | Full product info — name, category, segment, style, price |
| `product_hierarchy` | Raw tree structure: category → segment → style |
| `product_prices` | Product IDs mapped to prices |

---

## What We Found

### 📦 High-Level Sales
- Revenue, total items sold, and total discounts calculated in a single query — all three share the same grain and source table

### 🧾 Transaction Behaviour
- ~**2,500 unique transactions** in the dataset
- Average **6 unique products** per transaction
- Revenue percentiles (25th / 50th / 75th) calculated using `PERCENT_RANK()`
- **Members** make up ~60% of transactions and generate slightly higher average revenue than non-members

### 👗 Product Performance
- **Top 3 by revenue:** Blue Polo Shirt, Grey Fashion Jacket, White Tee Shirt
- **Jeans** is the top segment by quantity; **Jacket** leads by revenue
- **Womens** and **Mens** split revenue almost evenly — neither dominates
- Transaction penetration calculated per product — how often each product appears across all transactions
- **Most common 3-product combo:** White Tee Shirt + Grey Fashion Jacket + Teal Button Up Shirt (appeared 352 times)

### 🗂️ Monthly Report
All three sections were wrapped into a stored procedure called `monthly_report()`. Two key decisions made it cleaner: A1/A2/A3 combined into one SELECT (same grain), and C2/C4 merged with UNION ALL (same columns, different grouping level). One call runs everything.

---

## How the Hard Problems Were Solved

**Revenue percentage split within a group**
`SUM(revenue) OVER(PARTITION BY segment_name)` gives the segment total without a separate query. Dividing each product's revenue by this window total gives the percentage split in one pass.

**Finding the most common 3-product combination**
The sales table was self-joined three times on `txn_id`. The filter `s1.prod_id < s2.prod_id < s3.prod_id` enforces alphabetical order, which eliminates duplicate permutations of the same trio — without it, the same combination would appear 6 times.

**Transaction penetration per product**
Counted distinct `txn_id` per product, then divided by total distinct transactions using a subquery in the SELECT. No join needed — just a scalar subquery as the denominator.

**Wrapping everything into a stored procedure**
`DELIMITER $$` changed the statement terminator so MySQL didn't treat semicolons inside the procedure as the end of the whole statement. `BEGIN...END` wrapped all queries, and `CALL monthly_report()` runs it all at once.

---

## SQL Skills Demonstrated

| Skill | What It Did Here |
|-------|-----------------|
| SUM() OVER(PARTITION BY) | Calculated revenue share percentages within each segment and category |
| PERCENT_RANK() | Derived 25th, 50th, 75th revenue percentiles without native MySQL functions |
| ROW_NUMBER() OVER(PARTITION BY) | Found the top-selling product per segment and category |
| Self JOIN (3-way) | Generated all possible 3-product combos within a transaction |
| UNION ALL | Combined category and segment metrics into one result with a label column |
| Stored Procedure | Packaged the full monthly report into a single callable block |
| Scalar Subquery in SELECT | Used total transaction count as a denominator for penetration rate |

---

## 🧠 Mental Model Forge

| Model | The Pattern |
|-------|------------|
| Percentage within group = window SUM | `value / SUM(value) OVER(PARTITION BY group)` — no self-join or subquery needed |
| Combination deduplication = inequality filter | Self-join on txn_id, then `id1 < id2 < id3` collapses all permutations of the same combo into one |
| Nested aggregates need a CTE | `AVG(COUNT(*))` throws an error in MySQL — COUNT per group in a CTE, then AVG in the outer query |
| Same grain = combine into one SELECT | If multiple questions pull from the same table with the same GROUP BY, one query does the job |
| Same columns, different grouping = UNION ALL | When two questions are structurally identical but group differently, UNION ALL with a label column is cleaner than two separate queries |
| Stored procedures need DELIMITER change | Semicolons inside `BEGIN...END` break MySQL parsing — always set `DELIMITER $$` before creating a procedure |
