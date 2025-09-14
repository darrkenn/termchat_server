defmodule Client.Socket do
  alias Server.Chatroom
  @behaviour WebSock

  def init(_state) do
    IO.puts("User trying to connect")
    {:push, {:text, ~s({"type":"request","reason":"username"})}, %{await: :username}}
  end

  def handle_in({response, [opcode: :text]}, %{await: :username} = state) do
    case Jason.decode(response) do
      {:ok, %{"type" => "response", "value" => username}} ->
        exists = Server.Chatroom.username_exists(username)

        account_exists =
          if exists do
            IO.puts("Username exists")
            true
          else
            IO.puts("Username doesnt exist")
            false
          end

        new_state = %{await: :password, username: username, account_exists: account_exists}

        {:push, {:text, ~s({"type":"request","reason":"password"})}, new_state}

      _ ->
        {:ok, state}
    end
  end

  def handle_in(
        {response, [opcode: :text]},
        %{await: :password, username: username, account_exists: account_exists} = state
      ) do
    case Jason.decode(response) do
      {:ok, %{"type" => "response", "value" => password}} ->
        authenticated =
          if account_exists do
            case Server.Chatroom.correct_password(password, username) do
              {:ok, true} ->
                Server.Chatroom.join(self(), username)
                ~s({"type":"server","reason":"authenticated"})

              {:ok, false} ->
                ~s({"type":"server","reason":"unauthenticated","reason":"Incorrect password"})
            end
          else
            Server.Chatroom.create_account(password, username)
            Server.Chatroom.join(self(), username)
            ~s({"type":"server","reason":"authenticated"})
          end

        {:push, {:text, authenticated}, %{username: username}}

      _ ->
        {:ok, state}
    end
  end

  def handle_in({response, [opcode: :text]}, state) do
    case Jason.decode(response) do
      {:ok, %{"type" => "message", "value" => message}} ->
        case message do
          "/connected" ->
            users = Server.Chatroom.list_users()

            json =
              Jason.encode!(%{
                type: "server",
                reason: "message",
                body: Enum.join(users, ", ")
              })

            send(self(), {:send, {:text, json}})
            {:ok, state}

          "/leave" ->
            Server.Chatroom.leave(self())
            {:stop, :normal, state}

          "" ->
            {:ok, state}

          _ ->
            Server.Chatroom.broadcast(self(), message)
            {:ok, state}
        end

      {:ok, %{"type" => "priv_msg", "receiver" => receiver, "message" => message}} ->
        Chatroom.priv_msg(self(), message, receiver)
        {:ok, state}

      _ ->
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
