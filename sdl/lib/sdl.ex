defmodule SDL do
  @moduledoc false

  use Zig, otp_app: :sdl

  ~Z"""
  const beam = @import("beam");

  pub const InitFlags = struct { video: bool };

  pub fn init(options: InitFlags) beam.term {
      if (options.video) {}
      return beam.make(.ok, .{});
  }

  pub fn quit() beam.term {
      return beam.make(.ok, .{});
  }
  """
end
