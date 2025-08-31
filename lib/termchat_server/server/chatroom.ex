defmodule Server.Chatroom do
  use GenServer

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def join(pid), do: GenServer.cast(__MODULE__, {:join, pid})
  def leave(pid), do: GenServer.cast(__MODULE__, {:leave, pid})
  def broadcast(msg), do: GenServer.cast(__MODULE__, {:broadcast, msg})

  def init(_), do: {:ok, %{clients: MapSet.new()}}

  def handle_cast({:join, pid}, state) do
    Process.monitor(pid)

    Enum.each(state.clients, fn client ->
      send(client, {:send, {:text, "New client joined"}})
    end)

    {:noreply, %{state | clients: MapSet.put(state.clients, pid)}}
  end

  def handle_cast({:leave, pid}, state) do
    {:noreply, %{state | clients: MapSet.delete(state.clients, pid)}}
  end

  def handle_cast({:broadcast, msg}, state) do
    Enum.each(state.clients, fn client ->
      send(client, {:send, {:text, msg}})
    end)

    {:noreply, state}
  end

  def handle_info({:DOWN, _, :process, pid, _}, state) do
    {:noreply, %{state | clients: MapSet.delete(state.clients, pid)}}
  end
end
