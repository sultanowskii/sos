defmodule Db.MnesiaProvider do
  @moduledoc """
  Mnesia agent for processing operations with database
  """
  alias :mnesia, as: Mnesia
  use GenServer
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_) do
    status = Db.Cmd.init()
    {:ok, status}
  end

  @doc """
  Performs a health check on the database..
  """
  def handle_call(:health_check, _from, state) do
    case health_check() do
      :ok ->
        {:reply, :ok, state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  defp health_check do
    case Mnesia.system_info(:is_running) do
      :yes ->
        :ok

      _ ->
        {:error, "mnesia not running"}
    end
  end

  @doc """
  Adds records to Mnisia table


  examples:
    #adding to bucket table where bucket_name is "bucket_name"
    iex> {:ok, pid} = Db.MnesiaProvider.start_link([])
    ...> GenServer.call(pid, {:add, Db.Bucket, {"bucket_name"}})
    :ok

    #add an object (object_name="object_nameAAAA", bucket_name="bucket_name") record
    iex> {:ok, pid} = Db.MnesiaProvider.start_link([])
    ...> GenServer.call(pid, {:add, Db.Object, {"object_nameAAAA", "bucket_name","storage_name"}})
    :ok

    #add a storage (storage_name="storage_name", availabliity=true) record
    iex> {:ok, pid} = Db.MnesiaProvider.start_link([])
    ...> GenServer.call(pid, {:add, Db.Storage, {"storage_name", true}})
    :ok


    #example of error(same for each record)
    #adding to storage table data, but without available status
    iex> {:ok, pid} = Db.MnesiaProvider.start_link([])
    ...> GenServer.call(pid, {:add, Db.Storage, {"storage_name"}})
    {:error, {:transaction_aborted, {:bad_type, {:storage, "storage_name"}}}}
  """
  def handle_call({:add, module, record}, _from, state) do
    handle_db_operation(:add, module, record, state)
  end

  @doc """
  Gets records to Mnisia table

  sample of use TODO(need to ignore time difference while running the test)
  but the sample of use & output:
  i{:ok, pid} = Db.MnesiaProvider.start_link([])
  .> GenServer.call(pid, {:add, Db.Bucket, {"bucket_name"}})
  .> GenServer.call(pid, {:get, Db.Bucket, {"bucket_name"}})
  {:ok, {:bucket, "bucket_name", timestamp}}
  """
  def handle_call({:get, module, id}, _from, state) do
    handle_db_operation(:get, module, id, state)
  end

  @doc """
  Deletes record from Mnesia table


  examples:
    #add a bucket (name="bucket_name") record
    iex> {:ok, pid} = Db.MnesiaProvider.start_link([])
    ...> GenServer.call(pid, {:add, Db.Bucket, {"bucket_name"}})
    ...> GenServer.call(pid, {:add, Db.Bucket, {"bucket_name"}})
    :ok


    #adding to storage table where storage_name is "storage_name"
    iex> {:ok, pid} = Db.MnesiaProvider.start_link([])
    ...> GenServer.call(pid, {:add, Db.Storage, {"storage_name", true}})
    ...> GenServer.call(pid, {:delete, Db.Storage, {"storage_name"}})
    :ok


    # example of error (same for each record)
    # add an invalid storage record (without `availability` field)
    {:ok, pid} = Db.MnesiaProvider.start_link([])
    ...> GenServer.call(pid, {:delete, Db.Storage, {"da"}})
    :fail
  """
  def handle_call({:delete, module, id}, _from, state) do
    handle_db_operation(:delete, module, id, state)
  end

  def handle_call({:get_or_create, module, id}, _from, state) do
    handle_db_operation(:get_or_create, module, id, state)
  end

  def handle_call({:get_all, module}, _, state) do
    handle_db_operation(:get_all, module, state)
  end

  def handle_call({:get_all, module, name}, _, state) do
    handle_db_operation(:get_all, module, name, state)
  end

  def handle_call({:get_objects, name}, _, state) do
    handle_db_operation(:get_objects, Db.Object, name, state)
  end

  def handle_call({:get_objects_by_bucket, name}, _, state) do
    handle_db_operation(:get_objects_by_bucket, Db.Object, name, state)
  end

  def handle_call({:get_storage, name, bucket_name}, _, state) do
    case Db.Object.get({name, bucket_name}) do
      {:ok, record} ->
        {:object, _, _, provider, _} = record
        {:reply, {:ok, provider}, state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  defp handle_db_operation(:get_objects_by_bucket, module, prefix, state) do
    case module.get_all_by_bucket_name(prefix) do
      {:ok, records} ->
        {:reply, {:ok, records}, state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  defp handle_db_operation(:get_all, module, state) do
    case module.get_all() do
      {:ok, records} ->
        {:reply, {:ok, records}, state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  defp handle_db_operation(:get_all, module, prefix, state) do
    case module.get_all(prefix) do
      {:ok, records} ->
        {:reply, {:ok, records}, state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  defp handle_db_operation(:add, module, record, state) do
    case module.add(record) do
      :ok ->
        {:reply, :ok, state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  defp handle_db_operation(:get, module, id, state) do
    case module.get(id) do
      {:ok, record} ->
        {:reply, {:ok, record}, state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  defp handle_db_operation(:delete, module, id, state) do
    case module.delete(id) do
      :ok ->
        {:reply, :ok, state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  defp handle_db_operation(:get_or_create, module, id, state) do
    case module.get_or_create(id) do
      :ok ->
        {:reply, :ok, state}

      data when is_tuple(data) ->
        {:reply, {:ok, data}, state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}

      _ ->
        {:reply, {:error, :unknown}, state}
    end
  end
end
