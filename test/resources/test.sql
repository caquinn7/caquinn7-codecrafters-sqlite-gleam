-- CREATE TABLE sandwiches (
--     id INTEGER PRIMARY KEY,
--     [name] TEXT,
--     [length] REAL,
--     count INTEGER
-- );
CREATE TABLE sandwiches (
    id INTEGER PRIMARY KEY,
    name TEXT,
    count INTEGER,
    category TEXT
);

INSERT INTO sandwiches (name, count, category) VALUES ('Turkey Club', 10, 'Cold');
INSERT INTO sandwiches (name, count, category) VALUES ('Ham and Cheese', 15, 'Cold');
INSERT INTO sandwiches (name, count, category) VALUES ('BLT', 8, 'Cold');
INSERT INTO sandwiches (name, count, category) VALUES ('Veggie Delight', 12, 'Vegetarian');
INSERT INTO sandwiches (name, count, category) VALUES ('Chicken Salad', 5, 'Cold');
INSERT INTO sandwiches (name, count, category) VALUES ('Roast Beef', 20, 'Hot');
INSERT INTO sandwiches (name, count, category) VALUES ('Tuna Melt', 7, 'Hot');
INSERT INTO sandwiches (name, count, category) VALUES ('Meatball Sub', 4, 'Hot');
INSERT INTO sandwiches (name, count, category) VALUES ('Italian Sub', 6, 'Cold');
INSERT INTO sandwiches (name, count, category) VALUES ('Egg Salad', 11, 'Cold');
INSERT INTO sandwiches (name, count, category) VALUES ('Kimchi Grilled Cheese', 5, NULL);

CREATE TABLE employees (
    id INTEGER PRIMARY KEY,
    first_name TEXT,
    last_name TEXT,
    salary INTEGER,
    is_manager BOOLEAN
);

CREATE INDEX idx_last_name ON employees(last_name);

INSERT INTO employees (first_name, last_name, salary, is_manager) VALUES ('John', 'Doe', 60000, FALSE);
INSERT INTO employees (first_name, last_name, salary, is_manager) VALUES ('Jane', 'Smith', 65000, TRUE);
INSERT INTO employees (first_name, last_name, salary, is_manager) VALUES ('Michael', 'Johnson', 70000, FALSE);
INSERT INTO employees (first_name, last_name, salary, is_manager) VALUES ('Emily', 'Davis', 72000, TRUE);
INSERT INTO employees (first_name, last_name, salary, is_manager) VALUES ('Chris', 'Brown', 68000, FALSE);
INSERT INTO employees (first_name, last_name, salary, is_manager) VALUES ('Patricia', 'Wilson', 75000, TRUE);
INSERT INTO employees (first_name, last_name, salary, is_manager) VALUES ('Robert', 'Taylor', 64000, FALSE);
INSERT INTO employees (first_name, last_name, salary, is_manager) VALUES ('Linda', 'Anderson', 71000, FALSE);
INSERT INTO employees (first_name, last_name, salary, is_manager) VALUES ('William', 'Thomas', 69000, TRUE);
INSERT INTO employees (first_name, last_name, salary, is_manager) VALUES ('Barbara', 'Martinez', 73000, FALSE);

