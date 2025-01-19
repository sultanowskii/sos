defmodule StorageAgent do
  @moduledoc """
  Storage Agent responsible for handling object storage operations.
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
    case init_storage(config) do
      {:ok, config} ->
        {:ok, config}

      {:stop, reason} ->
        {:stop, reason}
    end
  end

  defp init_storage(config) do
    case File.mkdir_p(@storage_dir) do
      :ok ->
        Logger.info("Directory with name #{@storage_dir} created successfully")
        {:ok, config}

      {:error, :eexist} ->
        Logger.info("Directory with name #{@storage_dir} already exists")
        {:ok, config}

      {:error, reason} ->
        Logger.error("Failed to create directory with name #{@storage_dir}: #{reason}")
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
        Logger.info("Saved object to bucket=#{bucket}, key=#{key}")
        {:reply, :ok, state}

      {:error, reason} ->
        Logger.error("Failed to save object to bucket=#{bucket}, key=#{key}: #{reason}")
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:get_object, bucket, key}, _from, state) do
    file_path = "#{@storage_dir}/#{bucket}/#{key}"

    case StorageOperation.read(file_path) do
      {:ok, binary_data} ->
        Logger.info("Retrieved object from bucket=#{bucket}, key=#{key}")
        {:reply, {:ok, binary_data}, state}

      {:error, reason} ->
        Logger.error("Failed to retrieve object from bucket=#{bucket}, key=#{key}: #{reason}")
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:delete_object, bucket, key}, _from, state) do
    file_path = "#{@storage_dir}/#{bucket}/#{key}"

    case StorageOperation.delete(file_path) do
      :ok ->
        Logger.info("Deleted object from bucket=#{bucket}, key=#{key}")
        {:reply, :ok, state}

      {:error, reason} ->
        Logger.error("Failed to delete object from bucket=#{bucket}, key=#{key}: #{reason}")
        {:reply, {:error, reason}, state}
    end
  end
end
