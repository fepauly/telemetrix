defmodule TelemetrixWeb.DashboardLive.Index do
  use TelemetrixWeb, :live_view
  alias Telemetrix.SensorReadings

  @stream_limit 20
  @chart_limit 100

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Telemetrix.PubSub, "sensor_readings")
      Telemetrix.MQTT.ConnectionMonitor.subscribe()
    end

    readings = SensorReadings.list_sensor_readings(@stream_limit)
    topic_options = load_topic_options()
    initial_mqtt_status = Telemetrix.MQTT.ConnectionMonitor.connected?()

    {:ok,
      socket
      |> assign(:device_filter, nil)
      |> assign(:type_filter, nil)
      |> assign(:topic_options, topic_options)
      |> assign(:selected_topic, nil)
      |> assign(:chart_data, nil)
      |> assign(:selected_device_id, nil)
      |> assign(:selected_type, nil)
      |> assign(:mqtt_connect, initial_mqtt_status)
      |> assign(:chart_limit, @chart_limit)
      |> assign(:topics_loading, false)
      |> stream(:sensor_readings, readings)}
  end

  @impl true
  def handle_info(:mqtt_disconnect, socket) do
    {:noreply, assign(socket, mqtt_connect: false)}
  end

  @impl true
  def handle_info(:mqtt_connect, socket) do
    {:noreply, assign(socket, mqtt_connect: true)}
  end

 @impl true
  def handle_info({:new_reading, reading}, socket) do
    selected_topic = socket.assigns[:selected_topic]
    new_topic = "#{reading.device_id}/#{reading.type}"

    socket = if selected_topic && new_topic == selected_topic do
      chart_entry = %{
        value: reading.value,
        timestamp: format_timestamp(reading.timestamp)
      }

      old_chart_data = socket.assigns[:chart_data] || []

      # Neue Daten rechts anhängen (chronologisch)
      new_chart_data =
        old_chart_data
        |> Kernel.++([chart_entry])      # Am Ende anhängen
        |> Enum.take(-@chart_limit)      # Nur die letzten @chart_limit behalten

      assign(socket, :chart_data, new_chart_data)
    else
      socket
    end

    {:noreply, socket |> stream_insert(:sensor_readings, reading, at: 0, limit: @stream_limit)}
  end

  @impl true
  def handle_info({:write_error, reading}, socket) do
    # TODO
  end

  @impl true
  def handle_event("refresh_topics", _params, socket) do
    {:noreply,
      socket
      |> assign(:topics_loading, true)
      |> assign(:topic_options, load_topic_options())
      |> assign(:topics_loading, false)
    }
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

  @impl true
  def handle_event("clear_filters", _params, socket) do
    readings = SensorReadings.list_sensor_readings(@stream_limit)

    {:noreply,
      socket
      |> assign(:device_filter, nil)
      |> assign(:type_filter, nil)
      |> stream(:sensor_readings, readings, reset: true)
    }
  end

  @impl true
  def handle_event("select-topic", %{"topic" => topic}, socket) do
    topic = if topic == "", do: nil, else: topic

    case topic do
      nil ->
        {:noreply,
          socket
          |> assign(:selected_topic, nil)
          |> assign(:chart_data, nil)
          |> assign(:selected_device_id, nil)
          |> assign(:selected_type, nil)
          |> stream(:sensor_readings, [], reset: true)
        }
      _ ->
        [device_id, type] = String.split(topic, "/")

        readings = SensorReadings.list_sensor_readings(@stream_limit, device_id, type)

        chart_data =
          SensorReadings.list_sensor_readings(@chart_limit, device_id, type)
          |> Enum.sort_by(&(&1.timestamp), DateTime)
          |> Enum.map(fn sr ->
            %{
              value: sr.value,
              timestamp: format_timestamp(sr.timestamp)
            }
          end)
        {:noreply,
          socket
            |> assign(:selected_topic, topic)
            |> assign(:selected_device_id, device_id)
            |> assign(:selected_type, type)
            |> assign(:chart_data, chart_data)
            |> stream(:sensor_readings, readings, reset: true)
        }
    end
  end

  defp format_timestamp(%NaiveDateTime{} = ts) do
    ts
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.shift_zone!("Europe/Berlin")
    |> Calendar.strftime("%d.%m.%Y, %H:%M:%S")
  end

  defp format_timestamp(%DateTime{} = ts) do
    ts
    |> DateTime.shift_zone!("Europe/Berlin")
    |> Calendar.strftime("%d.%m.%Y, %H:%M:%S")
  end

  defp format_timestamp(nil), do: "-"

  defp load_topic_options() do
    SensorReadings.list_device_id_types_unique("30d")
    |> Enum.map(fn {device_id, type} ->
      label = "#{device_id}/#{type}"
      {label, label}
    end)
  end
end
