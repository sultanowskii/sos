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
      ["brain" | args] ->
        System.no_halt(true)
        Brain.Cmd.start(args)

      ["storage-agent" | args] ->
        System.no_halt(true)
        StorageAgent.Cmd.start(args)

      _ ->
        print_help()
    end

    {:ok, self()}
  end
end
