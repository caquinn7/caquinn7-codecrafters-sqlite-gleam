import file_streams/file_stream.{type FileStream, BeginningOfFile}
import gleam/int
import gleam/list.{Continue, Stop}
import gleam/option.{type Option, None, Some}
import gleam/order.{Eq, Lt}
import record_value.{type RecordValue, type RecordValueType, Integer}
import serial_type.{type SerialType}
import varint

pub type Page {
  TableInteriorPage(size: Int, number: Int, cells: List(Cell))
  IndexInteriorPage(size: Int, number: Int, cells: List(Cell))
  TableLeafPage(size: Int, number: Int, cell_pointers: List(Int))
  IndexLeafPage(size: Int, number: Int, cell_pointers: List(Int))
}

// The cell for the right-most child page has no key
pub type Cell {
  // For table interior cells, the key is the rowid
  TableInteriorCell(child_pointer: Int, key: Option(Int))
  // For index interior cells, the key is a value from the indexed column
  IndexInteriorCell(child_pointer: Int, key: Option(RecordValue))
}

pub type Record {
  TableRecord(values: List(RecordValue), rowid: Int)
  IndexRecord(values: List(RecordValue))
}

pub fn read(stream: FileStream, page_number: Int, page_size: Int) -> Page {
  let is_leaf = fn(i) {
    case i {
      2 | 5 -> False
      10 | 13 -> True
      _ -> panic
    }
  }

  let is_table = fn(i) {
    case i {
      2 | 10 -> False
      5 | 13 -> True
      _ -> panic
    }
  }

  let page_offset = calculate_page_offset(page_number, page_size)
  let page_content_offset = case page_number {
    1 -> 100
    _ -> page_offset
  }

  let assert Ok(_) =
    file_stream.position(stream, BeginningOfFile(page_content_offset))

  // The one-byte flag at offset 0 indicating the b-tree page type.
  // A value of 2 (0x02) means the page is an interior index b-tree page.
  // A value of 5 (0x05) means the page is an interior table b-tree page.
  // A value of 10 (0x0a) means the page is a leaf index b-tree page.
  // A value of 13 (0x0d) means the page is a leaf table b-tree page.
  let assert Ok(page_type_flag) = file_stream.read_uint8(stream)
  let assert Ok(_first_freeblock_offset) = file_stream.read_uint16_be(stream)

  //The two-byte integer at offset 3 gives the number of cells on the page.
  let assert Ok(cell_count) = file_stream.read_uint16_be(stream)

  // todo A zero value for this integer is interpreted as 65536
  let assert Ok(_cell_content_area_offset) = file_stream.read_uint16_be(stream)
  let assert Ok(_fragmented_free_byte_count) = file_stream.read_uint8(stream)

  case is_leaf(page_type_flag) {
    True -> {
      let cell_pointers = read_cell_pointers(stream, cell_count, [])
      case is_table(page_type_flag) {
        True -> TableLeafPage(page_size, page_number, cell_pointers)
        _ -> IndexLeafPage(page_size, page_number, cell_pointers)
      }
    }

    _ -> {
      // The four-byte page number at offset 8 is the right-most pointer.
      // This value appears in the header of interior b-tree pages only
      // and is omitted from all other pages.
      let assert Ok(right_child_page_number) =
        file_stream.read_uint32_be(stream)

      let cell_pointers = read_cell_pointers(stream, cell_count, [])

      case is_table(page_type_flag) {
        True -> {
          let left_children =
            cell_pointers
            |> list.map(fn(pointer) {
              go_to_cell(stream, page_offset, pointer)

              let assert Ok(child_page_number) =
                file_stream.read_uint32_be(stream)

              let key = varint.read(stream)
              TableInteriorCell(child_page_number, Some(key))
            })

          let children =
            left_children
            |> list.append([TableInteriorCell(right_child_page_number, None)])

          TableInteriorPage(page_size, page_number, children)
        }

        False -> {
          let left_children =
            cell_pointers
            |> list.map(fn(pointer) {
              go_to_cell(stream, page_offset, pointer)

              let assert Ok(child_page_number) =
                file_stream.read_uint32_be(stream)

              let _key_size = varint.read(stream)
              let values = read_record_values(stream)
              let assert Ok(key) = list.first(values)
              IndexInteriorCell(child_page_number, Some(key))
            })

          let children =
            left_children
            |> list.append([IndexInteriorCell(right_child_page_number, None)])

          IndexInteriorPage(page_size, page_number, children)
        }
      }
    }
  }
}

