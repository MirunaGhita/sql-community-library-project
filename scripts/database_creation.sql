/*============================================

DATABASE CREATION - COMMUNITY LIBRARY SYSTEM 

==============================================*/

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'CommunityLibrary')
BEGIN
    CREATE DATABASE CommunityLibrary;
    PRINT 'Database CommunityLibrary created successfully!';
END
ELSE
BEGIN
    PRINT 'Database CommunityLibrary already exists.';
END
GO

USE CommunityLibrary;
GO

PRINT 'Now using CommunityLibrary database...';
GO

-- ============================================
-- DROP OLD TABLES IF THEY EXIST
-- ============================================

IF OBJECT_ID('donations', 'U') IS NOT NULL DROP TABLE donations;
IF OBJECT_ID('book_reviews', 'U') IS NOT NULL DROP TABLE book_reviews;
IF OBJECT_ID('event_registrations', 'U') IS NOT NULL DROP TABLE event_registrations;
IF OBJECT_ID('events', 'U') IS NOT NULL DROP TABLE events;
IF OBJECT_ID('book_loans', 'U') IS NOT NULL DROP TABLE book_loans;
IF OBJECT_ID('books', 'U') IS NOT NULL DROP TABLE books;
IF OBJECT_ID('members', 'U') IS NOT NULL DROP TABLE members;
GO

PRINT 'Old tables dropped (if existed)';
GO

-- ============================================
-- TABLE CREATION
-- ============================================

-- Members table
CREATE TABLE members (
    member_id INT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    age_group VARCHAR(20) NOT NULL,
    membership_type VARCHAR(30) NOT NULL,
    join_date DATE NOT NULL,
    favorite_genre VARCHAR(50),
    CONSTRAINT CHK_age_group CHECK (age_group IN ('Child', 'Teen', 'Adult', 'Senior')),
    CONSTRAINT CHK_membership_type CHECK (membership_type IN ('Basic', 'Premium', 'Student', 'Family'))
);

-- Books table

CREATE TABLE books (
    book_id INT PRIMARY KEY,
    title VARCHAR(150) NOT NULL,
    author VARCHAR(100) NOT NULL,
    genre VARCHAR(50) NOT NULL,
    publication_year INT NOT NULL,
    isbn VARCHAR(20) UNIQUE,
    total_copies INT NOT NULL,
    CONSTRAINT CHK_total_copies CHECK (total_copies > 0),
    CONSTRAINT CHK_publication_year CHECK (publication_year >= 1000 AND publication_year <= YEAR(GETDATE()))
);

-- Book Loans table

CREATE TABLE book_loans (
    loan_id INT PRIMARY KEY,
    member_id INT NOT NULL,
    book_id INT NOT NULL,
    checkout_date DATE NOT NULL,
    due_date DATE NOT NULL,
    return_date DATE,
    FOREIGN KEY (member_id) REFERENCES members(member_id),
    FOREIGN KEY (book_id) REFERENCES books(book_id),
    CONSTRAINT CHK_due_after_checkout CHECK (due_date >= checkout_date),
    CONSTRAINT CHK_return_after_checkout CHECK (return_date IS NULL OR return_date >= checkout_date)
);

-- Events table

CREATE TABLE events (
    event_id INT PRIMARY KEY,
    event_name VARCHAR(100) NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    event_date DATE NOT NULL,
    max_attendees INT NOT NULL,
    cost DECIMAL(6, 2) NOT NULL DEFAULT 0,
    description VARCHAR(300),
    CONSTRAINT CHK_max_attendees CHECK (max_attendees > 0),
    CONSTRAINT CHK_cost CHECK (cost >= 0)
);

-- Event Registrations table

CREATE TABLE event_registrations (
    registration_id INT PRIMARY KEY,
    event_id INT NOT NULL,
    member_id INT NOT NULL,
    registration_date DATE NOT NULL,
    attended BIT NOT NULL DEFAULT 0,
    feedback_rating INT,
    FOREIGN KEY (event_id) REFERENCES events(event_id),
    FOREIGN KEY (member_id) REFERENCES members(member_id),
    CONSTRAINT CHK_feedback_rating CHECK (feedback_rating IS NULL OR (feedback_rating >= 1 AND feedback_rating <= 5)),
    CONSTRAINT CHK_feedback_requires_attendance CHECK (attended = 1 OR feedback_rating IS NULL)
);

-- Book Reviews table

CREATE TABLE book_reviews (
    review_id INT PRIMARY KEY,
    book_id INT NOT NULL,
    member_id INT NOT NULL,
    rating INT NOT NULL,
    review_text VARCHAR(500),
    review_date DATE NOT NULL,
    helpful_votes INT NOT NULL DEFAULT 0,
    FOREIGN KEY (book_id) REFERENCES books(book_id),
    FOREIGN KEY (member_id) REFERENCES members(member_id),
    CONSTRAINT CHK_rating CHECK (rating >= 1 AND rating <= 5),
    CONSTRAINT CHK_helpful_votes CHECK (helpful_votes >= 0),
    CONSTRAINT UQ_member_book_review UNIQUE (member_id, book_id)
);

