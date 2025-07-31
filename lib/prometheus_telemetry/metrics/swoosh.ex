if match?({:module, _}, Code.ensure_compiled(Swoosh)) do
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

    require Logger

    import Telemetry.Metrics, only: [counter: 2, distribution: 2]

    @duration_unit {:native, :millisecond}
    @buckets PrometheusTelemetry.Config.default_millisecond_buckets()

    def metrics do
      [
        counter("swoosh.deliver.request_count",
          event_name: [:swoosh, :deliver, :start],
          measurement: :count,
          description: "Swoosh delivery delivery count",
          tags: [:mailer, :status, :from_address],
          tag_values: fn metadata ->
            metadata
            |> add_status_to_metadata
            |> serialize_metadata
          end
        ),
        distribution("swoosh.deliver.request.duration.milliseconds",
          event_name: [:swoosh, :deliver, :stop],
          measurement: :duration,
          description: "Swoosh delivery duration",
          tags: [:mailer, :from_address],
          tag_values: &serialize_metadata/1,
          unit: @duration_unit,
          reporter_options: [buckets: @buckets]
        ),
        counter("swoosh.deliver.exception_count",
          event_name: [:swoosh, :deliver, :exception],
          measurement: :count,
          description: "Swoosh delivery delivery exception count",
          tags: [:mailer, :error, :from_address],
          tag_values: &serialize_metadata/1
        ),
        counter("swoosh.deliver_many.request.count",
          event_name: [:swoosh, :deliver_many, :start],
          measurement: :count,
          description: "Swoosh delivery many count",
          tags: [:mailer, :from_address],
          tag_values: &serialize_metadata/1
        ),
        distribution("swoosh.deliver_many.request.duration.milliseconds",
          event_name: [:swoosh, :deliver_many, :stop],
          measurement: :duration,
          description: "Swoosh delivery many duration",
          tags: [:mailer, :from_address],
          tag_values: &serialize_metadata/1,
          unit: @duration_unit,
          reporter_options: [buckets: @buckets]
        )
      ]
    end

    defp serialize_metadata(metadata) do
      metadata
      |> stringify_mailer_metadata
      |> add_email_from_to_metadata
    end

    defp stringify_mailer_metadata(%{mailer: mailer_mod} = metadata) do
      %{metadata | mailer: inspect(mailer_mod)}
    end

    defp add_status_to_metadata(%{error: _} = metadata), do: Map.put(metadata, :status, "error")
    defp add_status_to_metadata(metadata), do: Map.put(metadata, :status, "success")

    defp add_email_from_to_metadata(%{email: %Swoosh.Email{from: {_, address}}} = metadata) do
      Map.put(metadata, :from_address, address)
    end

    defp add_email_from_to_metadata(%{email: %Swoosh.Email{from: address}} = metadata) do
      Map.put(metadata, :from_address, address)
    end

    defp add_email_from_to_metadata(metadata) do
      Map.put(metadata, :from_address, "Unknown")
    end
  end
end
