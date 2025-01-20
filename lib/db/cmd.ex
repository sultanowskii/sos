defmodule Db.Cmd do
  @moduledoc """
   Module for initializing and configuring mnesia
  """

  require Logger
  alias :mnesia, as: Mnesia

  @db_store "#{System.user_home()}/.mnesia"

  def init do
    Mnesia.create_schema([node()])
    Mnesia.start()
    set_disk_location()

    init_tables()
  end

  defp init_tables do
    Db.Storage.init()
    Db.Bucket.init()
    Db.Object.init()
  end

  defp set_disk_location do
    disk_dir = @db_store

    File.mkdir_p!(disk_dir)

    Mnesia.change_config(:dir, disk_dir)
    Logger.debug("Mnesia directory set to #{disk_dir}")
  end
end
