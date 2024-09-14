import db_info
import file_streams/file_stream.{type FileStream}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/regex
import gleam/result
import gleam/string
import list_utils
import nibble.{
  type Parser, backtrackable, do, map, one_of, optional, return, sequence, token,
}
import nibble/lexer
import page.{type Record, IndexRecord, TableRecord}
import record_value.{type RecordValue, type RecordValueType, Integer, Real, Text}
import result_set.{type ResultSet}
import sql/token as sql_token

pub type SqlStatement {
  SelectCount(table: String)
  SelectValues(table: String, columns: List(String), Option(Condition))
  CreateTable(table: String, columns: List(ColumnDefinition))
  CreateIndex(table: String, column: String)
}

pub type Condition {
  Condition(column: String, value: RecordValue)
}

pub type ColumnDefinition {
  ColumnDefinition(
    name: String,
    data_type: RecordValueType,
    is_primary_key: Bool,
    is_auto_increment: Bool,
    is_not_null: Bool,
  )
}

pub fn from_string(input: String) -> Result(SqlStatement, Nil) {
  let to_lowercase = fn(str) {
    let assert Ok(re) = regex.from_string("(['\"].*?['\"])")
    re
    |> regex.split(str)
    |> list.map(fn(part) {
      // Convert to lowercase for everything outside of single quotes
      let is_quoted = {
        let is_single_quoted =
          string.starts_with(part, "'") && string.ends_with(part, "'")
        let is_double_quoted =
          string.starts_with(part, "\"") && string.ends_with(part, "\"")
        is_single_quoted || is_double_quoted
      }
      case is_quoted {
        True -> part
        _ -> string.lowercase(part)
      }
    })
    |> string.join("")
  }

  use tokens <- result.try(
    input
    |> to_lowercase
    |> lexer.run(sql_token.lexer())
    |> result.map_error(io.debug)
    |> result.replace_error(Nil),
  )
  use statement <- result.try(
    tokens
    |> nibble.run(sql_parser())
    |> result.map_error(io.debug)
    |> result.replace_error(Nil),
  )
  Ok(statement)
}

fn sql_parser() -> Parser(SqlStatement, sql_token.SqlToken, a) {
  let identifier_parser = {
    use tok <- nibble.take_map("identifier")
    case tok {
      sql_token.Identifier(s) -> Some(s)
      _ -> None
    }
  }

  let string_double_quoted_parser = {
    use tok <- nibble.take_map("string with double quotes")
    case tok {
      sql_token.StringDoubleQuoted(s) -> Some(s)
      _ -> None
    }
  }

  let string_single_quoted_parser = {
    use tok <- nibble.take_map("string with single quotes")
    case tok {
      sql_token.StringSingleQuoted(s) -> Some(s)
      _ -> None
    }
  }

  let column_name_parser = {
    one_of([identifier_parser, string_double_quoted_parser])
  }

  let table_name_parser = {
    one_of([
      identifier_parser,
      string_single_quoted_parser,
      string_double_quoted_parser,
    ])
  }

  let select_count_parser = {
    use _ <- do(token(sql_token.Select))
    use _ <- do(token(sql_token.Count))
    use _ <- do(token(sql_token.ParenL))
    use _ <- do(token(sql_token.Asterisk))
    use _ <- do(token(sql_token.ParenR))
    use _ <- do(token(sql_token.From))
    use target_table_name <- do(table_name_parser)
    return(SelectCount(target_table_name))
  }

  let condition_parser = {
    let str_parser = {
      use tok <- nibble.take_map("string with either double or single quotes")
      case tok {
        sql_token.StringSingleQuoted(s) -> Some(Text(s))
        sql_token.StringDoubleQuoted(s) -> Some(Text(s))
        _ -> None
      }
    }

    let num_parser = {
      use tok <- nibble.take_map("integer")
      case tok {
        sql_token.Integer(n) -> Some(Integer(n))
        sql_token.Real(n) -> Some(Real(n))
        _ -> None
      }
    }

    use _ <- do(token(sql_token.Where))
    use col <- do(column_name_parser)
    use _ <- do(token(sql_token.Equals))
    use val <- do(one_of([str_parser, num_parser]))
    return(Condition(col, val))
  }

  let select_values_parser = {
    use _ <- do(token(sql_token.Select))
    use target_column_names <- do(sequence(
      column_name_parser,
      token(sql_token.Comma),
    ))
    use _ <- do(token(sql_token.From))
    use target_table_name <- do(table_name_parser)
    use cond <- do(optional(condition_parser))
    return(SelectValues(target_table_name, target_column_names, cond))
  }

  let create_table_parser = {
    let data_type_parser = {
      use tok <- nibble.take_map("name of a datatype")
      case tok {
        sql_token.TypeInteger -> Some(record_value.IntegerType)
        sql_token.TypeReal -> Some(record_value.RealType)
        sql_token.TypeText -> Some(record_value.TextType)
        _ -> None
      }
    }

    let column_definition_parser = {
      use name <- do(column_name_parser)
      use data_type <- do(data_type_parser)
      use is_pk <- do(map(optional(token(sql_token.PrimaryKey)), option.is_some))
      use is_auto_incr <- do(map(
        optional(token(sql_token.AutoIncrement)),
        option.is_some,
      ))
      use is_not_null <- do(map(
        optional(token(sql_token.NotNull)),
        option.is_some,
      ))
      return(ColumnDefinition(name, data_type, is_pk, is_auto_incr, is_not_null))
    }

    use _ <- do(token(sql_token.Create))
    use _ <- do(token(sql_token.Table))
    use target_table_name <- do(table_name_parser)
    use _ <- do(token(sql_token.ParenL))
    use column_definitions <- do(sequence(
      column_definition_parser,
      token(sql_token.Comma),
    ))
    use _ <- do(token(sql_token.ParenR))
    return(CreateTable(target_table_name, column_definitions))
  }

  let create_index_parser = {
    use _ <- do(token(sql_token.Create))
    use _ <- do(token(sql_token.Index))
    use _index_name <- do(table_name_parser)
    use _ <- do(token(sql_token.On))
    use target_table_name <- do(table_name_parser)
    use _ <- do(token(sql_token.ParenL))
    use column_name <- do(column_name_parser)
    use _ <- do(token(sql_token.ParenR))
    return(CreateIndex(target_table_name, column_name))
  }

  one_of([
    backtrackable(select_values_parser),
    select_count_parser,
    backtrackable(create_table_parser),
    create_index_parser,
  ])
}

