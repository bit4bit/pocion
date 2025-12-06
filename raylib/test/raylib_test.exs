defmodule RaylibTest do
  use ExUnit.Case

  test "basics" do
    assert Raylib.init_window(640, 480, "jeje") == :ok
    assert Raylib.set_target_fps(60) == :ok
    assert Raylib.window_should_close() == false
    assert Raylib.begin_drawing() == :ok
    assert Raylib.clear_background(:raywhite)
    assert Raylib.draw_text("holaaaaaaaa", 190, 200, 20, :lightgray)
    assert Raylib.end_drawing() == :ok
    Process.sleep(1000)
    assert Raylib.close_window() == :ok
  end
end
