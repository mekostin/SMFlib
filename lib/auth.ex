defmodule Smflib.Authorization do
  defp grab_sessid({"Set-Cookie", <<"PHPSESSID=", sessid::bytes-size(26), "; ", _::binary>>}, _) do
    {:PHPSESSID, sessid}
  end

  defp grab_sessid(_, acc) do
    acc
  end

  defp get_sessid(%{headers: header, status_code: 200}) do
    header |> Enum.reduce([], &grab_sessid(&1, &2))
  end

  def grab_sessvar(body) do
    with [_, sessvar] <- Regex.run(~r/SessionVar: '(.*?)'/, body),
         [_, sessid] <- Regex.run(~r/SessionId: '(.*?)'/, body)
    do
      {String.to_atom(sessvar), sessid}
    end
  end

  defp auth(%{body: body, headers: header, status_code: 200}, url, user, password) do
    phpsessid = header |> Enum.reduce([], &grab_sessid(&1, &2))
    sessvar = body |> grab_sessvar
    usr_pwd = :crypto.hash(:sha, String.downcase(user)<>password) |> Base.encode16 |> String.downcase
    hash_passwrd = :crypto.hash(:sha, usr_pwd <> elem(sessvar, 1)) |> Base.encode16 |> String.downcase
    postdata = [
                 {:user, user},
                 {:passwrd, password},
                 {:cookielength, 60},
                 sessvar,
                 phpsessid,
                 {:hash_passwrd, hash_passwrd}
               ]

    url=url <> "/index.php?action=login2"
    HTTPoison.post(url, {:form, postdata})
      |> auth
  end

  defp auth({:ok, %HTTPoison.Response{body: body, headers: header, status_code: 302}}) do
    header |> Enum.reduce([], &grab_sessid(&1, &2))
  end

  defp auth(_, _, _, _) do
    auth(nil)
  end

  defp auth(_) do
    []
  end

  def get(url, user, password) do
    HTTPoison.get!(url)
      |> auth(url, user, password)
  end
end
