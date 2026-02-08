/*=====================================================
PART 3 - ADVANCED SCENARIO - Library Performance Dashboard
=======================================================
Skills Demonstrated:

Core Skills:

SELECT, FROM, WHERE, ORDER BY
JOIN operations (LEFT JOIN, INNER JOIN)
GROUP BY with multiple columns
Aggregate functions (COUNT, SUM, AVG)
DISTINCT for unique values

Advanced Skills:

CTEs (Common Table Expressions) - WITH clauses
Window Functions - LAG(), ROW_NUMBER(), OVER(), PARTITION BY
Conditional Logic - CASE statements, NULLIF, ISNULL/COALESCE
Date Functions - YEAR(), MONTH(), DATENAME(), DATEDIFF()
Subqueries - Nested SELECT statements
Type Casting - CAST(), converting data types
Mathematical Operations - Calculations, percentages
Filtering - Complex WHERE conditions with AND/OR
NULL Handling - IS NULL, IS NOT NULL
Aliasing - Table and column aliases

Professional Techniques:

Multi-table data integration
KPI calculations
Trend analysis (month-over-month)
Conditional aggregations
Data quality handling (division by zero prevention)
Complex business logic implementation

=======================================================
=======================================================
1) Library Performance Dashboard
Goal:
Create a comprehensive analytics dashboard that answers key business questions

Metrics to Calculate (per month):

-Total books borrowed
-Total books returned
-Books currently overdue
-New member registrations
-Late fees collected (from returned books)
-Late fees still owed (from overdue books)
-Event revenue
-Donation revenue
-Total revenue
-Active members (borrowed at least 1 book)
-Event attendance rate
-Average reviews per book borrowed
-Inventory utilization % (copies checked out / total copies)
-Average loan duration (days)
-Most popular genre of the month
=======================================================*/
WITH monthly_loans AS (
-- Core loan activity metrics
SELECT
    YEAR(checkout_date) AS year,
    MONTH(checkout_date) AS month_num,
    DATENAME(MONTH, checkout_date) AS month_name,
    COUNT(*) AS books_borrowed,
    COUNT(CASE WHEN return_date IS NOT NULL THEN 1 END) AS books_returned,
    COUNT(CASE WHEN return_date IS NULL THEN 1 END) AS books_still_out,
    COUNT(CASE WHEN return_date IS NULL AND '2024-02-19' > due_date THEN 1 END) AS books_overdue,
    SUM(CASE
    WHEN return_date IS NOT NULL AND return_date > due_date
    THEN DATEDIFF(day, due_date, return_date) * 0.25
    ELSE 0
    END) AS late_fees_collected,
    SUM(CASE
    WHEN return_date IS NULL AND '2024-02-19' > due_date
    THEN DATEDIFF(day, due_date, '2024-02-19') * 0.25
    ELSE 0
    END) AS late_fees_owed,
    COUNT(DISTINCT member_id) AS active_members,
    AVG(CASE
    WHEN return_date IS NOT NULL
    THEN DATEDIFF(day, checkout_date, return_date)
    END) AS avg_loan_duration_days,
    CAST(COUNT(CASE WHEN return_date IS NOT NULL AND return_date <= due_date THEN 1 END) * 100.0
    / NULLIF(COUNT(CASE WHEN return_date IS NOT NULL THEN 1 END), 0) AS DECIMAL(5,2)) AS on_time_return_rate_pct
FROM book_loans
GROUP BY YEAR(checkout_date), MONTH(checkout_date), DATENAME(MONTH, checkout_date)
),

monthly_members AS (
    SELECT
    YEAR(join_date) AS year,
    MONTH(join_date) AS month_num,
    COUNT(*) AS new_members
FROM members
GROUP BY YEAR(join_date), MONTH(join_date)
),

monthly_events AS (
SELECT
    YEAR(e.event_date) AS year,
    MONTH(e.event_date) AS month_num,
    COUNT(DISTINCT e.event_id) AS total_events,
    COUNT(DISTINCT er.registration_id) AS total_registrations,
    SUM(CAST(er.attended AS INT)) AS total_attendance,
    CAST(SUM(CAST(er.attended AS INT)) * 100.0 / NULLIF(COUNT(er.registration_id), 0) AS DECIMAL(5,2)) AS attendance_rate_pct,
    AVG(CAST(er.feedback_rating AS FLOAT)) AS avg_event_rating,
    SUM(e.cost) AS event_revenue
FROM events e
LEFT JOIN event_registrations er ON e.event_id = er.event_id
GROUP BY YEAR(e.event_date), MONTH(e.event_date)
),

monthly_donations AS (
SELECT
    YEAR(donation_date) AS year,
    MONTH(donation_date) AS month_num,
    COUNT(*) AS donation_count,
    SUM(donation_amount) AS donation_revenue,
    AVG(donation_amount) AS avg_donation_amount,
    COUNT(DISTINCT member_id) AS unique_donors
FROM donations
GROUP BY YEAR(donation_date), MONTH(donation_date)
),

monthly_reviews AS (
    SELECT
    YEAR(review_date) AS year,
    MONTH(review_date) AS month_num,
    COUNT(*) AS reviews_written,
    AVG(CAST(rating AS FLOAT)) AS avg_review_rating,
    COUNT(DISTINCT member_id) AS members_who_reviewed
FROM book_reviews
GROUP BY YEAR(review_date), MONTH(review_date)
),

