defmodule Brain.Router do
  use Plug.Router
  require Logger

  plug(:match)
  plug(:dispatch)

  forward("/api", to: Brain.ApiRouter)

  match _ do
    request_url = conn |> request_url()
    Logger.debug("attempted to access #{inspect(request_url)}, #{inspect(conn)}")
    send_resp(conn, 404, "this resource doesn't exist")
  end
end
