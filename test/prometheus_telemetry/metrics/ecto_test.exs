defmodule PrometheusTelemetry.Metrics.EctoTest do
  use ExUnit.Case, async: true
  alias PrometheusTelemetry.Metrics.Ecto

  describe "metrics/1" do
    setup _ do
      Module.create(MyEctoApp.Repo, nil, Macro.Env.location(__ENV__))

      :ok
    end

    test "rejects module as prefix" do
      assert_raise ArgumentError, ~r/^expects an atom or a string prefix/, fn ->
        Ecto.metrics(MyEctoApp.Repo)
      end

      assert_raise ArgumentError, ~r/^expects an atom or a string prefix/, fn ->
        Ecto.metrics([MyEctoApp.Repo, MyEctoApp.Repo.Replica1])
      end
    end
  end

  describe "metrics_for_repos/1" do
    test "able to create a list of metrics" do
      metrics_length = length(Ecto.metrics(:asdf))

      repos = [Repo, Repo.CMS]
      assert length(Ecto.metrics_for_repos(repos)) === length(repos) * metrics_length
    end

    test "able to reduce replica repo into one" do
      metrics_length = length(Ecto.metrics(:asdf))

      secondary_replicas = [
        Repo.Replica2,
        Repo.LeaguePlayer.Replica2
      ]

      repos = [
        Repo,
        Repo.Replica1,
        Repo.LeaguePlayer.Replica1
      ]

      metrics = Ecto.metrics_for_repos(repos ++ secondary_replicas)

      # Should have 8 metrics
      # 4 for regular repo
      # 4 for replicas
      assert length(metrics) === length(repos) * metrics_length
    end
  end

end
