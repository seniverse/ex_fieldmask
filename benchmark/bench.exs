inputs =
  for input <- ["a,b,c", "a(b,c)", "a/b/c", "a/b,c", "a/*/c", "ob,a(k,z(f,g/d)),c"], into: %{} do
    {input, input}
  end

Benchee.run(
  %{
    "Elixir - algorithmic" => fn text ->
      FieldMask.scan(text)
    end,
    # Slower
    "Elixir - grammar" => fn text ->
      FieldParser.parser(text)
    end
  },
  parallel: 4,
  inputs: inputs
  # formatters: [
  #   {Benchee.Formatters.Markdown, file: "results/parser.md"},
  #   Benchee.Formatters.Console
  # ]
)
