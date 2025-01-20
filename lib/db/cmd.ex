defmodule Db.Cmd do
  @moduledoc """
   Module for initializing and configuring mnesia
  """

  alias :mnesia, as: Mnesia

  @db_store "#{System.user_home()}/.mnesia"

  def init do
    # Сначала устанавливаем директорию для хранения данных
    set_disk_location()

    # Создаем схему и запускаем Mnesia
    Mnesia.create_schema([node()])
    Mnesia.start()

    # Инициализируем таблицы
    init_tables()
  end

  defp init_tables do
    Db.Storage.init()
    Db.Bucket.init()
    Db.Object.init()
  end

  defp set_disk_location do
    disk_dir = @db_store

    # Создаем директорию, если она не существует
    File.mkdir_p!(disk_dir)

    # Устанавливаем путь для хранения базы данных
    Mnesia.change_config(:dir, disk_dir)
  end
end
