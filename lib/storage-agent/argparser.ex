defmodule StorageAgent.Argparser do
  @moduledoc """
  Storage Agent CLI argument parser.
  """
  alias StorageAgent.Config

  def parse!(args) do
    {parsed, _} =
      OptionParser.parse!(
        args,
        strict: [
          brain_name: :string,
          client_id: :string
        ]
      )

    config = %Config{
      brain_name: parsed[:brain_name],
      client_id: parsed[:client_id]
    }

    validate!(config)
  end

  @spec validate!(Config.t()) :: Config.t()
  def validate!(config) do
    if config.brain_name == nil do
      raise %OptionParser.ParseError{message: "--brain-name is required"}
    end

    if config.client_id == nil do
      raise %OptionParser.ParseError{message: "--client-id is required"}
    end

    config
  end
end
