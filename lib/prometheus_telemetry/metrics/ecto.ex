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

    @millisecond_unit {:native, :millisecond}
    @millisecond_buckets PrometheusTelemetry.Config.default_millisecond_buckets()
    @max_query_length PrometheusTelemetry.Config.ecto_max_query_length()

    @replica_regex "(r|R)eplica"

    def metrics_for_repos(repo_list) when is_list(repo_list) do
      repo_list
        |> remove_duplicate_replicas
        |> change_pg_module_to_string
        |> Enum.flat_map(&metrics/1)
    end

    def metrics_for_repo(repo) do
      repo
        |> change_pg_module_to_string
        |> metrics
    end

    def metrics(prefixes) when is_list(prefixes) do
      Enum.flat_map(prefixes, &metrics/1)
    end

    def metrics(prefix) do
      event_name = create_event_name(prefix)

      [
        distribution(
          "ecto.query.total_time.milliseconds",
          event_name: event_name,
          measurement: :total_time,
          description: "Gets total time spent on query",
          unit: @millisecond_unit,
          reporter_options: [buckets: @millisecond_buckets],
          tags: [:repo, :query, :source, :result],
          tag_values: &format_proper_tag_values/1
        ),

        distribution(
          "ecto.query.decode_time.milliseconds",
          event_name: event_name,
          measurement: :decode_time,
          description: "Total time spent decoding query",
          unit: @millisecond_unit,
          reporter_options: [buckets: @millisecond_buckets],
          tags: [:repo, :query, :source, :result],
          tag_values: &format_proper_tag_values/1
        ),

        distribution(
          "ecto.query.queue_time.milliseconds",
          event_name: event_name,
          measurement: :queue_time,
          description: "Total time spent querying",
          unit: @millisecond_unit,
          reporter_options: [buckets: @millisecond_buckets],
          tags: [:repo, :query, :source, :result],
          tag_values: &format_proper_tag_values/1
        ),

        distribution(
          "ecto.query.query_time.milliseconds",
          event_name: event_name,
          measurement: :query_time,
          description: "Total time spent querying",
          unit: @millisecond_unit,
          reporter_options: [buckets: @millisecond_buckets],
          tags: [:repo, :query, :source, :result],
          tag_values: &format_proper_tag_values/1
        ),

        distribution(
          "ecto.query.idle_time.milliseconds",
          event_name: event_name,
          measurement: :idle_time,
          description: "Total time spent idling",
          unit: @millisecond_unit,
          reporter_options: [buckets: @millisecond_buckets],
          tags: [:repo, :query, :source, :result],
          tag_values: &format_proper_tag_values/1
        )
      ]
    end

    defp remove_duplicate_replicas(repo_list) do
      Enum.reduce(repo_list, [], fn repo, acc ->
        if inspect(repo) =~ ~r/#{@replica_regex}/ and replica_version_exists?(acc, repo) do
          acc
        else
          [repo | acc]
        end
      end)
    end

    defp replica_version_exists?(repo_list, repo) do
      replica_root_repo =
        repo
        |> Module.split()
        |> Enum.drop(-1)
        |> Enum.join(".")

      Enum.any?(repo_list, &(inspect(&1) =~ ~r/#{replica_root_repo}\.#{@replica_regex}/))
    end

    defp create_event_name(prefix) when is_atom(prefix) do
      [prefix, :query]
    end

    defp create_event_name(repo_string) do
      repo_string
      |> String.split(".")
      |> Enum.map(fn prefix -> String.to_atom(prefix) end)
      |> Kernel.++([:query])
    end

    defp change_pg_module_to_string(repos) when is_list(repos) do
      Enum.map(repos, &change_pg_module_to_string/1)
    end

    defp change_pg_module_to_string(repo) do
      repo
      |> inspect
      |> String.split(".")
      |> Enum.map_join(".", &Macro.underscore/1)
    end

    defp format_proper_tag_values(%{result: _result} = metadata) do
      {result_status, _} = metadata[:result]

      query =
        case Keyword.get(metadata[:options], :label) do
          nil ->
            maybe_shorten_query(metadata)

          label ->
            label
        end

      metadata
      |> Map.update!(:repo, &inspect/1)
      |> Map.merge(%{
        result: to_string(result_status),
        query: clamp_query_size(query)
      })
    end

    defp clamp_query_size(query) do
      if String.length(query) > @max_query_length do
        "#{String.slice(query, 1..@max_query_length)}..."
      else
        query
      end
    end

    @spec maybe_shorten_query(map) :: String.t()
    defp maybe_shorten_query(%{query: original_query} = _metadata) do
      known_query_module = PrometheusTelemetry.Config.ecto_known_query_module()

      if known_query_module and function_exported?(known_query_module, :shorten, 1) do
        case known_query_module.shorten(original_query) do
          {:ok, shortened_query} -> shortened_query
          {:error, _} -> original_query
        end
      else
        original_query
      end
    end

    defp maybe_shorten_query(metadata), do: metadata
  end
end
