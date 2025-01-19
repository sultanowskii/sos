defmodule Brain.Coordinator do
  @moduledoc """
  Coordinator.
  """
  use GenServer

  @health_check_interval 10_000

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    schedule_workers_health_check()
    {:ok, state}
  end

  # A typical way to set up a periodic work:
  # handle_info/2 + Process.send_after
  def handle_info(:check_workers_health, state) do
    case registered_storage_agents() do
      [] ->
        IO.puts("No worker is online")

      workers = [_ | _] ->
        for worker <- workers do
          result = GenServer.call({:global, worker}, :health_check)

          {:storage_agent, worker_name} = worker

          case result do
            :ok ->
              IO.puts("#{worker_name} is alive")

            _ ->
              IO.puts("#{worker_name} isn't alive")
          end
        end
    end

    schedule_workers_health_check()
    {:noreply, state}
  end

  defp registered_storage_agents do
    :global.registered_names()
    |> Enum.filter(fn name ->
      case name do
        {:storage_agent, _} -> true
        _ -> false
      end
    end)
  end

  defp schedule_workers_health_check do
    Process.send_after(self(), :check_workers_health, @health_check_interval)
  end
end
