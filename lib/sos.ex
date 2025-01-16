defmodule SOS do
  @moduledoc """
  CLI entrypoint.
  """
  use Application

  defp print_help do
    IO.puts("usage: sos COMMAND\n")
    IO.puts("Commands:")
    IO.puts("\tbrain\tThe Leader, the Server, the Whatever-you-name-it")
    IO.puts("\tstorage\tStorage agent")
  end

  def start(_type, _argv) do
    case System.argv() do
      [] ->
        print_help()

      ["brain" | args] ->
        System.no_halt(true)
        Cmd.Brain.start(args)

      ["storage" | args] ->
        System.no_halt(true)
        Cmd.Storage.start(args)
    end
  end
end
