defmodule PingPong.Ball do
  defmodule State do
    use PrivateModule
    defstruct [:position, :speed, :radius, :gravity, :bounce_sound_id]
  end

  def new(%{x: x, y: y, speed: speed, radius: radius, bounce_sound_id: bounce_sound_id}) do
    %State{
      position: %{x: x, y: y},
      speed: %{x: speed, y: speed},
      radius: radius,
      gravity: 0.0,
      bounce_sound_id: bounce_sound_id
    }
  end

  def update(%State{} = state, env, fun) do
    {state, changes} = next_state(env, state)
    {state, changes} = fun.(state, changes)
    {state, changes}
  end

  def bounce(%State{} = state, _env, collision_state, changes) do
    speed_x =
      if(collision_state.speed_x_changed?,
        do: state.speed.x * -1.0,
        else: state.speed.x
      )

    speed_y =
      if(collision_state.speed_y_changed?,
        do: state.speed.y * -1.0,
        else: state.speed.y
      )

    bounce? = collision_state.speed_x_changed? || collision_state.speed_y_changed?
    {%{state | speed: %{x: speed_x, y: speed_y}}, Map.put(changes, :bounce?, bounce?)}
  end

  def render(%State{} = state, _env, changes) do
    [
      %{
        op: :draw_circle_v,
        args: %{
          center: %{x: state.position.x, y: state.position.y},
          radius: state.radius,
          color: :lime
        }
      }
    ]
    |> then(fn ops ->
      if changes.bounce? do
        ops ++
          [
            %{
              op: :play_sound,
              args: %{sound_id: state.bounce_sound_id}
            }
          ]
      else
        ops
      end
    end)
  end

  defp next_state(env, state) do
    speed = state.speed
    position = %{x: state.position.x + speed.x, y: state.position.y + speed.y + state.gravity}
    new_state = %{state | position: position, gravity: env.gravity}

    {new_state, %{}}
  end
end
