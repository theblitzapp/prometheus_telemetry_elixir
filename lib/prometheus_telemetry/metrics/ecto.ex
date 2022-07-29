if PrometheusTelemetry.Utils.app_loaded?(:ecto) do
  defmodule PrometheusTelemetry.Metrics.Ecto do
    @moduledoc """
    These metrics give you metrics around phoenix requests

      - `ecto.query.total_time`
      - `ecto.query.decode_time`
      - `ecto.query.query_time`
      - `ecto.query.idle_time`
    """


    import Telemetry.Metrics, only: [distribution: 2]

    alias PrometheusTelemetry.Config

    @microsecond_buckets Config.default_microsecond_buckets()
    @microsecond_unit {:native, :microsecond}

    @millisecond_unit {:native, :millisecond}
    @millisecond_buckets Config.default_millisecond_buckets()

    def metrics(
      repo_list,
      default_opts \\ [
        millisecond_buckets: @millisecond_buckets,
        microsecond_buckets: @microsecond_buckets
    ])

    def metrics(repo_list, default_opts) when is_list(repo_list) do
      Enum.flat_map(repo_list, fn repo ->
        repo
          |> change_pg_module_to_string()
          |> metrics(default_opts)
      end)
    end

    def metrics(repo_str, default_opts) do
      event_name = repo_str |> change_pg_module_to_string |> create_event_name

      [
        distribution(
          "ecto.query.total_time",
          event_name: event_name,
          measurement: :total_time,
          description: "Gets total time spent on query",
          tags: [:repo, :query, :source, :result],
          tag_values: &format_proper_tag_values/1,
          unit: @microsecond_unit,
          reporter_options: [buckets: default_opts[:microsecond_buckets]]
        ),

        distribution(
          "ecto.query.decode_time",
          event_name: event_name,
          measurement: :decode_time,
          description: "Total time spent decoding query",
          tags: [:repo, :query, :source, :result],
          tag_values: &format_proper_tag_values/1,
          unit: @millisecond_unit,
          reporter_options: [buckets: default_opts[:millisecond_buckets]]
        ),

        distribution(
          "ecto.query.query_time",
          event_name: event_name,
          measurement: :query_time,
          description: "Total time spent querying",
          tags: [:repo, :query, :source, :result],
          tag_values: &format_proper_tag_values/1,
          unit: @millisecond_unit,
          reporter_options: [buckets: default_opts[:millisecond_buckets]]
        ),

        distribution(
          "ecto.query.idle_time",
          event_name: event_name,
          measurement: :idle_time,
          description: "Total time spent idling",
          tags: [:repo, :query, :source],
          unit: @millisecond_unit,
          reporter_options: [buckets: default_opts[:millisecond_buckets]]
        )
      ]
    end

    defp create_event_name(repo_string) do
      repo_string
        |> String.split(".")
        |> Enum.map(fn prefix -> String.to_atom(prefix) end)
        |> Kernel.++([:query])
    end

    defp change_pg_module_to_string(repo) when is_binary(repo) do
      repo
    end

    defp change_pg_module_to_string(repo) when is_atom(repo) do
      names = repo
        |> inspect()
        |> String.split(".")

      names
        |> Stream.map(fn name ->
          Macro.underscore(name)
        end)
        |> Enum.join(".")
    end

    defp format_proper_tag_values(%{result: result} = metadata) do
      {result_status, _} = result

      Map.put(metadata, :result, to_string(result_status))
    end
  end
end
