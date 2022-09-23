defmodule GraphQLTools.ErrorTypes do
  use Absinthe.Schema.Notation

  enum :validation_type do
    value(:custom)
    value(:required)
  end

  object :validation_error do
    field(:message, non_null(:string))
    field(:key, non_null(:string))
    field(:validation, non_null(:validation_type))
  end
end
