defmodule HasMedicine do
  use Callisto.Properties

  properties do
    name "has_medicine"
    field :amount, :integer
  end
end
