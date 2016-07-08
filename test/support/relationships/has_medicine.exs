defmodule HasMedicine do
  use Callisto.Relationship

  properties do
    field :amount, :integer
  end
end
