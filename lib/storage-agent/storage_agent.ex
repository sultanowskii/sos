defmodule StorageAgent do
  @moduledoc """
  Storage Agent responsible for handling object storage operations.
  """
  use GenServer

  def start_link(config) do
    GenServer.start_link(
      __MODULE__,
      config,
      name: {:global, {:storage_agent, "#{config.client_id}"}}
    )
  end

  def init(config) do
    {:ok, config}
  end

  def handle_call(:health_check, _from, state) do
    {:reply, :ok, state}
  end

  def handle_call({:put_object, bucket, key, data}, _from, state) do
    # todo format only for checking - should be changed
    file_path = "storage/#{bucket}/#{key}.txt"

    File.write!(file_path, data)

    IO.puts("Saved object to bucket=#{bucket}, key=#{key}")

    {:reply, :ok, state}
  end

  def handle_call({:get_object, bucket, key}, _from, state) do
    # TODO
    {:reply, :ok, state}
  end

  def handle_call({:delete_object, bucket, key}, _from, state) do
    # TODO
    {:reply, :ok, state}
  end
end
