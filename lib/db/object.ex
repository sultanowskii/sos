defmodule Db.Object do
  @moduledoc """
    Object entity
  """

  require Logger
  alias Db.MnesiaHelper
  @table :object

  def init do
    MnesiaHelper.init(@table, [:name, :bucket_name_id, :storage, :created_at])
  end

  def add(record) do
    {name, bucket_name_id, storage} = record
    Logger.debug("Adding object #{name} to bucket #{bucket_name_id} with storage #{storage}")

    MnesiaHelper.add(
      {@table, "#{bucket_name_id}/#{name}", bucket_name_id, storage,
       DateTime.to_string(DateTime.utc_now())}
    )
  end

  def get(record) do
    {name, bucket_name_id} = record
    MnesiaHelper.get({@table, "#{bucket_name_id}/#{name}"})
  end

  def delete(record) do
    {name, bucket_name_id} = record
    MnesiaHelper.delete({@table, "#{bucket_name_id}/#{name}"})
  end

  def get_or_create(_) do
    {:error, :not_supported}
  end

  def get_all do
    MnesiaHelper.get_matching_record({@table, :_, :_, :_, :_})
  end

  def get_all_by_bucket_name(bucket_name) do
    result = MnesiaHelper.get_matching_record({@table, :_, bucket_name, :_, :_})
    Logger.debug("Got all objects for bucket #{bucket_name}: #{inspect(result)}")
    result
  end
end
