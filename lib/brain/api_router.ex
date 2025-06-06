defmodule Brain.ApiRouter do
  @moduledoc """
  API Endpoints router.
  """
  alias Brain.ApiService
  alias Brain.Mapper

  use Plug.Router
  use Plug.ErrorHandler

  require Logger

  plug(:match)
  plug(:dispatch)

  @spec key_from_tokens([binary()]) :: binary()
  def key_from_tokens(tokens) do
    tokens |> Enum.join("/")
  end

  # ListBuckets
  get "/" do
    conn = fetch_query_params(conn)

    resp =
      ApiService.list_buckets()
      |> Mapper.map_resp_list_buckets()
      |> XmlBuilder.generate()

    send_resp(conn, 200, resp)
  end

  # ListObjectsV2
  # Supported params:
  # - list-type
  get "/:bucket" do
    conn = fetch_query_params(conn)
    params = conn.query_params
    _list_type = params["list-type"]

    result = ApiService.list_objects(bucket)

    case result do
      {:ok, result} ->
        resp =
          result
          |> Mapper.map_resp_list_objects()
          |> XmlBuilder.generate()

        send_resp(conn, 200, resp)

      e = {:error, _} ->
        handle_error(conn, e)
    end
  end

  # CreateBucket
  put "/:bucket" do
    ApiService.create_bucket(bucket)
    conn |> put_resp_header("location", "/#{bucket}")
    send_resp(conn, 200, "")
  end

  # DeleteBucket
  delete "/:bucket" do
    ApiService.delete_bucket(bucket)
    send_resp(conn, 204, "")
  end

  # PutObject / CopyObject
  # Supported headers:
  # - x-amz-copy-source
  put "/:bucket/*key_parts" do
    key = key_from_tokens(key_parts)
    conn = fetch_query_params(conn)
    copy_source = conn |> get_req_header("x-amz-copy-source")

    case copy_source do
      [] ->
        # PutObject
        with {:ok, request_data, conn} <- Plug.Conn.read_body(conn),
             :ok <- ApiService.put_object(bucket, key, request_data) do
          send_resp(conn, 200, "")
        else
          e = {:error, _} ->
            handle_error(conn, e)
        end

      _ ->
        # CopyObject
        send_resp(conn, 501, "copy is not supported")
    end
  end

  # GetObject
  get "/:bucket/*key_parts" do
    key = key_from_tokens(key_parts)
    result = ApiService.get_object(bucket, key)

    case result do
      {:ok, data} ->
        send_resp(conn, 200, data)

      e = {:error, _} ->
        handle_error(conn, e)
    end
  end

  # DeleteObject
  delete "/:bucket/*key_parts" do
    key = key_from_tokens(key_parts)
    result = ApiService.delete_object(bucket, key)

    case result do
      :ok ->
        send_resp(conn, 204, "")

      e = {:error, _} ->
        handle_error(conn, e)
    end
  end

  match _ do
    request_url = request_url(conn)
    Logger.debug("attempted to access #{inspect(request_url)}, #{inspect(conn)}")
    send_resp(conn, 404, "{}")
  end

  defp handle_error(conn, e) do
    case e do
      {:error, :coordinator_unavailable} ->
        Logger.warning("API: coordinator isn't found in registry")
        send_resp(conn, 503, "service unavailable")

      {:error, :agents_unavailable} ->
        Logger.warning("API: no agent is available")
        send_resp(conn, 503, "service unavailable")

      _ ->
        Logger.warning("API: unexpected error #{inspect(e)}")
        send_resp(conn, 500, "unexpected error")
    end
  end
end
