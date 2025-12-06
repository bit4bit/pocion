defmodule HelloWorld do
  @moduledoc """
  Documentation for `HelloWorld`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> HelloWorld.hello()
      :world

  """

  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, [])
  end

  @impl true
  def init(_) do
    {:ok, w} =
      Pocion.create_link_window(640, 480, "Hello World",
        otp_app: :hello_world,
        pocion_node_path: "../../pocion_node"
      )

    Pocion.call_window(w, fn ->
      Raylib.set_target_fps(60)
      Raylib.clear_background(:raywhite)
      Raylib.begin_drawing()
      Raylib.draw_text("Hello World!", 190, 200, 20, :lightgray)
      Raylib.end_drawing()
    end)

    {:ok, w2} =
      Pocion.create_link_window(640, 480, "Hello World",
        otp_app: :hello_world,
        pocion_node_path: "../../pocion_node"
      )

    Pocion.call_window(w2, fn ->
      Raylib.set_target_fps(60)
      Raylib.clear_background(:raywhite)
      Raylib.begin_drawing()
      Raylib.draw_text("Hello World!", 190, 200, 20, :lightgray)
      Raylib.end_drawing()
    end)

    Process.sleep(5000)
    {:ok, nil}
  end
end
