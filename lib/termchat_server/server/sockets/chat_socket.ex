defmodule Socket.ChatSocket do
  @behaviour WebSock

  def init(_state), do: {:ok, %{}}

  def handle_in({message, [opcode: :text]}, state) do
    IO.puts("Received from client: #{message}")
    {:push, {:text, "Echo: #{message}"}, state}
  end

  def handle_info(_info, state), do: {:ok, state}
  def terminate(_reason, _state), do: :ok
end
