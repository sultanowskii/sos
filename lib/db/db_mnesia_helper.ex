defmodule Db.MnesiaHelper do
  @moduledoc """
    Database operations processing
  """

  alias :mnesia, as: Mnesia
  require Logger

  def init(table, attributes) do
    Mnesia.create_table(table, attributes: attributes)
  end

  def add(record) do
    case Mnesia.transaction(fn -> Mnesia.write(record) end) do
      {:atomic, :ok} -> :ok
      {:atomic, _} -> {:error, :unknown_error}
      {:aborted, reason} -> {:error, {:transaction_aborted, reason}}
    end
  end

  def get(record) do
    case Mnesia.transaction(fn -> Mnesia.read(record) end) do
      {:atomic, [record]} ->
        {:ok, record}

      {:atomic, []} ->
        {:error, :not_found}

      {:aborted, reason} ->
        {:error, {:transaction_aborted, reason}}
    end
  end

  def delete(record) do
    case Mnesia.transaction(fn -> Mnesia.read(record) end) do
      {:atomic, []} ->
        {:error, :not_found}

      {:atomic, [_]} ->
        Mnesia.transaction(fn -> Mnesia.delete(record) end)
        :ok

      {:aborted, reason} ->
        {:error, {:transaction_aborted, reason}}
    end
  end

  @doc """
  Searches for the records in the database according to specified data

  ## Parameters
    * `record` - the record, e.g. `{:object, "object_name", "bucket_name", :_}`, where :_ meaninig any value
  """
  def get_matching_record(record) do
    case Mnesia.transaction(fn -> :mnesia.match_object(record) end) do
      {:atomic, records} when is_list(records) ->
        {:ok, records}

      {:aborted, reason} ->
        {:error, {:transaction_aborted, reason}}

      _ ->
        {:error, :unknown_error}
    end
  end

  def get_or_create(record) do
    case get(record) do
      {:ok, existing_record} ->
        {:ok, existing_record}

      {:error, :not_found} ->
        case add(record) do
          :ok -> {:ok, record}
          {:error, reason} -> {:error, reason}
        end
    end
  end
end
