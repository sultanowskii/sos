defmodule StorageOperation do
  @moduledoc """
  Data storage operations.
  """

  require Logger

  def write(file_path, data) do
    with :ok <- create_dir(Path.dirname(file_path)),
         :ok <- File.write(file_path, data) do
      Logger.debug("successfully wrote data to #{file_path}")
      :ok
    else
      {:error, reason} ->
        Logger.error("failed to write data to #{file_path}: #{reason}")
        {:error, "failed to write data"}
    end
  end

  def read(file_path) do
    case File.read(file_path) do
      {:ok, binary_data} ->
        Logger.debug("successfully read data from #{file_path}")
        {:ok, binary_data}

      {:error, reason} ->
        Logger.error("failed to read data from #{file_path}: #{reason}")
        {:error, "failed to read data"}
    end
  end

  def delete(file_path) do
    case File.rm(file_path) do
      :ok ->
        Logger.debug("successfully deleted file #{file_path}")
        :ok

      {:error, reason} ->
        Logger.error("failed to delete file #{file_path}: #{reason}")
        {:error, "failed to delete file"}
    end
  end

  defp create_dir(dir_path) do
    case File.mkdir_p(dir_path) do
      :ok ->
        Logger.debug("directory #{dir_path} created or already exists")
        :ok

      {:error, reason} ->
        Logger.error("failed to create directory #{dir_path}: #{reason}")
        {:error, "failed to create directory"}
    end
  end
end
