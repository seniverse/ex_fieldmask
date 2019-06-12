defmodule FieldMask do
  @moduledoc """
  FieldMask implements [Partial Responses protocol of Google+ API](https://developers.google.com/+/web/api/rest/#partial-responses) purely in Elixir via algorithmic method.
  """
  @delimiters [",", "/", "(", ")"]

  @doc """
  Compile text with Partial Responses protocol of Google+ API
  """
  def compile(text) when is_binary(text) do
    {tree, path, stack, _} = text |> scan() |> parse()

    cond do
      length(path) > 0 -> {:error, "Invalid text with inconsistent recursive depth: #{text}"}
      length(stack) > 0 -> {:error, "Invalid text with unmatchable brackets or slash: #{text}"}
      # TODO
      true -> nil
    end
  rescue
    InvalidText -> {:error, "Invalid text with unmatchable brackets: #{text}"}
  end

  @doc """
  Get tokens from text

  ## Examples

      iex> FieldMask.scan("ob,a(k,z(f,g/d))")
      ["ob", ",", "a", "(", "k", ",", "z", "(", "f", ",", "g", "/", "d", ")", ")"]

      iex> FieldMask.scan("ob,a(k,z(f,g/d)),d")
      ["ob", ",", "a", "(", "k", ",", "z", "(", "f", ",", "g", "/", "d", ")", ")", ",", "d"]

      iex> FieldMask.scan("")
      []
  """
  def scan(text) when is_binary(text) do
    text
    |> String.graphemes()
    |> Enum.chunk_while(
      [],
      fn char, acc ->
        if char in @delimiters do
          {:cont, {Enum.reverse(acc), char}, []}
        else
          {:cont, [char | acc]}
        end
      end,
      fn
        [] -> {:cont, [[], nil]}
        acc -> {:cont, {Enum.reverse(acc), nil}, []}
      end
    )
    |> Enum.reduce([], fn item, acc ->
      chars = elem(item, 0)
      delimiter = elem(item, 1)
      [delimiter, Enum.join(chars) | acc]
    end)
    |> Enum.reverse()
    |> Enum.filter(fn str -> str !== nil and str !== "" end)
  end

  @doc """
  Parse JSON tree from tokens
  """
  def parse(tokens) do
    tokens
    |> Enum.reduce({%{}, [], [], nil}, fn token, acc ->
      {tree, path, stack, last_token} = acc

      case token do
        "," ->
          acc

        "/" ->
          {tree, [last_token | path], [token | stack], token}

        "(" ->
          {tree, [last_token | path], [token | stack], token}

        ")" ->
          if List.first(stack) !== "(" do
            raise InvalidText
          end

          {tree, tl(path), tl(stack), token}

        _ ->
          tree = put_in(tree, Enum.reverse([token | path]), %{})

          if List.first(stack) === "/" do
            {tree, tl(path), tl(stack), token}
          else
            {tree, path, stack, token}
          end
      end
    end)
  end
end

defmodule InvalidText do
  defexception message: "Invalid text for parser"
end
