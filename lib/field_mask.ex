defmodule FieldMask do
  @moduledoc """
  FieldMask implements [Partial Responses protocol of Google+ API](https://developers.google.com/+/web/api/rest/#partial-responses) purely in Elixir via algorithmic method.
  """
  @delimiters [",", "/", "(", ")"]

  @doc ~S"""
  Get JSON result as a map masked by text

  ## Examples

      iex> FieldMask.mask("a,b", %{"a" => 1, "b" => 2, "c" => 3})
      {:ok, %{"a" => 1, "b" => 2}}

      iex> FieldMask.mask("a/b", %{"a" => %{"b" => 2, "c" => 3}})
      {:ok, %{"a" => %{"b" => 2}}}

      iex> FieldMask.mask("a(b,c)", %{"a" => %{"b" => 1, "c" => 2, "d" => 3}, "e" => 4})
      {:ok, %{"a" => %{"b" => 1, "c" => 2}}}

      iex> FieldMask.mask("a/*/c", %{"a" => %{"b" => %{"c" => 2, "e" => 1}, "d" => %{ "c" => 4, "f" => 3}}})
      {:ok, %{"a" => %{"b" => %{"c" => 2}, "d" => %{"c" => 4}}}}

      iex> FieldMask.mask("a/*/c", %{"a" => [%{"c" => 2, "e" => 1}, %{ "c" => 4, "f" => 3}]})
      {:error, "%ArgumentError{message: \"Wrong type for data: [%{\\\"c\\\" => 2, \\\"e\\\" => 1}, %{\\\"c\\\" => 4, \\\"f\\\" => 3}]\"}"}

      iex> FieldMask.mask("a/b", %{"a" => 1, "b" => 2, "c" => 3})
      {:error, "%ArgumentError{message: \"Wrong type for data: 1\"}"}

      iex> FieldMask.mask("a/b)", %{"a" => 1, "b" => 2, "c" => 3})
      {:error, "Invalid text with mismatched brackets: a/b)"}

      iex> FieldMask.mask("a/*/c", %{"a" => {%{"c" => 2, "e" => 1}, %{ "c" => 4, "f" => 3}}})
      {:error, "%ArgumentError{message: \"Wrong type for data: {%{\\\"c\\\" => 2, \\\"e\\\" => 1}, %{\\\"c\\\" => 4, \\\"f\\\" => 3}}\"}"}
  """
  def mask(text, data) when is_binary(text) do
    text
    |> compile()
    |> (fn
          {:ok, tree} ->
            try do
              {:ok, reveal(tree, data)}
            rescue
              e in ArgumentError ->
                {:error, inspect(e)}
                # err -> {:error, "Fail to mask data with text: #{inspect(err)}"}
            end

          err ->
            err
        end).()
  end

  @doc """
  Get JSON result as a map from compiled tree
  """
  def reveal(tree, data) when is_map(tree) do
    tree
    |> Map.keys()
    |> (fn
          [] ->
            data

          ["*"] ->
            if is_map(data) do
              data
              |> Map.keys()
              |> Enum.map(&[&1, reveal(tree["*"], data[&1])])
              |> Map.new(fn pair -> List.to_tuple(pair) end)
            else
              raise ArgumentError, message: "Wrong type for data: #{inspect(data)}"
            end

          keys ->
            cond do
              is_list(data) ->
                Enum.map(data, &reveal(tree, &1))

              is_map(data) ->
                keys
                |> Enum.map(&[&1, reveal(tree[&1], data[&1])])
                |> Map.new(fn pair -> List.to_tuple(pair) end)

              true ->
                raise ArgumentError, message: "Wrong type for data: #{inspect(data)}"
            end
        end).()
  end

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

      iex> FieldMask.compile("a/b,c")
      {:ok, %{"a" => %{"b" => %{}}, "c" => %{}}}

      iex> FieldMask.compile("ob,a(k,z(f,g/d))")
      {
        :ok,
        %{
          "a" => %{"k" => %{}, "z" => %{"f" => %{}, "g" => %{"d" => %{}}}},
          "ob" => %{}
        }
      }

      iex> FieldMask.compile("url,object(content,attachments/url)")
      {:ok,
      %{
        "object" => %{"attachments" => %{"url" => %{}}, "content" => %{}},
        "url" => %{}
      }}

      iex> FieldMask.compile("a(b,c")
      {:error, "Invalid text with mismatched brackets: a(b,c"}

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
          |> Enum.reduce(0, fn token, acc ->
            case token do
              "(" -> acc + 1
              ")" -> acc - 1
              _ -> acc
            end
          end)
          |> (fn
                0 -> {:ok, tree}
                _ -> {:error, "Invalid text with mismatched brackets: #{text}"}
              end).()
        end).()
  rescue
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
