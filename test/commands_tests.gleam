import commands
import db_info.{DbInfo}
import file_streams/file_stream.{type FileStream}
import gleam/bit_array
import gleam/erlang/atom.{type Atom}
import gleam/int
import gleam/io
import gleam/iterator
import gleam/list
import gleam/string
import gleeunit
import gleeunit/should
import gluid
import record/record_value.{Null}
import result_set
import temporary

pub fn main() {
  gleeunit.main()
}

const resources_dir = "test/resources/"

const test_sql_file = "test/resources/test.sql"

pub fn db_info_command_leaf_schema_test() {
  let db_path = generate_db_path()
  use stream <- do_with_temp_db(db_path, test_sql_file)
  stream
  |> commands.db_info
  |> should.equal(DbInfo(4096, 2))
}

pub fn db_info_command_interior_schema_test() {
  let db_path = generate_db_path()
  use sql_file <- do_with_sql(generate_interior_schema_sql())
  use stream <- do_with_temp_db(db_path, sql_file)
  stream
  |> commands.db_info
  |> should.equal(DbInfo(4096, 100))
}

pub fn tables_command_test() {
  let db_path = generate_db_path()
  use stream <- do_with_temp_db(db_path, test_sql_file)
  stream
  |> commands.tables
  |> should.equal(["employees", "sandwiches"])
}

pub fn run_sql_command_select_count_test() {
  let db_path = generate_db_path()
  use stream <- do_with_temp_db(db_path, test_sql_file)
  stream
  |> commands.run_sql("SELECT COUNT(*) FROM employees")
  |> should.be_ok
  |> result_set.unwrap
  |> should.equal([["10"]])
}

pub fn run_sql_command_select_value_test() {
  let db_path = generate_db_path()
  use stream <- do_with_temp_db(db_path, test_sql_file)
  stream
  |> commands.run_sql("SELECT first_name FROM employees")
  |> should.be_ok
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
  let db_path = generate_db_path()
  use stream <- do_with_temp_db(db_path, test_sql_file)
  stream
  |> commands.run_sql("SELECT last_name, salary, is_manager FROM employees")
  |> should.be_ok
  |> result_set.unwrap
  |> should.equal([
    ["Doe", "60000", "0"],
    ["Smith", "65000", "1"],
    ["Johnson", "70000", "0"],
    ["Davis", "72000", "1"],
    ["Brown", "68000", "0"],
    ["Wilson", "75000", "1"],
    ["Taylor", "64000", "0"],
    ["Anderson", "71000", "0"],
    ["Thomas", "69000", "1"],
    ["Martinez", "73000", "0"],
  ])
}

pub fn run_sql_command_select_values_null_value_test() {
  let db_path = generate_db_path()
  use stream <- do_with_temp_db(db_path, test_sql_file)
  stream
  |> commands.run_sql("SELECT name, category FROM sandwiches")
  |> should.be_ok
  |> result_set.unwrap
  |> list.find(fn(row) {
    list.any(row, fn(col) { col == "Kimchi Grilled Cheese" })
  })
  |> should.be_ok
  |> should.equal(["Kimchi Grilled Cheese", record_value.to_string(Null)])
}

pub fn run_sql_command_select_values_with_where_clause_with_str_test() {
  let db_path = generate_db_path()
  use stream <- do_with_temp_db(db_path, test_sql_file)
  stream
  |> commands.run_sql("SELECT name FROM sandwiches WHERE category = 'Hot'")
  |> should.be_ok
  |> result_set.unwrap
  |> should.equal([["Roast Beef"], ["Tuna Melt"], ["Meatball Sub"]])
}

pub fn run_sql_command_select_values_with_where_clause_with_int_test() {
  let db_path = generate_db_path()
  use stream <- do_with_temp_db(db_path, test_sql_file)
  stream
  |> commands.run_sql("SELECT name FROM sandwiches WHERE count = 5")
  |> should.be_ok
  |> result_set.unwrap
  |> should.equal([["Chicken Salad"], ["Kimchi Grilled Cheese"]])
}

fn generate_db_path() {
  resources_dir <> gluid.guidv4()
}

fn generate_interior_schema_sql() {
  let create_table_sql = fn(table_name) {
    "create table "
    <> table_name
    <> " (id integer primary key, col text not null);"
  }

  iterator.range(1, 100)
  |> iterator.map(fn(x) { create_table_sql("table" <> int.to_string(x)) })
  |> iterator.to_list
  |> string.join("")
}

fn do_with_sql(sql, do: fn(String) -> a) {
  use file <- temporary.create(temporary.file())
  let assert Ok(stream) = file_stream.open_write(file)

  let bytes = sql |> bit_array.from_string
  let assert Ok(_) = file_stream.write_bytes(stream, bytes)
  let assert Ok(_) = file_stream.close(stream)

  do(file)
}

fn do_with_temp_db(db_path, sql_path, do: fn(FileStream) -> a) {
  let create_db_cmd =
    atom.create_from_string("sqlite3 " <> db_path <> " < " <> sql_path)

  os_cmd(create_db_cmd) |> io.println_error

  let assert Ok(stream) = file_stream.open_read(db_path)
  do(stream)

  os_cmd(atom.create_from_string("rm " <> db_path)) |> io.println_error
}

@external(erlang, "os", "cmd")
fn os_cmd(cmd: Atom) -> String
