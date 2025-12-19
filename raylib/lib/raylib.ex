defmodule Raylib do
  @moduledoc """
  Documentation for `Raylib`.
  """

  use Zig,
    otp_app: :raylib,
    leak_check: true,
    callbacks: [on_load: :load_fn, on_unload: :unload_fn],
    c: [include_dirs: "/usr/local/include", link_lib: {:system, "raylib"}]

  defp __on_load__, do: 0

  ~Z"""
  const std = @import("std");

  const ray = @cImport({
      @cInclude("raylib.h");
  });

  const beam = @import("beam");
  const e = @import("erl_nif");

  const State = struct { sounds: std.AutoHashMap(u32, ray.Sound) };

  var engine_previous_time: f64 = 0.0;
  var engine_target_FPS: f64 = 60.0;

  // Module callbacks

  pub fn load_fn(private: ?*?*anyopaque, _: u32) !void {
      const stored_pointer = try beam.allocator.create(State);
      stored_pointer.* = .{ .sounds = std.AutoHashMap(u32, ray.Sound).init(beam.allocator) };
      private.?.* = stored_pointer;
  }

  pub fn unload_fn(private: ?*anyopaque) void {
      const priv_ptr_state: *State = @ptrCast(@alignCast(private.?));

      ray.CloseAudioDevice();
      var sound_it = priv_ptr_state.*.sounds.iterator();
      while (sound_it.next()) |entry| {
          ray.UnloadSound(entry.value_ptr.*);
      }
  }

  // Raylib

  const WindowOption = enum { audio };

  pub fn init_window(width: i32, height: i32, title: beam.term, options: beam.term) !beam.term {
      const woptions = try beam.get([]WindowOption, options, .{});
      const ctitle = try ray_string(title);
      defer beam.allocator.free(ctitle[0..std.mem.len(ctitle)]);
      ray.SetConfigFlags(ray.FLAG_MSAA_4X_HINT);
      ray.InitWindow(width, height, ctitle);
      for (woptions) |option| {
          switch (option) {
              .audio => ray.InitAudioDevice(),
          }
      }
      engine_previous_time = ray.GetTime();
      return beam.make(.ok, .{});
  }

  pub fn set_target_fps(fps: i32) beam.term {
      engine_target_FPS = @floatFromInt(fps);
      return beam.make(.ok, .{});
  }

  pub fn wait_target_fps() f64 {
      var current_time = ray.GetTime();
      var delta_time = current_time - engine_previous_time;
      const wait_time = (1.0 / engine_target_FPS) - delta_time;

      if (wait_time > 0) {
          ray.PollInputEvents();
          ray.WaitTime(wait_time);
          current_time = ray.GetTime();
      }

      delta_time = current_time - engine_previous_time;
      engine_previous_time = current_time;
      return delta_time;
  }

  pub fn window_should_close() bool {
      return ray.WindowShouldClose();
  }

  pub fn load_sound(sound_id: u32, sound_path: beam.term) !beam.term {
      const zsound_path = try ray_string(sound_path);
      const sound = ray.LoadSound(zsound_path);
      if (ray.IsSoundValid(sound)) {
          try get_priv_state().*.sounds.put(sound_id, sound);
          return beam.make(.ok, .{});
      } else {
          return beam.make(.{ .@"error", .invalid }, .{});
      }
  }

  const ColorType = enum { lightgray, raywhite, lime, blue };

  fn cast_color(icolor: beam.term) !ray.Color {
      const zcolor = try beam.get(ColorType, icolor, .{});
      return switch (zcolor) {
          .lightgray => ray.LIGHTGRAY,
          .raywhite => ray.RAYWHITE,
          .lime => ray.LIME,
          .blue => ray.BLUE,
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

  const KeyType = enum { KEY_G, KEY_H, KEY_RIGHT, KEY_LEFT, KEY_UP, KEY_DOWN, KEY_SPACE, KEY_ENTER, KEY_ESCAPE, KEY_LEFT_CONTROL };
  fn ray_key(key: KeyType) i32 {
      return switch (key) {
          .KEY_G => ray.KEY_G,
          .KEY_H => ray.KEY_H,
          .KEY_RIGHT => ray.KEY_RIGHT,
          .KEY_LEFT => ray.KEY_LEFT,
          .KEY_UP => ray.KEY_UP,
          .KEY_DOWN => ray.KEY_DOWN,
          .KEY_SPACE => ray.KEY_SPACE,
          .KEY_ENTER => ray.KEY_ENTER,
          .KEY_ESCAPE => ray.KEY_ESCAPE,
          .KEY_LEFT_CONTROL => ray.KEY_LEFT_CONTROL,
      };
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

  // error: error: evaluation exceeded 2000 backwards branches
  // soluciones intentadas:
  // - operation.op como beam.term (fallo)
  // - uso de union para separar por grupos los tipos (fallo)
  // - uso propiedad nif: [execute: [spec: false, doc: false]] (fallo)

  const Vector2 = struct { x: f32, y: f32 };
  const OperationType = enum { begin_drawing, end_drawing, draw_rectangle, draw_text, draw_fps, draw_circle, draw_circle_v, play_sound, clear_background, is_key_pressed, wait_time, swap_screen_buffer, poll_input_events };
  const Operation = struct { op: OperationType, args: beam.term };
  const DrawTextArguments = struct { text: beam.term, x: i32, y: i32, font_size: i32, color: beam.term };
  const DrawFPSArguments = struct { x: i32, y: i32 };
  const DrawCircleArguments = struct { x: i32, y: i32, radius: f32, color: beam.term };
  const DrawCircleVArguments = struct { center: Vector2, radius: f32, color: beam.term };
  const DrawRectangleArguments = struct { x: i32, y: i32, width: i32, height: i32, color: beam.term };
  const IsKeyPressedArguments = struct { key: KeyType, reply_pid: beam.pid, repeat: bool = false, release: bool = false };
  const PlaySoundArguments = struct { sound_id: u32 };
  const ClearBackgroundArguments = struct { color: beam.term };
  const WaitTimeArguments = struct { time: f64 };
  const SwapScreenBuffer = struct {};
  const PollInputEvents = struct {};
  pub fn execute(ops: []Operation) !beam.term {
      for (ops) |op| {
          switch (op.op) {
              .poll_input_events => {
                  ray.PollInputEvents();
              },
              .is_key_pressed => {
                  const args = try beam.get(IsKeyPressedArguments, op.args, .{});
                  const key = ray_key(args.key);

                  var pressed = ray.IsKeyPressed(key);
                  if (args.repeat and pressed == false) {
                      pressed = ray.IsKeyPressedRepeat(key);
                  }

                  if (args.release and ray.IsKeyReleased(key)) {
                      try beam.send(args.reply_pid, .{ .is_key_released, args.key }, .{});
                  } else if (pressed) {
                      try beam.send(args.reply_pid, .{ .is_key_pressed, args.key }, .{});
                  }
              },
              .begin_drawing => ray.BeginDrawing(),
              .end_drawing => ray.EndDrawing(),
              .draw_circle_v => {
                  const args = try beam.get(DrawCircleVArguments, op.args, .{});
                  ray.DrawCircleV(ray.Vector2{ .x = args.center.x, .y = args.center.y }, args.radius, try cast_color(args.color));
              },
              .draw_circle => {
                  const args = try beam.get(DrawCircleArguments, op.args, .{});
                  ray.DrawCircle(args.x, args.y, args.radius, try cast_color(args.color));
              },
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
              .play_sound => {
                  if (ray.IsAudioDeviceReady()) {
                      const args = try beam.get(PlaySoundArguments, op.args, .{});
                      const sound = get_priv_state().*.sounds.get(args.sound_id) orelse unreachable;
                      ray.PlaySound(sound);
                  }
              },
              .clear_background => {
                  const args = try beam.get(ClearBackgroundArguments, op.args, .{});
                  ray.ClearBackground(try cast_color(args.color));
              },
              .wait_time => {
                  const args = try beam.get(WaitTimeArguments, op.args, .{});
                  ray.WaitTime(args.time);
              },
              .swap_screen_buffer => {
                  ray.SwapScreenBuffer();
              },
          }
      }

      return beam.make(.ok, .{});
  }

  fn get_priv_state() *State {
      const priv_ptr: ?*anyopaque = e.enif_priv_data(beam.context.env);
      const priv_ptr_state: *State = @ptrCast(@alignCast(priv_ptr.?));
      return priv_ptr_state;
  }
  """
end
