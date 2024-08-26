import gleam/set
import nibble/lexer

pub type SqlToken {
  Asterisk
  AutoIncrement
  ColumnType(String)
  Comma
  Count
  Create
  Equals
  From
  Identifier(String)
  Integer(Int)
  LParen
  PrimaryKey
  Real(Float)
  RParen
  Select
  Str(String)
  Table
  Where
}

pub fn lexer() {
  lexer.simple([
    lexer.token("(", LParen),
    lexer.token("*", Asterisk),
    lexer.token(")", RParen),
    lexer.token(",", Comma),
    lexer.token("=", Equals),
    lexer.keyword("select", " ", Select),
    lexer.keyword("count", "\\(", Count),
    lexer.keyword("from", " ", From),
    lexer.keyword("where", " ", Where),
    lexer.keyword("create", " ", Create),
    lexer.keyword("table", " ", Table),
    lexer.keyword("autoincrement", "\\s+|,|\\)", AutoIncrement),
    lexer.keyword("primary key", "\\s+|,|\\)", PrimaryKey),
    lexer.string("'", Str),
    lexer.number(Integer, Real),
    lexer.identifier(
      "[a-z_]",
      "[a-zA-Z0-9_]",
      set.from_list(["integer", "text", "primary", "boolean"]),
      Identifier,
    ),
    lexer.identifier(
      "[a-zA-Z]",
      "[a-zA-Z]",
      set.from_list(["primary"]),
      ColumnType,
    ),
    lexer.whitespace(Nil) |> lexer.ignore,
  ])
}
