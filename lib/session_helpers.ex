defmodule GraphQLTools.SessionHelpers do
  @doc """
  Callback executed by `Absinthe.Plug` before sending a response to the client.
  If a value has been set in `context[:set_session]`, a new value would be set
  in the session. `context[:set_session]` needs to be a keyword list.
  """
  def before_send(conn, %Absinthe.Blueprint{} = blueprint) do
    case blueprint.execution.context do
      %{drop_session: true} ->
        Plug.Conn.clear_session(conn)

      %{set_session: list} when is_list(list) ->
        Enum.reduce(list, conn, fn
          {key, :delete}, conn ->
            Plug.Conn.delete_session(conn, key)

          {key, value}, conn ->
            Plug.Conn.put_session(conn, key, value)
        end)

      _ ->
        conn
    end
  end

  def before_send(conn, _), do: conn
end
