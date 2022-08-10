if PrometheusTelemetry.Utils.app_loaded?(:absinthe) do
  defmodule PrometheusTelemetry.Metrics.GraphQL.QueryName do
    @moduledoc false

    alias Absinthe.Blueprint
    alias Absinthe.Language.{ListType, NamedType, NonNullType}

    @regex_capture_operation ~r/(?<type>query|mutation|subscription|)(\s*(?<name>\w+)\(.*\)|)\s*{(?<query>.*)}$/U
    @regex_capture_query ~r/\s*(?<name>\w+)\(.*\)\s*({(?<args>.*)}$|$)/U

    def capture_operation(%Blueprint{input: operation}) when is_binary(operation) do
      capture_valid_graphql_values(@regex_capture_operation, operation)
    end

    def capture_query(query) do
      capture_valid_graphql_values(@regex_capture_query, query)
    end

    def capture_query_name(query) do
      case capture_query(query) do
        %{"name" => name} -> name
        _ -> "Unknown"
      end
    end

    defp capture_valid_graphql_values(regex, string) do
      case Regex.named_captures(regex, String.replace(string, "\n", "")) do
        nil -> %{"name" => "Unknown by Regex"}
        matches -> Map.reject(matches, fn {_, value} -> value === "" end)
      end
    end

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
      variables = Enum.map_join(definition.variable_definitions, ", ", fn variable_definition ->
        variable = variable_definition.variable.name
        type = name_from_type(variable_definition.type)
        "$#{variable}: #{type}"
      end)

      if variables === "", do: "", else: "(#{variables})"
    end

    defp build_variables_with_values(definition, variables) do
      variables =
        Enum.map_join(definition.variable_definitions, ", ", fn %{variable: %{name: name}} ->
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
