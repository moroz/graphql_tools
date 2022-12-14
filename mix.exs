defmodule GraphqlTools.MixProject do
  use Mix.Project

  def project do
    [
      app: :graphql_tools,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:absinthe, "~> 1.7"},
      {:ecto, "~> 3.0"},
      {:gettext, "~> 0.20.0"},
      {:plug, "~> 1.13"},
      {:scrivener, "~> 2.7"}
    ]
  end
end
