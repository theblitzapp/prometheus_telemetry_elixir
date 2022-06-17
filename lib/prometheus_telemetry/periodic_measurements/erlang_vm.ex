defmodule PrometheusTelemetry.PeriodicMeasurements.ErlangVM do
  @moduledoc """
    Uses the :erlang.statistics method to check the uptime of the Erlang VM and emits a :telemetry event
    with the most recent reading.
  """

  @event_name [:erlang_vm_uptime]

  @spec vm_wall_clock() :: :ok
  def vm_wall_clock() do
    {_, uptime} = :erlang.statistics(:wall_clock)
    :telemetry.execute(@event_name, %{uptime: uptime})
  end

  @spec periodic_measurements() :: [{module(), atom(), keyword()}]
  def periodic_measurements(), do: [{__MODULE__, :vm_wall_clock, []}]
end
