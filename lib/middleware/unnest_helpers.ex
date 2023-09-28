defmodule GraphQLTools.UnnestHelpers do
  @doc """
  Converts an arbitrarily nested map of translations to a flat map
  with all key levels combined to period-separated strings.
  Useful when you want to convert a nested structure like Rails
  i18n YAML translation files into a flat structure, like an Excel
  spreadsheet.

  ## Examples

      iex> nested = %{
      ...>   views: %{
      ...>     index: %{
      ...>       title: "Home page",
      ...>       section: "Recent news"
      ...>     },
      ...>     show: %{
      ...>       title: "Showing post: %{title}",
      ...>       test: "Test key"
      ...>     }
      ...>   }
      ...> }
      iex> GraphQLTools.UnnestHelpers.unnest_map(nested)
      %{
        "views.index.section" => "Recent news",
        "views.index.title" => "Home page",
        "views.show.test" => "Test key",
        "views.show.title" => "Showing post: %{title}"
      }

  """

  def unnest_map(map, prefix \\ nil)

  def unnest_map(map, prefix) when is_map(map) do
    Enum.reduce(map, %{}, fn tuple, acc ->
      unnest(tuple, acc, prefix)
    end)
  end

  def unnest_map(value, _prefix), do: value

  defp unnest({key, value}, acc, prefix) when is_map(value) do
    Map.merge(acc, unnest_map(value, join_prefix(prefix, key)))
  end

  defp unnest({key, value}, acc, prefix) do
    Map.put(acc, join_prefix(prefix, key), value)
  end

  defp join_prefix(nil, key), do: to_string(key)
  defp join_prefix(prefix, key), do: "#{prefix}.#{key}"

  @doc """
  Converts a flat map of period-separated strings to other terms to
  a deeply nested map, with each period-separated segment corresponding to one map
  level. Reverse of `unnest_map/2`. Does not preserve key data types -- all keys
  are converted to strings.

  ## Examples

      iex> flat = %{
      ...>   "views.index.section" => "Recent news",
      ...>   "views.index.title" => "Home page",
      ...>   "views.show.test" => "Test key",
      ...>   "views.show.title" => "Showing post: %{title}"
      ...> }
      iex> GraphQLTools.UnnestHelpers.nest_map(flat)
      %{
        "views" => %{
          "index" => %{"section" => "Recent news", "title" => "Home page"},
          "show" => %{"test" => "Test key", "title" => "Showing post: %{title}"}
        }
      }

  """
  def nest_map(input) do
    Enum.reduce(input, %{}, fn {key, value}, intermediate_map ->
      merge(intermediate_map, String.split(key, "."), value)
    end)
  end

  defp merge(map, [leaf], value), do: Map.put(map, leaf, value)

  defp merge(map, [node | remaining_keys], value) do
    inner_map = merge(Map.get(map, node, %{}), remaining_keys, value)
    Map.put(map, node, inner_map)
  end
end
