defmodule Telemetrix.Repo.Migrations.CreateSensorReadings do
  use Ecto.Migration

  def change do
    create table(:sensor_readings) do
      add :device_id, :string, null: false
      add :type, :string, null: false
      add :value, :float, null: false
      add :timestamp, :utc_datetime_usec, null: false

      timestamps()
    end

    create index(:sensor_readings, [:device_id])
    create index(:sensor_readings, [:type])
    create index(:sensor_readings, [:timestamp])
  end
end
