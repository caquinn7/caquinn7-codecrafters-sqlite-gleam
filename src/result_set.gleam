import gleam/list
import gleam/result
import gleam/string

pub opaque type ResultSet {
  ResultSet(List(Row))
}

type Row {
  Row(List(String))
}

pub fn new(rows: List(List(String))) -> Result(ResultSet, Nil) {
  // no rows should be empty
  // all rows should have the same length

  let expected_row_len =
    rows
    |> list.first
    |> result.unwrap(or: [])
    |> list.length

  let valid_rows =
    rows
    |> list.take_while(fn(vals) { list.length(vals) == expected_row_len })
    |> list.filter_map(fn(vals) {
      case vals {
        [] -> Error(Nil)
        _ -> Ok(Row(vals))
      }
    })

  case list.length(valid_rows) == list.length(rows) {
    True -> Ok(ResultSet(valid_rows))
    _ -> Error(Nil)
  }
}

pub fn unwrap(result_set: ResultSet) -> List(List(String)) {
  let ResultSet(rows) = result_set
  rows
  |> list.map(fn(row) {
    let Row(unwrapped) = row
    unwrapped
  })
}

pub fn to_string(result_set: ResultSet) -> String {
  let row_to_string = fn(row) {
    let Row(unwrapped) = row
    string.join(unwrapped, "|")
  }

  let ResultSet(rows) = result_set
  rows
  |> list.map(row_to_string)
  |> string.join("\n")
}
