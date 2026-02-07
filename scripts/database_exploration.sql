/*===================
DATABASE EXPLORATION
====================*/
-- List all tables and row counts

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    SUM(p.rows) AS row_count
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.partitions p ON t.object_id = p.object_id
WHERE p.index_id IN (0,1)
GROUP BY s.name, t.name
ORDER BY row_count DESC;

-- See columns + data types

SELECT 
    TABLE_SCHEMA,
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
ORDER BY TABLE_SCHEMA, TABLE_NAME, ORDINAL_POSITION;

-- Retrieve all columns for a specific table

SELECT 
    COLUMN_NAME, 
    DATA_TYPE, 
    IS_NULLABLE, 
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'books';


-- See PK

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name
FROM sys.indexes i
JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
JOIN sys.tables t ON i.object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE i.is_primary_key = 1
ORDER BY schema_name, table_name;


-- See FK relationships

SELECT 
    OBJECT_NAME(fk.parent_object_id) AS [From Table],
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS [Column],
    OBJECT_NAME(fk.referenced_object_id) AS [To Table]
FROM sys.foreign_keys AS fk
INNER JOIN sys.foreign_key_columns AS fkc ON fk.object_id = fkc.constraint_object_id;

-- Sample data

SELECT TOP 3 * FROM members;
SELECT TOP 3 * FROM books;
SELECT TOP 3 * FROM book_loans;
SELECT TOP 3 * FROM book_reviews;
SELECT TOP 3 * FROM donations;
SELECT TOP 3 * FROM event_registrations;
SELECT TOP 3 * FROM events;



