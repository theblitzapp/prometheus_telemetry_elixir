defmodule PrometheusTelemetry.MixProject do
  use Mix.Project

  def project do
    [
      app: :prometheus_telemetry,
      version: "0.1.0",
      elixir: "~> 1.12",
      description: "Prometheus metrics exporter using Telemetry.Metrics as a foundation",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      docs: docs(),
      package: package()
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
      {:telemetry_metrics_prometheus_core, "~> 1.0"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:nimble_options, "~> 0.4"},
      {:absinthe, "~> 1.7", optional: true},
      {:plug, "~> 1.8"},
      {:plug_cowboy, "~> 2.5"},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:faker, "~> 0.17", only: [:test, :dev]},
      {:finch, "~> 0.11", only: :test}
    ]
  end

  defp package do
    [
      maintainers: ["Mika Kalathil"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/theblitzapp/prometheus_telemetry_elixir"},
      files: ~w(mix.exs README.md CHANGELOG.md LICENSE lib config)
    ]
  end

  defp docs do
    [
      main: "PrometheusTelemetry",
      source_url: "https://github.com/theblitzapp/prometheus_telemetry_elixir",
      groups_for_modules: [
        General: [
          PrometheusTelemetry,
          PrometheusTelemetry.MetricsExporterPlug
        ],
        Metrics: [
          PrometheusTelemetry.Metrics.Ecto,
          PrometheusTelemetry.Metrics.GraphQL,
          PrometheusTelemetry.Metrics.Phoenix,
          PrometheusTelemetry.Metrics.VM
        ]
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
