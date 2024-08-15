CREATE TABLE sandwiches (
    id INTEGER PRIMARY KEY,
    [name] TEXT,
    -- [length] REAL,
    count INTEGER
);

INSERT INTO sandwiches (name, count) VALUES ('Turkey Club', 10);
INSERT INTO sandwiches (name, count) VALUES ('Ham and Cheese', 15);
INSERT INTO sandwiches (name, count) VALUES ('BLT', 8);
INSERT INTO sandwiches (name, count) VALUES ('Veggie Delight', 12);
INSERT INTO sandwiches (name, count) VALUES ('Chicken Salad', 5);
INSERT INTO sandwiches (name, count) VALUES ('Roast Beef', 20);
INSERT INTO sandwiches (name, count) VALUES ('Tuna Melt', 7);
INSERT INTO sandwiches (name, count) VALUES ('Meatball Sub', 4);
INSERT INTO sandwiches (name, count) VALUES ('Italian Sub', 6);
INSERT INTO sandwiches (name, count) VALUES ('Egg Salad', 11);

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

