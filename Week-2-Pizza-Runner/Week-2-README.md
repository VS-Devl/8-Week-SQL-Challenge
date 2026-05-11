# Week 2 — Pizza Runner 🍕

## The Story

Danny had a simple dream — combine his love for pizza with the 80s trend of Uberizing everything. So he launched **Pizza Runner**: a two-pizza delivery service where runners pick up orders from HQ and deliver them to customers.

The problem? His data was a disaster. Distances stored as `"20km"`, durations stored as `"32 minutes"`, and fake `"null"` text sprinkled everywhere instead of real empty values. Before answering a single business question, the data had to be cleaned from scratch.

Once cleaned, the analysis covered four areas: **how the business is performing, how runners are doing, what customers are ordering, and whether the business is actually profitable.**

---

## The Data

Six tables feed into this analysis:

| Table | What it holds |
|-------|--------------|
| `runners` | Runner IDs and when they signed up |
| `customer_orders` | Every pizza ordered, including any customizations |
| `runner_orders` | Delivery details — pickup time, distance, duration, cancellations |
| `pizza_names` | Two pizzas: Meatlovers and Vegetarian |
| `pizza_recipes` | What toppings go on each pizza |
| `pizza_toppings` | Topping ID to topping name reference |

---

## What We Found

### 🧹 The Data Was Broken — And We Fixed It
The raw dataset had three types of problems: text that said `"null"` instead of being actually empty, inconsistent units (`"20km"`, `"23.4 km"`, `"10"`), and duration values like `"32 minutes"` and `"15mins"` that couldn't be used in calculations. Every column was inspected, cleaned, and converted to the right format before any analysis started.

### 📊 Pizza & Order Metrics
- **14 pizzas** were ordered in total across **10 unique orders**
- **Peak hours** for orders: **1PM and 9PM** — useful for staffing decisions
- **Wednesday and Saturday** are the busiest days of the week
- Meatlovers is the clear favourite — ordered significantly more than Vegetarian

### 🏍️ Runner Performance
- Runner 1 has the highest number of successful deliveries
- More pizzas in an order = longer prep time, which makes sense — but the data confirms it with actual averages
- **Order #8 is a red flag** — the calculated delivery speed comes out to **93.6 km/h**, which is either reckless driving or a data entry error worth investigating
- Each runner's success rate (completed vs. cancelled orders) was calculated to measure reliability

### 🧅 What Customers Are Customizing
- **Bacon** is the most requested extra topping
- **Cheese** is the most excluded topping
- Each order was given a human-readable description — for example: *"Meatlovers - Extra Bacon - Exclude Cheese"* — making it easy to read without joining multiple tables
- The total quantity of every ingredient used across all delivered pizzas was counted to help with stock planning

### 💰 Is the Business Making Money?
- With Meatlovers at $12 and Vegetarian at $10, total revenue from successful deliveries was calculated
- Adding a $1 charge for extras (especially cheese) was factored in
- After paying runners **$0.30 per kilometre**, the leftover profit was calculated
- A brand new **Ratings table** was designed from scratch so customers can rate their runner from 1 to 5 — with rules built in at the database level to prevent invalid ratings
- A final **Master Delivery Table** was created combining everything: customer, runner, rating, order time, pickup time, speed, and total pizzas — all in one place

**Bonus:** Showed how to add a brand new pizza (Supreme) to the menu with just two lines of code — no restructuring needed — proving the database is built to scale.

---

## How the Hard Problems Were Solved

**The data had text where numbers should be**
Distance was stored as `"20km"` and duration as `"32 minutes"`. String manipulation functions were used to strip the units, leaving only the numbers — then the columns were converted to proper numeric types so calculations could actually run.

**Toppings were stored as a single jumbled string**
Each pizza's recipe was stored as `"1, 2, 3, 4, 5"` — all topping IDs crammed into one cell. A technique was used to split that into individual rows, match each ID to its name, then reassemble them into a clean readable list. This same pattern was applied to customer extras and exclusions on every single order.

**Counting two things at once without running two queries**
To see how many Meatlovers vs Vegetarian pizzas each customer ordered side by side, conditional counting inside a single query was used — no need to run separate queries and manually compare results.

**Calculating profit in one shot**
Total revenue and total runner costs were calculated in separate steps, then combined in a single query to show the final profit — clean and auditable.

---

## SQL Skills Demonstrated

| Skill | What It Did Here |
|-------|-----------------|
| Data Cleaning with UPDATE | Fixed broken NULLs and standardized messy text across two tables |
| String Functions | Stripped units from distance and duration columns |
| JSON_TABLE | Split comma-separated topping strings into individual rows |
| GROUP_CONCAT | Reassembled rows back into readable ingredient lists |
| Window Functions | Assigned unique IDs to rows for multi-step ingredient processing |
| TIMESTAMPDIFF | Calculated prep times and pickup delays in minutes |
| Conditional Aggregation | Counted and summed values based on conditions in a single query |
| Schema Design | Built a new Ratings table with data validation constraints and foreign keys |
| CTEs | Broke complex multi-step queries into readable, logical stages |
