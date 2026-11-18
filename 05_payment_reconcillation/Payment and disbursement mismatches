/**********************************************************************************
Payment and disbursement mismatches

Business problem: Payment amounts do not match the amounts allocated or disbursed.

SQL skills: Joins, aggregations, CTEs, COALESCE()

Business value: Identifies reconciliation exceptions for further investigation.

a fully reconciled payment, a payment with a partial disbursement, and a payment with a missing or invalid related record
**********************************************************************************/

WITH latest_payment_history AS (
    -- Get the latest status recorded for each payment
    SELECT
        ph.payment_id,
        ph.status AS latest_history_status,
        ph.status_date,
        ROW_NUMBER() OVER (
            PARTITION BY ph.payment_id
            ORDER BY ph.status_date DESC, ph.history_id DESC
        ) AS rn
    FROM payment_history ph
),

case_participants AS (
    -- Prevent multiple case roles from duplicating payment amounts
    SELECT
        cr.case_id,
        STRING_AGG(
            DISTINCT pt.participant_name,
            ', '
        ) AS participant_names
    FROM case_role cr
    LEFT JOIN participants pt
        ON cr.participant_id = pt.participant_id
    GROUP BY cr.case_id
),

disbursement_summary AS (
    -- Aggregate disbursements before joining to payments
    SELECT
        d.payment_id,
        COUNT(d.disbursement_id) AS disbursement_count,
        SUM(d.disbursement_amount) AS total_disbursed,
        MAX(d.disbursement_date) AS last_disbursement_date
    FROM disbursements d
    GROUP BY d.payment_id
),

payment_detail AS (
    SELECT
        p.payment_id,
        p.case_id,
        c.case_status,
        cp.participant_names,
        p.payment_date,
        DATE_TRUNC('quarter', p.payment_date)::DATE
            AS quarter_start,
        (
            DATE_TRUNC('quarter', p.payment_date)
            + INTERVAL '3 months'
            - INTERVAL '1 day'
        )::DATE AS quarter_end,

        EXTRACT(YEAR FROM p.payment_date) AS payment_year,
        EXTRACT(QUARTER FROM p.payment_date) AS payment_quarter,

        p.payment_amount,
        p.payment_status,
        lph.latest_history_status,
        lph.status_date AS latest_status_date,

        COALESCE(ds.disbursement_count, 0)
            AS disbursement_count,
        ds.total_disbursed,
        ds.last_disbursement_date,

        CASE
            WHEN p.payment_amount IS NULL
                THEN 'MISSING PAYMENT AMOUNT'
            WHEN p.payment_amount < 0
                THEN 'NEGATIVE PAYMENT AMOUNT'
            WHEN c.case_id IS NULL
                THEN 'INVALID CASE REFERENCE'
            WHEN cp.case_id IS NULL
                THEN 'MISSING CASE ROLE'
            WHEN lph.payment_id IS NULL
                THEN 'MISSING PAYMENT HISTORY'
            WHEN UPPER(TRIM(COALESCE(
                     lph.latest_history_status, ''
                 ))) IN ('FAILED', 'CANCELLED', 'REJECTED')
                THEN 'UNSUCCESSFUL PAYMENT STATUS'
            WHEN COALESCE(ds.disbursement_count, 0) = 0
                THEN 'MISSING DISBURSEMENT'
            WHEN ds.total_disbursed IS NULL
                THEN 'MISSING DISBURSEMENT AMOUNT'
            WHEN ABS(
                    p.payment_amount - ds.total_disbursed
                 ) > 0.01
                THEN 'PAYMENT / DISBURSEMENT MISMATCH'
            WHEN UPPER(TRIM(COALESCE(
                     p.payment_status, ''
                 ))) <>
                 UPPER(TRIM(COALESCE(
                     lph.latest_history_status, ''
                 )))
                THEN 'PAYMENT STATUS MISMATCH'
            ELSE 'RECONCILED'
        END AS reconciliation_status

    FROM payments p
    LEFT JOIN cases c
        ON p.case_id = c.case_id
    LEFT JOIN case_participants cp
        ON p.case_id = cp.case_id
    LEFT JOIN latest_payment_history lph
        ON p.payment_id = lph.payment_id
       AND lph.rn = 1
    LEFT JOIN disbursement_summary ds
        ON p.payment_id = ds.payment_id
),

quarterly_metrics AS (
    SELECT
        pd.*,

        COUNT(*) OVER (
            PARTITION BY quarter_start
        ) AS quarterly_payment_count,

        SUM(COALESCE(payment_amount, 0)) OVER (
            PARTITION BY quarter_start
        ) AS quarterly_payment_total,

        SUM(COALESCE(total_disbursed, 0)) OVER (
            PARTITION BY quarter_start
        ) AS quarterly_disbursement_total,

        SUM(
            CASE
                WHEN reconciliation_status = 'RECONCILED'
                THEN 1 ELSE 0
            END
        ) OVER (
            PARTITION BY quarter_start
        ) AS reconciled_payment_count,

        SUM(
            CASE
                WHEN reconciliation_status <> 'RECONCILED'
                THEN 1 ELSE 0
            END
        ) OVER (
            PARTITION BY quarter_start
        ) AS exception_count,

        DENSE_RANK() OVER (
            PARTITION BY quarter_start
            ORDER BY
                ABS(
                    COALESCE(payment_amount, 0)
                    - COALESCE(total_disbursed, 0)
                ) DESC
        ) AS discrepancy_rank

    FROM payment_detail pd
)

SELECT
    payment_id,
    case_id,
    participant_names,
    quarter_start,
    quarter_end,
    payment_year,
    payment_quarter,

    payment_amount,
    total_disbursed,

    ROUND(
        COALESCE(payment_amount, 0)
        - COALESCE(total_disbursed, 0),
        2
    ) AS payment_disbursement_difference,

    payment_status,
    latest_history_status,
    disbursement_count,
    last_disbursement_date,
    reconciliation_status,

    quarterly_payment_count,
    quarterly_payment_total,
    quarterly_disbursement_total,
    reconciled_payment_count,
    exception_count,
    discrepancy_rank

FROM quarterly_metrics
WHERE reconciliation_status <> 'RECONCILED'
ORDER BY
    quarter_start DESC,
    discrepancy_rank,
    payment_id;


This example assumes the payment amount is expected to equal the total allocation amount and that all amounts use the same currency and accounting basis.
