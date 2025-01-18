defmodule StorageAgent.Config do
  @moduledoc """
  Lab3 configuration.
  """

  @type t :: %StorageAgent.Config{
          brain_name: String.t()
        }

  defstruct brain_name: ""
end
