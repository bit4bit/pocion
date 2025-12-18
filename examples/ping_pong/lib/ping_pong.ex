defmodule PingPong do
  @moduledoc false

  defmodule State do
    use PrivateModule

    defstruct [:ball_pid, :winfo]
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

    {:ok, ball_pid} =
      PingPong.Ball.start_link(%{
        x: 100,
        y: 100,
        speed: 5.0,
        radius: 10.0,
        sound_bounce: @snd_bounce
      })

    Pocion.call_window(:main, fn ->
      Raylib.set_target_fps(60)
      Raylib.set_trace_log_level(:log_debug)
      Raylib.load_sound(@snd_bounce, "./priv/bounce-effect.ogg")
    end)

    state = %State{ball_pid: ball_pid, winfo: winfo}

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

    env_ref = make_ref()
    ball_operations = GenServer.call(state.ball_pid, {:update, env_ref, self(), env})
    operations = init_operations ++ main_operations ++ ball_operations ++ end_operations

    Pocion.execute(:main, operations)

    Pocion.call_window(:main, fn ->
      Raylib.wait_target_fps()
    end)

    receive do
      {:collision, ^env_ref} ->
        IO.puts("Collision")
    after
      0 -> :ok
    end

    loop(state)
  end
end
