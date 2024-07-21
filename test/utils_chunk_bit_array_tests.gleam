import gleeunit
import gleeunit/should
import utils.{chunk_bit_array}

pub fn main() {
  gleeunit.main()
}

pub fn byte_count_is_divisible_by_chunk_size_test() {
  <<1, 2, 3, 4>>
  |> chunk_bit_array(2)
  |> should.equal([<<1, 2>>, <<3, 4>>])
}

pub fn byte_count_is_not_divisible_by_chunk_size_test() {
  <<1, 2, 3>>
  |> chunk_bit_array(2)
  |> should.equal([<<1, 2>>, <<3>>])
}

pub fn byte_count_less_than_chunk_size_test() {
  <<1>>
  |> chunk_bit_array(2)
  |> should.equal([<<1>>])
}

pub fn bit_array_is_not_byte_aligned_test() {
  <<1, 2:size(2)>>
  |> chunk_bit_array(2)
  |> should.equal([<<1, 2:size(2)>>])
}

pub fn empty_bit_array_test() {
  <<>>
  |> chunk_bit_array(1)
  |> should.equal([])
}

pub fn chunk_size_zero_test() {
  <<1, 2>>
  |> chunk_bit_array(0)
  |> should.equal([<<1>>, <<2>>])
}

pub fn chunk_size_negative_test() {
  <<1, 2>>
  |> chunk_bit_array(-1)
  |> should.equal([<<1>>, <<2>>])
}
