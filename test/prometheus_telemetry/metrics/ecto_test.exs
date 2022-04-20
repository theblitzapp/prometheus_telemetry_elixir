defmodule PrometheusTelemetry.Metrics.EctoTest do
  use ExUnit.Case, async: true
  alias PrometheusTelemetry.Metrics.Ecto

  describe "metrics/1" do
    test "able to create a list of metrics" do
      repos = [Repo, Repo.CMS]
      assert length(Ecto.metrics(repos)) === length(repos) * 4
    end

    test "able to reduce replica repo into one" do
      repos = [Repo, Repo.Replica1, Repo.Replica2, Repo.Replica3]
      # Should have 8 metrics
      # 4 for regular repo
      # 4 for replicas
      assert length(Ecto.metrics(repos)) === 16
    end
  end
end
