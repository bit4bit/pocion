defmodule HelloWorld.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Supervisor.child_spec(
        {Pocion,
         [
           :hello_world,
           %{
             width: 640,
             height: 480,
             title: "Hello World",
             opts: [
               otp_app: :hello_world
             ]
           }
         ]},
        id: :hello_world
      ),
      HelloWorld,

      Supervisor.child_spec(
        {Pocion,
         [
           :bouncy_ball,
           %{
             width: 640,
             height: 480,
             title: "Bouncy Ball",
             opts: [
               otp_app: :hello_world
             ]
           }
         ]},
        id: :bouncy_ball
      ),
      BouncyBall,
            Supervisor.child_spec(
        {Pocion,
         [
           :bouncy_ball_vector2,
           %{
             width: 800,
             height: 450,
             title: "Bouncy Ball Vector2",
             opts: [
               otp_app: :hello_world
             ]
           }
         ]},
        id: :bouncy_ball_vector2
      ),
      BouncyBallVector2
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HelloWorld.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
