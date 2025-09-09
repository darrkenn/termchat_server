defmodule TermchatServer.MixProject do
  use Mix.Project

  def project do
    [
      app: :termchat_server,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {TermchatServer.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.4"},
      {:bandit, "~> 1.8"},
      {:ecto_sql, "~> 3.0"},
      {:exqlite, "~> 0.27"},
      {:websock_adapter, "~> 0.5"},
      {:bcrypt_elixir, "~> 3.0"}
    ]
  end
end
