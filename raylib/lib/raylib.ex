defmodule Raylib do
  @moduledoc """
  Documentation for `Raylib`.
  """

  use Zig,
    otp_app: :raylib,
    leak_check: true,
    c: [include_dirs: "/usr/local/include", link_lib: {:system, "raylib"}]

  ~Z"""
  const std = @import("std");

  const ray = @cImport({
      @cInclude("raylib.h");
  });

  const beam = @import("beam");

  pub fn init_window(width: i32, height: i32, title: beam.term) !beam.term {
      const ctitle = try ray_string(title);
      defer beam.allocator.free(ctitle[0..std.mem.len(ctitle)]);

      ray.InitWindow(width, height, ctitle);

      return beam.make(.ok, .{});
  }

  pub fn set_target_fps(fps: i32) beam.term {
      ray.SetTargetFPS(fps);
      return beam.make(.ok, .{});
  }

  pub fn window_should_close() bool {
      return ray.WindowShouldClose();
  }

  pub fn begin_drawing() beam.term {
      ray.BeginDrawing();
      return beam.make(.ok, .{});
  }

  pub fn clear_background(icolor: beam.term) !void {
      ray.ClearBackground(try cast_color(icolor));
  }

  pub fn end_drawing() beam.term {
      ray.EndDrawing();
      return beam.make(.ok, .{});
  }

  const ColorType = enum { lightgray, raywhite };

  fn cast_color(icolor: beam.term) !ray.Color {
      const zcolor = try beam.get(ColorType, icolor, .{});
      return switch (zcolor) {
          .lightgray => ray.LIGHTGRAY,
          .raywhite => ray.RAYWHITE,
      };
  }

  // hack: [*c]const u8 in signature is not working
  fn ray_string(text: beam.term) ![*c]const u8 {
      const text_slice = try beam.get([]const u8, text, .{});
      const null_terminated = try beam.allocator.alloc(u8, text_slice.len + 1);
      @memcpy(null_terminated[0..text_slice.len], text_slice);
      null_terminated[text_slice.len] = 0;
      return null_terminated.ptr;
  }

  pub fn draw_text(text: beam.term, pos_x: i32, pos_y: i32, font_size: i32, icolor: beam.term) !beam.term {
      const ctext = try ray_string(text);
      defer beam.allocator.free(ctext[0..std.mem.len(ctext)]);
      ray.DrawText(ctext, pos_x, pos_y, font_size, try cast_color(icolor));

      return beam.make(.ok, .{});
  }

  pub fn draw_fps(pos_x: i32, pos_y: i32) beam.term {
      ray.DrawFPS(pos_x, pos_y);
      return beam.make(.ok, .{});
  }

  const LogLevelType = enum { log_debug, log_info, log_error };

  pub fn set_trace_log_level(ilog_level: beam.term) !beam.term {
      const zlevel = try beam.get(LogLevelType, ilog_level, .{});
      const level = switch (zlevel) {
          .log_info => ray.LOG_INFO,
          .log_debug => ray.LOG_DEBUG,
          .log_error => ray.LOG_ERROR,
      };

      ray.SetTraceLogLevel(level);

      return beam.make(.ok, .{});
  }

  pub fn close_window() beam.term {
      ray.CloseWindow();
      return beam.make(.ok, .{});
  }

  const Operation = struct { op: []const u8, args: beam.term };
  const OperationType = enum { draw_text, draw_fps, clear_background };
  const DrawTextArguments = struct { text: beam.term, x: i32, y: i32, font_size: i32, color: beam.term };
  const DrawFPSArguments = struct { x: i32, y: i32 };
  const ClearBackgroundArguments = struct { color: beam.term };

  pub fn draw_operations(ops: []Operation) !beam.term {
      ray.BeginDrawing();
      for (ops) |op| {
          const operation = std.meta.stringToEnum(OperationType, op.op) orelse {
              return error.InvalidChoice;
          };

          switch (operation) {
              .draw_text => {
                  const args = try beam.get(DrawTextArguments, op.args, .{});
                  const ctext = try ray_string(args.text);
                  defer beam.allocator.free(ctext[0..std.mem.len(ctext)]);

                  ray.DrawText(ctext, args.x, args.y, args.font_size, try cast_color(args.color));
              },
              .draw_fps => {
                  const args = try beam.get(DrawFPSArguments, op.args, .{});
                  ray.DrawFPS(args.x, args.y);
              },
              .clear_background => {
                  const args = try beam.get(ClearBackgroundArguments, op.args, .{});
                  ray.ClearBackground(try cast_color(args.color));
              },
          }
      }
      ray.EndDrawing();
      return beam.make(.ok, .{});
  }
  """
end
