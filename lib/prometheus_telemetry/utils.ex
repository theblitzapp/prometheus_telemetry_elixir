defmodule PrometheusTelemetry.Utils do
  @moduledoc false

  def app_loaded?(app_name) do
    ensure_application_loaded?(app_name) and
    Enum.any?(Application.loaded_applications(), fn {dep_name, _, _} -> dep_name === app_name end)
  end

  defp ensure_application_loaded?(app_name) do
    case Application.ensure_loaded(app_name) do
      :ok -> true
      _ -> false
    end
  end

  def title_case(atom) when is_atom(atom) do
    atom |> to_string |> title_case
  end

  def title_case(str) do
    str |> String.replace("_", " ") |> :string.titlecase
  end
end
