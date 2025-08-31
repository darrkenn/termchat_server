defmodule Server do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/" do
    send_resp(conn, 200, "Im termchat server")
  end

  match "/websocket" do
    WebSockAdapter.upgrade(conn, Client.Socket, %{}, [])
  end

  match _ do
    send_resp(conn, 404, "UhOh")
  end
end
