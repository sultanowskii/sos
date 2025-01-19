defmodule Brain.Coordinator do
  @moduledoc """
  Coordinator.
  """
  use GenServer
  require Logger

  @health_check_interval 10_000

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    Registry.register(BrainRegistry, :coordinator, nil)
    schedule_agents_health_check()
    {:ok, state}
  end

  @impl true
  def terminate(_reason, _state) do
    Registry.unregister(BrainRegistry, :coordinator)
  end

  @impl true
  def handle_call({:put_object, bucket, key, data}, _from, _state) do
    agent = pick_random_agent()

    # TODO: compose the response (success/failure)
    GenServer.call({:global, agent}, {:put_object, bucket, key, data})
  end

  @impl true
  def handle_call({:get_object, bucket, key}, _from, _state) do
    # TODO: take from DB by (bucket, key)
    agent = nil
    # TODO: compose the response (success/failure)
    GenServer.call({:global, agent}, {:get_object, bucket, key})
  end

  @impl true
  def handle_call({:delete_object, bucket, key}, _from, _state) do
    agent = nil
    # TODO: take from DB by (bucket, key)
    # TODO: compose the response (success/failure)
    GenServer.call({:global, agent}, {:delete_object, bucket, key})
  end

  # A typical way to set up a periodic work:
  # handle_info/2 + Process.send_after
  @impl true
  def handle_info(:check_agents_health, state) do
    case alive_storage_agents() do
      [] ->
        Logger.error("No worker is online")

      agents = [_ | _] ->
        for agent <- agents do
          result = GenServer.call({:global, agent}, :health_check)

          {:storage_agent, agent_name} = agent

          case result do
            :ok ->
              Logger.debug("#{agent_name} is alive")

            _ ->
              Logger.debug("#{agent_name} isn't alive")
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
