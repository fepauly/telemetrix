defmodule TelemetrixWeb.SubscriptionsLive.Index do
  use TelemetrixWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
      topics = Telemetrix.Subscriptions.SubscriptionManager.get_topics()
      {:ok, assign(socket, topics: topics, new_topic: "", error: nil)}
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
