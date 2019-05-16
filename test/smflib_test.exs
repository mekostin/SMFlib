defmodule SmflibTest do
  use ExUnit.Case
  doctest Smflib

  test "greets the world" do
    assert Smflib.hello() == :world
  end
end
