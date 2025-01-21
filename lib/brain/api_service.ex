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

  def list_buckets(prefix) do
    case GenServer.call(Db.MnesiaProvider, {:get_all_by_prefix, Db.Bucket, prefix}) do
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

  # TODO REMOVE, ONLY FOR TESTING
  def ping() do
    GenServer.call(Brain.Coordinator, {:put_object, "my_bucket", "my_key.txt", "binary_data"})

    GenServer.call(
      Brain.Coordinator,
      {:put_object, "my_buck312et", "3my_1key.txt", "binary_data"}
    )

    GenServer.call(
      Brain.Coordinator,
      {:put_object, "my_buck312et", "dasdsadasmy_k312ey.txt", "das"}
    )

    GenServer.call(
      Brain.Coordinator,
      {:put_object, "my_buck321et", "my1_k312ey.txt", "binary_dadata"}
    )

    GenServer.call(
      Brain.Coordinator,
      {:put_object, "my_buck312et", "my1_k312ey.txt", "binary_adata"}
    )
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
