defmodule Smflib.Post do
  @max_deep_board_page 20

  def new(data, board, subject, message) do
    Map.merge(data, %{board_id: board, subject: subject, message: message})
      |> new_topic
  end

  defp grab_seqnum(body) do
    with [_, seqnum] <- Regex.run(~r/name="seqnum" value="(.*?)"/, body)
    do
      {:seqnum, seqnum}
    end
  end

  defp new_topic(%{sess_id: nil}) do
    :error
  end

  defp new_topic(%Smflib.Data{url: url, board_id: board, subject: subj, message: msg, sess_id: sessid}) do
    url="#{url}/index.php?action=post;board=#{board}"
    case HTTPoison.post!(url, {:form, [sessid]}) do
      %HTTPoison.Response{body: body, headers: headers, status_code: 200} ->
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
          new_topic(HTTPoison.post!(url, {:form, postdata}))
        _ -> :error
    end
  end

  defp new_topic(%HTTPoison.Response{body: body, headers: _, status_code: 302}) do
    :ok
  end

  defp new_topic(_) do
    :error
  end

  def update(data, board, subject, message) do
    data
      |> Map.merge(%{board_id: board, subject: subject})
      |> update(message)
  end

  def update(data, message) do
    data
      |> Map.merge(%{message: message})
      |> find_topic(0)
      |> update_topic
  end

  def find_topic(data, @max_deep_board_page) do
    data
  end

  def find_topic(%{sess_id: nil} = data, _) do
    data
  end

  def find_topic(%Smflib.Data{url: url, board_id: board, subject: subj, sess_id: sessid, topic_id: 0} = msg, board_list_id) do
      url="#{url}/index.php?board=#{board}.#{board_list_id}"
      with %HTTPoison.Response{body: body, headers: _, status_code: 200} <- HTTPoison.post!(url, {:form, [sessid]}),
           [_, _, topic_id] <- Regex.run(~r/<a href="(.+);topic=(.+).0">#{subj}/, body)
      do
        msg |> Map.merge(%{topic_id: String.to_integer(topic_id)})
      else
        _ -> find_topic(msg, board_list_id + 1)
      end
  end

  defp update_topic(%{sess_id: nil}) do
    :error
  end

  defp update_topic(%{topic_id: 0}) do
    :error
  end

  defp update_topic(%Smflib.Data{url: url, board_id: board, subject: subj, message: msg, sess_id: sessid, topic_id: topic}) do
    :ok
  end

  # def update(%{board_id: board, subject: subj, message: msg}) do
  #   postdata=authorize()
  #   topic=find_topic(postdata, board, subj, 0)
  #   url=Configuration.get("FORUM/URL")<>"/index.php?topic=#{topic}"
  #   {:ok, %HTTPoison.Response{body: body, headers: headers, status_code: code}}=HTTPoison.post(url, {:form, postdata})
  #   last_msg=Regex.scan(~r/last_msg=\d+/, body) |> hd |> hd |> String.split("=") |> tl |> hd
  #
  #   postdata=postdata
  #           ++ [{:topic, topic}, {:subject, "Re: #{subj}"}, {:icon, "xx"}, {:message, msg}, {:notify, 0}, {:goback, 0}, {:sticky, 0}, {:move, 0}]
  #           ++ find_seqnum(body, "name=\"last_msg\"")
  #
  #   url=Configuration.get("FORUM/URL")<>"/index.php?action=post2;start=0;board="<>board
  #   {:ok, %HTTPoison.Response{body: body, headers: headers, status_code: code}}=HTTPoison.post(url, {:form, postdata})
  #   case code do
  #     302-> :ok
  #     _->:error
  #   end
  # end
  #
  # def archive(%{board_id: board, subject: subj}) do
  #   postdata=authorize()
  #   topic=find_topic(postdata, board, subj, 0)
  #   url=Configuration.get("FORUM/URL")<>"/index.php?topic=#{topic}"
  #   {:ok, %HTTPoison.Response{body: body, headers: headers, status_code: code}}=HTTPoison.post(url, {:form, postdata})
  #   last_msg=Regex.scan(~r/last_msg=\d+/, body) |> hd |> hd |> String.split("=") |> tl |> hd
  #
  #   postdata=postdata
  #             ++ [{:topic, topic}]
  #             ++ find_seqnum(body, "name=\"last_msg\"")
  #
  #
  #   postdata
  #   |> Enum.reject(fn({name, value})-> name==:seqnum end)
  #   |> Enum.reject(fn({name, value})-> name==:FSRCookieSMF2017 end)
  #   |> Enum.reduce(Configuration.get("FORUM/URL")<>"/index.php?action=lock", fn({name, value}, acc)->
  #                       acc<>";"<>Atom.to_string(name)<>"="<>value
  #                    end)
  #   |> HTTPoison.get!
  #
  #   %HTTPoison.Response{body: body, headers: headers, status_code: code}=
  #   postdata
  #   |> Enum.filter(fn({name, value})-> name==:PHPSESSID end)
  #   |> Enum.concat([{:topic, topic}])
  #   |> Enum.reduce(Configuration.get("FORUM/URL")<>"/index.php?action=movetopic", fn({name, value}, acc)->
  #                       acc<>";"<>Atom.to_string(name)<>"="<>value
  #                    end)
  #   |> HTTPoison.get!
  #
  #   postdata=postdata
  #   |> Enum.filter(fn({name, value})-> name==:PHPSESSID end)
  #   |> Enum.concat([{:topic, topic}])
  #   |> Enum.concat([{:toboard, Configuration.get("FORUM/ARCHIVE_ATM_BRANCH")}])
  #   |> Enum.concat(find_seqnum(body, "name=\"reason\""))
  #
  #
  #   url=Configuration.get("FORUM/URL")<>"/index.php?action=movetopic2"
  #   {:ok, %HTTPoison.Response{body: body, headers: headers, status_code: code}}=HTTPoison.post(url, {:form, postdata})
  #   case code do
  #     302-> :ok
  #     _->:error
  #   end
  # end
  #
  #


end
