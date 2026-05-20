# Week 6 — Clique Bait 🎣

## The Story

Clique Bait is an online seafood store. Danny wants to understand how customers actually behave on his site — what they click, what they add to cart, what they abandon, and whether his ad campaigns are working.

The data tracks every event per visit: page views, cart adds, purchases, ad impressions, and ad clicks. The analysis covers digital behaviour, a full product conversion funnel, and campaign performance.

---

## The Data

| Table | What it holds |
|-------|--------------|
| `users` | 500 users with cookie IDs and sign-up dates |
| `events` | Every user action — page, event type, sequence, timestamp |
| `event_identifier` | Maps event_type numbers to readable names |
| `page_hierarchy` | Every page — product name, category, product ID |
| `campaign_identifier` | Three campaigns with date ranges and product coverage |

---

## What We Found

### 🖥️ Digital Behaviour
- **500 users**, averaging **3.56 cookies each** — one person, multiple devices
- **February** had the highest visit volume
- **49.86%** of all visits ended in a purchase — strong conversion for an online store
- **9.15%** of visits reached checkout but didn't buy — warm leads being lost

### 🛒 Product Funnel
Full view → cart → purchase metrics were built for every product and category:

- **Lobster** — most cart adds, most purchases, **48.74%** view-to-purchase rate
- **Oyster** — most viewed but lower conversion than Lobster
- **Russian Caviar** — most abandoned (249 times) — price sensitivity in action
- **Shellfish** dominates across all three metrics; it's the hero category
- Funnel summary: View → Cart **60.95%** | Cart → Purchase **75.93%** | The biggest drop happens at the top of the funnel

### 📢 Campaign Analysis
A `final_data` table was built — one row per visit with page views, cart adds, purchase flag, impressions, clicks, campaign name, and cart product list. Visits were matched to campaigns via a date range JOIN.

- Visits with ad impressions converted at a higher rate
- Ad clicks on top of impressions pushed conversion even higher
- Users who saw an ad and still didn't buy are the clearest retargeting opportunity

---

## How the Hard Problems Were Solved

**Think at the visit level, not the row level**
A visit can have 10+ rows — one per event. Filtering `WHERE event_type != purchase` removes rows, not visits. The right pattern is two CTEs (one for "did X", one for "did Y"), then joining them to compare at the visit level.

**Abandoned vs purchased products**
Both use the same two building blocks: a CTE of cart additions and a CTE of completed purchases. A RIGHT JOIN + IS NULL finds items that were added but the visit never purchased. An INNER JOIN finds items that were added and the visit did purchase.

**Matching visits to campaigns**
`event_start_time` had to be pre-calculated in a CTE before it could be used in a JOIN condition — aggregate functions can't be used directly inside a JOIN. Once available, `BETWEEN start_date AND end_date` handled the mapping cleanly.

**Expanding a product range like "1-3" into individual rows**
`JSON_TABLE` only extracted the endpoints (1 and 3), missing 2. A recursive CTE fixed it — starting from the left number, incrementing by 1 each step, stopping when it hit the right number.

---

## SQL Skills Demonstrated

| Skill | What It Did Here |
|-------|-----------------|
| CTEs + RIGHT JOIN + IS NULL | Found "did X but never did Y" patterns at the visit level |
| CROSS JOIN | Combined three single-row CTEs into one result row without a join condition |
| Conditional Aggregation | Counted views and cart adds per product in a single pass |
| GROUP_CONCAT + ORDER BY | Built ordered cart product lists per visit |
| MAX() for binary flags | `MAX(CASE WHEN purchase THEN 1 ELSE 0)` — safer than COUNT for 1/0 flags |
| BETWEEN in JOIN | Matched visit timestamps to campaign date ranges |
| Recursive CTEs | Expanded compressed product ranges like "1-3" into individual rows |
| Referential integrity checks | Confirmed no orphan records across all foreign key relationships |

---

## 🧠 Mental Model Forge

| Model | The Pattern |
|-------|------------|
| Always work at the visit level | A visit is the unit of behaviour — rows are just steps. Filter at visit level using CTEs + JOINs, not WHERE clauses on individual rows |
| Abandoned = RIGHT JOIN + IS NULL | Cart adds RIGHT JOIN purchases, WHERE purchase IS NULL = items added but session never bought |
| Aggregates can't live in JOIN conditions | Pre-calculate MIN/MAX/COUNT in a CTE first, then join on the result |
| CROSS JOIN for single-row CTEs | When each CTE returns exactly one row, CROSS JOIN combines them with no condition needed |
| cookie_id ≠ user_id | Cookies track devices/sessions. Always use user_id for counting people — cookie_id inflates by 3.5x |
| Build reference tables first | Complex funnels and campaign analysis get much cleaner when you materialise a `products` or `final_data` table once, then query it repeatedly |
