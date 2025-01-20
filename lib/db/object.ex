defmodule Db.Object do
  @moduledoc """
   Module for processing operations with Object enitity
  """

  alias Db.MnesiaHelper
  @table :object
  @index_time 2

  def init do
    MnesiaHelper.init(@table, [:name, :bucket_id, :created_at])
  end

  def add(record) do
    # adding data table name and column created at
    record = Tuple.insert_at(record, @index_time, DateTime.to_string(DateTime.utc_now()))
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
end
