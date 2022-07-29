if PrometheusTelemetry.Utils.app_loaded?(:absinthe) do
  defmodule PrometheusTelemetry.Metrics.GraphQL.Complexity do
    @moduledoc false

    import Telemetry.Metrics, only: [distribution: 2]

    @event_prefix [:graphql]
    @complexity_name @event_prefix ++ [:complexity, :score]
    @buckets PrometheusTelemetry.Config.default_millisecond_buckets()

    def metrics do
      [
        distribution(
          "graphql.complexity.score",
          event_name: @complexity_name,
          measurement: :score,
          unit: {:native, :millisecond},
          description: "Gets the root complexity score for a GraphQL query",
          reporter_options: [buckets: @buckets],
          tags: [:query]
        )
      ]
    end

    def observe_complexity(query, score) do
      :telemetry.execute(
        @complexity_name,
        %{score: score},
        %{query: query}
      )
    end
  end
end
