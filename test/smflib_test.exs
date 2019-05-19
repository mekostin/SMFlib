defmodule SmflibTest do
  use ExUnit.Case
  doctest Smflib

  test "test" do
    url = System.get_env("SMF_URL")
    user = System.get_env("SMF_USER")
    password = System.get_env("SMF_PASSWORD")

    board_id = 13
    topic = "TEST TOPIC"
    message = "Hello World"
    add_message = "The World is Mine"

    Smflib.authorize(url, user, password)
      |> Smflib.Post.new(board_id, topic, message)

  end
end
