defmodule Pocion do
  @moduledoc """
  """

  use GenServer

  def start_link([name, %{width: _width, height: _height, title: _title, opts: _opts} = args]) do
    GenServer.start_link(__MODULE__, args, name: name)
  end

  def call_window(name, func) do
    GenServer.call(name, {:call_window, func})
  end

  @spec info(GenServer.server()) :: Pocion.Window.Information.t()
  def info(name) do
    GenServer.call(name, :info)
  end

  @impl true
  def init(args) do
    {:ok, w} = Pocion.Window.create_link_window(args.width, args.height, args.title, args.opts)
    {:ok, w}
  end

  @impl true
  def handle_call({:call_window, func}, _from, w) do
    result = Pocion.Window.call_window(w, func)
    {:reply, result, w}
  end

  def handle_call(:info, _from, w) do
    {:reply, Pocion.Window.info(w), w}
  end

  @impl true
  def terminate(_reason, w) do
    Pocion.Window.close_window(w)
    :normal
  end
end
