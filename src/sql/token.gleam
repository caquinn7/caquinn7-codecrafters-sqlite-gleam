import gleam/set
import nibble/lexer

pub type SqlToken {
  Asterisk
  AutoIncrement
  Comma
  Count
  Create
  Equals
  From
  Index
  Identifier(String)
  Integer(Int)
  NotNull
  On
  ParenL
  ParenR
  PrimaryKey
  Real(Float)
  Select
  StringDoubleQuoted(String)
  StringSingleQuoted(String)
  Table
  TypeInteger
  TypeReal
  TypeText
  Where
}

pub fn lexer() {
  lexer.simple([
    lexer.token("*", Asterisk),
    lexer.token(",", Comma),
    lexer.token("=", Equals),
    lexer.token("(", ParenL),
    lexer.token(")", ParenR),
    lexer.keyword("autoincrement", "\\s+|,|\\)", AutoIncrement),
    lexer.keyword("count", "\\(", Count),
    lexer.keyword("create", " ", Create),
    lexer.keyword("from", " ", From),
    lexer.keyword("index", " ", Index),
    lexer.keyword("integer", "\\s+|,|\\)", TypeInteger),
    lexer.keyword("not null", "\\s+|,|\\)", NotNull),
    lexer.keyword("on", " ", On),
    lexer.keyword("primary key", "\\s+|,|\\)", PrimaryKey),
    lexer.keyword("real", "\\s+|,|\\)", TypeReal),
    lexer.keyword("select", " ", Select),
    lexer.keyword("table", " ", Table),
    lexer.keyword("text", "\\s+|,|\\)", TypeText),
    lexer.keyword("where", " ", Where),
    lexer.string("'", StringSingleQuoted),
    lexer.string("\"", StringDoubleQuoted),
    lexer.number(Integer, Real),
    lexer.identifier(
      "[a-z_]",
      "[a-zA-Z0-9_]",
      set.from_list(["integer", "text", "primary", "boolean", "not"]),
      Identifier,
    ),
    lexer.whitespace(Nil) |> lexer.ignore,
  ])
}
