/******************
Duplicate payment records

Business problem: The same payment transaction appears more than once, potentially inflating payment totals.

SQL skills: GROUP BY, HAVING, COUNT(*)

Business value: Prevents duplicate transactions from distorting financial reports
******************************/


SELECT
    payment_reference,
    COUNT(*) AS duplicate_count,
    SUM(payment_amount) AS total_recorded_amount
FROM payments
GROUP BY payment_reference
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;


Note: A duplicate reference flags a potential issue; confirm the business rules before treating it as a genuine duplicate.
