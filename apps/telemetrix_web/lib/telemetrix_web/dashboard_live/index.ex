defmodule TelemetrixWeb.DashboardLive.Index do
  use TelemetrixWeb, :live_view
  alias Telemetrix.SensorReadings

  @stream_limit 20
  @chart_limit 100

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Telemetrix.PubSub, "sensor_readings")
    end

    readings = SensorReadings.list_sensor_readings(@stream_limit)
    topic_options =
      SensorReadings.list_device_id_types_unique()
      |> Enum.map(fn {device_id, type} ->
        label = "#{device_id}/#{type}"
        {label, label}
      end)

    {:ok,
      socket
      |> assign(:device_filter, nil)
      |> assign(:type_filter, nil)
      |> assign(:topic_options, topic_options)
      |> assign(:selected_topic, nil)
      |> assign(:chart_data, nil)
      |> assign(:selected_device_id, nil)
      |> assign(:selected_type, nil)
      |> stream(:sensor_readings, readings)}
  end

  @impl true
  def handle_info({:new_reading, reading}, socket) do
    selected_topic = socket.assigns[:selected_topic]
    topic_options = socket.assigns[:topic_options]
    new_topic = "#{reading.device_id}/#{reading.type}"

    topic_option_values = Enum.map(topic_options, fn {_, v} -> v end)
    if new_topic not in topic_option_values do
      topic_options = [{new_topic, new_topic} | topic_options]
    end


    if selected_topic &&  new_topic == selected_topic do
      chart_entry = %{
        value: reading.value,
        timestamp: format_timestamp(reading.timestamp)
      }

      old_chart_data = socket.assigns[:chart_data] || []
      new_chart_data =
        [chart_entry | old_chart_data]
        |> Enum.take(@chart_limit)

      {:noreply,
        socket
        |> assign(:chart_data, Enum.reverse(new_chart_data))
        |> assign(:topic_options, topic_options)
        |> stream_insert(:sensor_readings, reading, at: 0, limit: @stream_limit)
      }
    else
      {:noreply,
      socket
      |> assign(:topic_options, topic_options)
      |> stream_insert(:sensor_readings, reading, at: 0, limit: @stream_limit)
    }
    end
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
        {:noreply, assign(socket, selected_topic: nil, chart_data: nil, selected_device_id: nil, selected_type: nil)}
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
