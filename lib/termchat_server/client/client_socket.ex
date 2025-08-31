defmodule Client.Socket do
  @behaviour WebSock

  def init(_state) do
    {:push, {:text, "Server: Enter a username: "}, %{no_username: true}}
  end

  def handle_in({message, [opcode: :text]}, %{no_username: true}) do
    username = String.trim(message)
    Server.Chatroom.join(self(), username)
    {:push, {:text, "Server: Welcome #{username}"}, %{username: username}}
  end

  def handle_in({message, [opcode: :text]}, state) do
    msg = String.trim(message)

    case msg do
      "/connected" ->
        users = Server.Chatroom.list_users()
        {:push, {:text, "Connected users: #{Enum.join(users, ", ")}"}, state}

      "" ->
        {:ok, state}

      _ ->
        Server.Chatroom.broadcast(self(), msg)
        {:ok, state}
    end
  end

  def handle_info({:send, frame}, state) do
    {:push, frame, state}
  end

  def terminate(_reason), do: Server.Chatroom.leave(self())
  def terminate(_reason, _state), do: Server.Chatroom.leave(self())
end
