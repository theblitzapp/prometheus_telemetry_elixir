if Enum.any?(Application.loaded_applications(), fn {dep_name, _, _} -> dep_name === :absinthe end) do
  defmodule PrometheusTelemetry.Metrics.GraphQL.QueryName do
    @moduledoc false

    alias Absinthe.Language.{ListType, NamedType, NonNullType}

    def get_name(query) do
      case get_initial_definition(query) do
        %{name: name} = definition when not is_nil(name) ->
          variables = build_variables_with_types(definition)
          "#{definition_operation(definition)} #{name}#{variables}"

        %{selection_set: %{selections: [%{name: name} | _]}} = definition ->
          variables = build_variables_with_types(definition)
          "#{definition_operation(definition)} #{name || "Unknown"}#{variables}"

        _ ->
          "operation Unknown"
      end
    end

    defp definition_operation(%{operation: operation}) do
      operation
    end

    def get_query_name(query) do
      query
      |> get_initial_definition
      |> get_name_from_definition(fn definition, _ ->
        build_variables_with_types(definition)
      end)
    end

    def get_query_name(query, variables) do
      query
      |> get_initial_definition
      |> get_name_from_definition(variables, &build_variables_with_values/2)
    end

    defp get_name_from_definition(definition, variables \\ nil, variables_func) do
      case definition do
        %{name: name} = definition when not is_nil(name) ->
          variables = variables_func.(definition, variables)
          "#{name}#{variables}"

        %{selection_set: %{selections: [%{name: name} | _]}} = definition ->
          variables = variables_func.(definition, variables)
          "#{name || "Unknown"}#{variables}"

        _ ->
          "Unknown"
      end
    end

    defp get_initial_definition(query) do
      with {:ok, tokens} <- tokenize(query),
           {:ok, %{definitions: [definition | _]}} <- :absinthe_parser.parse(tokens) do
        definition
      end
    end

    defp tokenize(query) do
      Absinthe.Lexer.tokenize(query)
    end

    defp build_variables_with_types(definition) do
      variables =
        definition.variable_definitions
        |> Enum.map_join(", ", fn variable_definition ->
          variable = variable_definition.variable.name
          type = name_from_type(variable_definition.type)
          "$#{variable}: #{type}"
        end)

      if variables === "", do: "", else: "(#{variables})"
    end

    defp build_variables_with_values(definition, variables) do
      variables =
        definition.variable_definitions
        |> Enum.map_join(", ", fn %{variable: %{name: name}} ->
          "$#{name}: #{variables[name]}"
        end)

      if variables === "", do: "", else: "(#{variables})"
    end

    defp name_from_type(%NamedType{} = definition), do: definition.name
    defp name_from_type(%NonNullType{} = definition), do: definition.type.name

    defp name_from_type(%ListType{} = definition) do
      "[#{name_from_type(definition.type)}]"
    end
  end
end
