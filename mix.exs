defmodule Callisto.Mixfile do
  use Mix.Project

  def project do
    [app: :callisto,
     version: "0.1.0",
     description: description(),
     package: package(),
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     test_coverage: [
       tool: Coverex.Task,
       console_log: true],
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:inflex, "~> 1.7.0"},
      {:uuid, "~> 1.1"},
      {:mix_test_watch, "~> 0.2", only: :dev},
      {:ex_doc, github: "elixir-lang/ex_doc"},
      # coverage tool for tests
      # https://github.com/alfert/coverex
      {:coverex, "~> 1.4.9", only: :test},
    ]
  end

  defp description do
    """
    Abstraction layer around graph databases and their query languages.
    """
  end

  defp package do
    [name: :callisto,
     files: ["lib", "priv", "mix.exs", "README*", "readme*", "LICENSE*", "license*"],
     maintainers: ["...Paul", "Michael Kompanets"],
     licenses: ["Apache 2.0"],
     links: %{"GitHub" => "https://github.com/CollabRx/callisto"}
    ]
  end
end
