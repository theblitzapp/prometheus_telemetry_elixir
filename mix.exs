defmodule PrometheusTelemetry.MixProject do
  use Mix.Project

  def project do
    [
      app: :prometheus_telemetry,
      version: "0.4.13",
      elixir: "~> 1.12",
      description: "Prometheus metrics exporter using Telemetry.Metrics as a foundation",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      docs: docs(),
      package: package(),
      preferred_cli_env: [
        dialyzer: :test
      ],

      elixirc_options: [
        warnings_as_errors: true
      ],

      dialyzer: [
        plt_add_apps: [:ex_unit, :mix, :credo],
        list_unused_filters: true,
        plt_local_path: ".dialyzer",
        plt_core_path: ".dialyzer",
        ignore_warnings: ".dialyzer-ignore.exs",
        flags: [:unmatched_returns, :no_improper_lists]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: (if Mix.env() === :prod, do: [:logger], else: [:logger, :eex])
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:telemetry_metrics_prometheus_core, "~> 1.2"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:nimble_options, "~> 1.0"},

      {:absinthe, ">= 0.0.0", optional: true},
      {:ecto, ">= 0.0.0", optional: true},
      {:oban, ">= 0.0.0", optional: true},
      {:phoenix, ">= 0.0.0", optional: true},
      {:hackney, ">= 0.0.0", optional: true},
      {:swoosh, ">= 0.0.0", optional: true},
      {:finch, ">= 0.12.0", optional: true},

      {:plug, "~> 1.8"},
      {:plug_cowboy, "~> 2.5"},

      {:faker, "~> 0.17", only: [:test, :dev]},

      {:credo, "~> 1.6", only: [:test, :dev], runtime: false},
      {:blitz_credo_checks, "~> 0.1", only: [:test, :dev], runtime: false},

      {:ex_doc, ">= 0.0.0", optional: true, only: :dev},
      {:dialyxir, "~> 1.0", optional: true, only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Mika Kalathil"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/theblitzapp/prometheus_telemetry_elixir"},
      files: ~w(mix.exs README.md CHANGELOG.md LICENSE lib config priv)
    ]
  end

  defp docs do
    [
      main: "PrometheusTelemetry",
      source_url: "https://github.com/theblitzapp/prometheus_telemetry_elixir",

      groups_for_modules: [
        "General": [
          PrometheusTelemetry,
          PrometheusTelemetry.MetricsExporterPlug
        ],

        "Metrics": [
          PrometheusTelemetry.Metrics.Cowboy,
          PrometheusTelemetry.Metrics.Ecto,
          PrometheusTelemetry.Metrics.Finch,
          PrometheusTelemetry.Metrics.GraphQL,
          PrometheusTelemetry.Metrics.Oban,
          PrometheusTelemetry.Metrics.Phoenix,
          PrometheusTelemetry.Metrics.Swoosh,
          PrometheusTelemetry.Metrics.VM
        ]
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
