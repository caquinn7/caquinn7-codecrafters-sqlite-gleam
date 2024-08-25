import db_info.{type DbInfo}
import file_streams/file_stream.{type FileStream}
import gleam/list
import gleam/option.{Some}
import gleam/result
import gleam/string
import page
import record/record.{TableRecord}
import record/record_value.{Text}
import result_set.{type ResultSet}
import sql/statement

pub fn db_info(stream: FileStream) -> DbInfo {
  stream
  |> db_info.read
}

pub fn tables(stream: FileStream) -> List(String) {
  let db_info = db_info.read(stream)

  stream
  |> page.read(number: 1, size: db_info.page_size)
  |> page.read_records(stream)
  |> list.filter_map(fn(rec) {
    let assert TableRecord(vals, _) = rec
    case vals {
      [Some(Text("table")), _, Some(Text(name)), ..] -> Ok(name)
      _ -> Error(Nil)
    }
  })
  |> list.sort(string.compare)
}

pub fn run_sql(stream: FileStream, str: String) -> Result(ResultSet, Nil) {
  str
  |> statement.from_string
  |> result.map(statement.execute(_, stream))
}
