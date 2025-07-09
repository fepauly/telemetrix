defmodule Telemetrix.Repo.Migrations.CreateSubscriptions do
  use Ecto.Migration

  def change do
    create table(:subscriptions) do
      add :topic, :string, null: false

      timestamps()
    end

    create unique_index(:subscriptions, [:topic])
  end
end
