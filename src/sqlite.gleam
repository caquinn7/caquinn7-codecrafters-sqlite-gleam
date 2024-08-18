import argv
import commands
import db_info
import file_streams/file_stream
import gleam/io
import gleam/result
import gleam/string
import result_set
import sql

pub fn main() {
  let args = argv.load().arguments

  let assert [database_file_path, ..] = args
  let assert Ok(stream) = file_stream.open_read(database_file_path)

  case args {
    [_, ".dbinfo", ..] ->
      stream
      |> commands.db_info
      |> db_info.to_string

    [_, ".tables", ..] ->
      stream
      |> commands.tables
      |> string.join(" ")

    [_, str] -> {
      str
      |> commands.run_sql(stream)
      |> result.map(result_set.to_string)
      |> result.map_error(fn(err) {
        case err {
          sql.Syntax -> todo
          sql.NoSuchTable(table) -> todo
          sql.NoSuchColumn(column) -> todo
        }
      })
      |> result.unwrap_both
    }

    _ -> "Unknown command"
  }
  |> io.println
}
