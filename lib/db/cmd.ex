defmodule Db.Cmd do
  @moduledoc """
    Mnesia entrypoint
  """

  require Logger
  alias :mnesia, as: Mnesia

  def init do
    Mnesia.start()
    Mnesia.change_table_copy_type(:schema, node(), :disc_copies)

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
