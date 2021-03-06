if PrometheusTelemetry.Utils.app_loaded?(:absinthe) do
  defmodule PrometheusTelemetry.Metrics.GraphQL.Request do
    @moduledoc false

    import Telemetry.Metrics, only: [counter: 2, distribution: 2]

    alias Absinthe.{Blueprint, Resolution}
    alias PrometheusTelemetry.Metrics.GraphQL.QueryName

    @buckets PrometheusTelemetry.Config.default_millisecond_buckets()
    @duration_unit {:native, :millisecond}

    @event_prefix [:absinthe]
    @execute_requests_name @event_prefix ++ [:execute, :operation, :start]
    @execute_duration_name @event_prefix ++ [:execute, :operation, :stop]
    @subscription_duration_name @event_prefix ++ [:subscription, :publish, :stop]
    @resolve_duration_name @event_prefix ++ [:resolve, :field, :stop]
    @batch_middleware_duration_name @event_prefix ++ [:middleware, :batch, :stop]

    @type counter_type :: :subscription | :query | :mutation
    @type histogram_type :: :query | :mutation

    def metrics do
      [
        counter(
          "graphql.requests.count",
          event_name: @execute_requests_name,
          tags: [:type, :name],
          tag_values: &parse_name_and_type/1,
          measurement: :count,
          description: "Execute count for (query/mutations)"
        ),

        distribution(
          "graphql.execute.duration.milliseconds",
          event_name: @execute_duration_name,
          tags: [:type, :name],
          tag_values: &extract_name_and_type/1,
          measurement: :duration,
          unit: @duration_unit,
          reporter_options: [buckets: @buckets],
          description: "Execute duration for (query/mutations)"
        ),

        distribution(
          "graphql.subscription.duration.milliseconds",
          event_name: @subscription_duration_name,
          tags: [:name],
          tag_values: &extract_name_and_type/1,
          measurement: :duration,
          unit: @duration_unit,
          reporter_options: [buckets: @buckets],
          description: "Subscription duration for (query/mutations)"
        ),

        distribution(
          "graphql.resolve.duration.milliseconds",
          event_name: @resolve_duration_name,
          measurement: :duration,
          description: "Resolve duration for (query/mutations)",
          measurement: :duration,
          unit: @duration_unit,
          reporter_options: [buckets: @buckets],
          tags: [:type, :name],
          tag_values: &extract_resolve_name_and_type/1,
          drop: &drop_resolve_subscriptions/1
        ),

        distribution(
          "graphql.middleware.batch.duration.milliseconds",
          event_name: @batch_middleware_duration_name,
          tags: [:module, :function],
          tag_values: &extract_batch_name/1,
          measurement: :duration,
          unit: @duration_unit,
          reporter_options: [buckets: @buckets],
          description: "Middleware duration for batching"
        )
      ]
    end

    defp parse_name_and_type(%{blueprint: blueprint}) do
      case QueryName.capture_operation(blueprint) do
        %{"type" => type, "name" => name} -> %{type: type, name: name}
        %{"type" => type, "query" => query} -> %{type: type, name: QueryName.capture_query_name(query)}
        %{"query" => query} -> %{type: :query, name: QueryName.capture_query_name(query)}
        _ -> %{type: "Unknown", name: "Unknown"}
      end
    end

    defp extract_name_and_type(%{blueprint: blueprint, options: options}) do
      case Blueprint.current_operation(blueprint) do
        %{type: type, name: nil} -> %{type: type, name: query_name(options)}
        %{type: type, name: name} -> %{type: type, name: name}
        _ -> %{type: "Unknown", name: "Unknown"}
      end
    end

    defp extract_resolve_name_and_type(metadata) do
      %{type: query_or_mutation(metadata), name: query_name(metadata)}
    end

    defp drop_resolve_subscriptions(metadata) do
      query_or_mutation(metadata) === "subscription"
    end

    defp extract_batch_name(%{batch_fun: batch_fun_tuple}) do
      [module, fnc_name | _] = Tuple.to_list(batch_fun_tuple)
      module_name =
        module
        |> to_string()
        |> String.replace("Elixir.", "")

      %{module: module_name, function: to_string(fnc_name)}
    end

    defp query_name(%{resolution: %Resolution{definition: %{name: name}}}) do
      name
    end

    defp query_name(opts) do
      if Keyword.has_key?(opts, :document) do
        QueryName.get_query_name(opts[:document])
      else
        "Unknown"
      end
    end

    defp query_or_mutation(%{
     resolution: %Resolution{definition: %{parent_type: %{identifier: identifier}}}
    }), do: identifier
  end
end
