defmodule GraphQLTools.TransformErrors do
  @moduledoc """
  Absinthe middleware module used to automatically convert success or 
  error responses from mutations into neat map responses.
  """

  defmacro __using__(opts) do
    quote do
      @behaviour Absinthe.Middleware

      def call(res, _) do
        value =
          case res do
            %{errors: [error]} ->
              %{
                res
                | errors: [],
                  value: GraphQLTools.TransformErrors.handle_error(error, unquote(opts))
              }

            # pre-formatted response
            %{errors: [], value: %{success: boolean}} = res when is_boolean(boolean) ->
              res

            %{errors: [], value: value} ->
              %{res | value: %{success: true, data: value, errors: []}}
          end

        value
      end
    end
  end

  def handle_error(%Ecto.Changeset{} = changeset, opts) do
    %{success: false, errors: transform_errors(changeset, opts)}
  end

  def handle_error(:not_found, _opts) do
    %{success: false, errors: %{msg: "The requested record could not be found."}}
  end

  def handle_error(errors, _opts) when is_map(errors) do
    %{success: false, errors: errors}
  end

  def handle_error(str, _opts) when is_binary(str) do
    %{success: false, errors: %{"msg" => str}}
  end

  defp transform_errors(changeset, opts) do
    gettext_module = Keyword.get(opts, :gettext_module)

    changeset
    |> remove_replace_content_changesets()
    |> Ecto.Changeset.traverse_errors(fn error ->
      format_and_translate_error(error, gettext_module)
    end)
    |> Enum.flat_map(fn {key, errors} ->
      key =
        key
        |> to_string()
        |> Absinthe.Adapter.LanguageConventions.to_external_name(:field)

      Enum.map(errors, fn error -> Map.put(error, :key, key) end)
    end)
  end

  defp format_and_translate_error({msg, opts}, module) do
    %{
      message: translate_error({msg, opts}, module),
      validation: Keyword.get(opts, :validation, :custom),
      key: nil
    }
  end

  defp translate_error({msg, _opts}, nil), do: msg

  defp translate_error({msg, opts}, gettext_module) when is_atom(gettext_module) do
    if count = opts[:count] do
      Gettext.dngettext(gettext_module, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(gettext_module, "errors", msg, opts)
    end
  end

  defp remove_replace_content_changesets(changeset) do
    case Map.get(changeset, :changes) do
      changes = %{content: content} when is_list(content) ->
        new_content = for %{action: :insert} = slice <- content, do: slice
        changes = %{changes | content: new_content}
        %{changeset | changes: changes}

      _ ->
        changeset
    end
  end
end
