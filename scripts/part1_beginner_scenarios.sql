/*=====================================================
                PART 1 - BEGINNER SCENARIOS
=======================================================
Skills Demonstrated:

- SQL Joins: LEFT JOIN
- Aggregation Functions: COUNT(), SUM(), MAX()
- Conditional Logic: CASE WHEN ... ELSE ... END
- Date Calculations: DATEDIFF()
- String Manipulation: CONCAT()
- Filtering & Grouping: GROUP BY, HAVING, ORDER BY
=======================================================
1) Basic Popularity List

Goal:
Show which books are most popular based on borrow count.

Requirements:
Show: title, author, genre, times borrowed
Include ALL books (even if never borrowed)
Sort by most popular first
=======================================================*/
SELECT
b.title,
b.author,
b.genre,
COUNT(l.loan_id) AS times_loaned
FROM books b 
LEFT JOIN book_loans l ON b.book_id=l.book_id
GROUP BY b.title, b.author, b.genre
ORDER BY times_loaned DESC;

-- Add Availabilty Status
SELECT
    b.title,
    b.author,
    b.genre,
    COUNT(l.loan_id) AS times_loaned,
    b.total_copies,
    COUNT(CASE WHEN l.return_date IS NULL THEN 1 END) AS currently_checked_out,
    b.total_copies - COUNT(CASE WHEN l.return_date IS NULL THEN 1 END) AS available_now
FROM books b 
LEFT JOIN book_loans l ON b.book_id = l.book_id
GROUP BY b.title, b.author, b.genre, b.total_copies
ORDER BY times_loaned DESC

/*=====================================================
2) Genre Popularity Dashboard

Goal: Analyze which genres are most popular

- Count checkouts by genre
- Compare across different age groups
=======================================================*/
SELECT 
    m.age_group,
    b.genre,
    COUNT (l.loan_id) AS times_loaned
FROM members m 
LEFT JOIN book_loans l ON m.member_id=l.member_id
LEFT JOIN books b ON b.book_id=l.book_id
GROUP BY m.age_group, b.genre
ORDER BY times_loaned DESC

/*=====================================================
3) Member Activity Report

Goal: Find inactive members who need re-engagement

- List members who haven't borrowed books in 30 days 
- Assuming current date = 2024-02-19
- Identify members who've never attended events
=======================================================*/
SELECT 
    CONCAT(m.first_name,' ', m.last_name) AS full_name,
    CASE 
        WHEN MAX(l.checkout_date) IS NULL OR DATEDIFF(day, MAX(l.checkout_date), '2024-02-19') > 30
        THEN 'Inactive >30 days'
        ELSE NULL
    END AS inactivity_status,
    CASE 
        WHEN SUM(CASE WHEN r.attended = 1 THEN 1 ELSE 0 END) = 0
        THEN 'Never attended events'
        ELSE NULL
    END AS event_status
FROM members m
LEFT JOIN book_loans l ON m.member_id = l.member_id
LEFT JOIN event_registrations r ON m.member_id = r.member_id
GROUP BY m.member_id, m.first_name, m.last_name
HAVING 
    MAX(l.checkout_date) IS NULL 
    OR DATEDIFF(day, MAX(l.checkout_date), '2024-02-19') > 30
    OR SUM(CASE WHEN r.attended = 1 THEN 1 ELSE 0 END) = 0
ORDER BY full_name;

      
