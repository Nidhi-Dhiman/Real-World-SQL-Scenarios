/***********************************************************************************
Build a monthly dashboard from orders: revenue, order_count, new_customers (customers whose first order falls in that month), and mom_growth_pct vs the prior month. 
Round growth to 2 decimals (NULL in the first month).

Output columns: month, revenue, order_count, new_customers, mom_growth_pct

Advanced SQL: CTEs, date functions (DATE_TRUNC), window functions (LAG), NULL handling (COALESCE), joins, aggregations, and monthly reporting.
****************************************************************************/
WITH monthly AS 
(SELECT 
DATE_TRUNC('month', order_date)::DATE AS month,
SUM(amount) AS revenue, 
COUNT(*) AS order_count
FROM orders 
GROUP BY 1), 
new_cust AS 
(SELECT 
DATE_TRUNC('month', first_order)::DATE AS month, 
COUNT(*) AS new_customers 
FROM
(SELECT customer_id,
MIN(order_date) AS first_order
 FROM orders 
 GROUP BY customer_id)
 t GROUP BY 1) 
SELECT m.month, 
m.revenue, m.order_count,
COALESCE(n.new_customers, 0) AS new_customers, 
ROUND((m.revenue - LAG(m.revenue) OVER (ORDER BY m.month))::NUMERIC / LAG(m.revenue) OVER (ORDER BY m.month) * 100, 2) AS mom_growth_pct 
FROM monthly m LEFT JOIN new_cust n 
ON n.month = m.month 
ORDER BY m.month
