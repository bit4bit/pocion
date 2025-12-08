<!-- LLM-Assisted -->


# Pocion

**!! Experimental**

A videogame library for Elixir built on top of Raylib, providing an ergonomic OTP-based API for creating games and graphical applications.

## Overview

Pocion wraps the Raylib graphics library with an Elixir-friendly interface, allowing you to create games using familiar OTP patterns like GenServers and Supervisors. Each window runs as a supervised process, making it easy to manage multiple windows and handle game state in a fault-tolerant way.

## Features

- OTP-based window management
- Multiple window support
- Drawing operations API (text, shapes, FPS counter)
- Raylib integration for graphics rendering
- Process-based game loops

## Project Structure

- `pocion/` - Core library providing the OTP wrapper around Raylib
- `raylib/` - Elixir bindings for the Raylib graphics library
- `examples/` - Sample applications demonstrating library usage

## Getting Started

Add `pocion` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:pocion, "~> 0.1.0"}
  ]
end
```

## Examples

See the [examples/](examples/) directory for complete working examples, including:

- **hello_world** - Multiple window examples with animated text and bouncing balls

Refer to [examples/README.md](examples/README.md) for instructions on how to run the examples.

## Basic Usage

```elixir
children = [
  {Pocion, [
    :my_window,
    %{
      width: 640,
      height: 480,
      title: "My Game",
      opts: [otp_app: :my_app]
    }
  ]}
]

Supervisor.start_link(children, strategy: :one_for_one)
```

## License

GNU General Public License v3.0