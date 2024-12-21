defmodule SosTest do
  use ExUnit.Case
  doctest Sos

  test "greets the world" do
    assert Sos.hello() == :world
  end
end
