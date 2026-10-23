/**********************************************************************************
Payment and disbursement mismatches

Business problem: Payment amounts do not match the amounts allocated or disbursed.

SQL skills: Joins, aggregations, CTEs, COALESCE()

Business value: Identifies reconciliation exceptions for further investigation.
**********************************************************************************/

WITH allocation_totals AS (
    SELECT
        payment_id,
        SUM(allocation_amount) AS allocated_amount
    FROM payment_allocations
    GROUP BY payment_id
)
SELECT
    p.payment_id,
    p.payment_amount,
    COALESCE(a.allocated_amount, 0) AS allocated_amount,
    p.payment_amount
        - COALESCE(a.allocated_amount, 0) AS difference
FROM payments p
LEFT JOIN allocation_totals a
    ON p.payment_id = a.payment_id
WHERE p.payment_amount
      <> COALESCE(a.allocated_amount, 0);

Business question: Do payment totals match the sum of their allocations?

This example assumes the payment amount is expected to equal the total allocation amount and that all amounts use the same currency and accounting basis.
