defmodule FieldMask do
  @moduledoc """
  FieldMask implements [Partial Responses protocol of Google+ API](https://developers.google.com/+/web/api/rest/#partial-responses) purely in Elixir via algorithmic method.
  """
  @delimiters [",", "/", "(", ")"]

  @doc ~S"""
  Compile text with Partial Responses protocol of Google+ API

  ## Examples

      iex> FieldMask.compile("a,b,c")
      {:ok, %{"a" => %{}, "b" => %{}, "c" => %{}}}

      iex> FieldMask.compile("a/b/c")
      {:ok, %{"a" => %{"b" => %{"c" => %{}}}}}

      iex> FieldMask.compile("a(b,c)")
      {:ok, %{"a" => %{"b" => %{}, "c" => %{}}}}

      iex> FieldMask.compile("a/*/c")
      {:ok, %{"a" => %{"*" => %{"c" => %{}}}}}

      iex> FieldMask.compile("ob,a(k,z(f,g/d))")
      {
        :ok,
        %{
          "a" => %{"k" => %{}, "z" => %{"f" => %{}, "g" => %{"d" => %{}}}},
          "ob" => %{}
        }
      }

      iex> FieldMask.compile("a(b,c")
      {:error, "Invalid text with unmatchable brackets: a(b,c"}

      iex> FieldMask.compile("a(b//c")
      {:error, "Fail to parse text a(b//c: %ArgumentError{message: \"could not put/update key \\\"c\\\" on a nil value\"}"}
  """
  def compile(text) when is_binary(text) do
    text
    |> scan()
    |> parse()
    |> (fn {tree, _, stack, _} ->
          stack
          |> Enum.reverse()
          |> Enum.filter(&(&1 !== "/"))
          |> Enum.reduce(0, fn token, acc ->
            case token do
              "(" -> acc + 1
              ")" -> acc - 1
              _ -> acc
            end
          end)
          |> (fn
                0 ->
                  {:ok, tree}

                _ ->
                  {:error, "Invalid text with unmatchable brackets: #{text}"}
              end).()
        end).()
  rescue
    InvalidText -> {:error, "Invalid text: #{text}"}
    e -> {:error, "Fail to parse text #{text}: #{inspect(e)}"}
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
          if List.first(stack) === "/" do
            {tree, tl(path), tl(stack), token}
          else
            acc
          end

        "/" ->
          {tree, [last_token | path], [token | stack], token}

        "(" ->
          {tree, [last_token | path], [token | stack], token}

        ")" ->
          {tree, tl(path), [token | stack], token}

        _ ->
          {put_in(tree, Enum.reverse([token | path]), %{}), path, stack, token}
      end
    end)
  end
end

defmodule InvalidText do
  defexception message: "Invalid text for parser"
end
