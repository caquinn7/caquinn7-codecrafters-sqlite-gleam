import file_streams/file_stream.{type FileStream}
import gleam/bit_array
import gleam/erlang/atom.{type Atom}
import gleam/int
import gleam/iterator
import gleam/string
import gluid
import temporary

pub const resources_dir = "test/resources/"

pub const test_sql_file = "test/resources/test.sql"

pub fn generate_db_path() {
  resources_dir <> gluid.guidv4() <> ".db"
}

pub fn generate_interior_schema_sql() {
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

pub fn do_with_sql(sql, do: fn(String) -> a) {
  use file <- temporary.create(temporary.file())
  let assert Ok(stream) = file_stream.open_write(file)

  let bytes = sql |> bit_array.from_string
  let assert Ok(_) = file_stream.write_bytes(stream, bytes)
  let assert Ok(_) = file_stream.close(stream)

  do(file)
}

pub fn do_with_temp_db2(sql_path, do: fn(FileStream) -> a) {
  use file <- temporary.create(temporary.file())
  do_with_temp_db3(file, sql_path, do)
}

pub fn do_with_temp_db3(db_path, sql_path, do: fn(FileStream) -> a) {
  let create_db_cmd =
    atom.create_from_string("sqlite3 " <> db_path <> " < " <> sql_path)

  os_cmd(create_db_cmd)

  let assert Ok(stream) = file_stream.open_read(db_path)
  do(stream)

  os_cmd(atom.create_from_string("rm " <> db_path))
  Nil
}

@external(erlang, "os", "cmd")
fn os_cmd(cmd: Atom) -> String
