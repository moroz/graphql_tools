defmodule GraphqlToolsTest do
  use ExUnit.Case
  doctest GraphqlTools

  test "greets the world" do
    assert GraphqlTools.hello() == :world
  end
end
