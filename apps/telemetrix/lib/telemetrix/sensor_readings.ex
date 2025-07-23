defmodule Telemetrix.SensorReadings do
  require Logger
  alias Telemetrix.Influx.InfluxConnection

  def list_sensor_readings(limit \\ 100, device_id \\ nil, type \\ nil, range \\ "24h") do
    query = build_flux_query(limit, device_id, type, range)

    case InfluxConnection.query(query) do
      records when is_list(records) ->
        parse_flux_records(records)
      {:ok, records} when is_list(records) ->
        parse_flux_records(records)
      {:error, reason} ->
        Logger.error("InfluxDB query failed: #{inspect(reason)}")
        []

      other ->
        Logger.error("Unexpected InfluxDB response: #{inspect(other)}")
        []
    end
  end

  defp build_flux_query(limit, device_id, type, range) do
    base_query = """
    from(bucket: "#{InfluxConnection.config(:bucket)}")
    |> range(start: -#{range})
    |> filter(fn: (r) => r._measurement == "sensor_data")
    """

    device_filter = if device_id, do: "|> filter(fn: (r) => r.device_id == \"#{device_id}\")", else: ""
    type_filter = if type, do: "|> filter(fn: (r) => r.type == \"#{type}\")", else: ""

    """
    #{base_query}#{device_filter}#{type_filter}
    |> sort(columns: ["_time"], desc: true)
    |> limit(n: #{limit})
    """
  end

  defp parse_flux_records(records) do
    records
    |> Enum.map(&parse_single_record/1)
    |> Enum.filter(fn r -> r != nil end)
  end

  def list_device_id_types_unique(range \\ "30d") do
    query = """
    from(bucket: "#{InfluxConnection.config(:bucket)}")
      |> range(start: -#{range})
      |> filter(fn: (r) => r._measurement == "sensor_data")
      |> group(columns: ["device_id", "type"])
      |> first()
      |> keep(columns: ["device_id", "type"])
    """

    case InfluxConnection.query(query) do
      records when is_list(records) ->
        records
        |> Enum.map(fn record ->
          {record["device_id"], record["type"]}
        end)
        |> Enum.uniq()
        |> Enum.sort()

      {:ok, records} when is_list(records) ->
        records
        |> Enum.map(fn record ->
          {record["device_id"], record["type"]}
        end)
        |> Enum.uniq()
        |> Enum.sort()

      error ->
        Logger.error("Failed to fetch unique topics: #{inspect(error)}")
        []
    end
  end

  defp parse_single_record(record) do
    with {:ok, timestamp} <- parse_timestamp(record["_time"]),
          value when is_number(value) <- record["_value"],
          device_id when is_binary(device_id) <- record["device_id"],
          type when is_binary(type) <- record["type"] do

      # Generate unique ID for LiveView streams
      id = "#{device_id}_#{type}_#{DateTime.to_unix(timestamp, :nanosecond)}"

      %{
        id: id,
        timestamp: timestamp,
        value: value,
        type: type,
        device_id: device_id
      }
    else
      error ->
        Logger.warning("Failed to parse record: #{inspect(record)}, error: #{inspect(error)}")
        nil
    end
  end

  defp parse_timestamp(timestamp) when is_integer(timestamp) do
    {:ok, DateTime.from_unix!(timestamp, :nanosecond)}
  rescue
    _ -> {:error, :invalid_timestamp}
  end

  defp parse_timestamp(_), do: {:error, :invalid_timestamp}
end