-- Donations table

CREATE TABLE donations (
    donation_id INT PRIMARY KEY,
    member_id INT NOT NULL,
    donation_amount DECIMAL(8, 2) NOT NULL,
    donation_date DATE NOT NULL,
    donation_type VARCHAR(50) NOT NULL,
    FOREIGN KEY (member_id) REFERENCES members(member_id),
    CONSTRAINT CHK_donation_amount CHECK (donation_amount > 0)
);

PRINT 'All tables created with proper constraints!';
GO

-- ============================================
-- DATA INSERTION
-- ============================================

-- Insert Members
INSERT INTO members VALUES (1, 'Emma', 'Thompson', 'emma.t@email.com', '555-0201', 'Adult', 'Premium', '2023-01-15', 'Mystery');
INSERT INTO members VALUES (2, 'Marcus', 'Johnson', 'marcus.j@email.com', '555-0202', 'Teen', 'Student', '2023-03-20', 'Science Fiction');
INSERT INTO members VALUES (3, 'Sofia', 'Rodriguez', 'sofia.r@email.com', '555-0203', 'Adult', 'Basic', '2023-02-10', 'Romance');
INSERT INTO members VALUES (4, 'Liam', 'Chen', 'liam.c@email.com', '555-0204', 'Senior', 'Premium', '2022-11-05', 'Historical Fiction');
INSERT INTO members VALUES (5, 'Ava', 'Patel', 'ava.p@email.com', '555-0205', 'Adult', 'Basic', '2023-05-12', 'Self-Help');
INSERT INTO members VALUES (6, 'Noah', 'Williams', 'noah.w@email.com', '555-0206', 'Child', 'Family', '2023-06-01', 'Fantasy');
INSERT INTO members VALUES (7, 'Olivia', 'Brown', 'olivia.b@email.com', '555-0207', 'Teen', 'Student', '2023-04-18', 'Young Adult');
INSERT INTO members VALUES (8, 'James', 'Martinez', 'james.m@email.com', '555-0208', 'Adult', 'Premium', '2023-01-30', 'Biography');

PRINT '8 members inserted!';
GO

-- Insert Books
INSERT INTO books VALUES (101, 'The Midnight Library', 'Matt Haig', 'Fiction', 2020, '978-0525559474', 5);
INSERT INTO books VALUES (102, 'Educated', 'Tara Westover', 'Biography', 2018, '978-0399590504', 4);
INSERT INTO books VALUES (103, 'Project Hail Mary', 'Andy Weir', 'Science Fiction', 2021, '978-0593135204', 6);
INSERT INTO books VALUES (104, 'The Thursday Murder Club', 'Richard Osman', 'Mystery', 2020, '978-1984880987', 4);
INSERT INTO books VALUES (105, 'Atomic Habits', 'James Clear', 'Self-Help', 2018, '978-0735211292', 8);
INSERT INTO books VALUES (106, 'The Seven Husbands of Evelyn Hugo', 'Taylor Jenkins Reid', 'Romance', 2017, '978-1501161933', 5);
INSERT INTO books VALUES (107, 'Where the Crawdads Sing', 'Delia Owens', 'Fiction', 2018, '978-0735219090', 7);
INSERT INTO books VALUES (108, 'The House in the Cerulean Sea', 'TJ Klune', 'Fantasy', 2020, '978-1250217318', 5);
INSERT INTO books VALUES (109, 'Sapiens', 'Yuval Noah Harari', 'Non-Fiction', 2011, '978-0062316097', 6);
INSERT INTO books VALUES (110, 'The Silent Patient', 'Alex Michaelides', 'Mystery', 2019, '978-1250301697', 4);

PRINT '10 books inserted!';
GO

-- Insert Book Loans
INSERT INTO book_loans VALUES (1, 1, 104, '2024-01-05', '2024-01-19', '2024-01-18');
INSERT INTO book_loans VALUES (2, 2, 103, '2024-01-08', '2024-01-22', '2024-01-25');
INSERT INTO book_loans VALUES (3, 3, 106, '2024-01-10', '2024-01-24', '2024-01-23');
INSERT INTO book_loans VALUES (4, 4, 102, '2024-01-12', '2024-01-26', '2024-02-02');
INSERT INTO book_loans VALUES (5, 1, 110, '2024-01-20', '2024-02-03', '2024-02-01');
INSERT INTO book_loans VALUES (6, 5, 105, '2024-01-22', '2024-02-05', NULL);
INSERT INTO book_loans VALUES (7, 6, 108, '2024-01-25', '2024-02-08', NULL);
INSERT INTO book_loans VALUES (8, 7, 101, '2024-01-28', '2024-02-11', NULL);
INSERT INTO book_loans VALUES (9, 8, 109, '2024-02-01', '2024-02-15', '2024-02-14');
INSERT INTO book_loans VALUES (10, 2, 107, '2024-02-03', '2024-02-17', NULL);
INSERT INTO book_loans VALUES (11, 3, 104, '2024-02-05', '2024-02-19', NULL);
INSERT INTO book_loans VALUES (12, 1, 107, '2024-01-15', '2024-01-29', '2024-01-27');

