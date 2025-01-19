defmodule StorageAgent.Config do
  @moduledoc """
  Lab3 configuration.
  """

  @type t :: %StorageAgent.Config{
          brain_name: String.t(),
          client_id: String.t(),
          directory: String.t()
        }

  defstruct brain_name: "", client_id: "", directory: ""
end
