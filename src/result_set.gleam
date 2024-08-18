import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string

pub opaque type ResultSet {
  ResultSet(List(Row))
}

type Row {
  Row(List(Option(String)))
}

pub fn new(rows: List(List(Option(String)))) -> Result(ResultSet, Nil) {
  // no rows should be empty
  // all rows should have the same length

  let expected_row_len =
    rows
    |> list.first
    |> result.unwrap(or: [])
    |> list.length

  let valid_rows =
    rows
    |> list.take_while(fn(r) { list.length(r) == expected_row_len })
    |> list.filter_map(row)

  case list.length(valid_rows) == list.length(rows) {
    True -> Ok(ResultSet(valid_rows))
    _ -> Error(Nil)
  }
}

fn row(vals: List(Option(String))) -> Result(Row, Nil) {
  case vals {
    [] -> Error(Nil)
    _ -> Ok(Row(vals))
  }
}

pub fn to_string(result_set: ResultSet) -> String {
  let row_to_string = fn(row) {
    let Row(unwrapped) = row
    unwrapped
    |> list.map(fn(col) {
      case col {
        Some(str) -> str
        None -> "NULL"
      }
    })
    |> string.join(" ")
  }

  let ResultSet(rows) = result_set
  rows
  |> list.map(row_to_string)
  |> string.join("\n")
}
