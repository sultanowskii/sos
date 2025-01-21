defmodule Db.Object do
  @moduledoc """
    Object entity
  """

  require Logger
  alias Db.MnesiaHelper
  @table :object

  def init do
    MnesiaHelper.init(@table, [:name, :bucket_name, :storage, :created_at])
  end

  def add(record) do
    {name, bucket_name, storage} = record
    Logger.debug("adding object #{name} to bucket #{bucket_name} with storage #{storage}")

    MnesiaHelper.add(
      {@table, "#{bucket_name}/#{name}", bucket_name, storage,
       DateTime.to_string(DateTime.utc_now())}
    )
  end

  def get(record) do
    {name, bucket_name} = record
    MnesiaHelper.get({@table, "#{bucket_name}/#{name}"})
  end

  def delete(record) do
    {name, bucket_name} = record
    MnesiaHelper.delete({@table, "#{bucket_name}/#{name}"})
  end

  def get_or_create(_) do
    {:error, :not_supported}
  end

  def get_all do
    MnesiaHelper.get_matching_record({@table, :_, :_, :_, :_})
  end

  def get_all_by_bucket_name(bucket_name) do
    result = MnesiaHelper.get_matching_record({@table, :_, bucket_name, :_, :_})
    result
  end
end
