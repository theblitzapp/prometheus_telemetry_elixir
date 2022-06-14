defmodule PrometheusTelemetry.PeriodicMeasurements.ErlangVMTest do
  use ExUnit.Case

  alias PrometheusTelemetry.PeriodicMeasurements.ErlangVM

  @event_name [:erlang_vm_uptime]

  doctest ErlangVM

  describe "vm_wall_clock/0" do
    setup do: %{self: self()}

    test "writes value to telemetry", %{self: self, test: test} do
      PrometheusTelemetry.TestHelpers.start_telemetry_listener(self, test, @event_name)

      ErlangVM.vm_wall_clock()

      assert_receive {:telemetry_event, @event_name, %{uptime: _}, _metadata}
    end
  end

  describe "periodic_measurements/0" do
    test "returns expected list" do
      assert [{ErlangVM, :vm_wall_clock, []}] = ErlangVM.periodic_measurements()
    end
  end
end
