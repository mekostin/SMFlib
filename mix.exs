defmodule Smflib.MixProject do
  use Mix.Project

  def project do
    [
      app: :smflib,
      version: "0.1.1",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: [
        maintainers: ["Mikhail Kostin"],
        licenses: ["MIT"],
        links: %{github: "https://github.com/mekostin/smflib"}
      ],
      description: """
           SMF forum library for Elixir
      """
    ]
  end

  def application do
    [
      extra_applications: [
        :httpoison
      ]
    ]
  end

  defp deps do
    [
      {:httpoison, "~> 1.4.0"},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end
end
