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

  defparsec(:name, utf8_string([{:not, ?,}, {:not, ?(..?)}, {:not, ?/}, {:not, ?*}], min: 1))

  defparsec(
    :object,
    choice([parsec(:name), string("*")]) |> optional(string("/") |> parsec(:object))
  )

  defparsec(
    :array,
    parsec(:name) |> string("(") |> parsec(:props) |> string(")")
  )

  defparsec(:prop, choice([parsec(:array), parsec(:object)]))

  defparsec(
    :props,
    parsec(:prop) |> optional(string(",") |> parsec(:props))
  )

  defparsec(:parser, parsec(:props) |> eos())
end
