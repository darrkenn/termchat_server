defmodule TermchatServer.Application do
  use Application

  @impl true
  def start(_type, _args) do
    IO.puts("Starting up server")

    {:ok, conn} = Exqlite.Sqlite3.open("/etc/termchat/server/database.db")

    :ok =
      Exqlite.Sqlite3.execute(conn, """
      CREATE TABLE IF NOT EXISTS Users (
      user_id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL UNIQUE,
      password TEXT NOT NULL
      )
      """)

    :ok =
      Exqlite.Sqlite3.execute(conn, """
      CREATE TABLE IF NOT EXISTS Messages (
      message_id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      message TEXT NOT NULL,
      time DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES Users(user_id)
      )
      """)

    children = [
      {Bandit, plug: Server, scheme: :http, port: 3113},
      Server.Chatroom
    ]

    opts = [strategy: :one_for_one, name: TermchatServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
