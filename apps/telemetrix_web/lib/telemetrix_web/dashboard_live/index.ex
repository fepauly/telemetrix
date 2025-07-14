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
    topic_options =
      SensorReadings.list_device_id_types_unique()
      |> Enum.map(fn {device_id, type} ->
        label = "#{device_id}/#{type}"
        {label, label}
      end)

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
      |> assign(:dropdown_open, false)
      |> assign(:pending_topics, [])
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
    topic_options = socket.assigns[:topic_options]
    dropdown_open = socket.assigns[:dropdown_open]
    pending_topics = socket.assigns[:pending_topics]
    new_topic = "#{reading.device_id}/#{reading.type}"

    topic_option_values = Enum.map(topic_options, fn {_, v} -> v end)

    needs_topic_update = new_topic not in topic_option_values

    {updated_topic_options, updated_pending_topics} =
      cond do
        # If dropdown is open, collect new topics but don't update the list yet
        dropdown_open && needs_topic_update ->
          {topic_options, [new_topic | pending_topics] |> Enum.uniq()}

        # If dropdown is closed add the new topics
        needs_topic_update ->
          {[{new_topic, new_topic} | topic_options], pending_topics}

        true ->
          {topic_options, pending_topics}
      end

    update_chart = selected_topic && new_topic == selected_topic

    socket =
      if update_chart do
        chart_entry = %{
          value: reading.value,
          timestamp: format_timestamp(reading.timestamp)
        }

        old_chart_data = socket.assigns[:chart_data] || []
        new_chart_data =
          [chart_entry | old_chart_data]
          |> Enum.take(@chart_limit)

        socket
        |> assign(:chart_data, Enum.reverse(new_chart_data))
      else
        socket
      end

    socket =
      socket
      |> assign(:topic_options, updated_topic_options)
      |> assign(:pending_topics, updated_pending_topics)

    {:noreply, socket |> stream_insert(:sensor_readings, reading, at: 0, limit: @stream_limit)}
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
  def handle_event("select_topic", %{"topic" => topic}, socket) do
    topic = if topic == "", do: nil, else: topic

    case topic do
      nil ->
        {:noreply,
          socket
          |> assign(:selected_topic, nil)
          |> assign(:chart_data, nil)
          |> assign(:selected_device_id, nil)
          |> assign(:selected_type, nil)
          |> assign(:dropdown_open, false)
        }
      _ ->
        [device_id, type] = String.split(topic, "/")
        chart_data =
          SensorReadings.list_sensor_readings(@chart_limit, device_id, type)
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
            |> assign(:dropdown_open, false)
        }
    end
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
  def handle_event("dropdown-toggle", _params, socket) do
    # Toggle the dropdown open/close
    current_state = socket.assigns.dropdown_open
    {:noreply, assign(socket, :dropdown_open, !current_state)}
  end

  @impl true
  def handle_event("dropdown-close", _params, socket) do
    # Apply any pending topics when dropdown is closed
    socket =
      if Enum.empty?(socket.assigns.pending_topics) do
        socket
      else
        updated_topic_options =
          Enum.reduce(socket.assigns.pending_topics, socket.assigns.topic_options, fn topic, acc ->
            topic_option_values = Enum.map(acc, fn {_, v} -> v end)
            if topic in topic_option_values do
              acc
            else
              [{topic, topic} | acc]
            end
          end)

        socket
        |> assign(:topic_options, updated_topic_options)
        |> assign(:pending_topics, [])
      end

    {:noreply, assign(socket, :dropdown_open, false)}
  end

  @impl true
  def handle_event("select-topic-item", %{"topic" => topic}, socket) do
    topic = if topic == "", do: nil, else: topic

    case topic do
      nil ->
        {:noreply,
          socket
          |> assign(:selected_topic, nil)
          |> assign(:chart_data, nil)
          |> assign(:selected_device_id, nil)
          |> assign(:selected_type, nil)
          |> assign(:dropdown_open, false)
        }
      _ ->
        [device_id, type] = String.split(topic, "/")
        chart_data =
          SensorReadings.list_sensor_readings(@chart_limit, device_id, type)
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
            |> assign(:dropdown_open, false)
        }
    end
  end

  defp format_timestamp(%NaiveDateTime{} = ts) do
    Calendar.strftime(ts, "%m/%d/%Y, %H:%M:%S")
  end

  defp format_timestamp(%DateTime{} = ts) do
    Calendar.strftime(ts, "%m/%d/%Y, %H:%M:%S")
  end

  defp format_timestamp(nil), do: "-"

end
