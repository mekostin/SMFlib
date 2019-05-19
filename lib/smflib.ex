defmodule Smflib do
  @moduledoc """
  Documentation for Smflib.
  """
  
  @doc """
  """

  defmodule Data do
    defstruct url: "", board: 0, subject: "", message: "", sessid: nil, topic: 0
  end

  def authorize(url, user, password) do
    Smflib.Authorization.get(url, user, password)
      |> (fn (auth) -> %{sessid: auth} end).()
      |> Map.merge(%Smflib.Data{url: url}, fn _, sessid, _ -> sessid end)
  end
end
