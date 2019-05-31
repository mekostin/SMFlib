defmodule Smflib do
  @moduledoc """
  Documentation for Smflib.
  """

  @doc """
  """

  defmodule Data do
    defstruct url: "", board_id: 0, subject: "", message: "", sess_id: nil, topic_id: 0
  end

  defp generate_data(sess_id, url) do
    %Smflib.Data{url: url, sess_id: sess_id}
  end

  def authorize(url, user, password) do
    Smflib.Authorization.get(url, user, password)
      |> generate_data(url)
  end
end
