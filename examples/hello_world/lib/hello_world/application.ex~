defmodule HelloWorld.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
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
      HelloWorld
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HelloWorld.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
