defmodule Client.Socket do
  @behaviour WebSock

  def init(_state) do
    Server.Chatroom.join(self())
    {:push, {:text, "Enter a username: "}, %{no_username: true}}
  end

  def handle_in({message, [opcode: :text]}, %{no_username: true}) do
    {:push, {:text, "Username #{message} accepted"}, %{username: message}}
  end

  def handle_in({message, [opcode: :text]}, %{username: username} = state) do
    Server.Chatroom.broadcast("#{username}: #{message}")
    {:ok, state}
  end

  def handle_info({:send, frame}, state) do
    {:push, frame, state}
  end

  def terminate(_reason, %{username: username}) do
    Server.Chatroom.leave(self())
    Server.Chatroom.broadcast("#{username} left!")
    :ok
  end
end
