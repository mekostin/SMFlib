defmodule Smflib do
  @moduledoc """
  Documentation for Smflib.
  """

  @doc """
  """

  defmodule Data do
    defstruct url: "", board_id: 0, subject: "", message: "", sess_id: nil, topic_id: 0
  end

  def authorize(url, user, password) do
    Smflib.Authorization.get(url, user, password)
      |> (fn (auth) -> %{sess_id: auth} end).()
      |> Map.merge(%Smflib.Data{url: url}, fn _, sessid, _ -> sessid end)
  end
end
