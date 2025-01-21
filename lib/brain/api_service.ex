defmodule Brain.ApiSerice do
  @moduledoc """
  Brain service logic.
  """
  require Logger

  @err_coordinator_unavailable :coordinator_unavailable

  def list_buckets do
    case GenServer.call(Db.MnesiaProvider, {:get_all, Db.Bucket}) do
      {:ok, records} ->
        data =
          Enum.map(records, fn record ->
            {:bucket, name, created_at} = record

            %{
              creation_date: created_at,
              name: name
            }
          end)

        data

      {:error, reason} ->
        Logger.warning("Failed to get buckets: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def list_buckets(name) do
    case GenServer.call(Db.MnesiaProvider, {:get_all, Db.Bucket, name}) do
      {:ok, records} ->
        data =
          Enum.map(records, fn record ->
            {:bucket, name, created_at} = record

            %{
              creation_date: created_at,
              name: name
            }
          end)

        data

      {:error, reason} ->
        Logger.error("Failed to get buckets: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def list_objects(bucket_name) do
    case GenServer.call(Db.MnesiaProvider, {:get_objects_by_bucket, bucket_name}) do
      {:ok, records} ->
        contents =
          Enum.map(records, fn record ->
            {:object, name, bucket_name_id, storage, created_at} = record

            %{
              name: name,
              key: "#{bucket_name_id}/#{name}",
              creation_date: created_at,
              storage: storage
            }
          end)

        %{
          name: bucket_name,
          key_count: Enum.count(contents),
          contents: contents
        }

      {:error, reason} ->
        Logger.warning("Failed to get buckets: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def list_objects do
    case GenServer.call(Db.MnesiaProvider, {:get_all, Db.Object}) do
      {:ok, records} ->
        contents =
          Enum.map(records, fn record ->
            {:object, name, bucket_name_id, storage, created_at} = record

            %{
              name: name,
              bucket_name: bucket_name_id,
              key: "#{bucket_name_id}/#{name}",
              creation_date: created_at,
              storage: storage
            }
          end)

        %{
          key_count: Enum.count(contents),
          contents: contents
        }

      {:error, reason} ->
        Logger.warning("Failed to get buckets: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def create_bucket(bucket) do
    GenServer.call(Db.MnesiaProvider, {:add, Db.Bucket, bucket})
  end

  def delete_bucket(bucket) do
    GenServer.call(Db.MnesiaProvider, {:delete, Db.Bucket, bucket})
  end

  def put_object(bucket, key, data) do
    case coordinator() do
      {:ok, c} ->
        GenServer.call(c, {:put_object, bucket, key, data})

      :error ->
        {:error, @err_coordinator_unavailable}
    end
  end

  def copy_object(source_bucket, source_key, dest_bucket, dest_key) do
    case coordinator() do
      {:ok, c} ->
        GenServer.call(
          c,
          {:copy_object, source_bucket, source_key, dest_bucket, dest_key}
        )

        {
          :ok,
          %{
            last_modified: "timestamp",
            checksum_sha1: "asd"
          }
        }

      :error ->
        {:error, @err_coordinator_unavailable}
    end
  end

  def get_object(bucket, key) do
    case coordinator() do
      {:ok, c} ->
        data = GenServer.call(c, {:get_object, bucket, key})
        {:ok, data}

      :error ->
        {:error, @err_coordinator_unavailable}
    end
  end

  def delete_object(bucket, key) do
    case coordinator() do
      {:ok, c} ->
        GenServer.call(c, {:delete_object, bucket, key})
        :ok

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
