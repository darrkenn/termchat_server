defmodule Server do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/" do
    send_resp(conn, 200, "Im termchat server")
  end

  post "/echo" do
    {:ok, body, _conn} = Plug.Conn.read_body(conn)
    send_resp(conn, 200, body)
  end

  match "/websocket" do
    WebSockAdapter.upgrade(conn, Socket.ChatSocket, %{}, [])
  end

  match _ do
    send_resp(conn, 404, "UhOh")
  end
end
