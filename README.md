# Smflib

Simple Elixir library for working with SMF(v2.0.15) forum:
Opportunities:
- create a new topic with new initial message
- add message to particular topic
- lock and move the topic to archive branch of forum

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `smflib` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:smflib, "~> 0.1.0"}
  ]
end
```

## Examples

### Add new forum topic with message
```elixir
Smflib.authorize(url, user, password)
  |> Smflib.Post.new(board_id, subject, message)
```

### Update the topic with an additional message
```elixir
Smflib.authorize(url, user, password)
  |> Smflib.Post.update(board_id, subject, add_message)
```

### Lock and move topic to archive
```elixir
Smflib.authorize(url, user, password)
  |> Smflib.Post.archive(board_id, subject, add_message)
```

### Full example
SMF requires to make a delay between forum posting actions. Function sleep_between_actions is realized this requirements.

```elixir
Smflib.authorize(url, user, password)
  |> Smflib.Post.new(board_id, subject, message)
  |> sleep_between_actions
  |> Smflib.Post.update(add_message)
  |> sleep_between_actions
  |> Smflib.Post.archive(archive_id)
```
