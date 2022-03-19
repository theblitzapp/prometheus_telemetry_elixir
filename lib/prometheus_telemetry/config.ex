defmodule PrometheusTelemetry.Config do
  @moduledoc false

  @app :prometheus_telemetry

  @default_microsecond_buckets [1_000, 3_000, 5_000, 10_000, 20_000, 50_000, 100_000]
  @default_millisecond_buckets [100, 300, 500, 1000, 2000, 5000, 10_000]


  def default_microsecond_buckets do
    Application.get_env(@app, :default_microsecond_buckets) || @default_microsecond_buckets
  end

  def default_millisecond_buckets do
    Application.get_env(@app, :default_millisecond_buckets) || @default_millisecond_buckets
  end
end
