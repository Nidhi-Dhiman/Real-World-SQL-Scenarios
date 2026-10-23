/*********************************************************
Monthly Reactivated Users Analysis

Business Scenario
Needs to monitor user engagement with the System. This SQL analysis identifies previously active users who return to the system after having no login activity during the immediately preceding month.

Objective: Calculate the number of monthly reactivated users to support operational reporting and user engagement analysis.

Note: This is a hypothetical portfolio use case using sample data.

Business Requirements
Identify users who return after a period of inactivity.
Exclude users who logged in during the immediately preceding calendar month.
Exclude first-time users with no earlier login history.
Calculate monthly reactivated-user counts.
Account for both month and year when analyzing login activity.
*************************************************************************/

SELECT
    DATE_TRUNC('month', curr_month.login_date)::DATE AS login_month,
    COUNT(DISTINCT curr_month.user_id) AS reactivated_users
FROM user_logins AS curr_month

WHERE EXISTS (
    -- User logged in before the current month
    SELECT 1
    FROM user_logins AS previous_login
    WHERE previous_login.user_id = curr_month.user_id
      AND previous_login.login_date <
          DATE_TRUNC('month', curr_month.login_date)
)

AND NOT EXISTS (
    -- No login during the immediately preceding calendar month
    SELECT 1
    FROM user_logins AS last_month
    WHERE last_month.user_id = curr_month.user_id
      AND last_month.login_date >=
          DATE_TRUNC('month', curr_month.login_date)
          - INTERVAL '1 month'
      AND last_month.login_date <
          DATE_TRUNC('month', curr_month.login_date)
)

GROUP BY DATE_TRUNC('month', curr_month.login_date)
ORDER BY login_month;
