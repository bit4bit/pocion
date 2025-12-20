defmodule PingPong do
  @moduledoc false
  alias PingPong.Ball
  alias PingPong.Racket

  defmodule State do
    use PrivateModule

    defstruct [:ball, :player, :operations, :winfo]
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

    player =
      PingPong.Racket.new(%{x: 200, y: 200, width: 100, height: 10})

    Pocion.call_window(:main, fn ->
      Raylib.set_target_fps(60)
      Raylib.set_trace_log_level(:log_debug)
      Raylib.load_sound(@snd_bounce, "./priv/bounce-effect.ogg")
    end)

    state = %State{ball: ball, player: player, winfo: winfo, operations: []}

    :proc_lib.init_ack(parent, {:ok, self()})

    loop(state)
  end

  defp add_op(state, {op, args}) do
    %{state | operations: state.operations ++ [%{op: op, args: args}]}
  end

  defp flush_operations(state) do
    operations = state.operations
    {operations, %{state | operations: []}}
  end

  def loop(state) do
    # constant gravity
    env = %{
      gravity: 0.2,
      wall: %{x: 0, y: 0, width: state.winfo.width, height: state.winfo.height}
    }

    state
    |> add_op({:begin_drawing, %{}})
    |> add_op({:clear_background, %{color: :raywhite}})
    |> add_op(
      {:draw_text, %{text: "Ping Pong in progress!!", x: 50, y: 200, font_size: 20, color: :lime}}
    )
    |> add_op({:end_drawing, %{}})
    |> logic(env)
    |> draw()
    |> wait_fps()
    |> loop()
  end

  defp draw(state) do
    {operations, state} = flush_operations(state)
    Pocion.execute(:main, operations)

    state
  end

  defp wait_fps(state) do
    Pocion.call_window(:main, fn ->
      Raylib.wait_target_fps()
    end)

    state
  end

  defp logic(state, env) do
    {ball, ball_changes} =
      Ball.update(state.ball, env, fn ball, changes ->
        collision_state = collision({:ball, ball, :env, env})
        Ball.bounce(ball, env, collision_state, changes)
      end)

    ball_operations = Ball.render(ball, env, ball_changes)

    {player, player_changes} =
      Racket.update(state.player, env)

    player_operations = Racket.render(player, env, player_changes)

    Enum.reduce(
      ball_operations ++ player_operations,
      %{state | ball: ball, player: player},
      fn op, state ->
        add_op(state, op)
      end
    )
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
