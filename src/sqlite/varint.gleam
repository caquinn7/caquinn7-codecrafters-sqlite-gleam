//// A variable-length integer or "varint" is a static Huffman encoding of 64-bit twos-complement integers that uses less space for small positive values.
//// A varint is between 1 and 9 bytes in length.
//// The varint consists of either zero or more bytes which have the high-order bit set followed by a single byte with the high-order bit clear, or nine bytes, whichever is shorter.
//// The lower seven bits of each of the first eight bytes and all 8 bits of the ninth byte are used to reconstruct the 64-bit twos-complement integer.
//// Varints are big-endian: bits taken from the earlier byte of the varint are more significant than bits taken from the later bytes.

import file_streams/file_stream.{type FileStream}
import gleam/int

pub fn read(stream: FileStream) -> Int {
  let #(result, _) = do_read(stream, 1, 0)
  result
}

/// Returns the decoded varint and the number of bytes consumed in the decoding process.
pub fn read_with_size(stream: FileStream) -> #(Int, Int) {
  do_read(stream, 1, 0)
}

fn do_read(
  stream: FileStream,
  byte_number: Int,
  accumulator: Int,
) -> #(Int, Int) {
  let assert Ok(current_byte) = file_stream.read_uint8(stream)

  let accumulator = case byte_number < 9 {
    True ->
      accumulator
      |> int.bitwise_shift_left(7)
      |> int.bitwise_or(int.bitwise_and(current_byte, 0x7f))

    _ ->
      accumulator
      |> int.bitwise_shift_left(8)
      |> int.bitwise_or(current_byte)
  }

  case int.bitwise_and(current_byte, 0x80) == 0 || byte_number == 9 {
    True -> #(accumulator, byte_number)
    _ -> do_read(stream, byte_number + 1, accumulator)
  }
}
