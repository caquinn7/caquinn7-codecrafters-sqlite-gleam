DROP TABLE IF EXISTS large_table;
DROP TABLE IF EXISTS small_table;

-- Create the first table with a small number of rows
CREATE TABLE small_table (
    id INTEGER PRIMARY KEY,
    name TEXT
);

-- Insert a few rows into the small_table to ensure it fits into a single leaf page
INSERT INTO small_table (name) VALUES ('Alice'), ('Bob'), ('Charlie'), ('Dave'), ('Eve');

-- Create the second table with a large number of rows to ensure it requires an interior page
CREATE TABLE large_table (
    id INTEGER PRIMARY KEY,
    description TEXT
);

-- Insert enough rows into the large_table to exceed the capacity of a single leaf page
-- Insert rows with random length descriptions (up to 10 characters)
-- WITH RECURSIVE
--     cnt(x) AS (SELECT 1 UNION ALL SELECT x+1 FROM cnt WHERE x < 100)
-- INSERT INTO large_table (description)
-- SELECT substr('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789', abs(random()) % 62 + 1, abs(random()) % 10 + 1)
-- FROM cnt;
WITH RECURSIVE
    cnt(x) AS (SELECT 1 UNION ALL SELECT x+1 FROM cnt WHERE x < 100)
INSERT INTO large_table (description)
SELECT 
    CASE 
        WHEN x % 5 = 1 THEN 'Short description ' || x
        WHEN x % 5 = 2 THEN 'Medium description ' || x || ' ' || x
        WHEN x % 5 = 3 THEN 'A longer description ' || x || ' ' || x || ' ' || x
        WHEN x % 5 = 4 THEN 'An even longer description with more text and numbers ' || x || ' ' || x || ' ' || x || ' ' || x
        ELSE 'A very long description that is significantly longer than the others and includes many repeated parts ' || x || ' ' || x || ' ' || x || ' ' || x || ' ' || x
    END
FROM cnt;
