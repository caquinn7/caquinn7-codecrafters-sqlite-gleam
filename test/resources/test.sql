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
    performance_score REAL
);

CREATE INDEX idx_last_name ON employees(last_name);

INSERT INTO employees (first_name, last_name, salary, performance_score) VALUES ('John', 'Doe', 60000, 3.8);
INSERT INTO employees (first_name, last_name, salary, performance_score) VALUES ('Jane', 'Smith', 65000, 1.2);
INSERT INTO employees (first_name, last_name, salary, performance_score) VALUES ('Michael', 'Johnson', 70000, 2.7);
INSERT INTO employees (first_name, last_name, salary, performance_score) VALUES ('Emily', 'Davis', 72000, 4.2);
INSERT INTO employees (first_name, last_name, salary, performance_score) VALUES ('Chris', 'Brown', 68000, 3.1);
INSERT INTO employees (first_name, last_name, salary, performance_score) VALUES ('Patricia', 'Wilson', 75000, 5.0);
INSERT INTO employees (first_name, last_name, salary, performance_score) VALUES ('Robert', 'Taylor', 64000, 2.5);
INSERT INTO employees (first_name, last_name, salary, performance_score) VALUES ('Linda', 'Anderson', 71000, 4.6);
INSERT INTO employees (first_name, last_name, salary, performance_score) VALUES ('William', 'Thomas', 69000, 3.4);
INSERT INTO employees (first_name, last_name, salary, performance_score) VALUES ('Barbara', 'Martinez', 73000, 0.5);

