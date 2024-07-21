import argv
import db_info
import gleam/int.{to_string}
import gleam/io

pub fn main() {
  let args = argv.load().arguments
  case args {
    [database_file_path, ".dbinfo", ..] -> {
      let db_info = db_info.new(database_file_path)

      io.println("database page size: " <> to_string(db_info.page_size))
      io.println("number of tables: " <> to_string(db_info.table_count))
    }
    _ -> {
      io.println("Unknown command")
    }
  }
}
