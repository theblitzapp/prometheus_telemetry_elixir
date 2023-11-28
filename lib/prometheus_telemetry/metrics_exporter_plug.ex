defmodule PrometheusTelemetry.MetricsExporterPlug do
  @moduledoc """
  This is the exporter for prometheus that sets up metrics to be scraped

  It uses /metrics as a route and is setup on port 4050 by default
  """

  def child_spec(opts) do
    Plug.Cowboy.child_spec(
      scheme: opts[:protocol],
      plug: PrometheusTelemetry.Router,
      options: [ip: opts[:ip], port: opts[:port]]
    )
  end
end
