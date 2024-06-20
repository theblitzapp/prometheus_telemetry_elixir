defmodule PrometheusTelemetry.Utils do
  @moduledoc false

  def app_loaded?(app_name) do
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
