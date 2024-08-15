import file_streams/file_stream.{type FileStream}
import gleam/int

pub fn read(stream: FileStream) -> Int {
  let #(result, _) = do_read(stream, 1, 0)
  result
}

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
