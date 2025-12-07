defmodule HelloWorld do
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def start_link(_) do
    :proc_lib.start_link(__MODULE__, :init, [self()])
  end

  def init(parent) do
    winfo = Pocion.info(:hello_world)

    Pocion.call_window(:hello_world, fn ->
      Raylib.set_target_fps(60)
      Raylib.set_trace_log_level(:log_debug)
    end)

    state = %{x: 0, y: 100, y_delta: 1, height: winfo.height}

    :proc_lib.init_ack(parent, {:ok, self()})

    loop(state)
  end

  def loop(state) do
    Pocion.execute(:hello_world, [
      %{op: :begin_drawing, args: %{}},
      %{op: :clear_background, args: %{color: :raywhite}},
      %{op: :draw_fps, args: %{x: 10, y: 10}},
      %{
        op: :draw_text,
        args: %{text: "Hello world!", x: 190, y: state.y, font_size: 20, color: :lightgray}
      },
      %{op: :end_drawing, args: %{}}
    ])

    y_next = state.y + state.y_delta

    y_delta =
      if y_next + 100 > state.height or y_next - 100 <= 0 do
        state.y_delta * -1
      else
        state.y_delta
      end

    loop(%{state | y: y_next, y_delta: y_delta})
  end
end
