import db_info
import file_streams/file_stream.{type FileStream}
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import list_utils
import nibble.{backtrackable, do, map, one_of, optional, return, sequence, token}
import nibble/lexer
import page
import page_type.{type PageType, Index, Table}
import record/record.{TableRecord}
import record/record_value.{Integer, Text}
import result_set.{type ResultSet}
import sql/token as sql_token

pub type SqlStatement {
  SelectCount(table: String)
  SelectValues(table: String, columns: List(String))
  CreateTable(table: String, columns: List(ColumnDefinition))
}

pub type ColumnDefinition {
  ColumnDefinition(
    name: String,
    data_type: String,
    is_primary_key: Bool,
    is_auto_increment: Bool,
  )
}

pub fn from_string(str: String) -> Result(SqlStatement, Nil) {
  let str = string.lowercase(str)

  let identifier_parser = {
    use tok <- nibble.take_map("expected string")
    case tok {
      sql_token.Identifier(str) -> Some(str)
      _ -> None
    }
  }

  let select_count_parser = {
    use _ <- do(token(sql_token.SelectToken))
    use _ <- do(token(sql_token.Count))
    use _ <- do(token(sql_token.LParen))
    use _ <- do(token(sql_token.Asterisk))
    use _ <- do(token(sql_token.RParen))
    use _ <- do(token(sql_token.From))
    use table_name <- do(identifier_parser)
    return(SelectCount(table_name))
  }

  let select_values_parser = {
    use _ <- do(token(sql_token.SelectToken))
    use cols <- do(sequence(identifier_parser, token(sql_token.Comma)))
    use _ <- do(token(sql_token.From))
    use table_name <- do(identifier_parser)
    return(SelectValues(table_name, cols))
  }

  let create_table_parser = {
    let column_type_parser = {
      use tok <- nibble.take_map("expected string")
      case tok {
        sql_token.ColumnType(str) -> Some(str)
        _ -> None
      }
    }

    let column_definition_parser = {
      use name <- do(identifier_parser)
      use data_type <- do(column_type_parser)
      use is_pk <- do(map(optional(token(sql_token.PrimaryKey)), option.is_some))
      use is_auto_incr <- do(map(
        optional(token(sql_token.AutoIncrement)),
        option.is_some,
      ))
      return(ColumnDefinition(name, data_type, is_pk, is_auto_incr))
    }

    use _ <- do(token(sql_token.Create))
    use _ <- do(token(sql_token.TableToken))
    use table_name <- do(identifier_parser)
    use _ <- do(token(sql_token.LParen))
    use column_definitions <- do(sequence(
      column_definition_parser,
      token(sql_token.Comma),
    ))
    use _ <- do(token(sql_token.RParen))
    return(CreateTable(table_name, column_definitions))
  }

  let sql_parser =
    one_of([
      backtrackable(select_values_parser),
      select_count_parser,
      create_table_parser,
    ])

  use tokens <- result.try(
    str
    |> lexer.run(sql_token.lexer())
    |> result.replace_error(Nil),
  )
  use statement <- result.try(
    tokens
    |> nibble.run(sql_parser)
    |> result.replace_error(Nil),
  )
  Ok(statement)
}

pub fn execute(statement: SqlStatement, stream: FileStream) -> ResultSet {
  let page_size = db_info.read(stream).page_size

  let get_schema_record = fn(table_name: String, object_type: PageType) {
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
        [Some(Text(s1)), _, Some(Text(s2)), ..]
          if s1 == object_type_str && s2 == table_name
        -> True
        _ -> False
      }
    })
  }

  let execute_select_count = fn(table_name) {
    let schema_record = get_schema_record(table_name, Table)
    let assert [TableRecord([_, _, _, Some(Integer(page_number)), _], _)] =
      schema_record

    let count =
      stream
      |> page.read(page_number, page_size)
      |> page.count_records
      |> int.to_string

    let assert Ok(result_set) = result_set.new([[Some(count)]])
    result_set
  }

  let execute_select_values = fn(table_name, cols) {
    let unwrap_record = fn(rec) {
      let assert [
        TableRecord(
          [_, _, _, Some(Integer(page_number)), Some(Text(create_sql))],
          _,
        ),
      ] = rec
      #(page_number, create_sql)
    }

    let #(page_number, create_sql) =
      table_name
      |> get_schema_record(Table)
      |> unwrap_record

    let assert Ok(CreateTable(_, column_definitions)) = from_string(create_sql)

    let column_indices =
      cols
      |> list.map(fn(col_name) {
        list_utils.find_index(column_definitions, fn(cd) { cd.name == col_name })
      })

    let target_values =
      stream
      |> page.read(page_number, page_size)
      |> page.read_records(stream)
      |> list.map(fn(rec) {
        list.map(column_indices, fn(i) {
          let assert Ok(val) = list_utils.element_at(rec.values, i)
          option.map(val, record_value.to_string)
        })
      })

    let assert Ok(result_set) = result_set.new(target_values)
    result_set
  }

  case statement {
    SelectCount(table) -> execute_select_count(table)
    SelectValues(table, cols) -> execute_select_values(table, cols)
    CreateTable(_table, _cols) -> todo
  }
}
