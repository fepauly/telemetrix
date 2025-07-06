defmodule Telemetrix.SensorReadings.SensorReading do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sensor_readings" do
    field :device_id, :string
    field :type, :string
    field :value, :float
    field :timestamp, :utc_datetime

    timestamps()
  end

  def changeset(sensor_reading, attrs) do
    sensor_reading
      |> cast(attrs, [:device_id, :type, :value, :timestamp])
      |> validate_required([:device_id, :type, :value, :timestamp])
  end
end
