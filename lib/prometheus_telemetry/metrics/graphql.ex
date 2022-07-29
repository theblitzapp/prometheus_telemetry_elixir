if PrometheusTelemetry.Utils.app_loaded?(:absinthe) do
  defmodule PrometheusTelemetry.Metrics.GraphQL do
    @moduledoc """
    These metrics give you metrics around Absinthes GraphQL requests

      - `graphql.execute.duration.milliseconds`
      - `graphql.subscription.duration.milliseconds`
      - `graphql.resolve.duration.milliseconds`
      - `graphql.middleware.batch.duration.milliseconds`
    """

    alias PrometheusTelemetry.Metrics.GraphQL.{Complexity, Request}

    def metrics do
      [
        Request.metrics(),
        Complexity.metrics()
      ]
    end

    defdelegate observe_complexity(query, score), to: Complexity
  end
end
