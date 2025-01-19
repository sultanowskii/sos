defmodule StorageAgent do
  @moduledoc """
  Storage Agent.
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
end
