defmodule Bcash.MixProject do
  use Mix.Project

  def project do
    [
      app: :bcash,
      version: "0.1.0",
      build_path: "./_build",
      config_path: "./config/config.exs",
      deps_path: "./deps",
      lockfile: "./mix.lock",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: "Bcash API wrapper in Elixir."
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 1.5"},
      {:exvcr, "~> 0.10", only: :test},
      {:poison, "~> 3.0"},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:elixir_uuid, "~> 1.2"}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/andrewcottage/bcash-elixir"},
      maintainers: ["Andrew Cottage"]
    ]
  end
end
