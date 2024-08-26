import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import sql/statement.{
  ColumnDefinition, Condition, CreateTable, SelectCount, SelectValues,
}

pub fn main() {
  gleeunit.main()
}

// SelectValues

pub fn sql_statement_from_string_select_value_test() {
  "SELECT name FROM apples"
  |> statement.from_string
  |> should.be_ok
  |> should.equal(SelectValues("apples", ["name"], None))
}

pub fn sql_statement_from_string_select_values_test() {
  "SELECT name, color FROM apples"
  |> statement.from_string
  |> should.be_ok
  |> should.equal(SelectValues("apples", ["name", "color"], None))
}

pub fn sql_statement_from_string_select_value_with_where_clause_with_str_test() {
  "SELECT name FROM apples WHERE color = 'Yellow'"
  |> statement.from_string
  |> should.be_ok
  |> should.equal(SelectValues(
    "apples",
    ["name"],
    Some(Condition("color", "Yellow")),
  ))
}

pub fn sql_statement_from_string_lowercase_select_value_with_where_clause_with_str_test() {
  "select name from apples where color = 'Yellow'"
  |> statement.from_string
  |> should.be_ok
  |> should.equal(SelectValues(
    "apples",
    ["name"],
    Some(Condition("color", "Yellow")),
  ))
}

pub fn sql_statement_from_string_select_value_with_where_clause_with_int_test() {
  "SELECT name FROM apples WHERE id = 1"
  |> statement.from_string
  |> should.be_ok
  |> should.equal(SelectValues("apples", ["name"], Some(Condition("id", "1"))))
}

pub fn sql_statement_from_string_select_value_with_where_clause_with_float_test() {
  "SELECT x FROM y WHERE z = 1.23"
  |> statement.from_string
  |> should.be_ok
  |> should.equal(SelectValues("y", ["x"], Some(Condition("z", "1.23"))))
}

// SelectCount

pub fn sql_statement_from_string_select_count_test() {
  "SELECT COUNT(*) FROM fruit"
  |> statement.from_string
  |> should.be_ok
  |> should.equal(SelectCount("fruit"))
}

// CreateTable

pub fn sql_statement_from_string_create_table_test() {
  "CREATE TABLE apples (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT,
    is_delicious BOOLEAN
  )"
  |> statement.from_string
  |> should.be_ok
  |> should.equal(
    CreateTable("apples", [
      ColumnDefinition("id", "integer", True, True),
      ColumnDefinition("name", "text", False, False),
      ColumnDefinition("is_delicious", "boolean", False, False),
    ]),
  )
}

pub fn sql_statement_from_string_create_table_no_autoincrement_test() {
  "CREATE TABLE apples (id INTEGER PRIMARY KEY)"
  |> statement.from_string
  |> should.be_ok
  |> should.equal(
    CreateTable("apples", [ColumnDefinition("id", "integer", True, False)]),
  )
}

pub fn sql_statement_from_string_create_table_no_primary_key_test() {
  "CREATE TABLE apples (id integer)"
  |> statement.from_string
  |> should.be_ok
  |> should.equal(
    CreateTable("apples", [ColumnDefinition("id", "integer", False, False)]),
  )
}

pub fn sql_statement_from_string_create_table_one_column_with_primary_key_and_autoincrement_test() {
  "CREATE TABLE apples (id integer primary key autoincrement)"
  |> statement.from_string
  |> should.be_ok
  |> should.equal(
    CreateTable("apples", [ColumnDefinition("id", "integer", True, True)]),
  )
}
