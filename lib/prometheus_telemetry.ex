defmodule PrometheusTelemetry do
  @definition [
    name: [
      type: :atom,
      default: :prometheus_telemetry,
      doc: "Name for the prometheus telemetry supervisor"
    ],

    exporter: [
      type: :keyword_list,
      default: [enabled?: false, opts: []],
      doc: "Exporter config",
      keys: [
        enabled?: [
          type: :boolean,
          default: false
        ],

        opts: [
          type: :keyword_list,
          default: [],
          doc: "Exporter options",
          keys: [
            port: [
              type: :integer,
              default: 4050,
              doc: "Port to start the exporter on"
            ],

            protocol: [
              type: {:in, [:http, :https]},
              default: :http
            ]
          ]
        ]
      ]
    ],

    metrics: [
      type: {:list, :any},
      doc: "Metrics to start and aggregate that will ultimately end up in the exporter"
    ],

    periodic_measurements: [
      type: {:list, :any},
      doc: "Periodic metrics to start and aggregate that will ultimately end up in the exporter"
    ]
  ]

  @external_resource "./README.md"

  @moduledoc """
  #{File.read!("./README.md")}"

  ### Supported Options
  #{NimbleOptions.docs(@definition)}
  """

  use Supervisor

  alias PrometheusTelemetry

  @poller_postfix "poller"
  @supervisor_postfix "prometheus_telemetry_supervisor"
  @watcher_postfix "metrics_watcher"

  def get_metrics_string(name) do
    get_supervisors_metrics_string([name])
  end

  def get_metrics_string do
    get_supervisors_metrics_string(list())
  end

  defp get_supervisors_metrics_string(supervisors) do
    supervisors
    |> Stream.flat_map(&list_prometheus_cores/1)
    |> Enum.map_join("\n", &TelemetryMetricsPrometheus.Core.scrape/1)
  end

  def list do
    # This could be better optimized via a registry
    Enum.filter(Process.registered(), &String.ends_with?(to_string(&1), @supervisor_postfix))
  end

  def list_prometheus_cores(supervisor) do
    supervisor
    |> Supervisor.which_children()
    |> Enum.reduce([], fn child, acc ->
      case prometheus_core_name(child) do
        nil -> acc
        metrics_core_name when is_list(metrics_core_name) -> metrics_core_name ++ acc
        metrics_core_name -> [metrics_core_name | acc]
      end
    end)
  end

  def poller_postfix, do: @poller_postfix

  defp prometheus_core_name(
         {metrics_core_name, _, _, [TelemetryMetricsPrometheus.Core.Registry]}
       ),
       do: metrics_core_name

  defp prometheus_core_name(_), do: nil

  @spec start_link(Keyword.t) :: {:ok, pid} | :ignore | {:error,  {:shutdown, term()} | term()}
  def start_link(opts \\ []) do
    opts = NimbleOptions.validate!(opts, @definition)

    exporter_config = opts[:exporter]
    params = %{
      name: :"#{opts[:name]}_#{Enum.random(1..100_000_000_000)}",
      enable_exporter?: exporter_config[:enabled?],
      exporter_opts: exporter_config[:opts],
      metrics: opts[:metrics],
      pollers: opts[:periodic_measurements]
    }

    opts = Keyword.update!(opts, :name, &:"#{&1}_#{@supervisor_postfix}")

    if is_nil(params.pollers) and is_nil(params.metrics) and not params.enable_exporter? do
      raise "Must provide at least one of opts[:pollers] or opts[:metrics] to PrometheusTelemetry or enable the exporter"
    end

    with {:error, {:already_started, _}} <- Supervisor.start_link(PrometheusTelemetry, params, opts) do
      opts = Keyword.update!(opts, :name, &:"#{&1}_#{Enum.random(1..100_000_000_000)}_#{@supervisor_postfix}")

      Supervisor.start_link(PrometheusTelemetry, params, opts)
    end
  end

  @impl true
  def init(
        %{
          name: name,
          pollers: pollers,
          metrics: metrics
        } = params
      ) do
    children = maybe_create_children(name, metrics, pollers) ++ maybe_create_exporter_child(params)

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp maybe_create_children(name, metrics, pollers) do
    maybe_create_poller_child(name, pollers) ++ maybe_create_metrics_child(name, metrics)
  end

  defp maybe_create_exporter_child(%{
         enable_exporter?: enabled?,
         exporter_opts: opts
       })
       when enabled? === true,
       do: create_exporter_child(opts)

  defp maybe_create_exporter_child(_), do: []

  defp create_exporter_child(opts) do
    # need to do a check if exporter child is up
    [PrometheusTelemetry.MetricsExporterPlug.child_spec(opts)]
  end

  defp maybe_create_metrics_child(name, metrics) when is_list(metrics) do
    [
      {TelemetryMetricsPrometheus.Core,
       metrics: List.flatten(metrics), name: :"#{name}_#{@watcher_postfix}"}
    ]
  end

  defp maybe_create_metrics_child(_, _) do
    []
  end

  defp maybe_create_poller_child(name, [_ | _] = pollers) do
    [
      {
        :telemetry_poller,
        measurements: List.flatten(pollers),
        period: PrometheusTelemetry.Config.measurement_poll_period(),
        name: :"#{name}_#{@poller_postfix}"
      }
      ]
  end

  defp maybe_create_poller_child(_, _), do: []
end
