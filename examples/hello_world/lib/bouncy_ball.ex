defmodule BouncyBall do
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
    winfo = Pocion.info(:bouncy_ball)

    Pocion.call_window(:bouncy_ball, fn ->
      Raylib.set_target_fps(60)
      Raylib.set_trace_log_level(:log_debug)
    end)

    state = %{x: 100,  y: winfo.height - 200,
              dir_y: -1, dir_x: 1, vel: -1,
              y_delta: 1,
              diameter: 50,
              wheight: winfo.height, wwidth: winfo.width}

    :proc_lib.init_ack(parent, {:ok, self()})

    loop(state)
  end

  def loop(state) do
    Pocion.execute(:bouncy_ball, [
      %{op: :begin_drawing, args: %{}},
      %{op: :clear_background, args: %{color: :raywhite}},
      %{op: :draw_fps, args: %{x: 10, y: 10}},
      %{op: :draw_circle, args: %{x: round(state.x), y: round(state.y), radius: state.diameter / 2, color: :lightgray, apply_delta_time: state.vel + 0.04}},
      %{op: :end_drawing, args: %{}}
    ])

     vel = state.vel
    dy = vel;
    dx = 10 * state.dir_x
    dir_y = if(dy > 0, do: 1, else: -1)
    
    x = state.x + dx
    y = state.y + (dy + (dir_y * (state.diameter/2)))
    dist_floor = min(y, state.wheight - y)
    dist_walls = min(x, state.wwidth - x)

    vel = if(dist_floor < state.diameter, do: vel * -1, else: vel)
    dir_x = if(dist_walls < state.diameter, do: state.dir_x * -1, else: state.dir_x)
    loop(%{state | x: x, y: y, vel: vel, dir_x: dir_x, dir_y: dir_y})
  rescue
    ex ->
      IO.inspect(ex)
  end
end
