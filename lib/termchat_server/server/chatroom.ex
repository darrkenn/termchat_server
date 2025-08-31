defmodule Server.Chatroom do
  use GenServer

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def join(pid, username), do: GenServer.cast(__MODULE__, {:join, pid, username})
  def leave(pid), do: GenServer.cast(__MODULE__, {:leave, pid})
  def broadcast(pid, msg), do: GenServer.cast(__MODULE__, {:broadcast, pid, msg})
  def list_users, do: GenServer.call(__MODULE__, :list_users)

  def init(_), do: {:ok, %{clients: %{}}}

  # Casts
  def handle_cast({:join, pid, username}, state) do
    Process.monitor(pid)
    {:noreply, %{state | clients: Map.put(state.clients, pid, username)}}
  end

  def handle_cast({:leave, pid}, state) do
    {:noreply, %{state | clients: Map.delete(state.clients, pid)}}
  end

  def handle_cast({:broadcast, pid, msg}, state) do
    username = Map.get(state.clients, pid, "???")

    Enum.each(state.clients, fn {client, _} ->
      send(client, {:send, {:text, "[#{username}]: #{msg}"}})
    end)

    {:noreply, state}
  end

  # Calls
  def handle_call(:list_users, _, state) do
    usernames = Map.values(state.clients)
    {:reply, usernames, state}
  end

  def handle_info({:DOWN, _, :process, pid, _}, state) do
    {:noreply, %{state | clients: Map.delete(state.clients, pid)}}
  end
end
