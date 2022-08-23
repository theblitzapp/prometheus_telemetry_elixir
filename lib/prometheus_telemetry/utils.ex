defmodule PrometheusTelemetry.Utils do
  @moduledoc false

  def app_loaded?(app_name) do
    Enum.any?(Application.loaded_applications(), fn {dep_name, _, _} -> dep_name === app_name end)
  end

  def title_case(atom) when is_atom(atom) do
    atom |> to_string |> title_case
  end

  def title_case(str) do
    str |> String.replace("_", " ") |> :string.titlecase
  end
end
