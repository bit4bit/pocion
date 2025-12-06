defmodule PocionTest do
  use ExUnit.Case

  setup do
    wm = start_supervised!(Pocion.WindowManager)
    %{wm: wm}
  end

  test "window as process" do
    start_supervised!({Pocion, [:test1, %{width: 640, height: 480, title: "test1", opts: []}]})
  end

  test "single window" do
    assert {:ok, w} = Pocion.Window.create_link_window(640, 480, "test1")
    Pocion.Window.close_window(w)
  end

  test "multi window" do
    assert {:ok, w} = Pocion.Window.create_link_window(640, 480, "test2")
    assert {:ok, w2} = Pocion.Window.create_link_window(320, 240, "test3")
    Pocion.Window.close_window(w)
    Pocion.Window.close_window(w2)
  end

  test "when root dies windows die", %{wm: wm} do
    test_pid = self()

    pid =
      spawn(fn ->
        {:ok, w} = Pocion.Window.create_link_window(640, 480, "die")
        :ok = Pocion.WindowManager.register(wm, w, :die)
        send(test_pid, :started)
      end)

    assert_receive :started, 30000
    monitor_ref = Pocion.WindowManager.monitor(wm, :die)
    Process.exit(pid, :kill)
    assert_receive {:pocion, {:DOWN, ^monitor_ref, :window, :die}}, 1000
  end

  # not possible to test
  @tag skip: true
  test "run code on window" do
    {:ok, w} = Pocion.Window.create_link_window(640, 480, "test1")
    assert Pocion.Window.call_window(w, fn -> 1 + 1 end) == 2
    Pocion.Window.close_window(w)
  end
end
