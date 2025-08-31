defmodule TermchatServer.Application do
  use Application

  @impl true
  def start(_type, _args) do
    IO.puts("Starting up server")

    children = [
      {Bandit, plug: Server, scheme: :http, port: 3113},
      Server.Chatroom
    ]

    opts = [strategy: :one_for_one, name: TermchatServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
