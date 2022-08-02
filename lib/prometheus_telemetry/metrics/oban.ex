if PrometheusTelemetry.Utils.app_loaded?(:oban) do
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
          tags: [:name, :attempt],
          tag_values: &extract_job_metadata/1
        ),
        distribution("oban.job.duration.millisecond",
          event_name: [:oban, :job, :stop],
          measurement: :duration,
          description: "Oban job duration",
          tags: [:name, :attempt],
          tag_values: &extract_job_metadata/1,
          unit: @duration_unit,
          reporter_options: [buckets: @buckets]
        ),
        distribution("oban.job.queue_time.millisecond",
          event_name: [:oban, :job, :stop],
          measurement: :queue_time,
          description: "Oban job queue time",
          tags: [:name, :attempt],
          tag_values: &extract_job_metadata/1,
          unit: @duration_unit,
          reporter_options: [buckets: @buckets]
        ),
        distribution("oban.job.exception.duration.millisecond",
          event_name: [:oban, :job, :exception],
          measurement: :duration,
          description: "Oban job exception duration",
          tags: [:name, :kind, :reason],
          tag_values: &extract_exception_metadata/1,
          unit: @duration_unit,
          reporter_options: [buckets: @buckets]
        ),
        distribution("oban.job.exception.queue_time.millisecond",
          event_name: [:oban, :job, :exception],
          measurement: :queue_time,
          description: "Oban job exception queue time",
          tags: [:name, :kind, :reason],
          tag_values: &extract_exception_metadata/1,
          unit: @duration_unit,
          reporter_options: [buckets: @buckets]
        )
      ]
    end

    defp extract_job_metadata(%{prefix: prefix, queue: queue, attempt: attempt}), 
      do: %{name: format_name(prefix, queue), attempt: attempt}
    
    defp extract_exception_metadata(%{prefix: prefix, queue: queue, kind: kind, reason: %{message: message}}), 
      do: %{name: format_name(prefix, queue), kind: kind, reason: message}

    defp format_name(prefix, queue), do: "#{prefix}.#{queue}"
  end
end
