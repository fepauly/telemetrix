defmodule Telemetrix.Subscriptions do
  alias Telemetrix.Subscriptions.Subscription
  alias Telemetrix.Repo

  def create_subscription(attrs) do
    topic = attrs["topic"] || attrs[:topic]

    if valid_topic_format?(topic) do
      %Subscription{}
      |> Subscription.changeset(attrs)
      |> Repo.insert()
    else
      {:error, :invalid_topic_format}
    end
  end

  def list_subscriptions() do
    Repo.all(Subscription)
  end

  def delete_subscription(%Subscription{} = subscription) do
    Repo.delete(subscription)
  end

  def get_subscription_by_topic(topic) do
    Repo.get_by(Subscription, topic: topic)
  end

  defp valid_topic_format?(topic) do
    parts =
      case topic do
        t when is_binary(t) -> String.split(t, "/")
        t when is_list(t) -> t
      end

      length(parts) >= 2
  end
end
