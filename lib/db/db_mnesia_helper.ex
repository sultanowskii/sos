defmodule Db.MnesiaHelper do
  @moduledoc """
   Module for processing operations with mnesia
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
      {:atomic, [record]} -> {:ok, record}
      {:atomic, []} -> {:error, :not_found}
      {:aborted, reason} -> {:error, {:transaction_aborted, reason}}
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
end
