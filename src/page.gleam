import file_streams/file_stream.{type FileStream, BeginningOfFile}
import gleam/int
import gleam/list
import page_type.{type PageType, Index, Table}
import record.{type Record}
import varint

pub type Page {
  Interior(page_type: PageType, size: Int, number: Int, children: List(Page))
  Leaf(page_type: PageType, size: Int, number: Int, cell_pointers: List(Int))
}

pub fn read(
  from stream: FileStream,
  number page_number: Int,
  size page_size: Int,
) -> Page {
  let is_leaf = fn(i) {
    case i {
      10 | 13 -> True
      _ -> False
    }
  }

  let get_page_type = fn(i) {
    case i {
      2 | 10 -> Ok(Index)
      5 | 13 -> Ok(Table)
      _ -> Error(Nil)
    }
  }

  let page_offset = calculate_offset(page_number, page_size)
  let page_content_offset = case page_number {
    1 -> 100
    _ -> page_offset
  }

  let assert Ok(_) =
    file_stream.position(stream, BeginningOfFile(page_content_offset))

  let assert Ok(page_type_flag) = file_stream.read_uint8(stream)
  let assert Ok(index_or_table) = get_page_type(page_type_flag)

  let assert Ok(_first_freeblock_offset) = file_stream.read_uint16_be(stream)

  let assert Ok(cell_count) = file_stream.read_uint16_be(stream)

  // todo A zero value for this integer is interpreted as 65536
  let assert Ok(_cell_content_area_offset) = file_stream.read_uint16_be(stream)
  let assert Ok(_fragmented_free_byte_count) = file_stream.read_uint8(stream)

  case is_leaf(page_type_flag) {
    True -> {
      let cell_pointers = read_cell_pointers(stream, cell_count, [])
      Leaf(index_or_table, page_size, page_number, cell_pointers)
    }

    _ -> {
      let assert Ok(right_child_page_number) =
        file_stream.read_uint32_be(stream)

      let cell_pointers = read_cell_pointers(stream, cell_count, [])

      let left_children_page_numbers =
        cell_pointers
        |> list.map(fn(pointer) {
          go_to_cell(stream, page_offset, pointer)
          let assert Ok(child_page_number) = file_stream.read_uint32_be(stream)
          child_page_number
        })

      let child_pages =
        left_children_page_numbers
        |> list.append([right_child_page_number])
        |> list.map(fn(page_number) { read(stream, page_number, page_size) })

      Interior(index_or_table, page_size, page_number, child_pages)
    }
  }
}

pub fn count_records(page: Page) -> Int {
  case page {
    Leaf(_, _, _, cell_pointers) -> list.length(cell_pointers)
    Interior(_, _, _, children) ->
      children
      |> list.map(count_records)
      |> int.sum
  }
}

pub fn read_records(page: Page, stream: FileStream) -> List(Record) {
  case page {
    Interior(_, _, _, children) ->
      children
      |> list.flat_map(read_records(_, stream))

    Leaf(page_type, size, number, cell_pointers) -> {
      cell_pointers
      |> list.map(fn(pointer) {
        let page_offset = calculate_offset(number, size)
        go_to_cell(stream, page_offset, pointer)

        let _payload_size = varint.read(stream)
        record.read(stream, page_type)
      })
    }
  }
}

fn calculate_offset(page_number: Int, page_size: Int) -> Int {
  page_size * { page_number - 1 }
}

fn read_cell_pointers(
  stream: FileStream,
  bytes_remaining: Int,
  acc: List(Int),
) -> List(Int) {
  case bytes_remaining == 0 {
    True -> list.reverse(acc)
    _ -> {
      let assert Ok(pointer) = file_stream.read_uint16_be(stream)
      read_cell_pointers(stream, bytes_remaining - 1, [pointer, ..acc])
    }
  }
}

fn go_to_cell(stream: FileStream, page_offset: Int, pointer: Int) -> Int {
  let assert Ok(pos) =
    file_stream.position(stream, BeginningOfFile(page_offset + pointer))
  pos
}
