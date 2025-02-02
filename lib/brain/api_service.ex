defmodule Brain.ApiService do
  @moduledoc """
  Brain service logic.
  """
  require Logger

  @err_coordinator_unavailable :coordinator_unavailable

  def list_buckets do
    case GenServer.call(Db.MnesiaProvider, {:get_all, Db.Bucket}) do
      {:ok, records} ->
        %{
          buckets:
            Enum.map(records, fn {:bucket, name, created_at} ->
              %{
                creation_date: created_at,
                name: name
              }
            end),
          prefix: ""
        }

      {:error, reason} ->
        Logger.warning("Failed to get buckets: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def list_objects(bucket) do
    case GenServer.call(Db.MnesiaProvider, {:get_objects_by_bucket, bucket}) do
      {:ok, records} ->
        contents =
          Enum.map(records, fn {:object, name, _bucket_name, _storage, size, created_at} ->
            %{
              key: name,
              last_modified: created_at,
              size: size,
              storage_class: "STANDARD"
            }
          end)

        result =
          %{
            name: bucket,
            prefix: "",
            key_count: Enum.count(records),
            is_truncated: false,
            contents: contents
          }

        {:ok, result}

      e = {:error, reason} ->
        Logger.warning("Failed to get objects: #{inspect(reason)}")
        e
    end
  end

  def create_bucket(bucket) do
    GenServer.call(Db.MnesiaProvider, {:add, Db.Bucket, {bucket}})
  end

  def delete_bucket(bucket) do
    GenServer.call(Db.MnesiaProvider, {:delete, Db.Bucket, {bucket}})
  end

  def put_object(bucket, key, data) do
    case coordinator() do
      {:ok, c} ->
        GenServer.call(c, {:put_object, bucket, key, data})

      :error ->
        {:error, @err_coordinator_unavailable}
    end
  end

  def get_object(bucket, key) do
    case coordinator() do
      {:ok, c} ->
        GenServer.call(c, {:get_object, bucket, key})

      :error ->
        {:error, @err_coordinator_unavailable}
    end
  end

  def delete_object(bucket, key) do
    case coordinator() do
      {:ok, c} ->
        GenServer.call(c, {:delete_object, bucket, key})

      :error ->
        {:error, @err_coordinator_unavailable}
    end
  end

  defp coordinator do
    case Registry.lookup(BrainRegistry, :coordinator) do
      [] -> :error
      [{pid, _} | _] -> {:ok, pid}
    end
  end
end
