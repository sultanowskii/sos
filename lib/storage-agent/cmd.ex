defmodule StorageAgent.Cmd do
  @moduledoc """
  Storage Agent entrypoint.
  """
  alias StorageAgent.Argparser
  require Logger

  def start(args) do
    config = Argparser.parse!(args)

    connected =
      config.brain_name
      |> String.to_atom()
      |> Node.connect()

    case connected do
      true ->
        StorageAgent.start_link()

      false ->
        UIO.eputs("Can't connect to the brain")
    end
  rescue
    e in OptionParser.ParseError ->
      UIO.eputs(e.message)
      exit({:shutdown, 1})
  end
end
