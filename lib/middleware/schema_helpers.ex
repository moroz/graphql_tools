defmodule GraphQLTools.SchemaHelpers do
  @moduledoc """
  Macros defining commonly used fields or field combinations
  for use in GraphQL objects.
  """

  use Absinthe.Schema.Notation

  defmacro timestamps(opts \\ []) do
    data_type = Keyword.get(opts, :type, :datetime)

    quote do
      field(:inserted_at, non_null(unquote(data_type)))
      field(:updated_at, non_null(unquote(data_type)))
    end
  end

  defmacro standard_pagination_params do
    quote do
      field(:page, non_null(:integer), default_value: 1)
      field(:page_size, :integer)
      field(:q, :string)
    end
  end

  defmacro dynamic_enum_values(values) do
    expanded = Macro.expand(values, __CALLER__)

    values =
      for {name, value} <- expanded do
        quote do
          value(unquote(name), as: unquote(value))
        end
      end

    quote do: (unquote_splicing(values))
  end

  defmacro pagination_fields(entry_type) do
    quote do
      field(:page_info, non_null(:page_info))
      field(:data, non_null(list_of(non_null(unquote(entry_type)))))
    end
  end

  defmacro mutation_result_fields(result_type) do
    quote do
      field(:success, non_null(:boolean))
      field(:errors, non_null(list_of(non_null(:validation_error))))
      field(:data, unquote(result_type))
    end
  end

  @doc """
  Macro to reuse the common pattern of preloading associations using
  a batch function using `id` as the key.
  """
  defmacro resolve_with_batch(module, function, opts \\ []) do
    key = Keyword.get(opts, :key, :id)
    default_value = Keyword.get(opts, :default)

    quote do
      resolve(fn parent, _, _ ->
        id = Map.get(parent, unquote(key))

        batch(
          {unquote(module), unquote(function)},
          id,
          fn batch ->
            {:ok, Map.get(batch, id, unquote(default_value))}
          end
        )
      end)
    end
  end
end
