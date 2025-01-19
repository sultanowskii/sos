defmodule SOS.MixProject do
  use Mix.Project

  def project do
    [
      app: :sos,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {SOS, []},
      extra_applications: [:logger, :mnesia]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:xml_builder, "~> 2.1"},
      {:bandit, "~> 1.0"}
    ]
  end
end
