defmodule Telemetrix.Subscriptions.Subscription do
  use Ecto.Schema
  import Ecto.Changeset

  schema "subscriptions" do
    field :topic, :string

    timestamps()
  end

  def changeset(subscription, attrs) do
    subscription
    |> cast(attrs, [:topic])
    |> validate_required([:topic])
    |> unique_constraint(:topic)
  end

end
