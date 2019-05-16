defmodule Smflib.Authorization do
  def grab_sessid({"Set-Cookie", <<"PHPSESSID=", sessid::bytes-size(26), "; ", _::binary>>}, _) do
    {:PHPSESSID, sessid}
  end

  def grab_sessid(_, acc) do
    acc
  end

  def get_sessid(%{headers: header, status_code: 200}) do
    header |> Enum.reduce([], &Smflib.Authorization.grab_sessid(&1, &2))
  end

  def grab_seqnum([_, <<"<input type=\"hidden\" name=\"", name::bytes-size(12),
                    "\" value=\"", value::bytes-size(32), "\" />", _::binary>>, _]) do
    {String.to_atom(name), value}
  end

  def grab_seqnum(body) do
    body
      |> String.split("<input type=\"hidden\" name=\"hash_passwrd\" value=\"\" />")
      |> grab_seqnum
  end

  def grab_seqnum(_) do
    []
  end

  def get(url, user, password) do
    case HTTPoison.get!(url) do
      %{body: body, headers: header, status_code: 200} ->
          phpsessid = header |> Enum.reduce([], &Smflib.Authorization.grab_sessid(&1, &2))
          seqnum = body |> grab_seqnum
          postdata = [
                       {:user, user},
                       {:passwrd, password},
                       {:cookielength, 60},
                       seqnum,
                       phpsessid
                     ]

                     #
                     # url=Configuration.get("FORUM/URL")<>"/index.php?action=login2"
                     # {:ok, %HTTPoison.Response{body: body, headers: headers, status_code: code}}=HTTPoison.post(url, {:form, postdata})

      _ ->
        []
    end

    #
    # Enum.filter(headers, fn
    #     {"Set-Cookie", _} -> true
    #      _ -> false
    #    end)
    # |> Enum.reduce([], fn(x, acc)->
    #      value=elem(x, 1) |> String.split(";") |> hd |> String.split("=")
    #      [{String.to_atom(hd(value)), hd(tl(value))} | acc]
    #    end)
  end

end
