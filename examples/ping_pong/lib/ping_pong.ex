defmodule PingPong do
  @moduledoc false
  alias PingPong.Ball
  alias PingPong.Racket
  require Logger

  defmodule State do
    use PrivateModule

    defstruct [:ball, :player, :operations, :winfo]
  end

  defmodule Collision do
    defstruct ball_horizontal_collision?: false, ball_vertical_collision?: false
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

    state = %State{
      ball: ball,
      player: player,
      operations: [],
      winfo: winfo
    }

    :proc_lib.init_ack(parent, {:ok, self()})

    loop(state)
  rescue
    ex ->
      Logger.error(Exception.format(:error, ex, __STACKTRACE__))
      :proc_lib.stop(self(), :exception, 5000)
  end

  defp add_op(state, {op, args}) do
    %{state | operations: state.operations ++ [%{op: op, args: args}]}
  end

  defp add_ops(state, ops) do
    Enum.reduce(ops, state, fn op, state -> add_op(state, op) end)
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
    |> add_op({:clear_background, %{color: :raywhite}})
    |> add_op(
      {:draw_text, %{text: "Ping Pong in progress!!", x: 50, y: 200, font_size: 20, color: :lime}}
    )
    |> logic(env)
    |> draw()
    |> wait_fps()
    |> loop()
  end

  defp draw(state) do
    {operations, state} =
      state
      |> add_ops(Ball.render(state.ball))
      |> add_ops(Racket.render(state.player))
      |> flush_operations()

    operations =
      [%{op: :begin_drawing, args: %{}}] ++ operations ++ [%{op: :end_drawing, args: %{}}]

    Pocion.execute(:main, operations)

    state
  end

  defp wait_fps(state) do
    Pocion.call_window(:main, fn ->
      Raylib.wait_target_fps()
    end)

    state
  end

  defp logic(%State{} = state, env) do
    state
    |> step_ball(env)
    |> step_player(env)
    |> with_collisions(env, fn state, collisions, env ->
      state
      |> logic_ball(collisions, env)
    end)
  end

  defp logic_ball(%State{} = state, collisions, _env) do
    ball = Ball.logic(state.ball, collisions)

    %{state | ball: ball}
  end

  defp step_ball(%State{} = state, env) do
    ball = Ball.step(state.ball, env)

    %{state | ball: ball}
  end

  defp step_player(%State{} = state, env) do
    player = Racket.step(state.player, env)

    %{state | player: player}
  end

  defp with_collisions(%State{} = state, env, fun) do
    {state, collisions} = collision(state, {:ball, state.ball, :env, env})

    fun.(state, collisions, env)
  end

  defp collision(state, {:ball, ball, :env, env}) do
    dist_vertical_walls = min(ball.position.y, env.wall.height - ball.position.y)
    dist_horizontal_walls = min(ball.position.x, env.wall.width - ball.position.x)

    ball_horizontal_collision? = dist_horizontal_walls <= ball.radius
    ball_vertical_collision? = dist_vertical_walls <= ball.radius

    {state,
     %Collision{
       ball_horizontal_collision?: ball_horizontal_collision?,
       ball_vertical_collision?: ball_vertical_collision?
     }}
  end
end
