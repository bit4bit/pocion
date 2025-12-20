defmodule PingPong.Racket do
  @moduledoc false

  defmodule State do
    @moduledoc false

    defstruct [:x, :y, :width, :height]
  end

  def new(%{x: x, y: y, width: width, height: height}) do
    %State{x: x, y: y, width: width, height: height}
  end

  def update(%State{} = state, env, fun \\ fn state, changes -> {state, changes} end) do
    {state, changes} = next_state(env, state)
    {state, changes} = fun.(state, changes)
    {state, changes}
  end

  def render(%State{} = state, _env, _changes) do
    [
      {:draw_rectangle,
       %{x: state.x, y: state.y, width: state.width, height: state.height, color: :lime}}
    ]
  end

  defp next_state(_env, %State{} = state) do
    {state, %{}}
  end
end
