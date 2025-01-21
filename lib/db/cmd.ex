defmodule Db.Cmd do
  @moduledoc """
    Mnesia entrypoint
  """

  require Logger
  alias :mnesia, as: Mnesia

  @db_dir "#{System.user_home!()}/.mnesia"

  def init do
    Application.put_env(:mnesia, :dir, String.to_charlist("#{System.user_home!()}/.mnesia"))

    Mnesia.stop()
    Mnesia.start()
    Mnesia.change_table_copy_type(:schema, node(), :disc_copies)

    Logger.info("mnesia started, data directory: #{@db_dir}")

    init_tables()
  end

  def terminate do
    Mnesia.stop()
  end

  defp init_tables do
    Db.Storage.init()
    Db.Bucket.init()
    Db.Object.init()
  end
end
