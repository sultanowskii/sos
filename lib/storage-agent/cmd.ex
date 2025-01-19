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
        IO.puts("connected to the brain")

        children = [
          {StorageAgent, config}
        ]

        opts = [strategy: :one_for_one, name: StorageAgent.Supervisor]

        Supervisor.start_link(children, opts)

      false ->
        UIO.eputs("can't connect to the brain")
    end
  rescue
    e in OptionParser.ParseError ->
      UIO.eputs(e.message)
      exit({:shutdown, 1})
  end
end
