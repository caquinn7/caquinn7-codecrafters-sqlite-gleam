import gleam/io
import gleeunit
import gleeunit/should
import result_set
import sqlite
import temporary
import utils

pub fn main() {
  gleeunit.main()
}

pub fn handle_args_empty_list_test() {
  []
  |> sqlite.handle_args
  |> should.be_error
  |> should.equal("First argument should be the path to the database file")
}

pub fn handle_args_only_db_path_test() {
  use db_path <- temporary.create(temporary.file())
  use _ <- utils.do_with_temp_db3(db_path, utils.test_sql_file)

  [db_path]
  |> sqlite.handle_args()
  |> should.be_ok
  |> should.equal("")
}

pub fn handle_args_db_path_does_not_exist_test() {
  ["/not/a/real/file"]
  |> sqlite.handle_args
  |> should.be_error
  |> should.equal("Error opening database file: Enoent")
}

pub fn handle_args_error_parsing_sql_test() {
  use db_path <- temporary.create(temporary.file())
  use _ <- utils.do_with_temp_db3(db_path, utils.test_sql_file)

  [db_path, "SELECT COUNT(*)"]
  |> sqlite.handle_args
  |> should.be_error
  |> should.equal("Expected sql but unable to parse input.")
}

pub fn handle_args_select_count_test() {
  use db_path <- temporary.create(temporary.file())
  use _ <- utils.do_with_temp_db3(db_path, utils.test_sql_file)
  let assert Ok(expected_result_set) = [["10"]] |> result_set.new

  [db_path, "SELECT COUNT(*) FROM employees"]
  |> sqlite.handle_args
  |> should.be_ok
  |> should.equal(result_set.to_string(expected_result_set))
}
