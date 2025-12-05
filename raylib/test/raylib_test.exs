defmodule RaylibTest do
  use ExUnit.Case

  test "basics" do
    assert :ok = Raylib.init_window(%{width: 640, height: 480, title: "jeje"})
    Process.sleep(1000)
    assert :ok = Raylib.close_window()
  end
end
