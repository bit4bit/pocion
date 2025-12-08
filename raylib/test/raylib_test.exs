defmodule RaylibTest do
  use ExUnit.Case

  test "operations" do
    loop = fn
      _, %{steps: steps} when steps <= 0 ->
        :done

      loop, state ->
        operations = [
          %{op: :begin_drawing, args: %{}},
          %{op: :clear_background, args: %{color: :raywhite}},
          %{op: :draw_fps, args: %{x: 10, y: 10}},
          %{
            op: :draw_text,
            args: %{text: "Hello world!", x: 190, y: state.y, font_size: 20, color: :lightgray}
          },
          %{op: :draw_circle, args: %{x: state.x, y: state.y, radius: 10.3, color: :lightgray}},
          %{
            op: :draw_circle_v,
            args: %{center: %{x: 500 + 0.0, y: state.y + 0.0}, radius: 10.0, color: state.color}
          },
          %{op: :end_drawing, args: %{}},
          %{op: :is_key_pressed, args: %{key: :KEY_G, reply_pid: self()}}
        ]

        y_next = state.y + state.y_delta

        {y_delta, operations} =
          if y_next + 100 > state.height or y_next - 100 <= 0 do
            operations = operations ++ [%{op: :play_sound, args: %{sound_id: 1}}]
            {state.y_delta * -1, operations}
          else
            {state.y_delta, operations}
          end

        operations = operations ++ [%{op: :end_drawing, args: %{}}]

        Raylib.execute(operations)

        state =
          receive do
            {:is_key_pressed, true} ->
              IO.inspect(state)
              color = if(state.color == :lime, do: :lightgray, else: :lime)

              state = %{state | color: color}

            {:is_key_pressed, false} ->
              state
          end

        loop.(loop, %{state | y: y_next, y_delta: y_delta, steps: state.steps - 1})
    end

    assert Raylib.init_window(640, 480, "jeje") == :ok
    assert Raylib.init_audio_device() == :ok
    assert Raylib.set_target_fps(60) == :ok
    assert Raylib.window_should_close() == false
    assert Raylib.load_sound(1, "./test/sounds/bounce-effect.ogg")

    loop.(loop, %{x: 0, y: 100, y_delta: 3, height: 480, steps: 500, color: :lightgray})

    assert Raylib.close_window() == :ok
  end
end
