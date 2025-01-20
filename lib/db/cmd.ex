defmodule Db.Cmd do
  alias :mnesia, as: Mnesia

  def init do
    Mnesia.create_schema([node()])
    init_tables()
    Mnesia.start()
  end

  defp init_tables() do
    Db.Storage.init()
    Db.Bucket.init()
    Db.Object.init()
  end
end
