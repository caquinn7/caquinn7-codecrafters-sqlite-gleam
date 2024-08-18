import db_info
import file_streams/file_stream.{type FileStream}
import gleam/int
import gleam/list
import gleam/option.{Some}
import gleam/result
import gleam/string
import page
import record.{Integer, TableRecord, Text}
import result_set.{type ResultSet}

pub opaque type Statement {
  Count(table: String)
  Select(table: String, columns: List(String))
}

pub type ParseError {
  Syntax
  NoSuchTable(String)
  NoSuchColumn(String)
}

pub fn statement(str: String) -> Result(Statement, ParseError) {
  let validate = fn(stmt: Statement) { Ok(stmt) }

  let parse =
    str
    |> string.lowercase
    |> string.split(" ")
    |> list.filter(fn(s) { s != "" })
    |> fn(tokens) {
      case tokens {
        ["select", "count(*)", "from", table] -> Ok(Count(table))
        _ -> Error(Syntax)
      }
    }

  parse
  |> result.try(validate)
}

pub fn execute(statement: Statement, stream: FileStream) -> ResultSet {
  case statement {
    Count(table) -> {
      let db_info = db_info.read(stream)

      let target_page_number = case
        stream
        |> page.read(1, db_info.page_size)
        |> page.read_records(stream)
        |> list.filter_map(fn(rec) {
          case rec {
            TableRecord(
              _,
              [
                Some(Text("table")),
                _,
                Some(Text(t)),
                Some(Integer(page_number)),
                ..
              ],
            )
              if t == table
            -> Ok(page_number)
            _ -> Error(Nil)
          }
        })
        |> list.first
      {
        Ok(target_page_number) -> target_page_number
        _ -> panic as "page number not found for table"
      }

      let count =
        stream
        |> page.read(target_page_number, db_info.page_size)
        |> page.count_records
        |> int.to_string

      let assert Ok(r) = result_set.new([[Some(count)]])
      r
    }

    Select(table, cols) -> todo
  }
}
