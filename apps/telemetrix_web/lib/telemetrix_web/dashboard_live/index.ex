defmodule TelemetrixWeb.DashboardLive.Index do
  use TelemetrixWeb, :live_view
  alias Telemetrix.SensorReadings

  @stream_limit 20

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Telemetrix.PubSub, "sensor_readings")
    end

    readings = SensorReadings.list_sensor_readings(@stream_limit)
    {:ok,
      socket
      |> assign(:device_filter, nil)
      |> assign(:type_filter, nil)
      |> stream(:sensor_readings, readings)}
  end

  @impl true
  def handle_info({:new_reading, reading}, socket) do
    {:noreply, stream_insert(socket, :sensor_readings, reading, at: 0, limit: @stream_limit)}
  end

  @impl true
  def handle_event("filter", %{"device_id" => device_id, "type" => type}, socket) do
    device_id = if device_id == "", do: nil, else: device_id
    type = if type == "", do: nil, else: type

    readings = SensorReadings.list_sensor_readings(@stream_limit, device_id, type)

    {:noreply,
      socket
      |> assign(:device_filter, device_id)
      |> assign(:type_filter, type)
      |> stream(:sensor_readings, readings, reset: true)
    }
  end

  defp format_timestamp(%NaiveDateTime{} = ts) do
    Calendar.strftime(ts, "%m/%d/%Y, %H:%M:%S")
  end

  defp format_timestamp(%DateTime{} = ts) do
    Calendar.strftime(ts, "%m/%d/%Y, %H:%M:%S")
  end

  # Falls mal nil kommt:
  defp format_timestamp(nil), do: "-"

end
