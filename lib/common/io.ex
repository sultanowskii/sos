defmodule UIO do
  @moduledoc """
  IO helpers.
  """

  @spec eputs(IO.chardata() | String.Chars.t()) :: :ok
  def eputs(item) do
    IO.puts(:stderr, item)
  end
end
