defmodule Telemetrix.Subscriptions.SubscriptionManager do
  use GenServer
  require Logger
  alias Telemetrix.Subscriptions
  alias Telemetrix.Subscriptions.Subscription

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_init_arg) do
    topics = Subscriptions.list_subscriptions() |> Enum.map(& &1.topic)
    Logger.info("Subscription Manager starts with topic: #{inspect(topics)}")

    Enum.each(topics, fn topic ->
      subscribe_to_topic(topic)
    end)

    {:ok, %{topics: topics}}
  end

  def add_topic(topic) do
    GenServer.call(__MODULE__, {:add_topic, topic})
  end

  def remove_topic(topic) do
    GenServer.call(__MODULE__, {:remove_topic, topic})
  end

  def get_topics() do
    GenServer.call(__MODULE__, :get_topics)
  end

  def handle_call({:add_topic, topic}, _from, state) do
    case Subscriptions.create_subscription(%{topic: topic}) do
      {:ok, _subscription} ->
        case subscribe_to_topic(topic) do
          :ok ->
            topics = Enum.uniq([topic | state.topics])
            {:reply, :ok, %{state | topics: topics}}

          {:error, reason} ->
            {:ok, %Subscription{} = sub} = Subscriptions.get_subscription_by_topic(topic)
            Subscriptions.delete_subscription(sub)
            {:reply, {:error, reason}, state}
        end

      {:error, changeset} ->
        {:reply, {:error, changeset}, state}
    end
  end

  def handle_call({:remove_topic, topic}, _from, state) do
    case Subscriptions.get_subscription_by_topic(topic) do
      %Subscription{} = sub ->
        case unsubscribe_from_topic(topic) do
          :ok ->
            Subscriptions.delete_subscription(sub)
            topics = List.delete(state.topics, topic)
            {:reply, :ok, %{state | topics: topics}}
          {:error, reason} ->
            {:reply, {:error, reason}, state}
        end

      nil ->
        {:reply, {:error, :not_found}, state}
    end
  end

  def handle_call(:get_topics, _from, state) do
    {:reply, state.topics, state}
  end


  defp subscribe_to_topic(topic) do
    case Tortoise.Connection.subscribe_sync(client_id(), [{topic, 0}]) do
      :ok ->
        Logger.info("Tortoise subscribed to #{topic}")
        :ok
      {:error, reason} ->
        Logger.error("Tortoise failed to subscribe to #{topic}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp unsubscribe_from_topic(topic) do
    case Tortoise.Connection.unsubscribe_sync(client_id(), [topic]) do
      :ok ->
        Logger.info("Tortoise unsubscribed from #{topic}")
        :ok
      {:error, reason} ->
        Logger.error("Tortoise failed to unsubscribe from #{topic}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp client_id do
  Application.fetch_env!(:telemetrix, :mqtt)[:client_id]
  end
end
