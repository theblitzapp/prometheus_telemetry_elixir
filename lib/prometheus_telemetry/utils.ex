defmodule PrometheusTelemetry.Utils do
  @moduledoc false

  def title_case(atom) when is_atom(atom) do
    atom |> to_string |> title_case
  end

  def title_case(str) do
    str |> String.replace("_", " ") |> :string.titlecase()
  end
end
