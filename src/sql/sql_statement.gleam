import db_info
import file_streams/file_stream.{type FileStream}
import gleam/float
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
import page
import page_type.{type PageType, Index, Table}
import record/record.{type Record, TableRecord}
import record/record_value.{Integer, Text}
import result_set.{type ResultSet}
import sql/token as sql_token

pub type SqlStatement {
  SelectCount(table: String)
  SelectValues(table: String, columns: List(String), Option(Condition))
  CreateTable(table: String, columns: List(ColumnDefinition))
}

pub type Condition {
  Condition(column: String, value: String)
}

pub type ColumnDefinition {
  ColumnDefinition(
    name: String,
    data_type: String,
    is_primary_key: Bool,
    is_auto_increment: Bool,
    is_not_null: Bool,
  )
}

pub fn from_string(input: String) -> Result(SqlStatement, Nil) {
  let to_lowercase = fn(str) {
    let assert Ok(re) = regex.from_string("('.*?')")
    re
    |> regex.split(str)
    |> list.map(fn(part) {
      // Convert to lowercase for everything outside of single quotes
      case string.starts_with(part, "'") && string.ends_with(part, "'") {
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
    let identifier_parser_no_quotes = {
      use tok <- nibble.take_map("expected string")
      case tok {
        sql_token.Identifier(str) -> Some(str)
        _ -> None
      }
    }

    let quoted_identifier_parser = {
      use _ <- do(token(sql_token.DoubleQuote))
      use identifier <- do(identifier_parser_no_quotes)
      use _ <- do(token(sql_token.DoubleQuote))
      return(identifier)
    }

    one_of([identifier_parser_no_quotes, quoted_identifier_parser])
  }

  let select_count_parser = {
    use _ <- do(token(sql_token.Select))
    use _ <- do(token(sql_token.Count))
    use _ <- do(token(sql_token.LParen))
    use _ <- do(token(sql_token.Asterisk))
    use _ <- do(token(sql_token.RParen))
    use _ <- do(token(sql_token.From))
    use table_name <- do(identifier_parser)
    return(SelectCount(table_name))
  }

  let condition_parser = {
    let str_parser = {
      use tok <- nibble.take_map("expected string")
      case tok {
        sql_token.Str(s) -> Some(s)
        _ -> None
      }
    }

    let num_parser = {
      use tok <- nibble.take_map("expected an integer or a float")
      case tok {
        sql_token.Integer(n) -> Some(int.to_string(n))
        sql_token.Real(n) -> Some(float.to_string(n))
        _ -> None
      }
    }

    use _ <- do(token(sql_token.Where))
    use col <- do(identifier_parser)
    use _ <- do(token(sql_token.Equals))
    use val <- do(one_of([str_parser, num_parser]))
    return(Condition(col, val))
  }

  let select_values_parser = {
    use _ <- do(token(sql_token.Select))
    use cols <- do(sequence(identifier_parser, token(sql_token.Comma)))
    use _ <- do(token(sql_token.From))
    use table_name <- do(identifier_parser)
    use cond <- do(optional(condition_parser))
    return(SelectValues(table_name, cols, cond))
  }

  let create_table_parser = {
    let data_type_parser = {
      use tok <- nibble.take_map("expected string")
      case tok {
        sql_token.ColumnType(str) -> Some(str)
        _ -> None
      }
    }

    let column_definition_parser = {
      use name <- do(identifier_parser)
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
    use table_name <- do(identifier_parser)
    use _ <- do(token(sql_token.LParen))
    use column_definitions <- do(sequence(
      column_definition_parser,
      token(sql_token.Comma),
    ))
    use _ <- do(token(sql_token.RParen))
    return(CreateTable(table_name, column_definitions))
  }

  one_of([
    backtrackable(select_values_parser),
    select_count_parser,
    create_table_parser,
  ])
}

pub fn execute(statement: SqlStatement, stream: FileStream) -> ResultSet {
  let page_size = db_info.read(stream).page_size

  case statement {
    SelectCount(table) -> execute_select_count(stream, page_size, table)
    SelectValues(table, cols, condition) ->
      execute_select_values(stream, page_size, table, cols, condition)
    CreateTable(_table, _cols) -> todo
  }
}

fn get_schema_record(
  stream: FileStream,
  page_size: Int,
  table_name: String,
  object_type: PageType,
) {
  let object_type_str = case object_type {
    Index -> "index"
    _ -> "table"
  }

  stream
  |> page.read(1, page_size)
  |> page.read_records(stream)
  |> list.filter(fn(rec) {
    let assert TableRecord(vals, _) = rec
    case vals {
      [Text(s1), _, Text(s2), ..] if s1 == object_type_str && s2 == table_name ->
        True
      _ -> False
    }
  })
}

fn execute_select_count(stream, page_size, table_name) {
  let schema_record = get_schema_record(stream, page_size, table_name, Table)
  let assert [TableRecord([_, _, _, Integer(page_number), _], _)] =
    schema_record

  let count =
    stream
    |> page.read(page_number, page_size)
    |> page.count_records
    |> int.to_string

  let assert Ok(result_set) = result_set.new([[count]])
  result_set
}

fn execute_select_values(stream, page_size, table_name, cols, condition) {
  let unwrap_record = fn(rec) {
    let assert [
      TableRecord([_, _, _, Integer(page_number), Text(create_sql)], _),
    ] = rec
    #(page_number, create_sql)
  }

  let get_column_index = fn(column_name, column_definitions) {
    let target =
      list_utils.find_item_and_index(
        column_definitions,
        fn(cd: ColumnDefinition) { cd.name == column_name },
      )
    case target {
      Ok(#(ColumnDefinition(_, "integer", True, ..), _)) -> -1
      Ok(#(_, index)) -> index
      Error(_) -> panic
    }
  }

  let #(page_number, create_sql) =
    get_schema_record(stream, page_size, table_name, Table) |> unwrap_record

  let assert Ok(CreateTable(_, column_definitions)) = from_string(create_sql)

  let target_column_indices =
    list.map(cols, get_column_index(_, column_definitions))

  let target_values =
    stream
    |> page.read(page_number, page_size)
    |> page.read_records(stream)
    |> fn(recs: List(Record)) {
      case condition {
        None -> recs
        Some(Condition(col, val)) -> {
          let column_index = get_column_index(col, column_definitions)
          case column_index == -1 {
            False -> {
              list.filter(recs, fn(rec) {
                let assert Ok(rec_val) =
                  list_utils.element_at(rec.values, column_index)

                record_value.to_string(rec_val) == val
              })
            }
            True -> {
              list.filter(recs, fn(rec) {
                let assert TableRecord(_, rowid) = rec
                int.to_string(rowid) == val
              })
            }
          }
        }
      }
    }
    |> list.map(fn(rec) {
      list.map(target_column_indices, fn(i) {
        case i == -1 {
          False -> {
            let assert Ok(val) = list_utils.element_at(rec.values, i)
            record_value.to_string(val)
          }
          _ -> {
            let assert TableRecord(_, rowid) = rec
            int.to_string(rowid)
          }
        }
      })
    })

  let assert Ok(result_set) = result_set.new(target_values)
  result_set
}
