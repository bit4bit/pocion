defmodule PingPong.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Pocion,
       [:main, %{width: 640, height: 480, title: "Ping Pong", opts: [otp_app: :ping_pong]}]},
      PingPong
    ]

    opts = [strategy: :one_for_one, name: PingPong.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
