import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import record_value.{
  BlobType, Integer, IntegerType, Real, RealType, Text, TextType,
}
import sql/sql_statement.{
  ColumnDefinition, Condition, CreateIndex, CreateTable, SelectCount,
  SelectValues, from_string,
}

pub fn main() {
  gleeunit.main()
}

// SelectValues

pub fn sql_statement_from_string_select_value_test() {
  "SELECT name FROM apples"
  |> from_string
  |> should.be_ok
  |> should.equal(SelectValues("apples", ["name"], None))
}

pub fn sql_statement_from_string_select_value_with_double_quoted_identifiers_test() {
  "SELECT \"name\" FROM \"apples\""
  |> from_string
  |> should.be_ok
  |> should.equal(SelectValues("apples", ["name"], None))
}

pub fn sql_statement_from_string_select_value_with_single_quoted_table_test() {
  "SELECT name FROM 'apples'"
  |> from_string
  |> should.be_ok
  |> should.equal(SelectValues("apples", ["name"], None))
}

pub fn sql_statement_from_string_select_value_with_single_quoted_column_test() {
  "SELECT 'name' FROM apples"
  |> from_string
  |> should.be_error
}

pub fn sql_statement_from_string_select_values_test() {
  "SELECT name, color FROM apples"
  |> from_string
  |> should.be_ok
  |> should.equal(SelectValues("apples", ["name", "color"], None))
}

// SelectValues with Condition

pub fn sql_statement_from_string_select_value_with_where_clause_with_single_quoted_str_test() {
  "SELECT name FROM apples WHERE color = 'Yellow'"
  |> from_string
  |> should.be_ok
  |> should.equal(SelectValues(
    "apples",
    ["name"],
    Some(Condition("color", Text("Yellow"))),
  ))
}

pub fn sql_statement_from_string_select_value_with_where_clause_with_double_quoted_str_test() {
  "SELECT name FROM apples WHERE color = \"Yellow\""
  |> from_string
  |> should.be_ok
  |> should.equal(SelectValues(
    "apples",
    ["name"],
    Some(Condition("color", Text("Yellow"))),
  ))
}

pub fn sql_statement_from_string_lowercase_select_value_with_where_clause_with_str_test() {
  "select name from apples where color = 'Yellow'"
  |> from_string
  |> should.be_ok
  |> should.equal(SelectValues(
    "apples",
    ["name"],
    Some(Condition("color", Text("Yellow"))),
  ))
}

pub fn sql_statement_from_string_select_value_with_where_clause_with_int_test() {
  "SELECT name FROM apples WHERE id = 1"
  |> from_string
  |> should.be_ok
  |> should.equal(SelectValues(
    "apples",
    ["name"],
    Some(Condition("id", Integer(1))),
  ))
}

pub fn sql_statement_from_string_select_value_with_where_clause_with_float_test() {
  "SELECT x FROM y WHERE z = 1.23"
  |> from_string
  |> should.be_ok
  |> should.equal(SelectValues("y", ["x"], Some(Condition("z", Real(1.23)))))
}

// SelectCount

pub fn sql_statement_from_string_select_count_test() {
  "SELECT COUNT(*) FROM fruit"
  |> from_string
  |> should.be_ok
  |> should.equal(SelectCount("fruit"))
}

// CreateTable

pub fn sql_statement_from_string_create_table_test() {
  "CREATE TABLE apples (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT,
    is_delicious INTEGER,
    weight REAL,
    photo BLOB
  )"
  |> from_string
  |> should.be_ok
  |> should.equal(
    CreateTable("apples", [
      ColumnDefinition("id", IntegerType, True, True, False),
      ColumnDefinition("name", TextType, False, False, False),
      ColumnDefinition("is_delicious", IntegerType, False, False, False),
      ColumnDefinition("weight", RealType, False, False, False),
      ColumnDefinition("photo", BlobType, False, False, False),
    ]),
  )
}

pub fn sql_statement_from_string_create_table_no_autoincrement_test() {
  "CREATE TABLE apples (id INTEGER PRIMARY KEY)"
  |> from_string
  |> should.be_ok
  |> should.equal(
    CreateTable("apples", [
      ColumnDefinition("id", IntegerType, True, False, False),
    ]),
  )
}

pub fn sql_statement_from_string_create_table_no_primary_key_test() {
  "CREATE TABLE apples (id integer)"
  |> from_string
  |> should.be_ok
  |> should.equal(
    CreateTable("apples", [
      ColumnDefinition("id", IntegerType, False, False, False),
    ]),
  )
}

pub fn sql_statement_from_string_create_table_one_column_with_primary_key_and_autoincrement_test() {
  "CREATE TABLE apples (id INTEGER PRIMARY KEY AUTOINCREMENT)"
  |> from_string
  |> should.be_ok
  |> should.equal(
    CreateTable("apples", [
      ColumnDefinition("id", IntegerType, True, True, False),
    ]),
  )
}

pub fn sql_statement_from_string_create_table_column_is_primary_key_autoincrement_not_null_test() {
  "CREATE TABLE apples (
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    name TEXT NOT NULL
  )"
  |> from_string
  |> should.be_ok
  |> should.equal(
    CreateTable("apples", [
      ColumnDefinition("id", IntegerType, True, True, True),
      ColumnDefinition("name", TextType, False, False, True),
    ]),
  )
}

pub fn sql_statement_from_string_double_quoted_identifiers_test() {
  "CREATE TABLE \"apples\" (
    \"name\" TEXT,
    \"is delicious\" INTEGER
  )"
  |> from_string
  |> should.be_ok
  |> should.equal(
    CreateTable("apples", [
      ColumnDefinition("name", TextType, False, False, False),
      ColumnDefinition("is delicious", IntegerType, False, False, False),
    ]),
  )
}

pub fn sql_statement_from_string_create_index_test() {
  "CREATE INDEX idx_companies_country ON companies (country)"
  |> from_string
  |> should.be_ok
  |> should.equal(CreateIndex("companies", "country"))
}
