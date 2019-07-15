defmodule FieldParser do
  @moduledoc """
  Grammar Parser for Google+ Partial Response text delivered by field

  ## Grammar definition via BNF (Backus Normal Form)

  Props ::= Prop | Prop "," Props
  Prop ::= Object | Array
  Object ::= NAME | NAME "/" Object
  Array ::= NAME "(" Props ")"
  NAME ::= ? all visible characters ?
  """
  import NimbleParsec

  defparsec(:name, utf8_string([{:not, ?,}, {:not, ?(..?)}, {:not, ?/}, {:not, ?*}], min: 1),
    inline: true
  )

  defparsec(
    :object,
    choice([parsec(:name), string("*")]) |> optional(string("/") |> parsec(:object)),
    inline: true
  )

  defparsec(
    :array,
    parsec(:name) |> string("(") |> parsec(:props) |> string(")"),
    inline: true
  )

  defparsec(:prop, choice([parsec(:array), parsec(:object)]), inline: true)

  defparsec(
    :props,
    parsec(:prop) |> optional(string(",") |> parsec(:props)),
    inline: true
  )

  defparsec(:parser, parsec(:props) |> eos(), inline: true)
end
