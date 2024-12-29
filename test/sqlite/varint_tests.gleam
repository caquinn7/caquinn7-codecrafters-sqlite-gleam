import file_streams/file_stream.{type FileStream}
import gleam/list
import gleeunit
import gleeunit/should
import sqlite/varint
import temporary

pub fn main() {
  gleeunit.main()
}

pub fn read_test() {
  [
    #(<<0x69>>, 105),
    #(<<0x7f>>, 127),
    #(<<0x80, 0x01>>, 1),
    #(<<0x81, 0x00>>, 128),
    #(<<0x82, 0x24>>, 292),
    #(<<0xAC, 0x02>>, 5634),
    #(<<0x82, 0x81, 0x34>>, 32_948),
    #(
      <<0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x01>>,
      72_057_594_037_927_809,
    ),
    #(
      <<0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7f>>,
      72_057_594_037_927_935,
    ),
    #(
      <<0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x01>>,
      18_446_744_073_709_551_361,
    ),
    #(
      <<0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF>>,
      18_446_744_073_709_551_615,
    ),
  ]
  |> list.each(fn(pair) {
    let #(input, expected) = pair
    use stream <- do_with_stream(input)
    stream
    |> varint.read
    |> should.equal(expected)
  })
}

fn do_with_stream(content: BitArray, do: fn(FileStream) -> a) {
  use file <- temporary.create(temporary.file())
  let assert Ok(write_stream) = file_stream.open_write(file)
  let assert Ok(_) = file_stream.write_bytes(write_stream, content)
  let assert Ok(_) = file_stream.close(write_stream)
  let assert Ok(read_stream) = file_stream.open_read(file)
  do(read_stream)
}
