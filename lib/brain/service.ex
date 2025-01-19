defmodule Brain.Service do
  @moduledoc """
  Brain service logic.
  """

  @err_coordinator_unavailable :coordinator_unavailable

  def list_buckets(prefix) do
    # TODO: DB
    data = %{
      prefix: prefix,
      buckets: [
        %{
          creation_date: "some_date",
          name: "some name #1"
        },
        %{
          creation_date: "some_other_date",
          name: "some name #2"
        }
      ]
    }

    data
  end

  def list_objects(prefix) do
    # TODO: DB
    data = %{
      name: "some_bucket",
      prefix: prefix,
      key_count: 1123,
      is_truncated: false,
      contents: [
        %{
          key: "some/cool/key.txt",
          last_modified: "timestamp",
          size: 1337,
          storage_class: "STANDARD"
        },
        %{
          key: "some/other-cool/key.txt",
          last_modified: "other timestamp",
          size: 288,
          storage_class: "STANDARD"
        }
      ]
    }

    data
  end

  def create_bucket(_bucket) do
    # TODO: DB
  end

  def delete_bucket(_bucket) do
    # TODO: DB
  end

  def put_object(bucket, key) do
    case coordinator() do
      {:ok, c} ->
        GenServer.call(c, {:put_object, bucket, key})
        :ok

      :err ->
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

      :err ->
        {:error, @err_coordinator_unavailable}
    end
  end

  def get_object(bucket, key) do
    case coordinator() do
      {:ok, c} ->
        data = GenServer.call(c, {:get_object, bucket, key})
        {:ok, data}

      :err ->
        {:error, @err_coordinator_unavailable}
    end
  end

  def delete_object(bucket, key) do
    case coordinator() do
      {:ok, c} ->
        GenServer.call(c, {:delete_object, bucket, key})
        :ok

      :err ->
        {:error, @err_coordinator_unavailable}
    end
  end

  defp coordinator do
    case Registry.lookup(BrainRegistry, :coordinator) do
      [] -> :err
      [{pid, _} | _] -> {:ok, pid}
    end
  end
end
