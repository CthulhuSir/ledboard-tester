defmodule LedboardTesterTest do
  use ExUnit.Case
  doctest LedboardTester

  test "greets the world" do
    assert LedboardTester.hello() == :world
  end
end
