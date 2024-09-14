import file_streams/file_stream.{type FileStream}
import gleam/bit_array
import gleam/float
import gleam/int
import gleam/option.{None, Some}
import gleam/order.{type Order, Eq, Gt, Lt}
import gleam/result
import gleam/string
import serial_type.{type SerialType}

// https://sqlite.org/datatype3.html

pub type RecordValue {
  Integer(Int)
  Real(Float)
  // Blob(BitArray)
  Text(String)
  Null
}

pub type RecordValueType {
  IntegerType
  RealType
  TextType
}

pub fn read(stream: FileStream, serial_type: SerialType) -> RecordValue {
  case serial_type {
    serial_type.NullType -> Null
    serial_type.IntegerType(byte_size) -> {
      let assert Ok(bytes) = file_stream.read_bytes_exact(stream, byte_size)
      let bit_size = byte_size * 8
      let assert <<i:size(bit_size)>> = bytes
      Integer(i)
    }
    serial_type.RealType -> {
      let byte_size = 8
      let assert Ok(bytes) = file_stream.read_bytes_exact(stream, byte_size)
      let assert <<f:float>> = bytes
      Real(f)
    }
    serial_type.Zero -> Integer(0)
    serial_type.One -> Integer(1)
    serial_type.BlobType(_byte_size) -> todo
    serial_type.TextType(byte_size) -> {
      let assert Ok(bytes) = file_stream.read_bytes_exact(stream, byte_size)
      let assert Ok(str) = bit_array.to_string(bytes)
      Text(str)
    }
  }
}

pub fn to_string(record_value: RecordValue) -> String {
  case record_value {
    Integer(n) -> int.to_string(n)
    Real(n) -> float.to_string(n)
    // Blob(bytes) -> bytes |> string.inspect
    Text(str) -> str
    Null -> ""
  }
}

pub fn compare(
  first: RecordValue,
  with second: RecordValue,
  expecting_type val_type: RecordValueType,
) -> Result(Order, Nil) {
  let unwrap_integer = fn(wrapped) {
    case wrapped {
      Integer(i) -> Ok(Some(i))
      Null -> Ok(None)
      _ -> Error(Nil)
    }
  }

  let unwrap_real = fn(wrapped) {
    case wrapped {
      Real(f) -> Ok(Some(f))
      Null -> Ok(None)
      _ -> Error(Nil)
    }
  }

  let unwrap_text = fn(wrapped) {
    case wrapped {
      Text(s) -> Ok(Some(s))
      Null -> Ok(None)
      _ -> Error(Nil)
    }
  }

  case val_type {
    IntegerType -> {
      use first <- result.try(unwrap_integer(first))
      use second <- result.try(unwrap_integer(second))
      // NULL is considered a special marker that represents “unknown” or “missing” data, and it doesn’t behave like other values in comparisons.
      // When comparing NULL with any other value, the result is typically NULL or “undefined,” which is interpreted as neither true nor false.
      // However, SQLite imposes a specific ordering for NULL values when sorting or indexing: NULL is considered less than any non-NULL value.
      case first, second {
        None, None -> Eq
        Some(_), None -> Gt
        None, Some(_) -> Lt
        Some(x), Some(y) -> int.compare(x, y)
      }
      |> Ok
    }

    RealType -> {
      use first <- result.try(unwrap_real(first))
      use second <- result.try(unwrap_real(second))
      case first, second {
        None, None -> Eq
        Some(_), None -> Gt
        None, Some(_) -> Lt
        Some(f1), Some(f2) -> float.compare(f1, f2)
      }
      |> Ok
    }

    TextType -> {
      use first <- result.try(unwrap_text(first))
      use second <- result.try(unwrap_text(second))
      case first, second {
        None, None -> Eq
        Some(_), None -> Gt
        None, Some(_) -> Lt
        Some(s1), Some(s2) -> string.compare(s1, s2)
      }
      |> Ok
    }
  }
}
