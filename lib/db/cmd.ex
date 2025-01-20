defmodule Db.Cmd do
  @moduledoc """
   Module for initializing and configuring mnesia
  """

  alias :mnesia, as: Mnesia

  @db_store "#{System.user_home()}/.mnesia"

  def init do
    set_disk_location()

    Mnesia.create_schema([node()])
    Mnesia.start()

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
  end
end
