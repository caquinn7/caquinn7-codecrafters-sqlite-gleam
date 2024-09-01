import argv
import commands
import db_info
import file_streams/file_stream
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import result_set
import sql/sql_statement

pub fn main() {
  let args = argv.load().arguments
  args
  |> handle_args
  |> result.unwrap_both
  |> io.println
}

pub fn handle_args(args: List(String)) -> Result(String, String) {
  use db_path <- result.try(
    args
    |> list.first
    |> result.replace_error(
      "First argument should be the path to the database file",
    ),
  )

  use stream <- result.try(
    db_path
    |> file_stream.open_read
    |> result.map_error(fn(err) {
      "Error opening database file: " <> string.inspect(err)
    }),
  )

  let assert Ok(args) = list.rest(args)
  case args {
    [] -> "" |> Ok
    [".dbinfo", ..] -> stream |> commands.db_info |> db_info.to_string |> Ok
    [".tables", ..] -> stream |> commands.tables |> string.join(" ") |> Ok
    [str, ..] -> {
      str
      |> sql_statement.from_string
      |> result.replace_error("Expected sql but unable to parse input.")
      |> result.map(commands.run_sql(stream, _))
      |> result.map(result_set.to_string)
    }
  }
}