monthly_top_genre AS (
SELECT
    year,
    month_num,
    genre AS top_genre,
    borrows AS top_genre_borrows
FROM (
SELECT
    YEAR(bl.checkout_date) AS year,
    MONTH(bl.checkout_date) AS month_num,
    b.genre,
    COUNT(*) AS borrows,
    ROW_NUMBER() OVER (PARTITION BY YEAR(bl.checkout_date), MONTH(bl.checkout_date) ORDER BY COUNT(*) DESC) AS rank
    FROM book_loans bl
    JOIN books b ON bl.book_id = b.book_id
    GROUP BY YEAR(bl.checkout_date), MONTH(bl.checkout_date), b.genre
    ) ranked
    WHERE rank = 1
    ),
    inventory_stats AS (
    SELECT
    YEAR(checkout_date) AS year,
    MONTH(checkout_date) AS month_num,
    (SELECT SUM(total_copies) FROM books) AS total_inventory,
    COUNT(*) AS copies_in_circulation
FROM book_loans
WHERE checkout_date <= '2024-02-19'
AND (return_date IS NULL OR return_date > '2024-02-19')
GROUP BY YEAR(checkout_date), MONTH(checkout_date)
)
SELECT
    ml.year,
    ml.month_num,
    ml.month_name,
    ml.books_borrowed,
    ml.books_returned,
    ml.books_still_out,
    ml.books_overdue,
    ml.active_members,
    ISNULL(mm.new_members, 0) AS new_members,
    ml.late_fees_collected,
    ml.late_fees_owed,
    ISNULL(me.event_revenue, 0) AS event_revenue,
    ISNULL(md.donation_revenue, 0) AS donation_revenue,
    (ml.late_fees_collected + ISNULL(me.event_revenue, 0) + ISNULL(md.donation_revenue, 0)) AS total_revenue,
    ISNULL(me.total_events, 0) AS events_held,
    ISNULL(me.total_registrations, 0) AS event_registrations,
    ISNULL(me.total_attendance, 0) AS event_attendance,
    ISNULL(me.attendance_rate_pct, 0) AS event_attendance_rate_pct,
    ISNULL(me.avg_event_rating, 0) AS avg_event_rating,
    ISNULL(mr.reviews_written, 0) AS reviews_written,
    ISNULL(mr.avg_review_rating, 0) AS avg_book_rating,
    ISNULL(mr.members_who_reviewed, 0) AS members_who_reviewed,
    ISNULL(md.donation_count, 0) AS donations_received,
    ISNULL(md.avg_donation_amount, 0) AS avg_donation_amount,
    ISNULL(md.unique_donors, 0) AS unique_donors,
    ml.avg_loan_duration_days,
    ml.on_time_return_rate_pct,
    ISNULL(inv.total_inventory, 0) AS total_inventory,
    ISNULL(inv.copies_in_circulation, 0) AS copies_in_circulation,
    CAST(ISNULL(inv.copies_in_circulation, 0) * 100.0 / NULLIF(inv.total_inventory, 0) AS DECIMAL(5,2)) AS inventory_utilization_pct,
    mtg.top_genre,
    mtg.top_genre_borrows,
    LAG(ml.books_borrowed) OVER (ORDER BY ml.year, ml.month_num) AS prev_month_borrowed,
    ml.books_borrowed - LAG(ml.books_borrowed) OVER (ORDER BY ml.year, ml.month_num) AS borrowed_change,
    CASE
    WHEN LAG(ml.books_borrowed) OVER (ORDER BY ml.year, ml.month_num) IS NULL THEN NULL
    WHEN LAG(ml.books_borrowed) OVER (ORDER BY ml.year, ml.month_num) = 0 THEN NULL
    ELSE CAST((ml.books_borrowed - LAG(ml.books_borrowed) OVER (ORDER BY ml.year, ml.month_num)) * 100.0
    / LAG(ml.books_borrowed) OVER (ORDER BY ml.year, ml.month_num) AS DECIMAL(5,2))
    END AS borrowed_change_pct,
    LAG(ml.active_members) OVER (ORDER BY ml.year, ml.month_num) AS prev_month_active,
    ml.active_members - LAG(ml.active_members) OVER (ORDER BY ml.year, ml.month_num) AS active_members_change,
    CAST(ml.books_borrowed * 1.0 / NULLIF(ml.active_members, 0) AS DECIMAL(5,2)) AS books_per_active_member,
    ml.books_borrowed + (ISNULL(me.total_attendance, 0) * 2) + (ISNULL(mr.reviews_written, 0) * 3) AS engagement_score,
    CAST((ml.late_fees_collected + ISNULL(me.event_revenue, 0) + ISNULL(md.donation_revenue, 0))
    / NULLIF(ml.active_members, 0) AS DECIMAL(10,2)) AS revenue_per_active_member,
    CAST(ml.books_returned * 100.0 / NULLIF(ml.books_borrowed, 0) AS DECIMAL(5,2)) AS return_rate_pct
FROM monthly_loans ml
LEFT JOIN monthly_members mm
ON ml.year = mm.year AND ml.month_num = mm.month_num
LEFT JOIN monthly_events me
ON ml.year = me.year AND ml.month_num = me.month_num
LEFT JOIN monthly_donations md
ON ml.year = md.year AND ml.month_num = md.month_num
LEFT JOIN monthly_reviews mr
ON ml.year = mr.year AND ml.month_num = mr.month_num
LEFT JOIN inventory_stats inv
ON ml.year = inv.year AND ml.month_num = inv.month_num
LEFT JOIN monthly_top_genre mtg
ON ml.year = mtg.year AND ml.month_num = mtg.month_num
ORDER BY ml.year, ml.month_num;
