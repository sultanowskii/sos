defmodule StorageAgent do
  @moduledoc """
  Storage Agent.
  """
  use GenServer

  def start_link do
    GenServer.start_link(
      __MODULE__,
      :ok,
      name: {:global, "storage_#{:rand.uniform(100_000_000)}"}
    )
  end

  def init(:ok) do
    {:ok, nil}
  end

  def handle_call(:health_check, _from, state) do
    {:reply, :ok, state}
  end
end
