import commands
import db_info.{DbInfo}
import file_streams/file_stream.{type FileStream}
import gleam/bit_array
import gleam/erlang/atom.{type Atom}
import gleam/int
import gleam/io
import gleam/iterator
import gleam/string
import gleeunit
import gleeunit/should
import gluid
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

  let sql_bytes = sql |> bit_array.from_string
  let assert Ok(_) = file_stream.write_bytes(stream, sql_bytes)
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
