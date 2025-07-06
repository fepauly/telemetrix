defmodule Telemetrix.SensorReadings do
  alias Telemetrix.SensorReadings.SensorReading
  alias Telemetrix.Repo

  def create_sensor_reading(attrs) do
    %SensorReading{}
    |> SensorReading.changeset(attrs)
    |> Repo.insert()
  end

  def list_sensor_readings(limit \\ 50, device_id \\ nil, type \\ nil) do
    import Ecto.Query, only: [from: 2]

    query = from sr in SensorReading, order_by: [desc: sr.inserted_at], limit: ^limit

    query =
      if device_id, do: from(sr in query, where: like(sr.device_id, ^"#{device_id}%")), else: query

    query =
      if type, do: from(sr in query, where: like(sr.type, ^"%#{type}%")), else: query

    Repo.all(query)
  end

  def ingest(device_id, type, value, timestamp) do
  create_sensor_reading(%{
    device_id: device_id,
    type: type,
    value: value,
    timestamp: timestamp
  })
end
end
