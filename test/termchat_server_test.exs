defmodule TermchatServerTest do
  use ExUnit.Case
  doctest TermchatServer

  test "greets the world" do
    assert TermchatServer.hello() == :world
  end
end
