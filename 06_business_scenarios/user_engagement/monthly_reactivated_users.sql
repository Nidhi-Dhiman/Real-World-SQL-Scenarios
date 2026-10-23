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
