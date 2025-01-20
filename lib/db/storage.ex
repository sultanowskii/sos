defmodule Db.Storage do
  @moduledoc """
    Module for processing operations with storage enitity
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
end
