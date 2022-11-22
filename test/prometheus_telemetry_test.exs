defmodule PrometheusTelemetryTest do
  use ExUnit.Case, async: true

  import Telemetry.Metrics, only: [counter: 2]

  @event_name_a [:some_event, :name]
  @event_name_b [:some_event, :name, :secondary]

  setup_all do
    key = generate_key()
    name = String.to_atom(key)

    {:ok, pid} =
      PrometheusTelemetry.start_link(
        name: name,
        metrics: metrics(key)
      )

    %{pid: pid, key: key, name: name}
  end

  describe "&start_link/1" do
    test "can start multiple metrics under a supervisor", %{key: key, pid: pid, name: name} do
      assert {:ok, _pid} =
               PrometheusTelemetry.start_link(
                 name: name,
                 metrics: new_metrics(key)
               )
    end

    test "raise error if metrics and periodic_measurements is nil" do
      assert_raise NimbleOptions.ValidationError, fn ->
        PrometheusTelemetry.start_link(
          periodic_measurements: nil,
          metrics: nil
        )
      end
    end

    test "can have multiple supervisors under separate names to group metrics", %{pid: pid} do
      key = generate_key()

      assert {:ok, new_pid} =
               PrometheusTelemetry.start_link(
                 name: String.to_atom(key),
                 metrics: metrics(key)
               )

      assert new_pid !== pid
    end

    test "starts telemetry_poller as a child" do
      key = generate_key()

      assert {:ok, _new_pid} = PrometheusTelemetry.start_link(
        name: String.to_atom(key),
        periodic_measurements: periodic_measurements(key)
      )

        [actual_name | _] = Enum.filter(Process.registered(), &String.ends_with?(to_string(&1), "poller"))
        actual_name = Atom.to_string(actual_name)

        assert String.starts_with?(actual_name, key)
        assert String.ends_with?(actual_name, PrometheusTelemetry.poller_postfix())
    end
  end

  describe "&list/0" do
    test "lists all supervisors", %{key: key} do
      new_key = generate_key()

      assert {:ok, _new_pid} =
               PrometheusTelemetry.start_link(
                 name: String.to_atom(new_key),
                 metrics: metrics(new_key)
               )

      supervisor_length =
        PrometheusTelemetry.list()
        |> Enum.filter(fn supervisor_name ->
          string_name = Atom.to_string(supervisor_name)

          string_name =~ key or string_name =~ new_key
        end)
        |> length()

      assert supervisor_length === 2
    end
  end

  describe "&list_prometheus_cores/1" do
    test "lists all the metric cores from a supervisor", %{pid: pid} do
      assert [prometheus_core | _] = PrometheusTelemetry.list_prometheus_cores(pid)

      assert prometheus_core |> TelemetryMetricsPrometheus.Core.scrape() |> is_binary()
    end
  end

  defp metrics(key) do
    [
      counter("#{key}.some_thing.test",
        event_name: @event_name_a,
        measurement: :count,
        description: "HELLO"
      )
    ]
  end

  defp periodic_measurements(_key) do
    [
      {
        PrometheusTelemetryTest,
        :measurement_method,
        []
      }
    ]
  end

  defp new_metrics(key) do
    [
      counter("#{key}.some_thing.test.version_2",
        event_name: @event_name_b,
        measurement: :count,
        description: "HELLO22",
        tag: [:second_item]
      )
    ]
  end

  defp generate_key, do: String.replace(Faker.Pokemon.name(), ~r/[^\d\w]/, "")
end
