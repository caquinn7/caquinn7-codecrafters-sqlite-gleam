import gleam/bool

pub fn find_index(xs: List(x), predicate: fn(x) -> Bool) -> Int {
  find_index_helper(xs, predicate, 0)
}

fn find_index_helper(xs: List(x), predicate: fn(x) -> Bool, index: Int) -> Int {
  case xs {
    [] -> -1
    [h, ..t] ->
      case predicate(h) {
        True -> index
        _ -> find_index_helper(t, predicate, index + 1)
      }
  }
}

pub fn element_at(xs: List(x), index: Int) -> Result(x, Nil) {
  use <- bool.guard(index < 0, Error(Nil))
  element_at_helper(xs, index, 0)
}

fn element_at_helper(xs: List(x), target: Int, curr: Int) -> Result(x, Nil) {
  case xs {
    [] -> Error(Nil)
    [h, ..] if curr == target -> Ok(h)
    [_, ..t] -> element_at_helper(t, target, curr + 1)
  }
}
