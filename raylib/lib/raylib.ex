defmodule Raylib do
  @moduledoc """
  Documentation for `Raylib`.
  """

  use Zig,
      otp_app: :raylib,
      c: [include_dirs: "/usr/local/include", link_lib: {:system, "raylib"}]

  ~Z"""
  const ray = @cImport({
    @cInclude("raylib.h");
  });

  pub const InitWindowOptions = struct { width: i32, height: i32, title: [*]const u8 };
  const beam = @import("beam");

  pub fn init_window(options: InitWindowOptions) beam.term {
  ray.InitWindow(options.width, options.height, options.title);
  return beam.make(.ok, .{});
  }

  pub fn close_window() beam.term {
  ray.CloseWindow();
  return beam.make(.ok, .{});
  }
  """
end
