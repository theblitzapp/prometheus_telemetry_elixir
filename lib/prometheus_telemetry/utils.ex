defmodule PrometheusTelemetry.Utils do
  def app_loaded?(app_name) do
    Enum.any?(Application.loaded_applications(), fn {dep_name, _, _} -> dep_name === app_name end)
  end
end
