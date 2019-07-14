defmodule FieldMask.MixProject do
  @moduledoc false
  use Mix.Project

  @version File.cwd!() |> Path.join("version") |> File.read!() |> String.trim()

  def project do
    [
      app: :ex_fieldmask,
      version: @version,
      elixir: "~> 1.8",
      description:
        "FieldMask implements Partial Responses protocol of Google+ API purely in Elixir via algorithmic method rather than grammar way.",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test],
      source_url: "https://github.com/seniverse/ex_fieldmask",
      homepage_url: "https://hex.pm/packages/ex_fieldmask",
      package: [
        licenses: ["Apache 2.0"],
        links: %{
          "GitHub" => "https://github.com/seniverse/ex_fieldmask",
          "Docs" => "https://hexdocs.pm/ex_fieldmask",
          "Author" => "http://maples7.com/about/"
        },
        maintainers: ["Maples7", "lib/*", ".formatter.exs"],
        files: ~w(lib .formatter.exs mix.exs README* LICENSE* CHANGELOG* version Makefile)
      ],
      docs: [
        extras: ["README.md", "CHANGELOG.md"],
        main: "readme"
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:nimble_parsec, "~> 0.5.0", only: :dev},
      {:pre_commit_hook, ">= 1.2.0", only: :dev, runtime: false},
      {:credo, ">= 1.0.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:excoveralls, "~> 0.11", only: [:dev, :test], runtime: false},
      {:benchee, "~> 1.0", only: :dev}
    ]
  end
end
