defmodule Cmd.StorageAgent do
  @moduledoc """
  Storage Agent entrypoint.
  """
  require Logger

  def start(_args) do
    StorageAgent.start_link()
  end
end
