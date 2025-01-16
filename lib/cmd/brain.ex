defmodule Cmd.Brain do
  @moduledoc """
  Brain entrypoint.
  """
  require Logger

  def start(_args) do
    children = [
      {
        Bandit,
        scheme: :http, plug: Brain.Router, port: 8080
      }
    ]

    opts = [strategy: :one_for_one, name: SOS.Supervisor]

    Logger.info("Starting application...")

    Supervisor.start_link(children, opts)
  end
end
