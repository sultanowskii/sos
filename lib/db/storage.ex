defmodule Db.Storage do
  @moduledoc """
    Storage entity
  """

  alias Db.MnesiaHelper

  @table :storage

  def init do
    MnesiaHelper.init(@table, [:name, :availability])
  end

  def add(record) do
    record = Tuple.insert_at(record, 0, @table)
    MnesiaHelper.add(record)
  end

  def get(name) do
    record = Tuple.insert_at(name, 0, @table)
    MnesiaHelper.get(record)
  end

  def delete(name) do
    record = Tuple.insert_at(name, 0, @table)
    MnesiaHelper.delete(record)
  end

  def get_or_create(_) do
    {:error, :not_supported}
  end

  def get_all do
    MnesiaHelper.get_matching_record({@table, :_, :_})
  end

  def get_by_prefix(prefix) do
    case get_all() do
      {:ok, records} ->
        data =
          Enum.filter(records, fn
            {@table, name, _} ->
              String.starts_with?(name, prefix)

            _ ->
              []
          end)

        {:ok, data}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
