import gleam/order.{Eq, Gt, Lt}
import gleeunit
import gleeunit/should
import sqlite/record_value.{
  Blob, BlobType, Integer, IntegerType, Null, Text, compare,
}

pub fn main() {
  gleeunit.main()
}

pub fn compare_type_mismatch_test() {
  Text("")
  |> compare(Integer(1), IntegerType)
  |> should.be_error
  |> should.equal(Nil)
}

pub fn compare_blobs_both_null_test() {
  Null
  |> compare(Null, BlobType)
  |> should.be_ok
  |> should.equal(Eq)
}

pub fn compare_blobs_first_is_null_test() {
  Null
  |> compare(Blob(<<>>), BlobType)
  |> should.be_ok
  |> should.equal(Lt)
}

pub fn compare_blobs_second_is_null_test() {
  Blob(<<>>)
  |> compare(Null, BlobType)
  |> should.be_ok
  |> should.equal(Gt)
}

pub fn compare_blobs_both_bit_arrays_empty_test() {
  Blob(<<>>)
  |> compare(Blob(<<>>), BlobType)
  |> should.be_ok
  |> should.equal(Eq)
}

pub fn compare_blobs_first_bit_array_empty_test() {
  Blob(<<>>)
  |> compare(Blob(<<1>>), BlobType)
  |> should.be_ok
  |> should.equal(Lt)
}

pub fn compare_blobs_second_bit_array_empty_test() {
  Blob(<<1>>)
  |> compare(Blob(<<>>), BlobType)
  |> should.be_ok
  |> should.equal(Gt)
}

pub fn compare_blobs_lt_test() {
  Blob(<<1, 2>>)
  |> compare(Blob(<<2>>), BlobType)
  |> should.be_ok
  |> should.equal(Lt)
}

pub fn compare_blobs_eq_test() {
  Blob(<<1, 1>>)
  |> compare(Blob(<<1, 1>>), BlobType)
  |> should.be_ok
  |> should.equal(Eq)
}

pub fn compare_blobs_gt_test() {
  Blob(<<2>>)
  |> compare(Blob(<<1, 2>>), BlobType)
  |> should.be_ok
  |> should.equal(Gt)
}
