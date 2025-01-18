defmodule Cmd.Storage do
  @moduledoc """
  Storage entrypoint.
  """
  require Logger

  def start(_args) do
    Storage.start_link()
  end
end
