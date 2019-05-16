defmodule Smflib.MixProject do
  use Mix.Project

  def project do
    [
      app: :smflib,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: [
        maintainers: ["Joshua Nussbaum"],
        licenses: ["MIT"],
        links: %{github: "https://github.com/mekostin/smflib"}
      ],
      description: """
           SNF forum library for Elixir
      """
    ]
  end

  def application do
    [
      extra_applications: []
    ]
  end

  defp deps do
    [
      {:httpoison, "~> 0.10.0"},
      {:poison, ">=0.0.0", override: true},
    ]
  end
end
