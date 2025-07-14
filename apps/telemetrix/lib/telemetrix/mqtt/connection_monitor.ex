defmodule Telemetrix.MQTT.ConnectionMonitor do
  @moduledoc """
  Provides utilities to monitor and check MQTT connection status.
  """
  require Logger

  @doc """
  Checks if the MQTT client is currently connected.
  Returns true if connected, false otherwise.

  This uses ping with a 500 ms timeout to determine if the connection is alive.
  """
  def connected? do
    client_id = Application.get_env(:telemetrix, Telemetrix.MQTT)[:client_id]

    try do
      # Try to ping the broker with a 500 ms timeout
      case Tortoise.Connection.ping_sync(client_id, 500) do
        {:ok, _latency} ->
          Logger.debug("MQTT Broker ping successful.")
          true
        {:error, :timeout} ->
          Logger.debug("MQTT Broker ping failed.")
          false
      end
    rescue
      e ->
        Logger.debug("Error checking MQTT connection: #{inspect(e)}")
        false
    catch
      :exit, reason ->
        Logger.debug("MQTT connection check failed with exit: #{inspect(reason)}")
        false
    end
  end

  @doc """
  Registers a process to receive MQTT connection status updates from MQTT.Handler.
  """
  def subscribe do
    Phoenix.PubSub.subscribe(Telemetrix.PubSub, "mqtt_connect")
    Phoenix.PubSub.subscribe(Telemetrix.PubSub, "mqtt_disconnect")
  end
end
