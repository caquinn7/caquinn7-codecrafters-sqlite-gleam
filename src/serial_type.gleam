import gleam/int

// Serial Type Codes Of The Record Format
// Serial Type	  Content Size	Meaning
// 0	            0	            Value is a NULL.
// 1	            1	            Value is an 8-bit twos-complement integer.
// 2	            2	            Value is a big-endian 16-bit twos-complement integer.
// 3	            3	            Value is a big-endian 24-bit twos-complement integer.
// 4	            4	            Value is a big-endian 32-bit twos-complement integer.
// 5	            6	            Value is a big-endian 48-bit twos-complement integer.
// 6	            8	            Value is a big-endian 64-bit twos-complement integer.
// 7	            8	            Value is a big-endian IEEE 754-2008 64-bit floating point number.
// 8	            0	            Value is the integer 0. (Only available for schema format 4 and higher.)
// 9	            0	            Value is the integer 1. (Only available for schema format 4 and higher.)
// 10,11	        variable	    Reserved for internal use. These serial type codes will never appear in a well-formed database file, but they might be used in transient and temporary database files that SQLite sometimes generates for its own use. The meanings of these codes can shift from one release of SQLite to the next.
// N≥12 and even	(N-12)/2	    Value is a BLOB that is (N-12)/2 bytes in length.
// N≥13 and odd	  (N-13)/2	    Value is a string in the text encoding and (N-13)/2 bytes in length. The null terminator is not stored.

/// Determines the datatype of each column in a record.
pub type SerialType {
  NullType
  IntegerType(Int)
  RealType
  Zero
  One
  BlobType(Int)
  TextType(Int)
}

pub fn from_code(code: Int) {
  // For serial types 0, 8, 9, 12, and 13, the value is zero bytes in length
  case code {
    0 -> NullType
    x if x >= 1 && x <= 4 -> IntegerType(x)
    5 -> IntegerType(6)
    6 -> IntegerType(8)
    7 -> RealType
    8 -> Zero
    9 -> One
    x if x >= 12 -> {
      case int.is_even(x) {
        True -> BlobType({ x - 12 } / 2)
        False -> TextType({ x - 13 } / 2)
      }
    }
    _ -> panic
  }
}
