defmodule Smflib.Post do

  def new(data, board, subject, message) do
    Map.merge(data, %{board: board, subject: subject, message: message}) |> new_topic
  end

  defp grab_seqnum(body) do
    with [_, seqnum] <- Regex.run(~r/name="seqnum" value="(.*?)"/, body)
    do
      {:seqnum, seqnum}
    end
  end

  defp new_topic(%Smflib.Data{url: url, board: board, subject: subj, message: msg, sessid: sessid})
  when not is_nil(sessid) do
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

  def update(url, user, password, message) do
    Smflib.Authorization.get(url, user, password)
      |> (fn (auth) -> %{sessid: auth} end).()
      |> Map.merge(message, fn _, sessid, _ -> sessid end)
      |> find_topic(0)
      |> update_topic
  end

  def find_topic(%Smflib.Data{url: url, board: board, subject: subj, sessid: sessid} = msg, board_list_id)
  when not is_nil(sessid) do
    if board_list_id<=20 do
      url="#{url}/index.php?board=#{board}.#{board_list_id}"
      case HTTPoison.post(url, {:form, [sessid]}) do
        %HTTPoison.Response{body: body, headers: _, status_code: 200} ->
            reg=Regex.compile!("<a (.+)>#{subj}")
            case Regex.match?(reg, body) do
              true ->
                Regex.scan(reg, body)
                  |> IO.inspect
                  |> hd |> tl |>hd |> String.split(";") |> tl |> hd |> String.split("=") |> tl |> hd |>String.trim("\"")
              false->
                find_topic(msg, board_list_id+1)
            end
        _ -> :error
      end
    end
  end

  def update_topic(%Smflib.Data{url: url, board: board, subject: subj, message: msg, sessid: sessid} = msg)
  when not is_nil(sessid) do
    :ok
  end

  def find_topic(_) do
    :error
  end

  def update_topic(_) do
    :error
  end



  # def update(%{board: board, subject: subj, message: msg}) do
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
  # def archive(%{board: board, subject: subj}) do
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
