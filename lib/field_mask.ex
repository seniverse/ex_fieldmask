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

  defp reveal(tree, data) when is_map(tree) do
    tree
    |> Map.keys()
    |> (fn
          [] ->
            data

          ["*"] ->
            keys = Map.keys(data)

            for key <- keys, into: %{} do
              {key, reveal(tree["*"], data[key])}
            end

          keys ->
            case data do
              data when is_list(data) ->
                for item <- data do
                  reveal(tree, item)
                end

              data when is_map(data) ->
                for key <- keys, into: %{} do
                  {key, reveal(tree[key], data[key])}
                end
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
          pairs_count =
            for char <- stack, reduce: 0 do
              acc ->
                case char do
                  "(" -> acc + 1
                  ")" -> acc - 1
                  _ -> acc
                end
            end

          if pairs_count === 0 do
            {:ok, tree}
          else
            {:error, "Invalid text with mismatched brackets: #{text}"}
          end
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
    {result, state} =
      for char <- String.graphemes(text), reduce: {[], []} do
        {result, state} ->
          if char in @delimiters do
            case state !== [] do
              true -> {[char, state |> Enum.reverse() |> Enum.join() | result], []}
              false -> {[char | result], []}
            end
          else
            {result, [char | state]}
          end
      end

    case state !== [] do
      true -> [Enum.join(state) | result] |> Enum.reverse()
      false -> result |> Enum.reverse()
    end
  end

  @doc """
  Parse JSON tree from tokens
  """
  def parse(tokens) do
    for token <- tokens, reduce: {%{}, [], [], nil} do
      {tree, path, stack, last_token} ->
        case token do
          "," ->
            if List.first(stack) === "/" do
              {tree, tl(path), tl(stack), token}
            else
              {tree, path, stack, last_token}
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
    end
  end
end
