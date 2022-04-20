defmodule PrometheusTelemetry.RouterTest do
  use ExUnit.Case, async: true

  @test_port 4050
  @finch_name RouterTest.Finch

  setup do
    assert {:ok, _} = Finch.start_link(name: @finch_name)
    :ok
  end

  describe "&fetch_metrics/0" do
    test "fetches and renders metric data" do
      assert {:ok, %Finch.Response{body: body}} =
               :get
               |> Finch.build("http://localhost:#{@test_port}")
               |> Finch.request(@finch_name)

      assert String.length(body) > 1
    end
  end
end
