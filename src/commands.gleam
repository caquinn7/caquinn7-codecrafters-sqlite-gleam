import db_info.{type DbInfo}
import file_streams/file_stream.{type FileStream}
import gleam/list
import gleam/string
import page.{TableRecord}
import record_value.{Text}
import result_set.{type ResultSet}
import sql/sql_statement.{type SqlStatement}

pub fn db_info(stream: FileStream) -> DbInfo {
  stream
  |> db_info.read
}

pub fn tables(stream: FileStream) -> List(String) {
  let db_info = db_info.read(stream)

  stream
  |> page.read(1, db_info.page_size)
  |> page.read_records(stream)
  |> list.filter_map(fn(rec) {
    let assert TableRecord(vals, _) = rec
    case vals {
      [Text("table"), _, Text(name), ..] -> Ok(name)
      _ -> Error(Nil)
    }
  })
  |> list.sort(string.compare)
}

pub fn run_sql(stream: FileStream, sql_statement: SqlStatement) -> ResultSet {
  sql_statement
  |> sql_statement.execute(stream)
}