pub fn execute(statement: SqlStatement, stream: FileStream) -> ResultSet {
  let page_size = db_info.read(stream).page_size

  case statement {
    SelectCount(table) -> execute_select_count(stream, page_size, table)
    SelectValues(table, target_column_names, condition) ->
      execute_select_values(
        stream,
        page_size,
        table,
        target_column_names,
        condition,
      )
    _ -> todo
  }
}

fn execute_select_count(stream, page_size, target_table_name) {
  let schema_record =
    get_schema_record_for_table(stream, page_size, target_table_name)

  let assert Ok(TableRecord([_, _, _, Integer(page_number), _], _)) =
    schema_record

  let count =
    stream
    |> page.read(page_number, page_size)
    |> page.count_records(stream)
    |> int.to_string

  let assert Ok(result_set) = result_set.new([[count]])
  result_set
}

fn execute_select_values(
  stream,
  page_size,
  target_table_name,
  target_column_names,
  condition,
) {
  let assert Ok(TableRecord(
    [_, _, _, Integer(table_page_number), Text(create_table_sql)],
    _,
  )) = get_schema_record_for_table(stream, page_size, target_table_name)

  let assert Ok(CreateTable(_, column_definitions)) =
    from_string(create_table_sql)

  let target_column_indices =
    list.map(target_column_names, get_column_index(_, column_definitions))

  let target_values = case condition {
    None -> {
      stream
      |> page.read(table_page_number, page_size)
      |> page.read_records(stream)
      |> filter_columns(target_column_indices)
    }

    Some(Condition(condition_col, condition_val)) -> {
      let index_page_number =
        get_index_page_number(
          stream,
          page_size,
          target_table_name,
          condition_col,
        )

      case index_page_number {
        // there is an index on the column that we can use
        Ok(index_page_number) -> {
          let assert Ok(index_key_type) =
            list.find_map(column_definitions, fn(cd) {
              case cd.name == condition_col {
                True -> Ok(cd.data_type)
                _ -> Error(Nil)
              }
            })

          let target_records =
            get_table_records_via_index(
              stream,
              index_page_number,
              table_page_number,
              page_size,
              condition_val,
              index_key_type,
            )

          filter_columns(target_records, target_column_indices)
        }

        // no index to use. full-table scan
        Error(_) -> {
          stream
          |> page.read(table_page_number, page_size)
          |> page.read_records(stream)
          |> fn(records: List(Record)) {
            let column_index =
              get_column_index(condition_col, column_definitions)

            case column_index == -1 {
              False -> {
                list.filter(records, fn(record) {
                  let assert Ok(record_val) =
                    list_utils.element_at(record.values, column_index)
                  record_val == condition_val
                })
              }

              // filter on the rowid
              _ -> {
                list.filter(records, fn(record) {
                  let assert TableRecord(_, rowid) = record
                  let assert Integer(val) = condition_val
                  rowid == val
                })
              }
            }
          }
          |> filter_columns(target_column_indices)
        }
      }
    }
  }

  let assert Ok(result_set) = result_set.new(target_values)
  result_set
}

