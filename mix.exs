defmodule Excentrique.MixProject do
  use Mix.Project

  def project do
    [
      app: :excentrique,
      version: "1.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      # Docs
      name: "Excentrique",
      source_url: "https://github.com/graupe/excentrique",
      homepage_url: "https://github.com/graupe/excentrique",
      docs: &docs/0
    ]
  end

  defp docs do
    [
      # The main page in the docs
      main: "Excentrique"
      # logo: "path/to/logo.png",
      # extras: ["README.md"]
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
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end
end
