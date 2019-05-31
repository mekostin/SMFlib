defmodule SmflibTest do
  use ExUnit.Case
  doctest Smflib

  #SMF requires delay between posting messages
  @test_topic_count 30
  @wait_between_postings 7000 # 6 seconds
  @tag timeout: 999999999

  def sleep_between_actions(data) do
    :timer.sleep(@wait_between_postings)
    data
  end

  test "test" do
    url = System.get_env("SMF_URL")
    user = System.get_env("SMF_USER")
    password = System.get_env("SMF_PASSWORD")

    board_id = 13
    archive_id = 3
    subject = "TEST_"
    message = "OFFLINE"
    add_message = "ONLINE"

    Enum.each(1..@test_topic_count, fn(x) ->
      IO.inspect "new #{subject}_#{x}"
      Smflib.authorize(url, user, password)
        |> Smflib.Post.new(board_id, "#{subject}_#{x}", message)
        |> sleep_between_actions
    end)

    Enum.each(1..@test_topic_count, fn(x) ->
      Enum.each(1..10, fn(y) ->
        IO.inspect "update_#{y}      #{subject}_#{x}"
        Smflib.authorize(url, user, password)
          |> Smflib.Post.update(board_id, "#{subject}_#{x}", "add_message_#{y}")
          |> sleep_between_actions
        end)
      end)

    Enum.each(1..@test_topic_count, fn(x) ->
      IO.inspect "archive #{subject}_#{x}"
      Smflib.authorize(url, user, password)
        |> Smflib.Post.archive(board_id, "#{subject}_#{x}", archive_id)
        # |> IO.inspect
        |> sleep_between_actions
    end)

    # Smflib.authorize(url, user, password)
    #   |> Smflib.Post.new(board_id, "#{subject}_#{x}", message)
    #   |> sleep_between_actions
    #   |> Smflib.Post.update(add_message)
    #   |> sleep_between_actions
    #   |> Smflib.Post.archive(archive_id)
    #   |> (fn (out) -> assert out != :error end).()

  end
end
