## PrometheusTelemetry
[![Test](https://github.com/theblitzapp/prometheus_telemetry_elixir/actions/workflows/test.yml/badge.svg)](https://github.com/theblitzapp/prometheus_telemetry_elixir/actions/workflows/test.yml)
[![Credo](https://github.com/theblitzapp/prometheus_telemetry_elixir/actions/workflows/credo.yml/badge.svg)](https://github.com/theblitzapp/prometheus_telemetry_elixir/actions/workflows/credo.yml)
[![Dialyzer](https://github.com/theblitzapp/prometheus_telemetry_elixir/actions/workflows/dialyzer.yml/badge.svg)](https://github.com/theblitzapp/prometheus_telemetry_elixir/actions/workflows/dialyzer.yml)
[![Hex version badge](https://img.shields.io/hexpm/v/prometheus_telemetry.svg)](https://hex.pm/packages/prometheus_telemetry)

PrometheusTelemetry is the plumbing for Telemetry.Metrics and allows the
metrics passed in to be collected and exported in the format expected
by the prometheus scraper.

This supervisor also contains the ability to spawn an exporter which will
scrape every supervisor running for metrics and will spin up a plug and return
it at `/metrics` on port 4050 by default, this will work out of the box with umbrella apps as well and allow you to define metrics in each umbrella app

### Installation

The package can be installed by adding `prometheus_telemetry` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:prometheus_telemetry, "~> 0.2.2"}
  ]
end
```

Documentation can be found at <https://hexdocs.pm/prometheus_telemetry>.


### Example

We can add this to any application we want:

```elixir
children = [
  {PrometheusTelemetry, metrics: [
   MyMetricsModule.metrics()
  ]}
]
```

Then to setup an exporter, on a server application like a phoenix app or pipeline
we can setup the exporter which will start the metrics server (by default on port `localhost:4050`):

```elixir
children = [
  {PrometheusTelemetry,
    exporter: [enabled?: true],
    metrics: MyMetricsModule.metrics()
  }
]
```

### Built in Metrics
There are built in metrics for some erlang vm stats, phoenix, absinthe, ecto and oban, to enable them we can use the following modules:

`PrometheusTelemetry.Metrics.{Ecto,Cowboy,Swoosh,Finch,Phoenix,GraphQL,Oban,VM}`
```elixir
children = [
  {PrometheusTelemetry,
    exporter: [enabled?: true],
    metrics: [
      PrometheusTelemetry.Metrics.Ecto.metrics(),
      PrometheusTelemetry.Metrics.Cowboy.metrics(),
      PrometheusTelemetry.Metrics.Swoosh.metrics(),
      PrometheusTelemetry.Metrics.Finch.metrics(),
      PrometheusTelemetry.Metrics.Phoenix.metrics(),
      PrometheusTelemetry.Metrics.GraphQL.metrics(),
      PrometheusTelemetry.Metrics.Oban.metrics(),
      PrometheusTelemetry.Metrics.VM.metrics()
    ]
  }
]
```

### Default Config
These are the default config settings, you can override by setting any of them
```
config :prometheus_telemetry,
  default_millisecond_buckets: [100, 300, 500, 1000, 2000, 5000, 10_000],
  default_microsecond_buckets: [50_000, 100_000, 250_000, 500_000, 750_000],
  measurement_poll_period: :timer.seconds(10),
  ecto_max_query_length: 150,
  ecto_known_query_module: nil
```

### Defining Custom Metrics
To define metrics we can create a module to group them like `MyMetricsModule`

```elixir
defmodule MyMetricsModule do
  import Telemetry.Metrics, only: [last_value: 2, counter: 2]

  def metrics do
    [
      counter(
        "prometheus_name.to_save", # becomes prometheus_name_to_save in prometheus
        event_name: [:event_namespace, :my_metric], # telemetry event name
        measurement: :count, # telemetry event metric
        description: "some description"
      ),

      last_value(
        "my_custom.name",
        event_name: [:event_namespace, :last_value],
        measurement: :total,
        description: "my value",
        tags: [:custom_metric] # custom metrics to save, derived from :telemetry.execute metadata
      )
    ]
  end

  def inc_to_save do
    :telemetry.execute([:event_namespace, :my_metric], %{count: 1})
  end

  def set_custom_name do
    :telemetry.execute([:event_namespace, :last_value], %{total: 123}, %{custom_metric: "region"})
  end
end
```

Ultimately every list will get flattened which allows you to group metric modules under a single module such as

```elixir
defmodule GraphQL.Request do
  def metrics do
    ...
  end
end

defmodule GraphQL.Complexity do
  def metrics do
    ...
  end
end

defmodule GraphQL do
  def metrics, do: [GraphQL.Complexity.metrics(), GraphQL.Request.metrics()]
end
```

For more details on types you can check [telemetry_metrics_prometheus_core](https://hexdocs.pm/telemetry_metrics_prometheus_core/1.0.1/TelemetryMetricsPrometheus.Core.html)
You can also generate these custom metrics modules using `mix prometheus_telemetry.gen.metrics`

#### Ecto Extras
A few extras exist for ecto, which include the ability to set the max query size before truncation
as well as add a known module query which will be called with `shorten(query)`

You can set both of these via config, by default there's no known query module and the max query size is 150.

The other way to set the label for a query is directly in the `Repo.all` or `Actions.all` (if using [ecto_shorts](https://github.com/MikaAK/ecto_shorts))

Repo:
```elixir
Repo.all(User, telemetry_options: [label: "All Users"])
```

EctoShorts:
```elixir
Actions.find(User, params, telemetry_options: [label: "Find User"])
```

#### Generating Metrics Modules
Using the `mix prometheus_telemetry.gen.metrics` you can generate metrics modules instead of writing them manually

```bash
$ mix prometheus_telemetry.gen.metrics MyApp.Metrics.Type counter:event.name.measurement.count:event.name.count:count:tags:profile:region
```

The format used is the following:
```elixir
<metric_type>:<metric_name>:<event_name>:<measurement_unit>:tags:<tag_name>:<tag_name>
```

View the `Mix.Tasks.PrometheusTelemetry.Gen.Metrics` module for more details

### Hiring

Are you looking for a new gig?? We're looking for mid-level to senior level developers to join our team and continue growing our platform while building awesome software!

Come join us at [Blitz.gg](https://blitz.gg/careers)
