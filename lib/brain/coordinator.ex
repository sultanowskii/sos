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
    schedule_agents_health_check()
    {:ok, state}
  end

  def handle_call({:put_object, bucket, key, data}, _from, _state) do
    agent = pick_random_agent()

    GenServer.call({:global, agent}, {:put_object, bucket, key, data})
  end

  def handle_call({:get_object, bucket, key}, _from, _state) do
    agent = nil
    # TODO: take from DB by (bucket, key)

    GenServer.call({:global, agent}, {:get_object, bucket, key})
  end

  def handle_call({:delete_object, bucket, key}, _from, _state) do
    agent = nil
    # TODO: take from DB by (bucket, key)

    GenServer.call({:global, agent}, {:delete_object, bucket, key})
  end

  # A typical way to set up a periodic work:
  # handle_info/2 + Process.send_after
  def handle_info(:check_agents_health, state) do
    case alive_storage_agents() do
      [] ->
        IO.puts("No worker is online")

      agents = [_ | _] ->
        for agent <- agents do
          result = GenServer.call({:global, agent}, :health_check)

          {:storage_agent, agent_name} = agent

          case result do
            :ok ->
              IO.puts("#{agent_name} is alive")

            _ ->
              IO.puts("#{agent_name} isn't alive")
          end
        end
    end

    schedule_agents_health_check()
    {:noreply, state}
  end

  defp pick_random_agent do
    agents = alive_storage_agents()

    index =
      agents
      |> Enum.count()
      |> :rand.uniform()
      |> Kernel.-(1)

    Enum.at(agents, index)
  end

  defp alive_storage_agents do
    :global.registered_names()
    |> Enum.filter(fn name ->
      case name do
        {:storage_agent, _} -> true
        _ -> false
      end
    end)
  end

  defp schedule_agents_health_check do
    Process.send_after(self(), :check_agents_health, @health_check_interval)
  end
end
