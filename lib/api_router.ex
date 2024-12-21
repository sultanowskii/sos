defmodule SOS.ApiRouter do
  @moduledoc """
  API Endpoints router.
  """
  use Plug.Router
  require Logger

  plug(:match)
  plug(:dispatch)

  get "/" do
    send_resp(conn, 404, "{}")
  end

  get "/:bucket/*key_parts" do
    send_resp(conn, 200, "I'm a file content!")
  end

  match _ do
    request_url = conn |> request_url()
    Logger.debug("attempted to access #{inspect(request_url)}, #{inspect(conn)}")
    send_resp(conn, 404, "{}")
  end
end
