defmodule Db.Object do
  @moduledoc """
    Object entity
  """

  alias Db.MnesiaHelper
  @table :object

  def init do
    MnesiaHelper.init(@table, [:name, :bucket_name_id, :created_at])
  end

  def add(record) do
    {name, bucket_name_id} = record

    MnesiaHelper.add(
      {@table, "#{name}#{bucket_name_id}", bucket_name_id, DateTime.to_string(DateTime.utc_now())}
    )
  end

  def get(record) do
    {name, bucket_name_id} = record
    MnesiaHelper.get({@table, "#{name}#{bucket_name_id}"})
  end

  @spec delete({any(), any()}) :: :ok | {:error, :not_found | {:transaction_aborted, any()}}
  def delete(record) do
    {name, bucket_name_id} = record
    MnesiaHelper.delete({@table, "#{name}#{bucket_name_id}"})
  end

  def get_or_create(_) do
    {:error, :not_supported}
  end

  def get_all do
    MnesiaHelper.get_matching_record({@table, :_, :_, :_})
  end

  def get_all(prefix) do
    MnesiaHelper.get_matching_record({@table, prefix, :_})
  end
end
