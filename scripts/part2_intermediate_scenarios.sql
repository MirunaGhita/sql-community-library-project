/*=====================================================
             PART 2 - INTERMEDIATE SCENARIOS
=======================================================
Skills Demonstrated:

-Multiple JOINs (INNER, LEFT), 
-Subqueries (Correlated, NOT IN), 
-CTEs (Common Table Expressions), 
-UNION ALL, 
-Window Functions (RANK, ROW_NUMBER, PERCENT_RANK), 
-Aggregations (COUNT, SUM, AVG), 
-CASE Statements, 
-GROUP BY with HAVING, 
-String Functions (CONCAT), 
-Date Functions (DATEDIFF), 
-NULL Handling (ISNULL), 
-Conditional Aggregation, 
-Percentile Calculations
=======================================================
=======================================================
1) Smart Book Recommendation System

Goal: Suggest books to members based on their preferences

- Match books to member's favorite genre
- Exclude books they've already read
- Prioritize available books
=======================================================*/
SELECT 
    CONCAT(m.first_name, ' ', m.last_name) AS full_name,
    b.title,
    b.author,
    b.genre,
    b.total_copies - COUNT(CASE WHEN l.return_date IS NULL THEN 1 END) AS available_copies
FROM members m
JOIN books b ON m.favorite_genre = b.genre
LEFT JOIN book_loans l ON b.book_id = l.book_id AND l.member_id = m.member_id  -- only count loans by this member if needed
WHERE b.book_id NOT IN (
    SELECT l2.book_id 
    FROM book_loans l2 
    WHERE l2.member_id = m.member_id
)
GROUP BY m.member_id, m.first_name, m.last_name, b.book_id, b.title, b.author, b.genre, b.total_copies
HAVING b.total_copies - COUNT(CASE WHEN l.return_date IS NULL THEN 1 END) > 0
ORDER BY full_name, available_copies DESC, b.title;

/*=====================================================
2) Event ROI Analyzer

Goal: Measure success of library events

- Calculate attendance rate (attended vs registered)
- Find average feedback ratings
- Identify which event types are most successful
- Calculate cost per attendee for paid events
=======================================================*/
SELECT
    e.event_name,
    e.event_type,
    COUNT(r.registration_id) AS registered,
    SUM(CASE WHEN r.attended = 1 THEN 1 ELSE 0 END) AS attended,
    ROUND(CAST(SUM(CASE WHEN r.attended = 1 THEN 1 ELSE 0 END) AS FLOAT)/ COUNT(r.registration_id) * 100, 2) AS attendance_rate,
    AVG(CASE WHEN r.attended = 1 THEN r.feedback_rating END) AS avg_feedback,
    e.cost AS total_cost,
    ROUND(
        CASE WHEN 
        SUM(CASE WHEN r.attended = 1 THEN 1 ELSE 0 END) > 0 
        THEN CAST(e.cost AS FLOAT) / SUM(CASE WHEN r.attended = 1 THEN 1 ELSE 0 END)
        ELSE NULL
    END, 2) AS cost_per_attendee
FROM events e
LEFT JOIN event_registrations r ON e.event_id = r.event_id
    GROUP BY e.event_id, e.event_name, e.event_type, e.cost
    ORDER BY attendance_rate DESC, avg_feedback DESC;

/*=====================================================
3) Inventory Management System

Goal: Track book availability and predict needs

- Find books with all copies checked out
- Calculate average loan duration by genre
- Identify books that should have more copies (high demand)
- Flag books that are never borrowed (consider removing)
=======================================================*/

SELECT 
    b.book_id,
    b.title,
    b.genre,
    b.total_copies, 
     -- Currently checked out copies
    SUM(CASE WHEN bl.return_date IS NULL THEN 1 ELSE 0 END) AS checked_out_copies,    
    -- All copies checked out?
    CASE 
    WHEN SUM(CASE WHEN bl.return_date IS NULL THEN 1 ELSE 0 END) = b.total_copies 
    THEN 'Yes' ELSE 'No' 
    END AS all_checked_out,    
    -- Average loan duration for this book
    ROUND(AVG(CAST(DATEDIFF(day, bl.checkout_date, ISNULL(bl.return_date, GETDATE())) AS FLOAT)), 2) AS avg_loan_duration_days,    
    -- Never borrowed?
    CASE 
    WHEN COUNT(bl.loan_id) = 0 THEN 'Yes' ELSE 'No' 
    END AS never_borrowed
FROM books b
LEFT JOIN book_loans bl ON b.book_id = bl.book_id
GROUP BY b.book_id, b.title, b.genre, b.total_copies
ORDER BY checked_out_copies DESC, b.title;

