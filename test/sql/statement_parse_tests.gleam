import gleeunit
import gleeunit/should
import sql/statement.{ColumnDefinition, CreateTable, SelectCount, SelectValues}

pub fn main() {
  gleeunit.main()
}

pub fn sql_statement_from_string_select_value_test() {
  "select name from apples"
  |> statement.from_string
  |> should.be_ok
  |> should.equal(SelectValues("apples", ["name"]))
}

pub fn sql_statement_from_string_select_values_test() {
  "select name, color from apples"
  |> statement.from_string
  |> should.be_ok
  |> should.equal(SelectValues("apples", ["name", "color"]))
}

pub fn sql_statement_from_string_select_count_test() {
  "select count(*) from fruit"
  |> statement.from_string
  |> should.be_ok
  |> should.equal(SelectCount("fruit"))
}

pub fn sql_statement_from_string_select_count_uppercase_test() {
  "SELECT COUNT(*) FROM FRUIT"
  |> statement.from_string
  |> should.be_ok
  |> should.equal(SelectCount("fruit"))
}

pub fn sql_statement_from_string_create_table_test() {
  "create table apples (
    id integer primary key autoincrement,
    name text,
    is_delicious boolean
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
  "create table apples (id integer primary key)"
  |> statement.from_string
  |> should.be_ok
  |> should.equal(
    CreateTable("apples", [ColumnDefinition("id", "integer", True, False)]),
  )
}

pub fn sql_statement_from_string_create_table_no_primary_key_test() {
  "create table apples (id integer)"
  |> statement.from_string
  |> should.be_ok
  |> should.equal(
    CreateTable("apples", [ColumnDefinition("id", "integer", False, False)]),
  )
}

pub fn sql_statement_from_string_create_table_one_column_with_primary_key_and_autoincrement_test() {
  "create table apples (id integer primary key autoincrement)"
  |> statement.from_string
  |> should.be_ok
  |> should.equal(
    CreateTable("apples", [ColumnDefinition("id", "integer", True, True)]),
  )
}
