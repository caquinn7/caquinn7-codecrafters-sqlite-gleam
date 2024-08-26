import file_streams/file_stream.{type FileStream, BeginningOfFile}
import gleam/int
import gleam/list
import page
import record/record.{TableRecord}
import record/record_value.{Text}

pub type DbInfo {
  DbInfo(page_size: Int, table_count: Int)
}

pub fn read(stream: FileStream) -> DbInfo {
  let assert Ok(_) = file_stream.position(stream, BeginningOfFile(16))
  let assert Ok(page_size) = file_stream.read_uint16_be(stream)

  let table_count =
    stream
    |> page.read(number: 1, size: 4096)
    |> page.read_records(stream)
    |> list.count(fn(rec) {
      case rec {
        TableRecord([Text("table"), ..], _) -> True
        _ -> False
      }
    })

  DbInfo(page_size, table_count)
}

pub fn to_string(db_info: DbInfo) -> String {
  "database page size: "
  <> int.to_string(db_info.page_size)
  <> "\n"
  <> "number of tables: "
  <> int.to_string(db_info.table_count)
}
