defmodule NeheOpengl.Mixfile do
  use Mix.Project

  def project do
    [
      app: :nehe_opengl,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:wx_utils, "~> 0.0.2"},
      {:gl_utils, "~> 0.0.1"}
    ]
  end
end
