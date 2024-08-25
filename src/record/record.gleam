import file_streams/file_stream.{type FileStream}
import gleam/bit_array
import gleam/list
import gleam/option.{type Option, None, Some}
import page_type.{type PageType, Index, Table}
import record/record_value.{type RecordValue, Blob, Integer, Text}
import serial_type.{
  type SerialType, BlobType, IntegerType, Null, One, RealType, TextType, Zero,
}
import varint

pub type Record {
  TableRecord(values: List(Option(RecordValue)), rowid: Int)
  IndexRecord(values: List(Option(RecordValue)))
}

pub fn read(stream: FileStream, page_type: PageType) -> Record {
  case page_type {
    Index -> todo
    Table -> {
      let rowid = varint.read(stream)
      let header_size = varint.read(stream)
      let serial_types = read_header(stream, header_size - 1, [])
      let values = serial_types |> list.map(read_value(stream, _))
      TableRecord(values, rowid)
    }
  }
}

fn read_header(
  stream: FileStream,
  bytes_remaining: Int,
  acc: List(SerialType),
) -> List(SerialType) {
  case bytes_remaining == 0 {
    True -> list.reverse(acc)
    _ -> {
      let #(serial_type_code, code_size) = varint.read_with_size(stream)
      let serial_type = serial_type.from_code(serial_type_code)
      let acc = [serial_type, ..acc]
      let bytes_remaining = bytes_remaining - code_size
      read_header(stream, bytes_remaining, acc)
    }
  }
}

fn read_value(
  stream: FileStream,
  serial_type: SerialType,
) -> Option(RecordValue) {
  case serial_type {
    Null -> None
    IntegerType(byte_size) -> {
      let assert Ok(bytes) = file_stream.read_bytes_exact(stream, byte_size)
      let bit_size = byte_size * 8
      let assert <<x:size(bit_size)>> = bytes
      Some(Integer(x))
    }
    RealType -> todo
    Zero -> Some(Integer(0))
    One -> Some(Integer(1))
    BlobType(byte_size) -> {
      let assert Ok(bytes) = file_stream.read_bytes_exact(stream, byte_size)
      Some(Blob(bytes))
    }
    TextType(byte_size) -> {
      let assert Ok(bytes) = file_stream.read_bytes_exact(stream, byte_size)
      let assert Ok(str) = bit_array.to_string(bytes)
      Some(Text(str))
    }
  }
}
