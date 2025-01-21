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

  @doc """
  Searches for the records in the database according to the specified prefix
    iex> Db.Object.add({"name","buck","stora"})
    ...> Db.Object.get_by_prefix("na")
    {:ok, [{:object, "f/name", "f", "storage", "2025-01-21 12:10:37.275384Z"}]}
  """
  def get_by_prefix(prefix) do
    case get_all() do
      {:ok, records} ->
        data =
          Enum.filter(records, fn
            {@table, name, _, _, _} ->
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
