if PrometheusTelemetry.Utils.app_loaded?(:swoosh) do
  defmodule PrometheusTelemetry.Metrics.Swoosh do
    @moduledoc """
    These metrics give you metrics around swoosh emails

      - `swoosh.deliver.request_count`
      - `swoosh.deliver.request_duration`
      - `swoosh.deliver.exception_count`
      - `swoosh.deliver_many.request_count`
      - `swoosh.deliver_many.request_duration`
      - `swoosh.deliver_many.exception_count`
    """

    import Telemetry.Metrics, only: [counter: 2, distribution: 2]

    @duration_unit {:native, :microsecond}
    @buckets PrometheusTelemetry.Config.default_microsecond_buckets()

    def metrics do
      [
        counter("swoosh.deliver.request_count",
          event_name: [:swoosh, :deliver, :start],
          measurement: :count,
          description: "Swoosh delivery delivery count",
          tags: [:mailer]
        ),

        distribution("swoosh.deliver.request_duration",
          event_name: [:swoosh, :deliver, :stop],
          measurement: :duration,
          description: "Swoosh delivery duration",
          tags: [:mailer],
          unit: @duration_unit,
          reporter_options: [buckets: @buckets]
        ),

        counter("swoosh.deliver.exception_count",
          event_name: [:swoosh, :deliver, :exception],
          measurement: :count,
          description: "Swoosh delivery delivery exception count",
          tags: [:mailer]
        ),

        counter("swoosh.deliver_many.request_count",
          event_name: [:swoosh, :deliver_many, :start],
          measurement: :count,
          description: "Swoosh delivery many count",
          tags: [:mailer]
        ),

        distribution("swoosh.deliver_many.request_duration",
          event_name: [:swoosh, :deliver_many, :stop],
          measurement: :duration,
          description: "Swoosh delivery many duration",
          tags: [:mailer],
          unit: @duration_unit,
          reporter_options: [buckets: @buckets]
        )
      ]
    end
  end
end
