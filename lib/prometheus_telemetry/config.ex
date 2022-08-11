defmodule PrometheusTelemetry.Config do
  @moduledoc false

  @app :prometheus_telemetry

  @default_microsecond_buckets [50_000, 100_000, 250_000, 500_000, 750_000, 1_000_000]
  @default_millisecond_buckets [100, 300, 500, 1000, 2000, 5000, 10_000]
  @default_poll_period :timer.seconds(10)


  def default_microsecond_buckets do
    Application.get_env(@app, :default_microsecond_buckets) || @default_microsecond_buckets
  end

  def default_millisecond_buckets do
    Application.get_env(@app, :default_millisecond_buckets) || @default_millisecond_buckets
  end

  def measurement_poll_period do
    Application.get_env(@app, :measurement_poll_period) || @default_poll_period
  end
end
