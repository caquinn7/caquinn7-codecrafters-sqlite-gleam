import gleam/set
import nibble/lexer

pub type SqlToken {
  Asterisk
  AutoIncrement
  ColumnType(String)
  Comma
  Count
  Create
  DoubleQuote
  Equals
  From
  Identifier(String)
  Integer(Int)
  LParen
  NotNull
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
    lexer.token("*", Asterisk),
    lexer.token(",", Comma),
    lexer.token("=", Equals),
    lexer.token("(", LParen),
    lexer.token("\"", DoubleQuote),
    lexer.token(")", RParen),
    lexer.keyword("autoincrement", "\\s+|,|\\)", AutoIncrement),
    lexer.keyword("count", "\\(", Count),
    lexer.keyword("create", " ", Create),
    lexer.keyword("from", " ", From),
    lexer.keyword("not null", "\\s+|,|\\)", NotNull),
    lexer.keyword("primary key", "\\s+|,|\\)", PrimaryKey),
    lexer.keyword("select", " ", Select),
    lexer.keyword("table", " ", Table),
    lexer.keyword("where", " ", Where),
    lexer.string("'", Str),
    lexer.number(Integer, Real),
    lexer.identifier(
      "[a-z_]",
      "[a-zA-Z0-9_]",
      set.from_list(["integer", "text", "primary", "boolean", "not"]),
      Identifier,
    ),
    lexer.identifier(
      "[a-zA-Z]",
      "[a-zA-Z]",
      set.from_list(["primary", "not"]),
      ColumnType,
    ),
    lexer.whitespace(Nil) |> lexer.ignore,
  ])
}
