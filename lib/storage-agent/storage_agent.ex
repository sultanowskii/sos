defmodule StorageAgent do
  @moduledoc """
  Storage Agent is responsible for handling object storage operations.
  """
  use GenServer
  require Logger

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
    case File.mkdir_p(config.directory) do
      :ok ->
        Logger.debug("directory with name #{config.directory} created successfully")
        {:ok, config}

      {:error, :eexist} ->
        Logger.debug("directory with name #{config.directory} already exists")
        {:ok, config}

      {:error, reason} ->
        Logger.error("failed to create directory with name #{config.directory}: #{reason}")
        {:stop, reason}
    end
  end

  def handle_call(:health_check, _from, state) do
    {:reply, :ok, state}
  end

  def handle_call({:put_object, bucket, key, data}, _from, state) do
    file_path = get_hashed_file_path(state, bucket, key)

    with :ok <- StorageOperation.write(file_path, data),
         {:ok, %File.Stat{size: file_size}} <- File.stat(file_path) do
      Logger.debug("saved object to bucket=#{bucket}, key=#{key}, size=#{file_size} bytes")
      {:reply, {:ok, file_size}, state}
    else
      {:error, reason} ->
        Logger.error("failed to save object to bucket=#{bucket}, key=#{key}: #{reason}")
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:get_object, bucket, key}, _from, state) do
    file_path = get_hashed_file_path(state, bucket, key)

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
    file_path = get_hashed_file_path(state, bucket, key)

    case StorageOperation.delete(file_path) do
      :ok ->
        Logger.debug("deleted object from bucket=#{bucket}, key=#{key}")
        {:reply, :ok, state}

      {:error, reason} ->
        Logger.error("failed to delete object from bucket=#{bucket}, key=#{key}: #{reason}")
        {:reply, {:error, reason}, state}
    end
  end

  defp get_hashed_file_path(config, bucket, key) do
    file_extension = Path.extname(key)
    filename = "#{hash_key(bucket, key)}#{file_extension}"
    file_path = "#{config.directory}/#{bucket}/#{filename}"
    file_path
  end

  defp hash_key(bucket, key) do
    :crypto.hash(:sha512, "#{bucket}/#{key}")
    |> Base.encode16(case: :lower)
  end
end
