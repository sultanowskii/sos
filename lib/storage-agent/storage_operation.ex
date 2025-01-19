defmodule StorageOperation do
  @moduledoc """
  Operation for storing data in the system.
  """

  require Logger

  def write(file_path, data) do
    case create_dir(Path.dirname(file_path)) do
      :ok ->
        case File.write(file_path, data) do
          :ok ->
            Logger.info("Successfully wrote data to #{file_path}")
            :ok

          {:error, reason} ->
            Logger.error("Failed to write data to #{file_path}: #{reason}")
            {:error, "Failed to write data"}
        end

      {:error, _reason} = error ->
        error
    end
  end

  def read(file_path) do
    case File.read(file_path) do
      {:ok, data} ->
        Logger.info("Successfully read data from #{file_path}")
        {:ok, data}

      {:error, reason} ->
        Logger.error("Failed to read data from #{file_path}: #{reason}")
        {:error, "Failed to read data"}
    end
  end

  def delete(file_path) do
    case File.rm(file_path) do
      :ok ->
        Logger.info("Successfully deleted file #{file_path}")
        :ok

      {:error, reason} ->
        Logger.error("Failed to delete file #{file_path}: #{reason}")
        {:error, "Failed to delete file"}
    end
  end

  defp create_dir(dir_path) do
    case File.mkdir_p(dir_path) do
      :ok ->
        Logger.info("Directory #{dir_path} created or already exists")
        :ok

      {:error, reason} ->
        Logger.error("Failed to create directory #{dir_path}: #{reason}")
        {:error, "Failed to create directory"}
    end
  end
end
