defmodule Telemetrix.MQTT.Handler do
  use Tortoise.Handler
  require Logger
  alias Telemetrix.SensorReadings

  def init(args) do
    Logger.info("Initializing handler with args: #{inspect(args)}")
    {:ok, args}
  end

  def connection(:up, state) do
    Logger.info("MQTT connected")
    {:ok, state}
  end

  def connection(:down, state) do
    Logger.warning("MQTT disconnected")
    {:ok, state}
  end

  def handle_message(topic, payload, state) do
    parts =
    case topic do
      t when is_binary(t) -> String.split(t, "/")
      t when is_list(t) -> t
    end

    case parts do
      [device_id | rest] when length(rest) >= 1 ->
        type = List.last(rest)

        case parse_payload(payload) do
          {:ok, value, timestamp} ->
            case SensorReadings.ingest(device_id, type, value, timestamp) do
              {:ok, reading} ->
                Phoenix.PubSub.broadcast(Telemetrix.PubSub, "sensor_readings", {:new_reading, reading})

              {:error, changeset} ->
                Logger.error("[DB] #{inspect(changeset)} | #{device_id}/#{type}")
            end

          {:error, reason} ->
            Logger.error("[MQTT] Invalid payload: #{reason} | #{inspect(payload)}")
        end

      _ ->
        Logger.error("[MQTT] Unexepected topic format: #{inspect(topic)}")
    end

    {:ok, state}
  end

  def subscription(status, topic_filter, state) do
    {:ok, state}
  end

  def terminate(reason, state) do
    Logger.info("Terminating with reason: #{reason}")
    {:ok, state}
  end


  def last_will(state) do
    {{:ok, nil}, state}
  end

  defp parse_payload(payload) do
    case Jason.decode(payload) do
      {:ok, %{"value" => value, "timestamp" => ts}} ->
        case DateTime.from_iso8601(ts) do
          {:ok, dt, _} -> {:ok, value, dt}
          error -> {:error, {:invalid_timestamp, error}}
        end

      error -> {:error, {:invalid_json, error}}
    end
  end
end
