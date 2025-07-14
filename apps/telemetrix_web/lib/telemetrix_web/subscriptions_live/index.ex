defmodule TelemetrixWeb.SubscriptionsLive.Index do
  use TelemetrixWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Telemetrix.MQTT.ConnectionMonitor.subscribe()
    end

    topics = Telemetrix.Subscriptions.SubscriptionManager.get_topics()

    # Get actual connection status
    initial_mqtt_status = Telemetrix.MQTT.ConnectionMonitor.connected?()

    {:ok, assign(socket,
      topics: topics,
      new_topic: "",
      error: nil,
      mqtt_connect: initial_mqtt_status
    )}
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
  def handle_event("add_topic", %{"topic" => topic}, socket) do
    case Telemetrix.Subscriptions.SubscriptionManager.add_topic(topic) do
      :ok ->
        topics = Telemetrix.Subscriptions.SubscriptionManager.get_topics()
        {:noreply, assign(socket, topics: topics, new_topic: "", error: nil)}

      {:error, :invalid_topic_format} ->
        {:noreply, assign(socket, error: "Invalid topic format! Expected: device_id/.../type")}

      {:error, changeset} when is_struct(changeset, Ecto.Changeset) ->
        {:noreply, assign(socket, error: "Error adding the topic: #{inspect(changeset.errors)}")}

      {:error, reason} ->
        {:noreply, assign(socket, error: "Unexpected error: #{inspect(reason)}")}
    end
  end

  @impl true
  def handle_event("remove_topic", %{"topic" => topic}, socket) do
    case Telemetrix.Subscriptions.SubscriptionManager.remove_topic(topic) do
      :ok ->
        topics = Telemetrix.Subscriptions.SubscriptionManager.get_topics()
        {:noreply, assign(socket, topics: topics, new_topic: "", error: nil)}
      {:error, reason} ->
        {:noreply, assign(socket, error: reason)}
    end
  end

  @impl true
  def handle_event("update_new_topic", %{"topic" => val}, socket) do
    {:noreply, assign(socket, new_topic: val)}
  end
end
