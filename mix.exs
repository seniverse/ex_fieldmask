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
        "FieldMask implements Partial Responses protocol of Google+ API purely in Elixir via algorithmic method rather than Grammar way",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:pre_commit_hook, ">= 1.2.0", only: :dev, runtime: false},
      {:credo, ">= 1.0.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
    ]
  end
end
