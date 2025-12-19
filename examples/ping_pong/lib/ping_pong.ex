defmodule PingPong do
  @moduledoc false
  alias PingPong.Ball

  defmodule State do
    use PrivateModule

    defstruct [:ball, :winfo]
  end

  @snd_bounce 1

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
    winfo = Pocion.info(:main)

    ball =
      PingPong.Ball.new(%{x: 100, y: 100, speed: 5.0, radius: 10.0, bounce_sound_id: @snd_bounce})

    Pocion.call_window(:main, fn ->
      Raylib.set_target_fps(60)
      Raylib.set_trace_log_level(:log_debug)
      Raylib.load_sound(@snd_bounce, "./priv/bounce-effect.ogg")
    end)

    state = %State{ball: ball, winfo: winfo}

    :proc_lib.init_ack(parent, {:ok, self()})

    loop(state)
  end

  def loop(state) do
    # constant gravity
    env = %{
      gravity: 0.2,
      wall: %{x: 0, y: 0, width: state.winfo.width, height: state.winfo.height}
    }

    init_operations = [
      %{op: :begin_drawing, args: %{}},
      %{op: :clear_background, args: %{color: :raywhite}}
    ]

    main_operations = [
      %{
        op: :draw_text,
        args: %{text: "Ping Pong in progress!!", x: 50, y: 200, font_size: 20, color: :lime}
      }
    ]

    end_operations = [
      %{op: :end_drawing, args: %{}}
    ]

    {operations, state} = logic(env, state)

    operations = init_operations ++ main_operations ++ operations ++ end_operations

    Pocion.execute(:main, operations)

    Pocion.call_window(:main, fn ->
      Raylib.wait_target_fps()
    end)

    loop(state)
  end

  defp logic(env, state) do
    {ball, ball_changes} =
      Ball.update(state.ball, env, fn ball, changes ->
        collision_state = collision({:ball, ball, :env, env})
        Ball.bounce(ball, env, collision_state, changes)
      end)

    {Ball.render(ball, env, ball_changes), %{state | ball: ball}}
  end

  defp collision({:ball, ball, :env, env}) do
    dist_vertical_walls = min(ball.position.y, env.wall.height - ball.position.y)
    dist_horizontal_walls = min(ball.position.x, env.wall.width - ball.position.x)

    speed_x_changed? = dist_horizontal_walls <= ball.radius
    speed_y_changed? = dist_vertical_walls <= ball.radius

    %{
      speed_x_changed?: speed_x_changed?,
      speed_y_changed?: speed_y_changed?
    }
  end
end
