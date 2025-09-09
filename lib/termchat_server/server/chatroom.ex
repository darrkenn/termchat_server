defmodule Server.Chatroom do
  use GenServer

  def start_link(conn), do: GenServer.start_link(__MODULE__, %{conn: conn}, name: __MODULE__)

  def join(pid, username), do: GenServer.cast(__MODULE__, {:join, pid, username})
  def leave(pid), do: GenServer.cast(__MODULE__, {:leave, pid})
  def init(_), do: {:ok, %{clients: %{}}}

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

  def handle_info({:DOWN, _, :process, pid, _}, state) do
    {:noreply, %{state | clients: Map.delete(state.clients, pid)}}
  end
end
