defmodule Brain.Coordinator do
  @moduledoc """
  Coordinator.
  """
  use GenServer
  require Logger

  @err_agents_unavailable :agents_unavailable
  @health_check_interval 10_000

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    Registry.register(BrainRegistry, :coordinator, nil)

    schedule_agents_health_check()
    shecule_db_health_check()

    {:ok, state}
  end

  @impl true
  def terminate(_reason, _state) do
    Registry.unregister(BrainRegistry, :coordinator)
  end

  @doc """
  Creates a new object in the storage and writes a record to database.
  If a bucket with specified name doesn't exist, creates a new bucket.


  # Examples
    iex> GenServer.call(Brain.Coordinator, {:put_object, "my_bucket", "my_key.txt", "binary_data"})
    :ok

  ## Parameters
    * `bucket` - name of the bucket
    * `key` - object key
    * `data` - binary data of the object
  """
  @impl true
  def handle_call({:put_object, bucket, key, data}, _from, state) do
    case pick_random_agent() do
      {:ok, agent} ->
        case GenServer.call({:global, agent}, {:put_object, bucket, key, data}) do
          :ok ->
            {:storage_agent, agent_name} = agent

            GenServer.call(Db.MnesiaProvider, {:get_or_create, Db.Bucket, {bucket}})
            GenServer.call(Db.MnesiaProvider, {:add, Db.Object, {key, bucket, agent_name}})

            {:reply, :ok, state}

          _ ->
            {:reply, :fail, state}
        end

      e = {:error, @err_agents_unavailable} ->
        {:reply, e, state}
    end
  end

  @doc """
  Gets an object from the storage by bucket & key

  iex> GenServer.call(Brain.Coordinator, {:put_object, "my_bucket", "my_key.txt", "binary_data"})
  ...> GenServer.call(Brain.Coordinator, {:get_object, "my_bucket", "my_key.txt"})
  {:ok, "binary_data"}
  """
  @impl true
  def handle_call({:get_object, bucket, key}, _from, state) do
    case GenServer.call(Db.MnesiaProvider, {:get_storage, key, bucket}) do
      {:ok, storage_name} ->
        agent = {:storage_agent, storage_name}

        result = GenServer.call({:global, agent}, {:get_object, bucket, key})

        {:reply, result, state}

      {:error, _} ->
        {:reply, {:error, @err_agents_unavailable}, state}
    end
  end

  @doc """
  Deletes objects from the storage by bucket & key
  iex> GenServer.call(Brain.Coordinator, {:put_object, "my_bucket", "my_key.txt", "binary_data"})
  ...> GenServer.call(Brain.Coordinator, {:delete_object, "my_bucket", "my_key.txt"})
  :ok
  """
  @impl true
  def handle_call({:delete_object, bucket, key}, _from, state) do
    case GenServer.call(Db.MnesiaProvider, {:get_storage, key, bucket}) do
      {:ok, storage_name} ->
        agent = {:storage_agent, storage_name}

        result = GenServer.call({:global, agent}, {:delete_object, bucket, key})

        case result do
          :ok ->
            Logger.debug("Object deleted from bucket=#{bucket}, key=#{key}")
            GenServer.call(Db.MnesiaProvider, {:delete, Db.Object, {key, bucket}})
            {:reply, :ok, state}

          _ ->
            {:reply, :fail, state}
        end

      {:error, _} ->
        {:reply, {:error, @err_agents_unavailable}, state}
    end
  end

  @impl true
  def handle_call({:copy_object, source_bucket, source_key, dest_bucket, dest_key}, _from, state) do
    get_result = GenServer.call(self(), {:get_object, source_bucket, source_key})

    case get_result do
      {:ok, data} ->
        put_result = GenServer.call(self(), {:put_object, dest_bucket, dest_key, data})

        {:reply, put_result, state}

      {:error, _} ->
        {:reply, get_result, state}
    end
  end

  # A typical way to set up a periodic work:
  # handle_info/2 + Process.send_after
  @impl true
  def handle_info(:check_agents_health, state) do
    case alive_storage_agents() do
      [] ->
        Logger.error("No agent is online")

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

  @impl true
  def handle_info(:check_db_health, state) do
    case GenServer.call(Db.MnesiaProvider, :health_check) do
      :ok ->
        Logger.debug("Database is healthy")

      {:error, reason} ->
        Logger.emergency("Database health check failed: #{inspect(reason)}")
    end

    shecule_db_health_check()
    {:noreply, state}
  end

  defp pick_random_agent do
    agents = alive_storage_agents()

    case agents do
      [] ->
        {:error, @err_agents_unavailable}

      [_] ->
        index =
          agents
          |> Enum.count()
          |> :rand.uniform()
          |> Kernel.-(1)

        {:ok, Enum.at(agents, index)}
    end
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

  defp shecule_db_health_check do
    Process.send_after(self(), :check_db_health, @health_check_interval)
  end
end
