defmodule Treatment do
  use Callisto.Properties

  properties do
    field :name, :string, required: true
    field :dose, :integer, default: 50
    field :duration, :integer, default: 1
  end
end