pub fn count_records(page: Page, stream: FileStream) -> Int {
  case page {
    TableLeafPage(_, _, cell_pointers) | IndexLeafPage(_, _, cell_pointers) ->
      list.length(cell_pointers)

    TableInteriorPage(_, _, cells) | IndexInteriorPage(_, _, cells) ->
      cells
      |> list.map(fn(cell) { read(stream, cell.child_pointer, page.size) })
      |> list.map(fn(page) { count_records(page, stream) })
      |> int.sum
  }
}

pub fn read_records(page: Page, stream: FileStream) -> List(Record) {
  case page {
    TableInteriorPage(_, _, cells) | IndexInteriorPage(_, _, cells) ->
      cells
      |> list.map(fn(cell) { read(stream, cell.child_pointer, page.size) })
      |> list.flat_map(read_records(_, stream))

    TableLeafPage(size, number, cell_pointers) ->
      list.map(cell_pointers, fn(pointer) {
        go_to_cell(stream, calculate_page_offset(number, size), pointer)
        let _payload_size = varint.read(stream)
        let rowid = varint.read(stream)
        let values = read_record_values(stream)
        TableRecord(values, rowid)
      })

    IndexLeafPage(size, number, cell_pointers) -> {
      list.map(cell_pointers, fn(pointer) {
        go_to_cell(stream, calculate_page_offset(number, size), pointer)
        let _payload_size = varint.read(stream)
        let values = read_record_values(stream)
        IndexRecord(values)
      })
    }
  }
}

pub fn find_records(
  page: Page,
  stream: FileStream,
  target_key: RecordValue,
  key_type: RecordValueType,
) -> List(Record) {
  case page {
    TableInteriorPage(size, _, cells) | IndexInteriorPage(size, _, cells) -> {
      let assert Ok(first_cell) = list.first(cells)
      let assert Ok(rest) = list.rest(cells)

      // Iterate through the page's cells until we find one whose key is greater than or equal to the target key.
      // If we find such a cell, the search stops, and this cell's child page will be visited next.
      // If we reach the end of the list without finding a greater or equal key, the right-most child page is visited next.
      rest
      |> list.fold_until(first_cell, fn(prev_cell, curr_cell) {
        let assert Some(key) = case prev_cell {
          TableInteriorCell(_, k) -> option.map(k, Integer)
          IndexInteriorCell(_, k) -> k
        }
        case record_value.compare(target_key, key, key_type) {
          Ok(Lt) -> Stop(prev_cell)
          Ok(_) -> Continue(curr_cell)
          _ -> panic
        }
      })
      |> fn(cell: Cell) { read(stream, cell.child_pointer, size) }
      |> find_records(stream, target_key, key_type)
    }

    TableLeafPage(size, number, cell_pointers) -> {
      let assert Integer(target_rowid) = target_key

      list.filter_map(cell_pointers, fn(pointer) {
        go_to_cell(stream, calculate_page_offset(number, size), pointer)
        let _payload_size = varint.read(stream)
        let rowid = varint.read(stream)
        case rowid == target_rowid {
          True -> {
            let values = read_record_values(stream)
            Ok(TableRecord(values, rowid))
          }
          _ -> Error(Nil)
        }
      })
    }

    IndexLeafPage(size, number, cell_pointers) ->
      list.filter_map(cell_pointers, fn(pointer) {
        go_to_cell(stream, calculate_page_offset(number, size), pointer)
        let _payload_size = varint.read(stream)
        let values = read_record_values(stream)
        let assert Ok(first_value) = list.first(values)
        case record_value.compare(target_key, first_value, key_type) {
          Ok(Eq) -> Ok(IndexRecord(values))
          _ -> Error(Nil)
        }
      })
  }
}

fn calculate_page_offset(page_number: Int, page_size: Int) -> Int {
  page_size * { page_number - 1 }
}

/// The cell pointer array of a b-tree page immediately follows the b-tree page header.
/// Let K be the number of cells on the btree. The cell pointer array consists of K 2-byte integer offsets to the cell contents.
/// The cell pointers are arranged in key order with left-most cell (the cell with the smallest key) first
/// and the right-most cell (the cell with the largest key) last.
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

fn read_record_values(stream: FileStream) -> List(RecordValue) {
  let header_size = varint.read(stream)
  let serial_types = read_record_header(stream, header_size - 1, [])
  list.map(serial_types, record_value.read(stream, _))
}

fn read_record_header(
  stream: FileStream,
  bytes_remaining: Int,
  acc: List(SerialType),
) -> List(SerialType) {
  case bytes_remaining == 0 {
    True -> list.reverse(acc)
    _ -> {
      let #(serial_type_code, code_size) = varint.read_with_size(stream)
      let serial_type = serial_type.from_code(serial_type_code)
      read_record_header(stream, bytes_remaining - code_size, [
        serial_type,
        ..acc
      ])
    }
  }
}
