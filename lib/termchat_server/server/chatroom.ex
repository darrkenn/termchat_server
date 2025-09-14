defmodule Server.Chatroom do
  use GenServer

  def start_link(conn), do: GenServer.start_link(__MODULE__, %{conn: conn}, name: __MODULE__)

  # Authentication
  def username_exists(username), do: GenServer.call(__MODULE__, {:username_exists, username})

  def create_account(pass, username),
    do: GenServer.call(__MODULE__, {:create_account, pass, username})

  def correct_password(pass, username),
    do: GenServer.call(__MODULE__, {:correct_password, pass, username})

  def join(pid, username), do: GenServer.cast(__MODULE__, {:join, pid, username})
  def leave(pid), do: GenServer.cast(__MODULE__, {:leave, pid})
  def init(%{conn: conn}), do: {:ok, %{conn: conn, clients: %{}}}

  def broadcast(pid, msg), do: GenServer.cast(__MODULE__, {:broadcast, pid, msg})

  # User Commands
  def list_users, do: GenServer.call(__MODULE__, :list_users)

  def priv_msg(pid, msg, username),
    do: GenServer.cast(__MODULE__, {:priv_msg, pid, msg, username})

  def handle_cast({:join, pid, username}, state) do
    {:ok, json} = Utils.Json.read_decode("/etc/termchat/server/config.json")

    if map_size(state.clients) < json["max_users"] do
      Process.monitor(pid)
      {:noreply, %{state | clients: Map.put(state.clients, pid, username)}}
    else
      send(pid, {:error, :max_users_reached})
      Process.exit(pid, :normal)
      {:noreply, state}
    end
  end

  def handle_cast({:leave, pid}, state) do
    {:noreply, %{state | clients: Map.delete(state.clients, pid)}}
  end

  def handle_cast({:broadcast, pid, msg}, state) do
    username = Map.get(state.clients, pid, "???")

    json =
      Jason.encode!(%{
        type: "message",
        from: username,
        body: msg
      })

    Enum.each(state.clients, fn {client, _} ->
      send(
        client,
        {:send, {:text, json}}
      )
    end)

    {:noreply, state}
  end

  def handle_cast({:priv_msg, pid, msg, username}, state) do
    sender = Map.get(state.clients, pid, "???")

    receiver_pid =
      state.clients
      |> Enum.find(fn {_pid, name} -> name == username end)
      |> case do
        {receiver, _} -> receiver
        nil -> nil
      end

    if receiver_pid do
      json =
        Jason.encode!(%{
          type: "priv_msg",
          sender: sender,
          body: msg
        })

      send(receiver_pid, {:send, {:text, json}})
    else
      IO.puts("Receiver PID not found: #{username}")
    end

    {:noreply, state}
  end

  def handle_call(:list_users, _, state) do
    usernames = Map.values(state.clients)
    {:reply, usernames, state}
  end

  def handle_call({:username_exists, username}, _, state) do
    {:ok, statement} =
      Exqlite.Sqlite3.prepare(
        state.conn,
        "SELECT username FROM Users WHERE username = ? LIMIT 1"
      )

    :ok = Exqlite.Sqlite3.bind(statement, [username])

    exists =
      case Exqlite.Sqlite3.step(state.conn, statement) do
        {:row, _} -> true
        :done -> false
      end

    :ok = Exqlite.Sqlite3.release(state.conn, statement)

    {:reply, exists, state}
  end

  def handle_call({:create_account, pass, username}, _, state) do
    hashed_pass = Bcrypt.hash_pwd_salt(pass)

    {:ok, statement} =
      Exqlite.Sqlite3.prepare(
        state.conn,
        "INSERT INTO Users (username, password) VALUES (?, ?)"
      )

    :ok = Exqlite.Sqlite3.bind(statement, [username, hashed_pass])

    result =
      case Exqlite.Sqlite3.step(state.conn, statement) do
        :done -> {:ok, "User created"}
        {:row, _} -> {:error, "Error"}
      end

    :ok = Exqlite.Sqlite3.release(state.conn, statement)

    {:reply, result, state}
  end

  def handle_call({:correct_password, pass, username}, _, state) do
    {:ok, statement} =
      Exqlite.Sqlite3.prepare(
        state.conn,
        "SELECT password FROM Users WHERE username = ? LIMIT 1"
      )

    :ok = Exqlite.Sqlite3.bind(statement, [username])

    result =
      case Exqlite.Sqlite3.step(state.conn, statement) do
        {:row, [hashed_pass]} ->
          if Bcrypt.verify_pass(pass, hashed_pass) do
            IO.puts("Password correct")
            {:ok, true}
          else
            IO.puts("Password incorrect")
            {:ok, false}
          end

        :done ->
          {:ok, false}
      end

    :ok = Exqlite.Sqlite3.release(state.conn, statement)

    {:reply, result, state}
  end

  def handle_info({:DOWN, _, :process, pid, _}, state) do
    {:noreply, %{state | clients: Map.delete(state.clients, pid)}}
  end
end
