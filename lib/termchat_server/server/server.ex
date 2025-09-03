defmodule Server do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/" do
    IO.puts("User requested json")

    case Utils.Json.read_decode("/etc/termchat/server/info.json") do
      {:ok, json} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(json))

      {:error, error} ->
        conn
        |> send_resp(500, "#{inspect(error)}")
    end
  end

  match "/chat" do
    WebSockAdapter.upgrade(conn, Client.Socket, %{}, timeout: 120_000)
  end

  match _ do
    send_resp(conn, 404, "UhOh")
  end
end
