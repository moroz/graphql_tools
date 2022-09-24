defmodule GraphQLTools.LazyPreload do
  @moduledoc """
  Absinthe middleware to preload Ecto associations only if they have
  been requested.
  """

  defmacro __using__(opts) do
    repo = Keyword.get(opts, :repo)

    quote bind_quoted: [repo: repo] do
      @behaviour Absinthe.Middleware

      @repo unquote(repo)

      def call(resolution, opts) do
        opts = Keyword.put_new(opts, :repo, unquote(repo))
        GraphQLTools.LazyPreload.call(resolution, opts)
      end

      defmacro lazy_preload(assoc_name \\ nil) do
        quote do
          middleware(GraphQLTools.LazyPreload,
            assoc_name: unquote(assoc_name),
            repo: unquote(@repo)
          )
        end
      end
    end
  end

  require Absinthe.Schema.Notation

  @behaviour Absinthe.Middleware

  import Ecto.Query

  def call(%Absinthe.Resolution{state: :resolved} = res, _opts), do: res

  def call(%Absinthe.Resolution{} = res, opts) do
    assoc_name = Keyword.get(opts, :assoc_name) || res.definition.schema_node.identifier
    repo = Keyword.get(opts, :repo)
    preload_assoc(res, assoc_name, repo)
  end

  defp preload_assoc(%Absinthe.Resolution{source: source} = res, assoc_name, repo)
       when is_atom(assoc_name) do
    value =
      case Map.get(source, assoc_name) do
        %Ecto.Association.NotLoaded{__cardinality__: :one} ->
          repo.one(Ecto.assoc(source, assoc_name))

        %Ecto.Association.NotLoaded{} ->
          source
          |> Ecto.assoc(assoc_name)
          |> order_by(:id)
          |> repo.all()

        nil ->
          nil

        %_module{} = struct ->
          struct

        list when is_list(list) ->
          list
      end

    %{res | value: value, state: :resolved}
  end

  defp preload_assoc(%Absinthe.Resolution{source: source} = res, [{assoc_name, _}] = list, repo) do
    preloaded = repo.preload(source, list)
    value = Map.get(preloaded, assoc_name)
    %{res | value: value, state: :resolved}
  end
end
