if PrometheusTelemetry.Utils.app_loaded?(:finch) do
  defmodule PrometheusTelemetry.Metrics.Finch do
    import Telemetry.Metrics, only: [counter: 2, distribution: 2]

    @duration_unit {:native, :millisecond}
    @buckets PrometheusTelemetry.Config.default_millisecond_buckets()

    def metrics do
      request_metrics() ++ pool_metrics() ++ send_receive_metrics() ++ max_idle_time_metrics()
    end

    def request_metrics do
      [
        counter("finch.request_start.count",
          event_name: [:finch, :request, :start],
          measurement: :count,
          tags: [:name, :host, :port, :method],
          tag_values: &add_extra_metadata/1,
          description: "Finch request count"
        ),

        counter("finch.request_end.count",
          event_name: [:finch, :request, :stop],
          measurement: :count,
          tags: [:name, :host, :status, :port, :method],
          tag_values: fn metadata ->
            metadata
              |> add_extra_metadata
              |> add_status_metadata
          end,
          description: "Finch request count"
        ),

        distribution("finch.request.duration.milliseconds",
          event_name: [:finch, :request, :stop],
          measurement: :duration,
          description: "Finch request durations",
          tags: [:name, :host, :port, :method],
          tag_values: &add_extra_metadata/1,
          unit: @duration_unit,
          reporter_options: [buckets: @buckets]
        ),

        counter("finch.request_error.count",
          event_name: [:finch, :request, :exception],
          tags: [:name, :host, :port, :method, :reason, :kind],
          tag_values: &add_extra_metadata/1,
          measurement: :count,
          description: "Finch request error count"
        ),

        distribution("finch.request_error.duration.milliseconds",
          event_name: [:finch, :request, :exception],
          measurement: :duration,
          tags: [:reason, :kind, :host, :port, :method],
          tag_values: &add_extra_metadata/1,
          description: "Finch request error durations",
          unit: @duration_unit,
          reporter_options: [buckets: @buckets]
        )
      ]
    end

    def pool_metrics do
      [
        counter("finch.pool.request_connection.count",
          event_name: [:finch, :queue, :start],
          tags: [:host, :port, :method],
          tag_values: &add_extra_metadata/1,
          measurement: :count,
          description: "Finch count for attempting to checkout a connection from a pool"
        ),

        counter("finch.pool.checked_out_connection.count",
          event_name: [:finch, :queue, :stop],
          measurement: :count,
          tags: [:host, :port, :method],
          tag_values: &add_extra_metadata/1,
          description: "Finch count for attempting to checkout a connection from a pool"
        ),

        counter("finch.pool.error",
          event_name: [:finch, :queue, :exception],
          measurement: :count,
          tags: [:reason, :kind, :host, :port, :method],
          tag_values: &add_extra_metadata/1,
          description: "Finch count for pool errors"
        ),

        distribution("finch.pool.checked_out_connection.idle_time.milliseconds",
          event_name: [:finch, :queue, :stop],
          measurement: :idle_time,
          tags: [:host, :port, :method],
          tag_values: &add_extra_metadata/1,
          description: "Finch idle_time for since connection last initialized",
          unit: @duration_unit,
          reporter_options: [buckets: @buckets]
        ),

        distribution("finch.pool.checked_out_connection.duration.milliseconds",
          event_name: [:finch, :queue, :stop],
          measurement: :duration,
          tags: [:host, :port, :method],
          tag_values: &add_extra_metadata/1,
          description: "Finch duration for checking out a connection from pool",
          unit: @duration_unit,
          reporter_options: [buckets: @buckets]
        ),

        distribution("finch.pool.error.duration.milliseconds",
          event_name: [:finch, :queue, :exception],
          measurement: :duration,
          description: "Finch duration for before error occured",
          tags: [:reason, :kind, :host, :port, :method],
          tag_values: &add_extra_metadata/1,
          unit: @duration_unit,
          reporter_options: [buckets: @buckets]
        )
      ]
    end

    def send_receive_metrics do
      [
        counter("finch.request_send.count",
          event_name: [:finch, :send, :start],
          measurement: :count,
          tags: [:host, :port, :method],
          tag_values: &add_extra_metadata/1,
          measurement: :count,
          description: "Finch count for requests started"
        ),

        counter("finch.request_receive.count",
          event_name: [:finch, :recv, :start],
          tags: [:host, :port, :method],
          measurement: :count,
          tag_values: &add_extra_metadata/1,
          description: "Finch count for response receive starting"
        ),

        distribution("finch.send_end.duration.milliseconds",
          event_name: [:finch, :send, :stop],
          measurement: :duration,
          description: "Finch duration for how long request took to send",
          tags: [:error, :host, :port, :method],
          tag_values: fn metadata ->
            metadata
              |> add_extra_metadata
              |> add_error_metadata
          end,
          unit: @duration_unit,
          reporter_options: [buckets: @buckets]
        ),

        distribution("finch.request_end.duration.milliseconds",
          event_name: [:finch, :recv, :stop],
          measurement: :duration,
          description: "Finch duration for how long receiving the request took",
          tags: [:status, :error, :host, :port, :method],
          tag_values: fn metadata ->
            metadata
              |> add_extra_metadata
              |> add_error_metadata
          end,
          unit: @duration_unit,
          reporter_options: [buckets: @buckets]
        )
      ]
    end

    defp max_idle_time_metrics do
      [
        counter("finch.conn_max_idle_time_exceeded.count",
          event_name: [:finch, :conn_max_idle_time_exceeded],
          measurement: :count,
          tags: [:host, :port, :method],
          tag_values: &add_max_idle_time_metadata/1,
          description: "Finch count for Conn Max Idle Time Exceeded errors"
        ),

        counter("finch.pool_max_idle_time_exceeded.count",
          event_name: [:finch, :pool_max_idle_time_exceeded],
          measurement: :count,
          tags: [:host, :port, :method],
          tag_values: &add_max_idle_time_metadata/1,
          description: "Finch count for Pool Max Idle Time Exceeded errors"
        )
      ]
    end

    defp add_max_idle_time_metadata(%{request: %Finch.Request{host: host, port: port, method: method}} = metadata) do
      Map.merge(metadata, %{host: host, port: port, method: method})
    end

    defp add_max_idle_time_metadata(%{host: host, port: port, scheme: scheme}) do
      %{host: host, port: port, method: scheme}
    end

    defp add_max_idle_time_metadata(metadata) do
      metadata
    end

    defp add_error_metadata(%{error: _} = metadata), do: metadata
    defp add_error_metadata(metadata), do: Map.put(metadata, :error, "")

    defp add_extra_metadata(%{request: %Finch.Request{host: host, port: port, method: method}} = metadata) do
      Map.merge(metadata, %{host: host, port: port, method: method})
    end

    defp add_extra_metadata(%{host: _, port: _, scheme: _} = metadata) do
      Map.put(metadata, :method, "GET")
    end

    defp add_status_metadata(%{result: {:error, _}} = metadata) do
      Map.put(metadata, :status, 500)
    end

    defp add_status_metadata(%{result: {:ok, %Finch.Response{status: status}}} = metadata) do
      Map.put(metadata, :status, status)
    end

    defp add_status_metadata(metadata) do
      Map.put(metadata, :status, "Unknown")
    end
  end
end

