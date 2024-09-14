import commands
import db_info.{DbInfo}
import gleam/list
import gleeunit
import gleeunit/should
import record_value.{Null}
import result_set
import sql/sql_statement
import utils

pub fn main() {
  gleeunit.main()
}

// These tests use utility methods that create temporary db files via os command.
// Wanted to try using in-memory dbs via sqlight library but it requires rebar
// which is not installed on the codecrafters servers.

pub fn db_info_command_leaf_schema_test() {
  use stream <- utils.do_with_temp_db2(utils.test_sql_file)
  stream
  |> commands.db_info
  |> should.equal(DbInfo(utils.default_page_size, 2))
}

pub fn db_info_command_interior_schema_test() {
  let expected_table_count = 50
  use sql_file <- utils.do_with_file(utils.generate_create_tables_sql(
    expected_table_count,
  ))
  use stream <- utils.do_with_temp_db2(sql_file)

  stream
  |> utils.page_is_interior(1, utils.default_page_size)
  |> should.be_true

  stream
  |> commands.db_info
  |> should.equal(DbInfo(utils.default_page_size, expected_table_count))
}

pub fn tables_command_test() {
  use stream <- utils.do_with_temp_db2(utils.test_sql_file)
  stream
  |> commands.tables
  |> should.equal(["employees", "sandwiches"])
}

pub fn run_sql_command_select_count_test() {
  use stream <- utils.do_with_temp_db2(utils.test_sql_file)
  "SELECT COUNT(*) FROM employees"
  |> sql_statement.from_string
  |> should.be_ok
  |> commands.run_sql(stream, _)
  |> result_set.unwrap
  |> should.equal([["10"]])
}

pub fn run_sql_command_select_value_test() {
  use stream <- utils.do_with_temp_db2(utils.test_sql_file)
  "SELECT first_name FROM employees"
  |> sql_statement.from_string
  |> should.be_ok
  |> commands.run_sql(stream, _)
  |> result_set.unwrap
  |> should.equal([
    ["John"],
    ["Jane"],
    ["Michael"],
    ["Emily"],
    ["Chris"],
    ["Patricia"],
    ["Robert"],
    ["Linda"],
    ["William"],
    ["Barbara"],
  ])
}

pub fn run_sql_command_select_values_test() {
  use stream <- utils.do_with_temp_db2(utils.test_sql_file)
  "SELECT last_name, salary, performance_score FROM employees"
  |> sql_statement.from_string
  |> should.be_ok
  |> commands.run_sql(stream, _)
  |> result_set.unwrap
  |> should.equal([
    ["Doe", "60000", "3.8"],
    ["Smith", "65000", "1.2"],
    ["Johnson", "70000", "2.7"],
    ["Davis", "72000", "4.2"],
    ["Brown", "68000", "3.1"],
    ["Wilson", "75000", "5"],
    ["Taylor", "64000", "2.5"],
    ["Anderson", "71000", "4.6"],
    ["Thomas", "69000", "3.4"],
    ["Martinez", "73000", "0.5"],
  ])
}

pub fn run_sql_command_select_values_null_value_test() {
  use stream <- utils.do_with_temp_db2(utils.test_sql_file)
  "SELECT name, category FROM sandwiches"
  |> sql_statement.from_string
  |> should.be_ok
  |> commands.run_sql(stream, _)
  |> result_set.unwrap
  |> list.find(fn(row) {
    list.any(row, fn(col) { col == "Kimchi Grilled Cheese" })
  })
  |> should.be_ok
  |> should.equal(["Kimchi Grilled Cheese", record_value.to_string(Null)])
}

pub fn run_sql_command_select_values_selecting_rowid_as_primary_key_test() {
  use stream <- utils.do_with_temp_db2(utils.test_sql_file)
  "SELECT id, last_name FROM employees"
  |> sql_statement.from_string
  |> should.be_ok
  |> commands.run_sql(stream, _)
  |> result_set.unwrap
  |> should.equal([
    ["1", "Doe"],
    ["2", "Smith"],
    ["3", "Johnson"],
    ["4", "Davis"],
    ["5", "Brown"],
    ["6", "Wilson"],
    ["7", "Taylor"],
    ["8", "Anderson"],
    ["9", "Thomas"],
    ["10", "Martinez"],
  ])
}

pub fn run_sql_command_select_values_with_where_clause_with_str_test() {
  use stream <- utils.do_with_temp_db2(utils.test_sql_file)
  "SELECT name FROM sandwiches WHERE category = 'Hot'"
  |> sql_statement.from_string
  |> should.be_ok
  |> commands.run_sql(stream, _)
  |> result_set.unwrap
  |> should.equal([["Roast Beef"], ["Tuna Melt"], ["Meatball Sub"]])
}

pub fn run_sql_command_select_values_with_where_clause_with_int_test() {
  use stream <- utils.do_with_temp_db2(utils.test_sql_file)
  "SELECT name FROM sandwiches WHERE count = 5"
  |> sql_statement.from_string
  |> should.be_ok
  |> commands.run_sql(stream, _)
  |> result_set.unwrap
  |> should.equal([["Chicken Salad"], ["Kimchi Grilled Cheese"]])
}

pub fn run_sql_command_select_values_with_rowid_as_filter_test() {
  use stream <- utils.do_with_temp_db2(utils.test_sql_file)
  "SELECT last_name FROM employees WHERE id = 5"
  |> sql_statement.from_string
  |> should.be_ok
  |> commands.run_sql(stream, _)
  |> result_set.unwrap
  |> should.equal([["Brown"]])
}
