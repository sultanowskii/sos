defmodule SOS do
  @moduledoc """
  Server starter.
  """
  use Application
  require Logger

  def start(_type, _args) do
    children = [
      {
        Bandit,
        scheme: :http, plug: SOS.Router, port: 8080
      }
    ]

    opts = [strategy: :one_for_one, name: SOS.Supervisor]

    Logger.info("Starting application...")

    Supervisor.start_link(children, opts)
  end
end
