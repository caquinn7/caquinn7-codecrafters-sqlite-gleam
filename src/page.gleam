import file_streams/file_stream.{type FileStream, BeginningOfFile}
import gleam/int
import gleam/list
import utils

pub type Page {
  Interior(
    page_type: IndexOrTable,
    size: Int,
    number: Int,
    children: List(Page),
  )
  Leaf(
    page_type: IndexOrTable,
    size: Int,
    number: Int,
    cell_pointers: List(BitArray),
  )
}

pub type IndexOrTable {
  Index
  Table
}

pub fn new(stream: FileStream, page_number: Int, page_size: Int) -> Page {
  let is_leaf = fn(i) {
    case i {
      10 | 13 -> True
      _ -> False
    }
  }

  let is_index_or_table = fn(i) {
    case i {
      2 | 10 -> Ok(Index)
      5 | 13 -> Ok(Table)
      _ -> Error(Nil)
    }
  }

  let page_offset = page_size * { page_number - 1 }
  let page_content_offset = case page_number {
    1 -> 100
    _ -> page_offset
  }

  let assert Ok(_) =
    file_stream.position(stream, BeginningOfFile(page_content_offset))
  let assert Ok(page_type_flag) = file_stream.read_uint8(stream)
  let assert Ok(index_or_table) = is_index_or_table(page_type_flag)
  let assert Ok(_first_freeblock_offset) = file_stream.read_uint16_be(stream)
  let assert Ok(cell_count) = file_stream.read_uint16_be(stream)
  // todo A zero value for this integer is interpreted as 65536
  let assert Ok(_cell_content_area_offset) = file_stream.read_uint16_be(stream)
  let assert Ok(_fragmented_free_byte_count) = file_stream.read_uint8(stream)

  case is_leaf(page_type_flag) {
    True -> {
      let assert Ok(cell_pointer_bytes) =
        file_stream.read_bytes_exact(stream, cell_count * 2)

      let cell_pointers = utils.chunk_bit_array(cell_pointer_bytes, 2)

      Leaf(index_or_table, page_size, page_number, cell_pointers)
    }
    False -> {
      let assert Ok(right_child_page_number) =
        file_stream.read_uint32_be(stream)

      let assert Ok(cell_pointer_bytes) =
        file_stream.read_bytes_exact(stream, cell_count * 2)

      let cell_pointers = utils.chunk_bit_array(cell_pointer_bytes, 2)

      let left_children_page_numbers =
        cell_pointers
        |> list.map(fn(bytes) {
          let assert <<cell_contents_offset:size(16)>> = bytes
          let assert Ok(_) =
            file_stream.position(
              stream,
              file_stream.BeginningOfFile(page_offset + cell_contents_offset),
            )
          let assert Ok(child_page_number) = file_stream.read_uint32_be(stream)
          child_page_number
        })

      let child_pages =
        left_children_page_numbers
        |> list.append([right_child_page_number])
        |> list.map(fn(page_number) { new(stream, page_number, page_size) })

      Interior(index_or_table, page_size, page_number, child_pages)
    }
  }
}

pub fn count_rows(page: Page) -> Int {
  case page {
    Leaf(_, _, _, cell_pointers) -> list.length(cell_pointers)
    Interior(_, _, _, children) ->
      children
      |> list.map(count_rows)
      |> int.sum
  }
}
