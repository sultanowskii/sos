defmodule Db.Object do
  @moduledoc """
   Module for processing operations with Object enitity
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
end