PRINT '12 book loans inserted!';
GO

-- Insert Events
INSERT INTO events VALUES (1, 'Mystery Book Club', 'Book Club', '2024-02-15', 20, 0.00, 'Monthly mystery book discussion. This month: The Thursday Murder Club');
INSERT INTO events VALUES (2, 'Author Meet & Greet: Local Author Sarah Kim', 'Author Visit', '2024-02-20', 50, 5.00, 'Meet bestselling local author Sarah Kim and get your books signed!');
INSERT INTO events VALUES (3, 'Teen Writing Workshop', 'Workshop', '2024-02-22', 15, 0.00, 'Creative writing workshop for teens led by published YA author');
INSERT INTO events VALUES (4, 'Digital Literacy for Seniors', 'Workshop', '2024-02-25', 12, 0.00, 'Learn to use e-readers, download library apps, and access digital books');
INSERT INTO events VALUES (5, 'Kids Story Time: Fantasy Adventures', 'Story Time', '2024-02-28', 30, 0.00, 'Interactive storytelling session for children ages 5-10');
INSERT INTO events VALUES (6, 'Science Fiction Discussion Group', 'Book Club', '2024-03-01', 15, 0.00, 'Discussing Project Hail Mary by Andy Weir');
INSERT INTO events VALUES (7, 'Resume Building Workshop', 'Workshop', '2024-03-05', 25, 0.00, 'Professional development: Create a winning resume');

PRINT '7 events inserted!';
GO

-- Insert Event Registrations
INSERT INTO event_registrations VALUES (1, 1, 1, '2024-02-01', 1, 5);
INSERT INTO event_registrations VALUES (2, 1, 3, '2024-02-03', 1, 4);
INSERT INTO event_registrations VALUES (3, 2, 1, '2024-02-05', 1, 5);
INSERT INTO event_registrations VALUES (4, 2, 8, '2024-02-06', 1, 5);
INSERT INTO event_registrations VALUES (5, 2, 3, '2024-02-07', 0, NULL);
INSERT INTO event_registrations VALUES (6, 3, 2, '2024-02-08', 1, 5);
INSERT INTO event_registrations VALUES (7, 3, 7, '2024-02-09', 1, 4);
INSERT INTO event_registrations VALUES (8, 4, 4, '2024-02-10', 1, 5);
INSERT INTO event_registrations VALUES (9, 5, 6, '2024-02-12', 1, 5);
INSERT INTO event_registrations VALUES (10, 6, 2, '2024-02-14', 0, NULL);
INSERT INTO event_registrations VALUES (11, 1, 8, '2024-02-02', 1, 4);
INSERT INTO event_registrations VALUES (12, 7, 5, '2024-02-20', 0, NULL);

PRINT '12 event registrations inserted!';
GO

-- Insert Book Reviews
INSERT INTO book_reviews VALUES (1, 104, 1, 5, 'Absolutely delightful mystery! The characters are charming and the plot keeps you guessing.', '2024-01-20', 12);
INSERT INTO book_reviews VALUES (2, 103, 2, 5, 'Best sci-fi book I have read in years. Could not put it down!', '2024-01-28', 8);
INSERT INTO book_reviews VALUES (3, 106, 3, 4, 'Beautiful love story with complex characters. Highly recommend!', '2024-01-25', 6);
INSERT INTO book_reviews VALUES (4, 102, 4, 5, 'Life-changing memoir. Tara Westover is an incredible writer.', '2024-02-05', 15);
INSERT INTO book_reviews VALUES (5, 110, 1, 4, 'Great psychological thriller with an amazing twist ending.', '2024-02-03', 7);
INSERT INTO book_reviews VALUES (6, 109, 8, 5, 'Mind-blowing perspective on human history. A must-read!', '2024-02-16', 10);
INSERT INTO book_reviews VALUES (7, 107, 1, 4, 'Beautifully written coming-of-age story set in the marshlands.', '2024-01-30', 9);
INSERT INTO book_reviews VALUES (8, 101, 7, 5, 'Philosophical and heartwarming. Made me think about life choices.', '2024-02-10', 5);

PRINT '8 book reviews inserted!';
GO

-- Insert Donations
INSERT INTO donations VALUES (1, 1, 50.00, '2024-01-15', 'Book Fund');
INSERT INTO donations VALUES (2, 4, 100.00, '2024-01-20', 'General Fund');
INSERT INTO donations VALUES (3, 8, 25.00, '2024-02-01', 'Youth Programs');
INSERT INTO donations VALUES (4, 1, 30.00, '2024-02-10', 'Book Fund');
INSERT INTO donations VALUES (5, 5, 75.00, '2024-02-15', 'Technology Upgrade');

PRINT '5 donations inserted!';
GO
