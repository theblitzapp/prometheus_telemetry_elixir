if match?({:module, _}, Code.ensure_compiled(Oban)) do
  defmodule PrometheusTelemetry.Metrics.Oban do
    @moduledoc """
      These metrics give you metrics around Oban jobs

        - `oban.job.started.count`
        - `oban.job.duration.millisecond`
        - `oban.job.queue_time.millisecond`
        - `oban.job.exception.duration.millisecond`
        - `oban.job.exception.queue_time.millisecond`
    """

    import Telemetry.Metrics, only: [counter: 2, distribution: 2]

    @duration_unit {:native, :millisecond}
    @buckets PrometheusTelemetry.Config.default_millisecond_buckets()

    def metrics do
      [
        counter("oban.job.started.count",
          event_name: [:oban, :job, :start],
          measurement: :count,
          description: "Oban jobs fetched count",
          tags: [:prefix, :queue, :attempt],
          tag_values: &extract_job_metadata/1
        ),
        distribution("oban.job.duration.millisecond",
          event_name: [:oban, :job, :stop],
          measurement: :duration,
          description: "Oban job duration",
          tags: [:prefix, :queue, :attempt, :state],
          tag_values: &extract_duration_metadata/1,
          unit: @duration_unit,
          reporter_options: [buckets: @buckets]
        ),
        distribution("oban.job.queue_time.millisecond",
          event_name: [:oban, :job, :stop],
          measurement: :queue_time,
          description: "Oban job queue time",
          tags: [:prefix, :queue, :attempt, :state],
          tag_values: &extract_duration_metadata/1,
          unit: @duration_unit,
          reporter_options: [buckets: @buckets]
        ),
        distribution("oban.job.exception.duration.millisecond",
          event_name: [:oban, :job, :exception],
          measurement: :duration,
          description: "Oban job exception duration",
          tags: [:prefix, :queue, :kind, :state, :reason],
          tag_values: &extract_exception_metadata/1,
          unit: @duration_unit,
          reporter_options: [buckets: @buckets]
        ),
        distribution("oban.job.exception.queue_time.millisecond",
          event_name: [:oban, :job, :exception],
          measurement: :queue_time,
          description: "Oban job exception queue time",
          tags: [:prefix, :queue, :kind, :state, :reason],
          tag_values: &extract_exception_metadata/1,
          unit: @duration_unit,
          reporter_options: [buckets: @buckets]
        )
      ]
    end

    defp extract_job_metadata(metadata), do: Map.take(metadata, [:prefix, :queue, :attempt])

    defp extract_duration_metadata(metadata),
      do: Map.take(metadata, [:prefix, :queue, :attempt, :state])

    defp extract_exception_metadata(%{reason: reason} = metadata) do
      metadata
      |> Map.take([:prefix, :queue, :kind, :state])
      |> Map.put(:reason, format_reason(reason))
    end

    defp format_reason(%Oban.CrashError{}), do: "Crash Error"
    defp format_reason(%Oban.PerformError{}), do: "Perform Error"
    defp format_reason(%Oban.TimeoutError{}), do: "Timeout Error"
    defp format_reason(_), do: "Unknown"
  end
end
