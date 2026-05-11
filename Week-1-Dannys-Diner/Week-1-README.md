# Week 1 — Danny's Diner 🍜

## What's This About?

Danny runs a small Japanese restaurant called **Danny's Diner** that serves three things — sushi, curry, and ramen. He's been collecting basic data about his customers but has no idea how to use it.

He wants answers to simple questions like who's spending the most, what's popular, and whether his loyalty program is actually working. Our job is to answer all of that using SQL.

---

## The Data

Three simple tables:

| Table | What it holds |
|-------|--------------|
| `sales` | Every order — who bought what and when |
| `menu` | The three items and their prices |
| `members` | Which customers joined the loyalty program and when |

---

## Questions Covered

1. What is the total amount each customer spent?
2. How many days has each customer visited the restaurant?
3. What was the first item purchased by each customer?
4. What is the most purchased item on the menu?
5. What is the most popular item for each customer?
6. What was the first item ordered after a customer joined the membership?
7. What was the last item ordered before a customer joined the membership?
8. How many items and how much did each customer spend before joining?
9. How many points would each customer have under the loyalty points system?
10. How many points would customers A and B have at the end of January with the first-week bonus?

**Bonus:** Merged all three tables into a single `dannys_sales` table and ranked each member's orders after joining.

---

## Highlighted Techniques

**Window Functions with DENSE_RANK()**
Used to find "firsts" — like the first item a customer ordered or their first purchase after joining. The trick is partitioning by customer and ordering by date, then grabbing rank 1.

**CASE inside SUM for Points**
Instead of filtering rows separately, a `CASE` statement was used directly inside `SUM()` to apply different point multipliers (sushi gets 2x, everything else gets 1x) in a single query.

**DATE_ADD() for the First-Week Bonus**
To calculate the 7-day bonus window after joining, `DATE_ADD(join_date, INTERVAL 6 DAY)` was used — then a `CASE` statement checked if the order fell inside that window.

**CTEs for Readability**
Complex queries were broken into CTEs so each step is easy to follow — first count, then rank, then filter. Much cleaner than nesting subqueries.

---

## SQL Concepts Used

`JOIN` · `LEFT JOIN` · `GROUP BY` · `SUM` · `COUNT` · `CASE` · `CTE` · `DENSE_RANK()` · `DATE_ADD()` · `DISTINCT`
