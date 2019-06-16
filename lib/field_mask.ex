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

      iex> FieldMask.mask("a/b)", %{"a" => 1, "b" => 2, "c" => 3})
      {:error, "Invalid text with mismatched brackets: a/b)"}
  """
  def mask(text, data) when is_binary(text) do
    text
    |> compile()
    |> (fn
          {:ok, tree} -> {:ok, reveal(tree, data)}
          err -> err
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
            data
            |> Map.keys()
            |> Enum.map(&[&1, reveal(tree["*"], data[&1])])
            |> Map.new(fn pair -> List.to_tuple(pair) end)

          keys ->
            case data do
              data when is_list(data) ->
                Enum.map(data, &reveal(tree, &1))

              data when is_map(data) ->
                keys
                |> Enum.map(&[&1, reveal(tree[&1], data[&1])])
                |> Map.new(fn pair -> List.to_tuple(pair) end)
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

      iex> FieldMask.scan("abc/*")
      ["abc", "/", "*"]
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
        acc -> {:cont, {Enum.reverse(acc), nil}, []}
      end
    )
    |> Enum.reduce([], fn
      {[], nil}, acc -> acc
      {[], delimiter}, acc -> [delimiter | acc]
      {chars, nil}, acc -> [Enum.join(chars) | acc]
      {chars, delimiter}, acc -> [delimiter, Enum.join(chars) | acc]
    end)
    |> Enum.reverse()
  end

  @doc """
  Parse JSON tree from tokens
  """
  def parse(tokens) do
    tokens
    |> Enum.reduce({%{}, [], [], nil}, fn
      "," = token, {tree, path, stack, last_token} ->
        if List.first(stack) === "/" do
          {tree, tl(path), tl(stack), token}
        else
          {tree, path, stack, last_token}
        end

      "/" = token, {tree, path, stack, last_token} ->
        {tree, [last_token | path], [token | stack], token}

      "(" = token, {tree, path, stack, last_token} ->
        {tree, [last_token | path], [token | stack], token}

      ")" = token, {tree, path, stack, _} ->
        {tree, tl(path), [token | stack], token}

      token, {tree, path, stack, _} ->
        {put_in(tree, Enum.reverse([token | path]), %{}), path, stack, token}
    end)
  end
end
