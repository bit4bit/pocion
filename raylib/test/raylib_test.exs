defmodule RaylibTest do
  use ExUnit.Case

  test "basics" do
    assert Raylib.init_window(640, 480, "jeje") == :ok
    assert Raylib.set_target_fps(60) == :ok
    assert Raylib.window_should_close() == false
    assert Raylib.begin_drawing() == :ok
    assert Raylib.draw_text("holaaaaaaaa", 190, 200, 20, :lightgray)
    assert Raylib.end_drawing() == :ok
    Process.sleep(1000)
    assert Raylib.close_window() == :ok
  end

  test "operations" do
    assert Raylib.init_window(640, 480, "jeje") == :ok
    assert Raylib.set_target_fps(60) == :ok
    assert Raylib.window_should_close() == false

    Raylib.draw_operations([
      %{op: "clear_background", args: %{color: :raywhite}},
      %{op: "draw_fps", args: %{x: 10, y: 10}},
      %{
        op: "draw_text",
        args: %{text: "carajo", x: 100, y: 100, font_size: 20, color: :lightgray}
      }
    ])

    Process.sleep(1000)
    assert Raylib.close_window() == :ok
  end
end
