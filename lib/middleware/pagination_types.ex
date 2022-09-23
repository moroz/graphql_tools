defmodule GraphQLTools.PaginationTypes do
  use Absinthe.Schema.Notation

  object :page_info do
    field(:page, non_null(:integer))
    field(:page_size, non_null(:integer))
    field(:total_pages, non_null(:integer))
    field(:total_entries, non_null(:integer))
  end
end
