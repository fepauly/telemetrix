defmodule Telemetrix.MQTT.Handler do
  use Tortoise.Handler
  require Logger

  def init(args) do
    Logger.info("Initializing handler with args: #{inspect(args)}")
    {:ok, args}
  end

  def connection(:up, state) do
    Logger.info("MQTT connected")
    Phoenix.PubSub.broadcast(Telemetrix.PubSub, "mqtt_connect", :mqtt_connect)
    {:ok, state}
  end

  def connection(:down, state) do
    Logger.warning("MQTT disconnected")
    Phoenix.PubSub.broadcast(Telemetrix.PubSub, "mqtt_disconnect", :mqtt_disconnect)
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
          {:ok, value} ->
            point = %Telemetrix.Influx.SensorDataPoint{}
            point = %{point | fields: %{point.fields | value: value}}
            point = %{point | tags: %{point.tags | device_id: device_id, type: type}}
            Logger.debug("[DATA POINT] #{inspect(point)}")
            Telemetrix.Influx.InfluxConnection.write(point)

          {:error, reason} ->
            Logger.error("[MQTT] Invalid payload: #{inspect(reason)} | #{inspect(payload)}")
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
      {:ok, %{"value" => value}} when is_number(value) ->
        Logger.debug("Data point value #{value}")
        {:ok, value * 1.0} # enforce float
      {:ok, %{"value" => value}} ->
        {:error, {:invalid_value_type, value}}
      {:ok, _other} ->
        {:error, :missing_value_field}
      error ->
        {:error, {:invalid_json, error}}
    end
  end
end
