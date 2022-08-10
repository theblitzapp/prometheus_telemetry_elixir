defmodule PrometheusTelemetry.TestHelpers do
  @moduledoc """
    Provides helper methods for testing :telemetry events.

    Calling start_telemetry_listener/4 registers the event_handler/1 method which echoes the telemetry event
    back to the containing module.

    This allows the use of assert_receive/3 to confirm the event was fired.

    Example:

    @event_name [:my_counter]

    describe "my_event_executioner/0" do
      test "counter event is executed", %{self: self, test: test} do
        Telemetry.TestHelpers.start_telemetry_listener(self, test, @event_name)

        OUT.my_event_executioner()

        assert_receive({:telemetry_event, @event_name, %{<measurement_name>: _}, _metadata})
      end
    end
  """

  @spec start_telemetry_listener(module(), atom(), [atom()], map()) :: :ok | {:error, :already_exists}
  def start_telemetry_listener(send_dest, handler_id, event_name, config \\ %{}) do
    :telemetry.attach(
      handler_id,
      event_name,
      event_handler(send_dest),
      config
    )
  end

  @spec event_handler(module()) :: function()
  def event_handler(dest) do
    fn name, measurements, metadata, _config ->
      send(dest, {:telemetry_event, name, measurements, metadata})
    end
  end
end
