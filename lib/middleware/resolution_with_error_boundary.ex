defmodule GraphQLTools.ResolutionWithErrorBoundary do
  @moduledoc """
  Absinthe middleware module wrapping `Absinthe.Resolution`
  to handle `Ecto.NoResultsError`s without modifying resolution code.
  """

  @behaviour Absinthe.Middleware

  @impl true
  def call(%Absinthe.Resolution{state: :resolved} = res, _), do: res

  def call(%Absinthe.Resolution{} = res, resolver) do
    try do
      Absinthe.Resolution.call(res, resolver)
    rescue
      Ecto.NoResultsError ->
        %{res | errors: ["No results found in query."], state: :resolved}
    end
  end

  @doc """
  Replaces the default resolution middleware with this module.
  You can use it in your schema's `middleware/3` callback.
  """
  def replace_resolution_middleware(middleware) when is_list(middleware) do
    Enum.map(middleware, fn
      {{Absinthe.Resolution, :call}, resolver} ->
        {{ResolutionWithErrorBoundary, :call}, resolver}

      other ->
        other
    end)
  end
end
