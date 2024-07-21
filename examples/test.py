import sqlite3
import os
import sys

def get_create_table_statement(table_num):
    table_name = 'table' + str(table_num)
    return f'''
    CREATE TABLE {table_name} (
        id INTEGER PRIMARY KEY,
        col TEXT NOT NULL
    );
    '''

def get_script(table_count):
    table_statements = [
        get_create_table_statement(i + 1)
        for i in range(table_count)
    ]
    return 'BEGIN TRANSACTION;\n' + ''.join(table_statements) + '\nCOMMIT;'

def create_database(db_name, table_count):
    # Delete the database file if it exists
    if os.path.exists(db_name):
        os.remove(db_name)
        print(f"Deleted existing database file '{db_name}'.")

    # Connect to the SQLite database (it will be created if it doesn't exist)
    conn = sqlite3.connect(db_name)
    cursor = conn.cursor()
    script = get_script(table_count)
    try:
        cursor.executescript(script)
    except sqlite3.Error as e:
        print(f"An error occurred: {e}")

    conn.commit()
    conn.close()

if __name__ == "__main__":
    db_name = sys.argv[1]
    table_count = int(sys.argv[2])
    create_database(db_name, table_count)

