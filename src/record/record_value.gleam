import gleam/float
import gleam/int
import gleam/string

pub type RecordValue {
  Integer(Int)
  Real(Float)
  Blob(BitArray)
  Text(String)
  Null
}

pub fn to_string(record_value: RecordValue) -> String {
  case record_value {
    Integer(n) -> int.to_string(n)
    Real(n) -> float.to_string(n)
    Blob(bytes) -> bytes |> string.inspect
    Text(str) -> str
    Null -> ""
  }
}
