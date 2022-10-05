defmodule Mix.Tasks.PrometheusTelemetry.Gen.Metrics do
  @shortdoc "Generates Metrics modules"
  @moduledoc """
  This can be used to generate metrics modules

  The format used is
  ```elixir
  <metric_type>:<metric_name>:<event_name>:<measurement_unit>:tags:<tag_name>:<tag_name>
  ```

  ### Example
  ```bash
  $ mix prometheus_telemetry.gen.metrics MyApp.Metrics.Type counter:event.name.measurement.count:event.name.count:count:tags:profile:region
  ```
  """

  use Mix.Task

  def run([]) do
    Mix.raise("Must supply arguments to prometheus_telemetry.gen.metrics")
  end

  def run([metrics_module | measurements]) do

    measurements
      |> Enum.map(&(&1 |> String.split(":") |> parse_measurements))
      |> build_metrics_module_from_measurements(metrics_module)
      |> write_metrics_file(metrics_module)
  end

  defp parse_measurements(["counter", metric_name, event_name, measurement | tags]) do
    [
      type: :counter,
      metric_name: metric_name,
      event_name: parse_event_name(event_name),
      event_function: parse_function_name(event_name, measurement),
      measurement: String.to_atom(measurement),
      tags: parse_tags(tags)
    ]
  end

  defp parse_measurements(["distribution", "milliseconds", metric_name, event_name, measurement | tags]) do
    [
      type: :distribution,
      metric_name: metric_name,
      event_name: parse_event_name(event_name),
      event_function: parse_function_name(event_name, measurement),
      measurement: String.to_atom(measurement),
      unit: :milliseconds, tags: parse_tags(tags)
    ]
  end

  defp parse_measurements(["distribution", "microseconds", metric_name, event_name, measurement | tags]) do
    [
      type: :distribution,
      metric_name: metric_name,
      event_name: parse_event_name(event_name),
      event_function: parse_function_name(event_name, measurement),
      measurement: String.to_atom(measurement),
      unit: :microseconds, tags: parse_tags(tags)
    ]
  end

  defp parse_measurements(["distribution", "seconds", metric_name, event_name, measurement | tags]) do
    [
      type: :distribution,
      metric_name: metric_name,
      event_name: parse_event_name(event_name),
      event_function: parse_function_name(event_name, measurement),
      measurement: String.to_atom(measurement),
      tags: parse_tags(tags)
    ]
  end

  defp parse_measurements(["distribution", metric_name, event_name, measurement | tags]) do
    [
      type: :distribution,
      metric_name: metric_name,
      event_name: parse_event_name(event_name),
      event_function: parse_function_name(event_name, measurement),
      measurement: String.to_atom(measurement),
      unit: :milliseconds, tags: parse_tags(tags)
    ]
  end

  defp parse_measurements(["last_value", metric_name, event_name, measurement | tags]) do
    [
      type: :last_value,
      metric_name: metric_name,
      event_name: parse_event_name(event_name),
      event_function: parse_function_name(event_name, measurement),
      measurement: String.to_atom(measurement),
      tags: parse_tags(tags)
    ]
  end

  defp parse_measurements(["sum", metric_name, event_name, measurement | tags]) do
    [
      type: :sum,
      metric_name: metric_name,
      event_name: parse_event_name(event_name),
      event_function: parse_function_name(event_name, measurement),
      measurement: String.to_atom(measurement),
      tags: parse_tags(tags)
    ]
  end

  defp parse_tags(["tags" | tags]) when tags !== [] do
    Enum.map(tags, &String.to_atom/1)
  end

  defp parse_tags(_) do
    []
  end

  defp parse_event_name(event_name) do
    event_name |> String.split(".") |> Enum.map(&String.to_atom/1)
  end

  defp parse_function_name(event_name, measurement) do
    event_name
      |> String.replace(".", "_")
      |> String.trim_trailing("_#{measurement}")
      |> String.trim_trailing(measurement)
  end

  defp build_metrics_module_from_measurements(measurements, metrics_module) do
    :prometheus_telemetry
      |> :code.priv_dir
      |> Path.join("metric_template.ex.eex")
      |> EEx.eval_file(
        assigns: %{
          metrics: measurements,
          module_name: metrics_module,
          metrics_imports: measurement_metrics_imports(measurements)
        }
      )
      |> Code.format_string!
  end

  defp measurement_metrics_imports(measurements) do
    measurements
      |> Enum.group_by(&(&1[:type]))
      |> Map.keys
      |> Enum.map(fn type -> {type, 2} end)
  end

  defp write_metrics_file(metrics_file_contents, metrics_module) do
    file_path = module_file_path(metrics_module)

    Mix.Generator.create_file(file_path, metrics_file_contents)
  end

  defp module_file_path(metrics_module) do
    metrics_path = metrics_module
      |> String.split(".")
      |> Enum.map(&Macro.underscore/1)
      |> then(&List.update_at(&1, length(&1) - 1, fn file_name -> "#{file_name}.ex" end))

    Path.join(["lib" | metrics_path])
  end
end
