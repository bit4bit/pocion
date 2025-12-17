defmodule PingPong do
  @moduledoc false

  defmodule State do
    use PrivateModule

    defstruct []
  end

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
    Pocion.call_window(:main, fn ->
      Raylib.set_target_fps(60)
      Raylib.set_trace_log_level(:log_debug)
    end)

    state = %State{}

    :proc_lib.init_ack(parent, {:ok, self()})

    loop(state)
  end

  def loop(state) do
    Pocion.execute(:main, [
      %{op: :begin_drawing, args: %{}},
      %{op: :clear_background, args: %{color: :raywhite}},
      %{
        op: :draw_text,
        args: %{text: "Ping Pong in progress!!", x: 50, y: 200, font_size: 20, color: :lime}
      },
      %{op: :end_drawing, args: %{}}
    ])

    Pocion.call_window(:main, fn ->
      Raylib.wait_target_fps()
    end)

    loop(state)
  end
end
