defmodule Brain.ApiSerice do
  @moduledoc """
  Brain service logic.
  """
  require Logger

  @err_coordinator_unavailable :coordinator_unavailable

  def list_buckets(prefix) do
    case GenServer.call(Db.MnesiaProvider, {:get_by_prefix, Db.Bucket, prefix}) do
      {:ok, records} ->
        %{
          buckets:
            Enum.map(records, fn {:bucket, name, created_at} ->
              %{
                creation_date: created_at,
                name: name
              }
            end),
          prefix: prefix
        }

      {:error, reason} ->
        Logger.warning("Failed to get buckets: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def list_objects(prefix) do
    case GenServer.call(Db.MnesiaProvider, {:get_by_prefix, Db.Object, prefix}) do
      {:ok, records} ->
        grouped_by_bucket =
          Enum.group_by(records, fn {:object, _name, bucket_name, _storage, _size, _created_at} ->
            bucket_name
          end)

        contents =
          Enum.map(grouped_by_bucket, fn {bucket_name, records} ->
            %{
              bucket_name: bucket_name,
              prefix: prefix,
              key_count: Enum.count(records),
              is_truncated: false,
              contents:
                Enum.map(records, fn {:object, name, _bucket_name, _storage, size, created_at} ->
                  %{
                    key: name,
                    last_modified: created_at,
                    size: size,
                    storage_class: "STANDARD"
                  }
                end)
            }
          end)

        {:ok, contents}

      {:error, reason} ->
        Logger.warning("Failed to get objects: #{inspect(reason)}")
        {:error, reason}
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
