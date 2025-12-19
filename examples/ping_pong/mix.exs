defmodule PingPong.MixProject do
  use Mix.Project

  def project do
    [
      app: :ping_pong,
      compilers: [:private_module] ++ Mix.compilers(),
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_options: [
        warnings_as_errors: true
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {PingPong.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:private_module, "~> 0.1"},
      {:raylib, "~> 0.0", path: "../../raylib"},
      {:pocion, "~> 0.0", path: "../../pocion"}
    ]
  end
end
