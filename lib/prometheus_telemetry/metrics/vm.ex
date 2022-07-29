defmodule PrometheusTelemetry.Metrics.VM do
  @moduledoc """
  These metrics give you some basic VM statistics from erlang, this includes:

    - `erlang.vm.memory`
    - `erlang.vm.run_queue.total`
    - `erlang.vm.run_queue.cpu`
    - `erlang.vm.run_queue.io`
  """

  import Telemetry.Metrics, only: [last_value: 2, sum: 2]

  def metrics do
    [
      last_value(
        "erlang.vm.memory",
        event_name: [:vm, :memory],
        measurement: :total,
        unit: {:byte, :kilobyte}
      ),
      
      last_value(
        "erlang.vm.memory.ets",
        event_name: [:vm, :memory],
        measurement: :ets
      ),

      last_value(
        "erlang.vm.run_queue.total",
        event_name: [:vm, :total_run_queue_lengths],
        measurement: :total
      ),

      last_value(
        "erlang.vm.run_queue.cpu",
        event_name: [:vm, :total_run_queue_lengths],
        measurement: :cpu
      ),

      last_value(
        "erlang.vm.run_queue.io",
        event_name: [:vm, :total_run_queue_lengths],
        measurement: :io
      ),

      sum(
        "erlang_vm_uptime",
        event_name: [:erlang_vm_uptime],
        measurement: :uptime,
        description: "The continuous uptime of the Erlang VM"
      ),
      
      last_value(
        "erlang.vm.system_counts.process_count",
        event_name: [:vm, :system_counts],
        measurement: :process_count
      ),
      
      last_value(
        "erlang.vm.system_counts.port_count",
        event_name: [:vm, :system_counts],
        measurement: :port_count
      ),
      
      last_value(
        "erlang.vm.system_counts.atom_count",
        event_name: [:vm, :system_counts],
        measurement: :atom_count
      )
    ]
  end
end
