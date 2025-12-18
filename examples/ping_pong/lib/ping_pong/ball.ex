defmodule PingPong.Ball do
  @moduledoc false

  use GenServer

  def start_link(%{x: x, y: y, speed: speed, radius: radius, sound_bounce: sound_bounce}) do
    GenServer.start_link(
      __MODULE__,
      %{x: x, y: y, speed: speed, radius: radius, sound_bounce: sound_bounce},
      []
    )
  end

  @impl true
  def init(%{x: x, y: y, speed: speed, radius: radius, sound_bounce: sound_bounce}) do
    position = %{x: x, y: y}
    speed = %{x: speed, y: speed}

    {:ok,
     %{position: position, speed: speed, radius: radius, gravity: 0.0, sound_bounce: sound_bounce}}
  end

  @impl true
  def handle_call({:update, env_ref, env_pid, %{wall: _, gravity: _} = env}, _from, state) do
    {state, changes} = next_state(env, state)

    operations = [
      %{
        op: :draw_circle_v,
        args: %{
          center: %{x: state.position.x, y: state.position.y},
          radius: state.radius,
          color: :lime
        }
      }
    ]

    operations =
      if(changes.speed?,
        do: operations ++ [%{op: :play_sound, args: %{sound_id: state.sound_bounce}}],
        else: operations
      )

    if changes.speed? do
      send(env_pid, {:collision, env_ref})
    end

    {:reply, operations, state}
  end

  defp next_state(env, state) do
    speed = state.speed
    position = %{x: state.position.x + speed.x, y: state.position.y + speed.y + state.gravity}
    dist_vertical_walls = min(position.y, env.wall.height - position.y)
    dist_horizontal_walls = min(position.x, env.wall.width - position.x)

    {speed_x, speed_x_changed?} =
      if(dist_horizontal_walls <= state.radius,
        do: {speed.x * -1.0, true},
        else: {speed.x, false}
      )

    {speed_y, speed_y_changed?} =
      if(dist_vertical_walls <= state.radius, do: {speed.y * -1.0, true}, else: {speed.y, false})

    speed = %{x: speed_x, y: speed_y}

    new_state = %{state | position: position, speed: speed, gravity: env.gravity}
    changes = %{speed?: speed_x_changed? or speed_y_changed?}

    {new_state, changes}
  end
end
