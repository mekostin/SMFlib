defmodule SmflibTest do
  use ExUnit.Case
  doctest Smflib

  #SMF requires delay between posting messages
  @wait_between_postings 6000 # 6 seconds

  def sleep_between_actions(data) do
    :timer.sleep(@wait_between_postings)
    data
  end

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
      |> sleep_between_actions
      |> Smflib.Post.update(add_message)
      # |> sleep_between_post
      # |> Smflib.Post.archive(add_message)
      |> (fn (out) -> assert out != :error end).()

  end
end
