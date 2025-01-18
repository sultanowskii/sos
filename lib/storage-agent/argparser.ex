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
          brain_name: :string
        ]
      )

    config = %Config{
      brain_name: parsed[:brain_name]
    }

    validate!(config)
  end

  @spec validate!(Config.t()) :: Config.t()
  def validate!(config) do
    case config.brain_name do
      nil ->
        raise %OptionParser.ParseError{message: "--brain-name is required"}

      _ ->
        nil
    end

    config
  end
end
