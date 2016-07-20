defmodule Medicine do
  use Callisto.Properties

  properties do
    field :name, :string, required: true
    field :is_bitter, :boolean, default: false
    field :dose, :integer, default: 100
    field :efficacy, :float, default: 0.9
  end
end
