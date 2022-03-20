## PrometheusTelemetry

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
    {:prometheus_telemetry, "~> 0.1.0"}
  ]
end
```

Documentation can be found at <https://hexdocs.pm/prometheus_telemetry_elixir>.


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
