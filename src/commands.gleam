import db_info.{type DbInfo}
import file_streams/file_stream.{type FileStream}
import gleam/list
import gleam/option.{Some}
import gleam/result
import gleam/string
import page
import record.{TableRecord, Text}
import result_set.{type ResultSet}
import sql.{type ParseError}

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
    case rec {
      TableRecord(_, [Some(Text("table")), _, Some(Text(name)), ..]) -> Ok(name)
      _ -> Error(Nil)
    }
  })
  |> list.sort(string.compare)
}

pub fn run_sql(str: String, stream: FileStream) -> Result(ResultSet, ParseError) {
  str
  |> sql.statement
  |> result.map(sql.execute(_, stream))
}
