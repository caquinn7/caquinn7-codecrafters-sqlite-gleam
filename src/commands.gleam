import db_info
import file_streams/file_stream
import gleam/list
import gleam/option.{Some}
import gleam/string
import page
import record.{TableRecord, Text}

pub fn db_info(database_file_path: String) -> String {
  let assert Ok(stream) = file_stream.open_read(database_file_path)
  stream
  |> db_info.read
  |> db_info.to_string
}

pub fn tables(database_file_path: String) -> String {
  let assert Ok(stream) = file_stream.open_read(database_file_path)
  let db_info = db_info.read(stream)

  stream
  |> page.read(number: 1, size: db_info.page_size)
  |> page.read_records(stream)
  |> list.filter_map(fn(rec) {
    case rec {
      TableRecord(_, [Some(Text("table")), _, Some(Text(name)), ..]) -> Ok(name)
      _ -> Error(Nil)
    }
  })
  |> list.sort(string.compare)
  |> string.join(" ")
}
