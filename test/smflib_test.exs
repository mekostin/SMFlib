defmodule SmflibTest do
  use ExUnit.Case
  doctest Smflib

  test "test" do
    url = System.get_env("SMF_URL")
    user = System.get_env("SMF_USER")
    password = System.get_env("SMF_PASSWORD")

    board_id = 13
    subject = "TEST TOPIC"
    message = "Hello World"
    add_message = "The World is Mine"

    Smflib.authorize(url, user, password)
      |> Smflib.Post.new(board_id, subject, message)
      # |> Smflib.Post.updat(add_message)

    Smflib.authorize(url, user, password)
      |>Smflib.Post.update(board_id, subject, add_message)

  end
end
