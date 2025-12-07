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
      Raylib.init_audio_device()
      Raylib.set_target_fps(60)
      Raylib.set_trace_log_level(:log_debug)
      Raylib.load_sound(1, "./priv/bounce-effect.ogg")
    end)

    state = %{
      x: 100,
      y: winfo.height - 200,
      dir_y: -1,
      dir_x: 1,
      vel: -1,
      y_delta: 1,
      diameter: 50,
      wheight: winfo.height,
      wwidth: winfo.width
    }

    :proc_lib.init_ack(parent, {:ok, self()})

    loop(state)
  end

  def loop(state) do
    operations = [
      %{op: :begin_drawing, args: %{}},
      %{op: :clear_background, args: %{color: :raywhite}},
      %{op: :draw_fps, args: %{x: 10, y: 10}},
      %{
        op: :draw_circle,
        args: %{
          x: round(state.x),
          y: round(state.y),
          radius: state.diameter / 2,
          color: :lightgray
        }
      },
      %{op: :end_drawing, args: %{}}
    ]

    vel = state.vel
    dy = vel
    dx = 10 * state.dir_x
    dir_y = if(dy > 0, do: 1, else: -1)

    x = state.x + dx
    y = state.y + (dy + dir_y * (state.diameter / 2))
    dist_floor = min(y, state.wheight - y)
    dist_walls = min(x, state.wwidth - x)

    {vel, vel_changed?} =
      if(dist_floor < state.diameter, do: {vel * -1, true}, else: {vel, false})

    {dir_x, dir_x_changed?} =
      if(dist_walls < state.diameter, do: {state.dir_x * -1, true}, else: {state.dir_x, false})

    operations =
      if vel_changed? or dir_x_changed? do
        operations
      else
        operations
      end

    Pocion.execute(:bouncy_ball, operations)
    loop(%{state | x: x, y: y, vel: vel, dir_x: dir_x, dir_y: dir_y})
  rescue
    ex ->
      IO.inspect(ex)
  end
end

defmodule BouncyBallVector2 do
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
    winfo = Pocion.info(:bouncy_ball_vector2)

    Pocion.call_window(:bouncy_ball_vector2, fn ->
      Raylib.init_audio_device()
      Raylib.set_target_fps(60)
      Raylib.set_trace_log_level(:log_debug)
      Raylib.load_sound(1, "./priv/bounce-effect.ogg")
    end)

    state = %{
      ball_position: %{x: winfo.width / 2, y: winfo.height / 2},
      ball_speed: %{x: 5.0, y: 4.0},
      ball_radius: 20.0,
      gravity: 0.2,
      wheight: winfo.height,
      wwidth: winfo.width
    }

    :proc_lib.init_ack(parent, {:ok, self()})

    loop(state)
  end

  def loop(state) do
    Pocion.execute(:bouncy_ball_vector2, [
      %{op: :begin_drawing, args: %{}},
      %{op: :clear_background, args: %{color: :raywhite}},
      %{op: :draw_fps, args: %{x: 10, y: 10}},
      %{
        op: :draw_circle_v,
        args: %{center: state.ball_position, radius: state.ball_radius, color: :lime}
      },
      %{op: :end_drawing, args: %{}}
    ])

    ball_position = %{
      x: state.ball_position.x + state.ball_speed.x,
      y: state.ball_position.y + state.ball_speed.y
    }

    dist_floor = min(ball_position.y, state.wheight - ball_position.y)
    dist_walls = min(ball_position.x, state.wwidth - ball_position.x)

    {ball_speed_x, ball_speed_x_changed?} =
      if(dist_walls <= state.ball_radius,
        do: {state.ball_speed.x * -1.0, true},
        else: {state.ball_speed.x, false}
      )

    {ball_speed_y, ball_speed_y_changed?} =
      if(dist_floor <= state.ball_radius,
        do: {state.ball_speed.y * -0.95, true},
        else: {state.ball_speed.y, false}
      )

    ball_speed = %{x: ball_speed_x, y: ball_speed_y + state.gravity}

    if ball_speed_x_changed? or ball_speed_y_changed? do
      Pocion.execute(:bouncy_ball_vector2, [
        %{op: :play_sound, args: %{sound_id: 1}}
      ])
    end

    loop(%{state | ball_speed: ball_speed, ball_position: ball_position})
  rescue
    ex ->
      IO.inspect(ex)
  end
end
