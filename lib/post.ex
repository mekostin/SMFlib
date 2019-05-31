defmodule Smflib.Post do
  @max_deep_board_page 400

  defp grab_seqnum(body) do
    with [_, seqnum] <- Regex.run(~r/name="seqnum" value="(.*?)"/, body)
    do
      {:seqnum, seqnum}
    end
  end

  def new(data, board, subject, message) do
    Map.merge(data, %{board_id: board, subject: subject, message: message})
      |> new_topic
  end

  defp new_topic(%{sess_id: nil}), do: :error
  defp new_topic(%Smflib.Data{url: url, board_id: board, subject: subj,
                              message: msg, sess_id: sessid} = data) do
    url="#{url}/index.php?action=post;board=#{board}"
    case HTTPoison.post!(url, {:form, [sessid]}) do
      %HTTPoison.Response{body: body, headers: _, status_code: 200} ->
          postdata = [
            {:topic, 0},
            {:subject, subj},
            {:icon, "xx"},
            {:message, msg},
            {:message_mode, 0},
            {:notify, 0},
            {:lock, 0},
            {:sticky, 0},
            {:move, 0},
            {:additional_options, 0},
            sessid,
            Smflib.Authorization.grab_sessvar(body),
            grab_seqnum(body)
          ]

          url="#{url}/index.php?PHPSESSID=#{elem(sessid, 1)};action=post2;start=0;board=#{board}"
          case HTTPoison.post!(url, {:form, postdata}) do
            %HTTPoison.Response{body: _, headers: _, status_code: 302} -> data
            _ -> :error
          end

        _ -> :error
    end
  end

  def update(data, board, subject, message) do
    data
      |> Map.merge(%{board_id: board, subject: subject})
      |> update(message)
  end

  def update(:error, _), do: :error
  def update(data, message) do
    data
      |> Map.merge(%{message: message})
      |> find_topic(0)
      |> update_topic
  end

  def find_topic(data, @max_deep_board_page), do: data
  def find_topic(%{sess_id: nil} = data, _), do: data
  def find_topic(%Smflib.Data{topic_id: topic_id} = data, _) when topic_id>0, do: data
  def find_topic(%Smflib.Data{url: url, board_id: board, subject: subj, sess_id: sessid, topic_id: 0} = msg, board_list_id) do
    url = "#{url}/index.php?board=#{board}.#{board_list_id}"
    with %HTTPoison.Response{body: body, headers: _, status_code: 200} <- HTTPoison.post!(url, {:form, [sessid]}),
         [_, _, topic_id] <- Regex.run(~r/<a href="(.+);topic=(.+).0">#{subj}</, body)
    do
      msg |> Map.merge(%{topic_id: String.to_integer(topic_id)})
    else
      _ ->
          find_topic(msg, board_list_id + 20)
    end
  end

  defp update_topic(%{sess_id: nil}), do: :error
  defp update_topic(%{topic_id: 0}), do: :error
  defp update_topic(%Smflib.Data{url: url, board_id: board, subject: subj,
                                 message: msg, sess_id: sessid, topic_id: topic} = data) do
   url="#{url}/index.php?topic=#{topic}"
   with %HTTPoison.Response{body: body, headers: _, status_code: 200} <- HTTPoison.post!(url, {:form, [sessid]}),
        [_, _, last_msg] <- Regex.run(~r/<a class=\"button_strip_reply active\" href="(.+);last_msg=(.+)">/, body)
   do
     postdata = [
       {:topic, topic},
       {:subject, "Re: #{subj}"},
       {:icon, "xx"},
       {:message, msg},
       {:message_mode, 0},
       {:notify, 0},
       {:lock, 0},
       {:sticky, 0},
       {:move, 0},
       {:additional_options, 0},
       sessid,
       Smflib.Authorization.grab_sessvar(body),
       grab_seqnum(body)
     ]

     url="#{url}/index.php?PHPSESSID=#{elem(sessid, 1)};action=post2;board=#{board}"
     case HTTPoison.post!(url, {:form, postdata}) do
       %HTTPoison.Response{body: _, headers: _, status_code: 302} -> data
       _ -> :error
     end
   end
  end

  def archive(data, board, subject, archive_id) do
    data
      |> Map.merge(%{board_id: board, subject: subject})
      |> archive(archive_id)
  end

  def archive(data, archive_id) do
    data
      |> find_topic(0)
      |> lock
      |> archive_topic(archive_id)
  end

  def lock(%Smflib.Data{url: url, sess_id: sessid, topic_id: topic} = data) do
    url="#{url}/index.php?topic=#{topic}"
    with %HTTPoison.Response{body: body, headers: _, status_code: 200} <- HTTPoison.post!(url, {:form, [sessid]}),
         [_, lock_url] <- Regex.run(~r/<a class=\"button_strip_lock\" href="(.+)">/, body),
         %HTTPoison.Response{body: _, headers: _, status_code: 302} <- HTTPoison.get!(lock_url)
    do
      data
    else
      _ -> :error
    end
  end

  defp archive_topic(:error, _), do: :error
  defp archive_topic(%{sess_id: nil}, _), do: :error
  defp archive_topic(%{topic_id: 0}, _), do: :error
  defp archive_topic(%Smflib.Data{url: url, topic_id: topic, sess_id: sessid, subject: subject} = data, archive_id) do
    url="#{url}/index.php?topic=#{topic}"
    with %HTTPoison.Response{body: body, headers: _, status_code: 200} <- HTTPoison.post!(url, {:form, [sessid]}),
         [_, move_url] <- Regex.run(~r/<a class=\"button_strip_move\" href="(.+)">/, body),
         %HTTPoison.Response{body: _, headers: _, status_code: 200} <- HTTPoison.get!(move_url)
    do
      postdata = [
        {:topic, topic},
        {:toboard, archive_id},
        {:custom_subject, subject},
        {:reason, ""},
        sessid,
        Smflib.Authorization.grab_sessvar(body),
        grab_seqnum(body)
      ]

      url="#{url}/index.php?PHPSESSID=#{elem(sessid, 1)};action=movetopic2"
      case HTTPoison.post!(url, {:form, postdata}) do
        %HTTPoison.Response{body: _, headers: _, status_code: 302} -> data
        _ -> :error
      end
   else
     _ -> :error
   end
  end

end
