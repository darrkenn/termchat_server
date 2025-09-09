defmodule TermchatServer.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children =
      if Mix.env() != :test do
        {:ok, conn} = Exqlite.Sqlite3.open("/etc/termchat/server/users.db")
        create_tables(conn)

        [
          {Bandit, plug: Server, scheme: :http, port: 3113},
          {Server.Chatroom, conn}
        ]
      else
        [
          {Bandit, plug: Server, scheme: :http, port: 3113}
        ]
      end

    opts = [strategy: :one_for_one, name: TermchatServer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp create_tables(conn) do
    :ok =
      Exqlite.Sqlite3.execute(conn, """
      CREATE TABLE IF NOT EXISTS Users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL UNIQUE,
      password TEXT NOT NULL
      )
      """)
  end
end
