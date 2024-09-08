import gleam/set
import nibble/lexer

pub type SqlToken {
  Asterisk
  AutoIncrement
  Comma
  Count
  Create
  DoubleQuote
  Equals
  From
  Index
  Identifier(String)
  IdentifierQuoted(String)
  Integer(Int)
  IntegerType
  LParen
  NotNull
  On
  PrimaryKey
  Real(Float)
  RParen
  Select
  SingleQuotedString(String)
  DoubleQuotedString(String)
  Table
  TextType
  Where
}

pub fn lexer() {
  lexer.simple([
    lexer.token("*", Asterisk),
    lexer.token(",", Comma),
    lexer.token("=", Equals),
    lexer.token("(", LParen),
    lexer.token(")", RParen),
    lexer.keyword("autoincrement", "\\s+|,|\\)", AutoIncrement),
    lexer.keyword("count", "\\(", Count),
    lexer.keyword("create", " ", Create),
    lexer.keyword("from", " ", From),
    lexer.keyword("index", " ", Index),
    lexer.keyword("integer", "\\s+|,|\\)", IntegerType),
    lexer.keyword("not null", "\\s+|,|\\)", NotNull),
    lexer.keyword("on", " ", On),
    lexer.keyword("primary key", "\\s+|,|\\)", PrimaryKey),
    lexer.keyword("select", " ", Select),
    lexer.keyword("table", " ", Table),
    lexer.keyword("text", "\\s+|,|\\)", TextType),
    lexer.keyword("where", " ", Where),
    lexer.string("'", SingleQuotedString),
    lexer.string("\"", DoubleQuotedString),
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
