import gleam/set
import nibble/lexer

pub type SqlToken {
  Asterisk
  AutoIncrement
  ColumnType(String)
  Comma
  Count
  Create
  From
  Identifier(String)
  LParen
  PrimaryKey
  RParen
  SelectToken
  TableToken
}

pub fn lexer() {
  lexer.simple([
    lexer.keyword("select", " ", SelectToken),
    lexer.keyword("count", "\\(", Count),
    lexer.token("(", LParen),
    lexer.token("*", Asterisk),
    lexer.token(")", RParen),
    lexer.keyword("from", " ", From),
    lexer.identifier(
      "[a-z_]",
      "[a-zA-Z0-9_]",
      set.from_list([
        ".", "-", "create", "table", "integer", "text", "primary", "boolean",
        "autoincrement",
      ]),
      Identifier,
    ),
    //
    lexer.keyword("create", " ", Create),
    lexer.keyword("table", " ", TableToken),
    lexer.identifier(
      "[a-zA-Z]",
      "[a-zA-Z]",
      set.from_list(["create", "table", "primary", "autoincrement"]),
      ColumnType,
    ),
    lexer.keyword("primary key", "\\s+|,|\\)", PrimaryKey),
    lexer.keyword("autoincrement", "\\s+|,|\\)", AutoIncrement),
    lexer.token(",", Comma),
    //
    lexer.whitespace(Nil) |> lexer.ignore,
  ])
}
