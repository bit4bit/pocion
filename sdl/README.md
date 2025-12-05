# Sdl

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `sdl` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:sdl, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/sdl>.

## Issues


### asdf sema error: No version is set for command zig

```
22:31:18.099 [debug] running command: /home/bit4bit/.asdf/shims/zig build -Dzigler-mode=sema

22:31:18.109 [error] sema error: No version is set for command zig
Consider adding one of the following versions in your config file at /tmp/Elixir.SDL/.tool-versions
zig 0.15.2
```

run
```
cp .tool-version ~/
```
