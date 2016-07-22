defmodule HasMedicine do
  use Callisto.Properties

  properties id: false do
    name "has_medicine"
    field :amount, :integer
  end
end
