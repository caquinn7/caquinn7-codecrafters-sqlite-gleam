import gleam/int

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
