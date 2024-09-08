import file_streams/file_stream.{type FileStream}
import gleam/bit_array
import gleam/erlang/atom.{type Atom}
import gleam/int
import gleam/iterator
import gleam/string
import gluid
import page.{IndexInteriorPage, TableInteriorPage}
import temporary

pub const resources_dir = "test/resources/"

pub const test_sql_file = "test/resources/test.sql"

pub const default_page_size = 4096

pub fn generate_db_path() {
  resources_dir <> gluid.guidv4() <> ".db"
}

pub fn generate_create_tables_sql(table_count: Int) {
  let create_table_sql = fn(table_name) {
    "create table "
    <> table_name
    <> " (id integer primary key, col text not null);"
  }

  iterator.range(1, table_count)
  |> iterator.map(fn(x) { create_table_sql("table" <> int.to_string(x)) })
  |> iterator.to_list
  |> string.join("")
}

pub fn page_is_interior(
  stream: FileStream,
  page_number: Int,
  page_size: Int,
) -> Bool {
  let page =
    stream
    |> page.read(page_number, page_size)

  case page {
    TableInteriorPage(..) | IndexInteriorPage(..) -> True
    _ -> False
  }
}

/// Create a temporary file with the desired contents
/// and call a function that takes the file path as an argument.
/// The file is automatically deleted when this function is done.
pub fn do_with_file(file_content, do: fn(String) -> a) {
  use file <- temporary.create(temporary.file())
  let assert Ok(stream) = file_stream.open_write(file)

  let bytes = file_content |> bit_array.from_string
  let assert Ok(_) = file_stream.write_bytes(stream, bytes)
  let assert Ok(_) = file_stream.close(stream)

  do(file)
}

/// Create a temporary sqlite db file,
/// execute a sql script against it,
/// open a stream to the db file,
/// and call a function that takes the stream as an argument.
/// The database is automatically deleted when this function is over.
pub fn do_with_temp_db2(sql_path, do: fn(FileStream) -> a) {
  // use file <- temporary.create(temporary.file())
  let assert Ok(_) =
    temporary.create(temporary.file(), fn(file) {
      do_with_temp_db3(file, sql_path, do)
    })
  Nil
}

/// Create a temporary sqlite db file at the given location,
/// execute a sql script against it,
/// open a stream to the db file,
/// and call a function that takes the stream as an argument.
/// The database is automatically deleted when this function is over.
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
