defmodule Server do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/" do
    send_resp(conn, 200, "Im termchat server")
  end

  match "/chat" do
    WebSockAdapter.upgrade(conn, Client.Socket, %{}, timeout: 120_000)
  end

  match _ do
    send_resp(conn, 404, "UhOh")
  end
end
