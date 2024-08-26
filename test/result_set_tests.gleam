import gleeunit
import gleeunit/should
import result_set

pub fn main() {
  gleeunit.main()
}

pub fn result_set_new_empty_test() {
  []
  |> result_set.new
  |> should.be_ok
}

pub fn result_set_new_single_row_one_col_test() {
  [[""]]
  |> result_set.new
  |> should.be_ok
}

pub fn result_set_new_single_row_two_col_test() {
  [["", ""]]
  |> result_set.new
  |> should.be_ok
}

pub fn result_set_new_two_row_one_col_test() {
  [[""], [""]]
  |> result_set.new
  |> should.be_ok
}

pub fn result_set_new_two_row_two_col_test() {
  [["", ""], ["", ""]]
  |> result_set.new
  |> should.be_ok
}

pub fn result_set_new_empty_row_test() {
  [[]]
  |> result_set.new
  |> should.be_error
}

pub fn result_set_new_mismatched_lengths_test() {
  [["", ""], [""]]
  |> result_set.new
  |> should.be_error
}

pub fn result_set_new_nonempty_row_and_empty_row_test() {
  [[""], []]
  |> result_set.new
  |> should.be_error
}

pub fn result_set_to_string_empty_test() {
  []
  |> result_set.new
  |> should.be_ok
  |> result_set.to_string
  |> should.equal("")
}

pub fn result_set_to_string_single_row_two_col_test() {
  [["col1", "col2"]]
  |> result_set.new
  |> should.be_ok
  |> result_set.to_string
  |> should.equal("col1|col2")
}

pub fn result_set_to_string_two_row_two_col_test() {
  [["row1-col1", "row1-col2"], ["row2-col1", "row2-col2"]]
  |> result_set.new
  |> should.be_ok
  |> result_set.to_string
  |> should.equal("row1-col1|row1-col2\nrow2-col1|row2-col2")
}
