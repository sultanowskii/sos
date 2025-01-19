defmodule StorageAgent do
  @moduledoc """
  Storage Agent is responsible for handling object storage operations.
  """
  use GenServer
  require Logger

  @storage_dir "#{System.user_home()}/#{__MODULE__}"

  def start_link(config) do
    GenServer.start_link(
      __MODULE__,
      config,
      name: {:global, {:storage_agent, "#{config.client_id}"}}
    )
  end

  def init(config) do
    init_storage(config)
  end

  defp init_storage(config) do
    case File.mkdir_p(@storage_dir) do
      :ok ->
        Logger.debug("directory with name #{@storage_dir} created successfully")
        {:ok, config}

      {:error, :eexist} ->
        Logger.debug("directory with name #{@storage_dir} already exists")
        {:ok, config}

      {:error, reason} ->
        Logger.error("failed to create directory with name #{@storage_dir}: #{reason}")
        {:stop, reason}
    end
  end

  def handle_call(:health_check, _from, state) do
    {:reply, :ok, state}
  end

  def handle_call({:put_object, bucket, key, data}, _from, state) do
    dir_path = "#{@storage_dir}/#{bucket}"
    file_path = "#{dir_path}/#{key}"

    case StorageOperation.write(file_path, data) do
      :ok ->
        Logger.debug("saved object to bucket=#{bucket}, key=#{key}")
        {:reply, :ok, state}

      {:error, reason} ->
        Logger.error("failed to save object to bucket=#{bucket}, key=#{key}: #{reason}")
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:get_object, bucket, key}, _from, state) do
    file_path = "#{@storage_dir}/#{bucket}/#{key}"

    case StorageOperation.read(file_path) do
      {:ok, binary_data} ->
        Logger.debug("retrieved object from bucket=#{bucket}, key=#{key}")
        {:reply, {:ok, binary_data}, state}

      {:error, reason} ->
        Logger.error("failed to retrieve object from bucket=#{bucket}, key=#{key}: #{reason}")
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:delete_object, bucket, key}, _from, state) do
    file_path = "#{@storage_dir}/#{bucket}/#{key}"

    case StorageOperation.delete(file_path) do
      :ok ->
        Logger.debug("deleted object from bucket=#{bucket}, key=#{key}")
        {:reply, :ok, state}

      {:error, reason} ->
        Logger.error("failed to delete object from bucket=#{bucket}, key=#{key}: #{reason}")
        {:reply, {:error, reason}, state}
    end
  end
end
