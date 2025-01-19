defmodule Brain.ApiRouter do
  @moduledoc """
  API Endpoints router.
  """
  alias Brain.Mapper
  alias Brain.Service

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
  # Supported params:
  # - prefix
  get "/" do
    conn = fetch_query_params(conn)
    params = conn.query_params
    prefix = params["prefix"]

    resp =
      Service.list_buckets(prefix)
      |> Mapper.map_resp_list_buckets()
      |> XmlBuilder.generate()

    send_resp(conn, 200, resp)
  end

  # ListObjectsV2
  # Supported params:
  # - list-type
  # - prefix
  get "/:bucket" do
    conn = fetch_query_params(conn)
    params = conn.query_params
    _list_type = params["list-type"]
    prefix = params["prefix"]

    resp =
      Service.list_objects(prefix)
      |> Mapper.map_resp_list_objects()
      |> XmlBuilder.generate()

    send_resp(conn, 200, resp)
  end

  # CreateBucket
  put "/:bucket" do
    Service.create_bucket(bucket)
    conn |> put_resp_header("location", "/#{bucket}")
    send_resp(conn, 200, "")
  end

  # DeleteBucket
  delete "/:bucket" do
    Service.delete_bucket(bucket)
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
        case Plug.Conn.read_body(conn) do
          {:ok, request_data, conn} ->
            result = Service.put_object(bucket, key, request_data)

            case result do
              :ok ->
                send_resp(conn, 200, "")

              e = {:error, _} ->
                handle_error(conn, e)
            end

          e = {:error, _} ->
            handle_error(conn, e)
        end

      _ ->
        # CopyObject
        parse_result = parse_path(copy_source)

        case parse_result do
          {:error, message} ->
            send_resp(conn, 400, message)

          {source_bucket, source_key} ->
            result = Service.copy_object(source_bucket, source_key, bucket, key)

            case result do
              {:ok, raw} ->
                resp =
                  raw
                  |> Mapper.map_resp_copy_object()
                  |> XmlBuilder.generate()

                send_resp(conn, 200, resp)

              e = {:error, _} ->
                handle_error(conn, e)
            end
        end
    end
  end

  # GetObject
  get "/:bucket/*key_parts" do
    key = key_from_tokens(key_parts)
    result = Service.get_object(bucket, key)

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
    result = Service.delete_object(bucket, key)

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

  defp parse_path(s) do
    s
    |> Enum.at(0)
    |> String.trim("/")
    |> String.split("/")
    |> case do
      [source_bucket | source_key_parts] ->
        {source_bucket, key_from_tokens(source_key_parts)}

      _ ->
        {:error, "invalid parameter"}
    end
  end
end
