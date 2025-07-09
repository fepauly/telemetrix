defmodule TelemetrixWeb.ChartComponent do
  use TelemetrixWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id} phx-hook="ChartjsHook" phx-update="ignore"
         data-chart-data={Jason.encode!(@chart_data || [])}
         class="w-full max-w-2xl h-72">
    </div>
    """
  end
end
