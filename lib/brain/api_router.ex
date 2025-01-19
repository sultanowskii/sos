import XmlBuilder

defmodule Brain.ApiRouter do
  @moduledoc """
  API Endpoints router.
  """
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

    # TODO: DB
    data =
      element(
        :ListAllMyBucketsResult,
        [
          element(
            :Buckets,
            [
              element(
                :Bucket,
                [
                  element(:CreationDate, "some date"),
                  element(:Name, "test")
                ]
              )
            ]
          ),
          element(
            :Prefix,
            prefix
          )
        ]
      )

    xml_resp = data |> XmlBuilder.generate()
    send_resp(conn, 200, xml_resp)
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

    # TODO: DB
    data =
      element(
        :ListBucketResult,
        [
          element(:Name, "bucket name"),
          element(:Prefix, prefix),
          element(:KeyCount, 123),
          element(:IsTruncated, false),
          element(
            :Contents,
            [
              element(:Key, "some-key.txt"),
              element(:LastModified, "timestamp!!"),
              element(:Size, 1337),
              element(:StorageClass, "STANDARD")
            ]
          ),
          element(
            :Contents,
            [
              element(:Key, "some-other-key.pdf"),
              element(:LastModified, "other timestamp"),
              element(:Size, 228),
              element(:StorageClass, "STANDARD")
            ]
          )
        ]
      )

    xml_resp = data |> XmlBuilder.generate()

    send_resp(conn, 200, xml_resp)
  end

  # CreateBucket
  put "/:bucket" do
    # TODO: DB
    conn |> put_resp_header("location", "/#{bucket}")
    send_resp(conn, 200, "")
  end

  # DeleteBucket
  delete "/:bucket" do
    # TODO: DB
    send_resp(conn, 204, "")
  end

  # PutObject / CopyObject
  # Supported headers:
  # - x-amz-copy-source
  put "/:bucket/*key_parts" do
    key = key_from_tokens(key_parts)

    conn = fetch_query_params(conn)

    copy_source = conn |> get_req_header("x-amz-copy-source")

    case coordinator() do
      {:ok, c} ->
        if copy_source |> Enum.empty?() do
          # PutObject
          _res = GenServer.call(c, {:put_object, bucket, key})
          send_resp(conn, 200, "")
        else
          # CopyObject
          parse_result = parse_path(copy_source)

          case parse_result do
            {:err, message} ->
              send_resp(conn, 400, message)

            {source_bucket, source_key} ->
              _res =
                GenServer.call(
                  c,
                  {:copy_object, bucket, key, source_bucket, source_key}
                )

              data =
                element(
                  :CopyObjectResult,
                  [
                    element(:LastModified, "timestamp!!"),
                    element(:ChecksumSHA1, "123456789")
                  ]
                )

              xml_resp = data |> XmlBuilder.generate()
              send_resp(conn, 200, xml_resp)
          end
        end

      :err ->
        error_coordinator_not_found_in_registry(conn)
    end
  end

  # GetObject
  get "/:bucket/*key_parts" do
    key = key_from_tokens(key_parts)

    case coordinator() do
      {:ok, c} ->
        res = GenServer.call(c, {:get_object, bucket, key})
        send_resp(conn, 200, res)

      :err ->
        error_coordinator_not_found_in_registry(conn)
    end
  end

  # DeleteObject
  delete "/:bucket/*key_parts" do
    key = key_from_tokens(key_parts)

    case coordinator() do
      {:ok, c} ->
        _res = GenServer.call(c, {:delete_object, bucket, key})
        send_resp(conn, 204, "")

      :err ->
        error_coordinator_not_found_in_registry(conn)
    end
  end

  match _ do
    request_url = request_url(conn)
    Logger.debug("attempted to access #{inspect(request_url)}, #{inspect(conn)}")
    send_resp(conn, 404, "{}")
  end

  defp error_coordinator_not_found_in_registry(conn) do
    Logger.warning("coordinator isn't found in registry")
    send_resp(conn, 503, "service unavailable")
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
        {:err, "invalid parameter"}
    end
  end

  defp coordinator do
    case Registry.lookup(BrainRegistry, :coordinator) do
      [] -> :err
      [{pid, _} | _] -> {:ok, pid}
    end
  end
end
