defmodule LedboardTester.MixProject do
  use Mix.Project

  def project do
    [
      app: :ledboard_tester,
      version: "0.1.0",
      elixir: "~> 1.11.4",
      start_permanent: Mix.env() == :prod,
      escript: [main_module: LedboardTester],
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp releases() do
    [
      ledboard_tester: [
        include_executables_for: [:unix],
        applications: [runtime_tools: :permanent]
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:elixir_uuid, "~> 1.2"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
