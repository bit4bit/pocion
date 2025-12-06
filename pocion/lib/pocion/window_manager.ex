defmodule Pocion.WindowManager do
  @moduledoc """
  """

  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, [])
  end

  def register(manager, window, name) do
    GenServer.call(manager, {:register, window, name})
  end

  def monitor(manager, name) do
    GenServer.call(manager, {:monitor, name, self()})
  end

  @impl true
  def init(_) do
    {:ok, %{windows: %{}, monitors: %{}}}
  end

  @impl true
  def handle_call({:register, window, name}, _from, state) do
    state = put_in(state, [:windows, name], window)
    {:reply, :ok, state}
  end

  def handle_call({:monitor, name, reply_to}, _from, state) do
    case Map.get(state.windows, name) do
      nil ->
        raise "can't monitor window #{name}: not linked"

      window ->
        monitor_ref = Port.monitor(window.node_port)
        state = put_in(state, [:monitors, monitor_ref], {reply_to, name})

        {:reply, monitor_ref, state}
    end
  end

  @impl true
  def handle_info({:DOWN, ref, :port, _, _}, state) do
    {{reply_to, window_name}, monitors} = Map.pop(state.monitors, ref)
    windows = Map.delete(state.windows, window_name)

    send(reply_to, {:pocion, {:DOWN, ref, :window, window_name}})

    {:noreply, %{state | windows: windows, monitors: monitors}}
  end
end
