defmodule Client.Socket do
  @behaviour WebSock

  def init(_state) do
    IO.puts("User trying to connect")
    {:push, {:text, ~s({"type":"request","reason":"username"})}, %{await: :username}}
  end

  def handle_in({response, [opcode: :text]}, %{await: :username} = state) do
    case Jason.decode(response) do
      {:ok, %{"type" => "response", "username" => username}} ->
        new_state = %{await: :password, username: username}
        {:push, {:text, ~s({"type":"request","reason":"password"})}, new_state}

      _ ->
        {:ok, state}
    end
  end

  def handle_in({raw, [opcode: :text]}, %{await: :password, username: username} = state) do
    case Jason.decode(raw) do
      {:ok, %{"type" => "response", "password" => _password}} ->
        Server.Chatroom.join(self(), username)
        {:push, {:text, ~s({"type":"server","reason":"authenticated"})}, %{username: username}}

      _ ->
        {:ok, state}
    end
  end

  def handle_in({message, [opcode: :text]}, state) do
    case message do
      "/connected" ->
        users = Server.Chatroom.list_users()
        {:push, {:text, "Connected users: #{Enum.join(users, ", ")}"}, state}

      "/leave" ->
        Server.Chatroom.leave(self())
        {:stop, :normal, state}

      "" ->
        {:ok, state}

      _ ->
        Server.Chatroom.broadcast(self(), message)
        {:ok, state}
    end
  end

  def handle_info({:send, {:text, json}}, state) do
    {:push, {:text, json}, state}
  end

  def handle_info({:error, :max_users_reached}, state) do
    {:stop, :normal, state}
  end

  def handle_info({:EXIT, _, _}, state) do
    {:stop, :normal, state}
  end

  def terminate(_reason), do: Server.Chatroom.leave(self())
  def terminate(_reason, _state), do: Server.Chatroom.leave(self())
end
