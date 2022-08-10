if PrometheusTelemetry.Utils.app_loaded?(:cowboy) do
  defmodule PrometheusTelemetry.Metrics.Cowboy do
    @moduledoc """
    These metrics give you data around Cowboy, the low level web handler of phoenix

      - `cowboy.request.count`
      - `cowboy.request.early_error.count`
      - `cowboy.request.exception.count`
      - `cowboy.request.duration.milliseconds`
    """

    import Telemetry.Metrics, only: [distribution: 2, counter: 2]

    @duration_unit {:native, :millisecond}
    @buckets PrometheusTelemetry.Config.default_millisecond_buckets()

    def metrics do
      [
        counter(
          "cowboy.request.count",
          event_name: [:cowboy, :request, :start],
          measurement: :count,
          description: "Request count for cowboy"
        ),

        counter(
          "cowboy.request.early_error.count",
          event_name: [:cowboy, :request, :early_error],
          measurement: :count,
          description: "Request count for cowboy early errors"
        ),

        counter(
          "cowboy.request.exception.count",
          event_name: [:cowboy, :request, :exception],
          measurement: :count,
          tags: [:exit_code],
          tag_values: &exit_code_from_metadata/1,
          description: "Request count for cowboy exceptions"
        ),

        distribution(
          "cowboy.request.duration.milliseconds",
          event_name: [:cowboy, :request, :stop],
          measurement: :duration,
          unit: @duration_unit,
          reporter_options: [buckets: @buckets],
          description: "Request duration for cowboy"
        ),
      ]
    end

    defp exit_code_from_metadata(opts) do
      %{exit_code: opts[:kind] || "Unknown"}
    end
  end
end
