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
          tags: [:mailer, :status],
          tag_values: fn metadata ->
            metadata
              |> stringify_mailer_metadata
              |> add_status_to_metadata
          end
        ),

        distribution("swoosh.deliver.request.duration.microseconds",
          event_name: [:swoosh, :deliver, :stop],
          measurement: :duration,
          description: "Swoosh delivery duration",
          tags: [:mailer],
          tag_values: &stringify_mailer_metadata/1,
          unit: @duration_unit,
          reporter_options: [buckets: @buckets]
        ),

        counter("swoosh.deliver.exception_count",
          event_name: [:swoosh, :deliver, :exception],
          measurement: :count,
          description: "Swoosh delivery delivery exception count",
          tags: [:mailer, :error],
          tag_values: &stringify_mailer_metadata/1
        ),

        counter("swoosh.deliver_many.request.count",
          event_name: [:swoosh, :deliver_many, :start],
          measurement: :count,
          description: "Swoosh delivery many count",
          tags: [:mailer],
          tag_values: &stringify_mailer_metadata/1
        ),

        distribution("swoosh.deliver_many.request.duration.milliseconds",
          event_name: [:swoosh, :deliver_many, :stop],
          measurement: :duration,
          description: "Swoosh delivery many duration",
          tags: [:mailer],
          tag_values: &stringify_mailer_metadata/1,
          unit: @duration_unit,
          reporter_options: [buckets: @buckets]
        )
      ]
    end

    defp stringify_mailer_metadata(%{mailer: mailer_mod}), do: inspect(mailer_mod)

    defp add_status_to_metadata(%{error: _} = metadata), do: Map.put(metadata, :status, "error")
    defp add_status_to_metadata(_ = metadata), do: Map.put(metadata, :status, "success")
  end
end
