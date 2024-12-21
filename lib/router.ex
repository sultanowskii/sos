defmodule SOS.Router do
  use Plug.Router
  require Logger

  plug(:match)
  plug(:dispatch)

  forward("/api", to: SOS.ApiRouter)

  match _ do
    request_url = conn |> request_url()
    Logger.debug("attempted to access #{inspect(request_url)}, #{inspect(conn)}")
    send_resp(conn, 404, "This resource doesn't exist")
  end
end
