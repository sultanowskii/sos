defmodule Db.Bucket do
  @moduledoc """
    Bucket entity
  """
  require Logger
  alias Db.MnesiaHelper

  @table :bucket
  @index_time 1

  def init do
    MnesiaHelper.init(@table, [:name, :created_at])
  end

  def add(name) do
    record = Tuple.insert_at(name, @index_time, DateTime.to_string(DateTime.utc_now()))
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

  def get_or_create(name) do
    case get(name) do
      {:ok, record} ->
        Logger.debug("Bucket already exists")

        record

      {:error, :not_found} ->
        Logger.debug("bucket not found, creating new bucket")
        IO.puts("Creating new bucket")
        add(name)
    end
  end

  def get_all do
    MnesiaHelper.get_matching_record({@table, :_, :_})
  end
end
