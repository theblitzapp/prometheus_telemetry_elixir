if PrometheusTelemetry.Utils.app_loaded?(:phoenix) do
  defmodule PrometheusTelemetry.Metrics.Phoenix do
    @moduledoc """
    These metrics give you metrics around phoenix requests

      - `http_request.duration.microseconds`
      - `phoenix.endpoint_call.duration.microseconds`
      - `phoenix.controller_call.duration.microseconds`
      - `phoenix.controller_error_rendered.duration.microseconds`
      - `phoenix.channel_join.duration.microseconds_bucket`
      - `phoenix.channel_receive.duration.microseconds`
    """


    import Telemetry.Metrics, only: [distribution: 2]

    @duration_unit {:native, :microsecond}
    @buckets PrometheusTelemetry.Config.default_microsecond_buckets()

    def metrics do
      [
        distribution("http_request.duration.microseconds",
          event_name: [:phoenix, :endpoint, :stop],
          measurement: :duration,
          description: "HTTP Request duration",
          tags: [:status_class, :method, :host, :scheme],
          tag_values: &http_request_metadata/1,
          unit: @duration_unit,
          reporter_options: [buckets: @buckets]
        ),

        distribution("phoenix.endpoint_call.duration.microseconds",
          event_name: [:phoenix, :endpoint, :stop],
          measurement: :duration,
          description: "Phoenix endpoint request time (inc middleware)",
          tags: [:action, :controller, :status],
          keep: &has_action?/1,
          tag_values: &controller_metadata/1,
          unit: @duration_unit,
          reporter_options: [buckets: @buckets]
        ),

        distribution("phoenix.controller_call.duration.microseconds",
          event_name: [:phoenix, :router_dispatch, :stop],
          measurement: :duration,
          description: "Phoenix router request time",
          tags: [:action, :controller, :status],
          keep: &has_action?/1,
          tag_values: &controller_metadata/1,
          unit: @duration_unit,
          reporter_options: [buckets: @buckets]
        ),

        distribution("phoenix.controller_error_rendered.duration.microseconds",
          event_name: [:phoenix, :error_rendered],
          measurement: :duration,
          description: "Phoenix controller error render time",
          tags: [:action, :controller, :status],
          keep: &has_action?/1,
          tag_values: &controller_metadata/1,
          unit: @duration_unit,
          reporter_options: [buckets: @buckets]
        ),

        distribution("phoenix.channel_join.duration.microseconds_bucket",
          event_name: [:phoenix, :router_dispatch],
          measurement: :duration,
          description: "Phoenix router request time",
          tags: [:channel, :topic, :transport],
          tag_values: &socket_metadata/1,
          unit: @duration_unit,
          reporter_options: [buckets: @buckets]
        ),

        distribution("phoenix.channel_receive.duration.microseconds",
          event_name: [:phoenix, :channel_handled_in],
          measurement: :duration,
          description: "Phoenix router request time",
          tags: [:channel, :topic, :event, :transport],
          tag_values: &socket_metadata/1,
          unit: @duration_unit,
          reporter_options: [buckets: @buckets]
        )
      ]
    end

    defp has_action?(%{conn: %{private: %{phoenix_action: action}}}) when not is_nil(action) do
      true
    end

    defp has_action?(_), do: false

    defp controller_metadata(%{
      conn: %{
        status: status,
        private: private
      }
    }) do
      action = Map.get(private, :phoenix_action, "Unknown")
      controller = private |> Map.get(:phoenix_controller, "Unknown") |> module_name_to_string

      %{action: action, controller: controller, status: status}
    end

    defp socket_metadata(%{socket: socket} = metadata) do
      channel = socket |> Map.get(:channel, "Unknown") |> module_name_to_string
      transport = Map.get(socket, :transport, "Unknown")
      topic = Map.get(socket, :topic, "Unknown")

      %{channel: channel, topic: topic, transport: transport, event: metadata[:event]}
    end

    defp module_name_to_string(module) when is_binary(module) do
      module
    end

    defp module_name_to_string(module) do
      module
      |> to_string
      |> String.replace("Elixir.", "")
    end

    defp http_request_metadata(%{
           conn: %{host: host, method: method, scheme: scheme, status: status}
         }) do
      %{status_class: status_class(status), method: method, host: host, scheme: scheme}
    end

    defp status_class(code) when code <= 100 or code >= 600 do
      "unknown"
    end

    defp status_class(code) when code < 200 do
      "informational"
    end

    defp status_class(code) when code < 300 do
      "success"
    end

    defp status_class(code) when code < 400 do
      "redirection"
    end

    defp status_class(code) when code < 500 do
      "client-error"
    end

    defp status_class(code) when code < 600 do
      "server-error"
    end

    defp status_class(code) do
      raise "Status code for phoenix_metric not an integer #{inspect(code)}"
    end
  end
end
