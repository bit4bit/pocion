defmodule RaylibTest do
  use ExUnit.Case

  test "operations" do
    loop = fn
      _, %{steps: steps} when steps <= 0 ->
        :done

      loop, state ->
        Raylib.execute([
          %{op: :begin_drawing, args: %{}},
          %{op: :clear_background, args: %{color: :raywhite}},
          %{op: :draw_fps, args: %{x: 10, y: 10}},
          %{
            op: :draw_text,
            args: %{text: "Hello world!", x: 190, y: state.y, font_size: 20, color: :lightgray}
          },
          %{op: :draw_circle, args: %{x: 100, y: state.y, radius: 10.3, color: :lightgray}},
          %{op: :end_drawing, args: %{}}
        ])

        y_next = state.y + state.y_delta

        y_delta =
          if y_next + 100 > state.height or y_next - 100 <= 0 do
            state.y_delta * -1
          else
            state.y_delta
          end

        loop.(loop, %{state | y: y_next, y_delta: y_delta, steps: state.steps - 1})
    end

    assert Raylib.init_window(640, 480, "jeje") == :ok
    assert Raylib.set_target_fps(60) == :ok
    assert Raylib.window_should_close() == false

    loop.(loop, %{x: 0, y: 100, y_delta: 1, height: 480, steps: 100})

    assert Raylib.close_window() == :ok
  end
end
