defmodule PrometheusTelemetry.Support.MockSupervisor do
  @moduledoc "gen server use for mock metric"

  import Telemetry.Metrics, only: [counter: 2]

  @event_name_b "magic_snort_snort"

  @spec setup :: any
  def setup do
    PrometheusTelemetry.start_link(
      name: :test_exporter,
      exporter: [enabled?: true],
      metrics: [
        counter("some_thing.test.magic",
          event_name: @event_name_b,
          measurement: :count,
          description: "HELLO",
          tag: [:bacon]
        )
      ]
    )
  end
end

