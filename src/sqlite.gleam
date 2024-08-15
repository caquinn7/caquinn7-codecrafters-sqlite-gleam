import argv
import commands
import gleam/io

pub fn main() {
  let args = argv.load().arguments
  case args {
    [database_file_path, ".dbinfo", ..] -> commands.db_info(database_file_path)
    [database_file_path, ".tables", ..] -> commands.tables(database_file_path)
    _ -> "Unknown command"
  }
  |> io.println
}
