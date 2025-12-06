defmodule HelloWorld do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, [])
  end

  @impl true
  def init(_) do
    winfo = Pocion.info(:hello_world)

    Pocion.call_window(:hello_world, fn ->
      Raylib.set_target_fps(60)
      Raylib.set_trace_log_level(:log_debug)
      Raylib.begin_drawing()
      Raylib.clear_background(:raywhite)
      Raylib.end_drawing()
    end)

    tick()
    {:ok, %{x: 0, y: 100, y_delta: 1, height: winfo.height}}
  end

  @impl true
  def handle_info(:tick, state) do
    tick()

    Pocion.call_window(:hello_world, fn ->
      Raylib.draw_operations([
        %{op: "clear_background", args: %{color: :raywhite}},
        %{op: "draw_fps", args: %{x: 10, y: 10}},
        %{op: "draw_text", args: %{text: "Hello world!", x: 190, y: state.y, font_size: 20, color: :lightgray}}
      ])

    end)

    y_next = state.y + state.y_delta

    y_delta =
      if y_next + 100 > state.height or y_next - 100 <= 0 do
        state.y_delta * -1
      else
        state.y_delta
      end

    {:noreply, %{state | y: y_next, y_delta: y_delta}}
  end

  defp tick do
    Process.send_after(self(), :tick, 10)
  end
end
