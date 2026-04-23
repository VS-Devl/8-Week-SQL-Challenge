# 🚀 8-Week SQL Challenge: Data Engineering Portfolio
**By M. Hammad Qureshi | Aspiring Data Engineer**

> Solving 8 real-world business case studies using advanced SQL.  
> Every solution is built independently with a focus on **Data Integrity**, **Performance**, and **Business Value**[cite: 1, 2].

📂 **GitHub:** [m-hammad-qureshi](https://github.com/m-hammad-qureshi)  
💼 **LinkedIn:** [m-hammad-qureshi](https://linkedin.com/in/m-hammad-qureshi)

---

## 📈 Curriculum & Progress

| Week | Case Study | Status | Key Focus Area |
|:---|:---|:---|:---|
| 1 | Danny's Diner | ✅ Complete | Customer Loyalty & Spending Trends |
| 2 | Pizza Runner | ✅ Complete | Data Cleaning & Delivery Performance |
| 3 | Foodie-Fi | ✅ Complete | Subscription Life Cycles & Churn Analysis |
| 4 | Data Bank | ✅ Complete | Financial Modeling & Data Profiling |
| 5 | Data Mart | 🔄 In Progress | Large-Scale Sales Analysis |
| 6 | Clique Bait | ⏳ Pending | Web Analytics & Funnel Tracking |
| 7 | Balanced Tree | ⏳ Pending | Merchandising & Revenue Optimization |
| 8 | Fresh Segments | ⏳ Pending | Customer Interest & Engagement |

---

## 🛠️ Technical Methodology: The Data Engineer's Approach

I follow a strict professional workflow for every case study to ensure results are accurate and actionable[cite: 1]:

1.  **Data Profiling First:** Before analyzing, I audit for duplicates, NULLs, and "Sentinel Values" (like the `9999-12-31` dates found in Week 4)[cite: 1, 2].
2.  **Logic Before Code (OSF):** I map out the **O**utput, **S**ource, and **F**ilters before writing a single line of SQL[cite: 1].
3.  **Documented Logic:** Every query includes comments explaining the **"Why"** behind the code for team collaboration[cite: 1].
4.  **Business Storytelling:** I deliver insights, not just tables. Every project ends with strategic recommendations[cite: 2].
5.  **Iterative Learning:** I solve each challenge twice—once for the answer, and again to optimize for performance[cite: 1].

---

## 💎 Project Highlights

### **Week 4 — Data Bank (Financial Analysis)**
*   **Problem:** Optimize cloud storage allocation based on banking behavior[cite: 2].
*   **Solution:** Built 3 storage models and calculated interest rewards using **Recursive CTEs**[cite: 1, 2].
*   **Key Finding:** Compound interest grows **~100x faster** than simple interest by Month 4[cite: 1, 2].

### **Week 3 — Foodie-Fi (Subscription Trends)**
*   **Problem:** Track churn patterns and revenue growth for a streaming service[cite: 1].
*   **Solution:** Mapped full customer journeys and built an MRR master table[cite: 1].
*   **Key Finding:** Identified a **30.7% churn rate**, signaling a need for a new retention strategy[cite: 1].

### **Week 2 — Pizza Runner (Data Cleaning)**
*   **Problem:** Clean and standardize messy operational data to evaluate runner performance[cite: 1].
*   **Solution:** Built a full data cleaning pipeline—handling inconsistent NULLs, type casting, and string standardization[cite: 1].
*   **Key Finding:** Standardized delivery data allowed for accurate calculations of average speed and runner efficiency[cite: 1].

### **Week 1 — Danny's Diner (Customer Analytics)**
*   **Problem:** Analyze visiting patterns and spending habits to optimize a loyalty program[cite: 1].
*   **Solution:** Used multi-table JOINs and ranking logic to identify menu popularity and visit frequency[cite: 1].
*   **Key Finding:** Mapped the exact moment customers joined the loyalty program vs. their spending behavior[cite: 1].

---

## 🧠 Advanced SQL Patterns Mastered

*   **Running Balances:** `SUM(amount) OVER(PARTITION BY user ORDER BY date)`[cite: 1]
*   **Growth Tracking:** Using `LAG()` to calculate Month-over-Month performance[cite: 1].
*   **Dynamic Bucketing:** Using `FLOOR` and `CONCAT` to group data into ranges[cite: 1].
*   **Recursive Logic:** Filling "data gaps" between transaction dates for daily interest modeling[cite: 1, 2].
*   **Financial Math:** Implementing compound interest formulas using `POWER()`[cite: 1, 2].

---

## ⚙️ Tools & Environment
*   **Database:** MySQL Workbench[cite: 1]
*   **Workflow:** Git, GitHub, Markdown Documentation[cite: 1]
*   **Challenge Source:** [8 Week SQL Challenge by Danny Ma](https://8weeksqlchallenge.com)

---
*Last Updated: April 2026*
