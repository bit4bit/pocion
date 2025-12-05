defmodule SDLTest do
  use ExUnit.Case

  test "basicc" do
    assert :ok = SDL.init(%{video: true})
    assert :ok = SDL.quit()
  end
end