/*=======================================================
4) Member Loyalty Program
Goal: Create a points system to reward active members
- Award points for: loans (1pt), events attended (2pts), 
  reviews (3pts), donations ($1 = 1pt)
- Rank members by total points
- Identify "Super Members" (top 10%)
=======================================================*/

-- Step 1: Calculate points from each activity
WITH LoanPoints AS (
    SELECT 
    member_id,
    COUNT(*) AS activity_count,
    COUNT(*) * 1 AS points,
    'Loans' AS activity_type
FROM book_loans
GROUP BY member_id
),

EventPoints AS (
    SELECT 
    member_id,
    SUM(CASE WHEN attended = 1 THEN 1 ELSE 0 END) AS activity_count,
    SUM(CASE WHEN attended = 1 THEN 2 ELSE 0 END) AS points,
    'Events Attended' AS activity_type
FROM event_registrations
GROUP BY member_id
),

ReviewPoints AS (
    SELECT 
    member_id,
    COUNT(*) AS activity_count,
    COUNT(*) * 3 AS points,
    'Reviews' AS activity_type
FROM book_reviews
GROUP BY member_id
),

DonationPoints AS (
    SELECT 
    member_id,
    COUNT(*) AS activity_count,
    CAST(SUM(donation_amount) AS INT) AS points,
    'Donations' AS activity_type
FROM donations
GROUP BY member_id
),
-- Step 2: Combine all points
AllPoints AS (
SELECT * FROM LoanPoints
UNION ALL
SELECT * FROM EventPoints
UNION ALL
SELECT * FROM ReviewPoints
UNION ALL
SELECT * FROM DonationPoints
),
-- Step 3: Calculate total points per member
MemberTotalPoints AS (
SELECT 
    m.member_id,
    m.first_name,
    m.last_name,
    m.email,
    m.membership_type,
    m.age_group,
    m.join_date,
    DATEDIFF(day, m.join_date, (SELECT MAX(checkout_date) FROM book_loans)) AS days_member,    
    -- Point breakdown
    ISNULL(SUM(CASE WHEN ap.activity_type = 'Loans' THEN ap.points END), 0) AS loan_points,
    ISNULL(SUM(CASE WHEN ap.activity_type = 'Events Attended' THEN ap.points END), 0) AS event_points,
    ISNULL(SUM(CASE WHEN ap.activity_type = 'Reviews' THEN ap.points END), 0) AS review_points,
    ISNULL(SUM(CASE WHEN ap.activity_type = 'Donations' THEN ap.points END), 0) AS donation_points,      
    -- Activity counts
    ISNULL(SUM(CASE WHEN ap.activity_type = 'Loans' THEN ap.activity_count END), 0) AS total_loans,
    ISNULL(SUM(CASE WHEN ap.activity_type = 'Events Attended' THEN ap.activity_count END), 0) AS events_attended,
    ISNULL(SUM(CASE WHEN ap.activity_type = 'Reviews' THEN ap.activity_count END), 0) AS reviews_written,
    ISNULL(SUM(CASE WHEN ap.activity_type = 'Donations' THEN ap.activity_count END), 0) AS donations_made,     
    -- Total points
    ISNULL(SUM(ap.points), 0) AS total_points       
FROM members m
LEFT JOIN AllPoints ap ON m.member_id = ap.member_id
GROUP BY 
m.member_id, m.first_name, m.last_name, m.email, 
m.membership_type, m.age_group, m.join_date
),

-- Step 4: Add rankings
RankedMembers AS 
(
SELECT 
    *,
    -- Different ranking methods
    RANK() OVER (ORDER BY total_points DESC) AS points_rank,
    PERCENT_RANK() OVER (ORDER BY total_points DESC) AS percentile_rank-- Percentile calculation 
FROM MemberTotalPoints
)
-- Step 5: Final output with Super Member identification
SELECT 
    member_id,
    first_name + ' ' + last_name AS member_name,
    email,
    membership_type,
    age_group,
    join_date,
    days_member,
    -- Point breakdown
    loan_points,
    event_points,
    review_points,
    donation_points,
    total_points,
    -- Activity summary
    total_loans,
    events_attended,
    reviews_written,
    donations_made,
    -- Rankings
    points_rank,
    -- Super Member Status (top 10%)
    CASE 
    WHEN percentile_rank <= 0.10 THEN 'SUPER MEMBER'
    WHEN percentile_rank <= 0.25 THEN 'GOLD MEMBER'
    WHEN percentile_rank <= 0.50 THEN 'SILVER MEMBER'
    ELSE 'BRONZE MEMBER'
    END AS loyalty_tier
FROM RankedMembers
ORDER BY points_rank ASC, member_id ASC;

