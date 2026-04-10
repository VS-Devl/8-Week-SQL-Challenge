-- SECTION A: CUSTOMER JOURNEY
-- APPROACH 1: MANUAL OBSERVATION (THE NARRATIVE)
-- In this approach, we use a simple JOIN to see the human-readable plan names and dates. 
-- This allows an analyst to manually synthesize the "story" for each customer.

-- METHOD 1: DATA RETRIEVAL FOR MANUAL SUMMARY
SELECT 
    SUB.CUSTOMER_ID, 
    P.PLAN_NAME, 
    MONTHNAME(SUB.START_DATE) AS MONTH_NAME, 
    DAY(SUB.START_DATE) AS DAY_NUM  
FROM PLANS AS P
JOIN SUBSCRIPTIONS AS SUB 
    ON P.PLAN_ID = SUB.PLAN_ID
ORDER BY CUSTOMER_ID, START_DATE ASC;

/* Manual Interpretation of Sample IDs:
- Customer 1: Started 7-day trial on Aug 1; upgraded to Basic Monthly on Aug 8.
- Customer 2: Started 7-day trial on Sep 20; upgraded to Pro Annual on Sep 27.
- Customer 3: Started 7-day trial on Jan 13; upgraded to Basic Monthly on Jan 20.
- Customer 4: Started 7-day trial on Jan 17; upgraded to Basic Monthly on Jan 24; churned on Apr 21.
- Customer 5: Started 7-day trial on Aug 3; upgraded to Basic Monthly on Aug 10.
- Customer 6: Started 7-day trial on Dec 23; upgraded to Basic Monthly on Dec 30; churned on Feb 26.
- Customer 7: Started 7-day trial on Feb 5; upgraded to Basic Monthly on Feb 12; upgraded to Pro Monthly on May 22.
- Customer 8: Started 7-day trial on Jun 11; upgraded to Basic Monthly on Jun 18; upgraded to Pro Monthly on Aug 3.
*/

-- APPROACH 2: AUTOMATED SUMMARY (THE DATA PIPELINE)
-- This approach uses String Aggregation (GROUP_CONCAT) to programmatically generate a journey description. 
-- This is more scalable; if you wanted to see the journey for specific customers (e.g., ID 11 and 13), 
-- you would simply add a WHERE SUB.CUSTOMER_ID IN (11, 13) clause before the GROUP BY.

-- METHOD 2: PROGRAMMATIC STRING AGGREGATION
SELECT 
    SUB.CUSTOMER_ID,
    GROUP_CONCAT(
        CASE
            WHEN SUB.PLAN_ID = 0 THEN CONCAT('Customer ', SUB.CUSTOMER_ID, ' started their 7-day ', P.PLAN_NAME, ' on ', MONTHNAME(SUB.START_DATE), ' ', DAY(SUB.START_DATE))
            WHEN SUB.PLAN_ID = 1 THEN CONCAT('upgraded to the ', P.PLAN_NAME, ' on ', MONTHNAME(SUB.START_DATE), ' ', DAY(SUB.START_DATE))
            WHEN SUB.PLAN_ID = 2 THEN CONCAT('upgraded to the ', P.PLAN_NAME, ' on ', MONTHNAME(SUB.START_DATE), ' ', DAY(SUB.START_DATE))
            WHEN SUB.PLAN_ID = 3 THEN CONCAT('upgraded to the ', P.PLAN_NAME, ' on ', MONTHNAME(SUB.START_DATE), ' ', DAY(SUB.START_DATE))
            WHEN SUB.PLAN_ID = 4 THEN CONCAT('and eventually churned on ', MONTHNAME(SUB.START_DATE), ' ', DAY(SUB.START_DATE))
        END 
        ORDER BY SUB.START_DATE ASC 
        SEPARATOR ', '
    ) AS DESCRIPTION
FROM PLANS AS P
JOIN SUBSCRIPTIONS AS SUB 
    ON P.PLAN_ID = SUB.PLAN_ID
WHERE SUB.CUSTOMER_ID IN (1, 2, 3, 4, 5, 6, 7, 8) -- CAN BE FILTERED FOR SPECIFIC SAMPLES
GROUP BY SUB.CUSTOMER_ID
ORDER BY SUB.CUSTOMER_ID;