fn filter_columns(records: List(Record), target_column_indices: List(Int)) {
  let filter_columns_for_record = fn(index, record: Record) {
    case index == -1 {
      False -> {
        let assert Ok(val) = list_utils.element_at(record.values, index)
        record_value.to_string(val)
      }
      _ -> {
        let assert TableRecord(_, rowid) = record
        int.to_string(rowid)
      }
    }
  }

  list.map(records, fn(record) {
    list.map(target_column_indices, filter_columns_for_record(_, record))
  })
}

/// Uses the target column name to search the list of columns defined on the table
/// and determine the 0-based index of the target column.
/// 
/// The order of values in each record is the same as the order of columns in the SQL table definition.
/// By knowing the index of the column, we can retrieve the corresponding value from the record.
/// 
/// If the target column is an INTEGER PRIMARY KEY, then that column appears in the record as a NULL value
/// because it aliases the rowid. -1 is returned in this case.
fn get_column_index(
  column_name: String,
  column_definitions: List(ColumnDefinition),
) {
  let target =
    list_utils.find_item_and_index(column_definitions, fn(cd) {
      cd.name == column_name
    })
  case target {
    Ok(#(ColumnDefinition(_, record_value.IntegerType, True, ..), _)) -> -1
    Ok(#(_, index)) -> index
    Error(_) -> panic
  }
}

fn get_schema_record_for_table(
  stream: FileStream,
  page_size: Int,
  target_table_name: String,
) -> Result(Record, Nil) {
  stream
  |> page.read(1, page_size)
  |> page.read_records(stream)
  |> list.find(fn(record) {
    let assert TableRecord(vals, _) = record
    case vals {
      [Text("table"), _, Text(s), ..] if s == target_table_name -> True
      _ -> False
    }
  })
}

fn get_schema_records_for_index(
  stream: FileStream,
  page_size: Int,
  target_table_name: String,
) -> Result(List(Record), Nil) {
  let records_with_table_name =
    stream
    |> page.read(1, page_size)
    |> page.read_records(stream)
    |> list.filter(fn(record) {
      case record.values {
        [_, _, Text(s), ..] if s == target_table_name -> True
        _ -> False
      }
    })

  case records_with_table_name {
    [] -> Error(Nil)
    recs ->
      list.filter(recs, fn(record: Record) {
        case record.values {
          [Text("index"), _, Text(s), ..] if s == target_table_name -> True
          _ -> False
        }
      })
      |> Ok
  }
}

fn get_index_page_number(
  stream,
  page_size,
  target_table_name,
  target_column_name,
) {
  let assert Ok(index_schema_records) =
    get_schema_records_for_index(stream, page_size, target_table_name)

  list.find_map(index_schema_records, fn(record) {
    let assert TableRecord(
      [_, _, _, Integer(page_number), Text(create_table_sql)],
      _,
    ) = record

    let assert Ok(CreateIndex(_table, indexed_col)) =
      from_string(create_table_sql)

    case target_column_name == indexed_col {
      True -> Ok(page_number)
      _ -> Error(Nil)
    }
  })
}

fn get_table_records_via_index(
  stream,
  index_page_number,
  table_page_number,
  page_size,
  target_key,
  key_type,
) {
  let target_rowids =
    stream
    |> page.read(index_page_number, page_size)
    |> page.find_records(stream, target_key, key_type)
    |> list.map(fn(record) {
      let assert IndexRecord(vals) = record
      let assert Ok(rowid) = list.last(vals)
      rowid
    })

  case target_rowids {
    [] -> []
    [_, ..] -> {
      let table_page = page.read(stream, table_page_number, page_size)
      list.map(target_rowids, fn(rowid) {
        let assert [target_record] =
          page.find_records(table_page, stream, rowid, record_value.IntegerType)
        target_record
      })
    }
  }
}
