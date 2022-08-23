defmodule PrometheusTelemetry.Config do
  @moduledoc false

  @app :prometheus_telemetry

  @default_microsecond_buckets [50_000, 100_000, 250_000, 500_000, 750_000]
  @default_millisecond_buckets [100, 300, 500, 1000, 2000, 5000, 10_000]
  @default_poll_period :timer.seconds(10)
  @default_ecto_max_query_length 150


  def default_microsecond_buckets do
    Application.get_env(@app, :default_microsecond_buckets) || @default_microsecond_buckets
  end

  def default_millisecond_buckets do
    Application.get_env(@app, :default_millisecond_buckets) || @default_millisecond_buckets
  end

  def measurement_poll_period do
    Application.get_env(@app, :measurement_poll_period) || @default_poll_period
  end

  def ecto_known_query_module do
    Application.get_env(@app, :ecto_known_query_module)
  end

  def ecto_max_query_length do
    Application.get_env(@app, :ecto_max_query_length) || @default_ecto_max_query_length
  end
end
