defmodule PrometheusTelemetry.Router do
  @moduledoc false

  use Plug.Router

  import Plug.Conn, only: [put_resp_content_type: 2, send_resp: 3]

  plug :match
  plug Plug.Telemetry, event_prefix: [:prometheus_metrics, :plug]
  plug :dispatch

  get "/metrics" do
    metrics = PrometheusTelemetry.get_metrics_string()

    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, metrics)
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
