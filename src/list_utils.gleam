import gleam/bool

pub fn find_item_and_index(
  xs: List(x),
  predicate: fn(x) -> Bool,
) -> Result(#(x, Int), Nil) {
  find_item_and_index_helper(xs, predicate, 0)
}

pub fn find_item_and_index_helper(
  xs: List(x),
  predicate: fn(x) -> Bool,
  index: Int,
) {
  case xs {
    [] -> Error(Nil)
    [h, ..t] ->
      case predicate(h) {
        True -> Ok(#(h, index))
        _ -> find_item_and_index_helper(t, predicate, index + 1)
      }
  }
}

pub fn element_at(xs: List(x), index: Int) -> Result(x, Nil) {
  use <- bool.guard(index < 0, Error(Nil))
  element_at_helper(xs, index, 0)
}

fn element_at_helper(xs: List(x), target: Int, curr: Int) {
  case xs {
    [] -> Error(Nil)
    [h, ..] if curr == target -> Ok(h)
    [_, ..t] -> element_at_helper(t, target, curr + 1)
  }
}
