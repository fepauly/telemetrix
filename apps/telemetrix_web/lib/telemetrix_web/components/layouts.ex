defmodule TelemetrixWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is rendered as component
  in regular views and live views.
  """
  use TelemetrixWeb, :html

  embed_templates "layouts/*"

  @doc """
  Renders the app layout

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layout.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <header class="flex items-center justify-between px-6 py-3 bg-base-200 shadow-md sticky top-0 z-50">
      <div class="flex items-center gap-3">
        <span class="text-xl font-bold tracking-tight text-primary flex items-center">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
          </svg>
          Telemetrix
        </span>
      </div>

      <nav class="flex items-center gap-6">
        <.link navigate={~p"/"} class="text-base-content/80 hover:text-primary transition font-medium flex items-center gap-1">
          <.icon name="hero-home-micro" class="size-4" />
          <span>Home</span>
        </.link>
        <.link navigate={~p"/dashboard"} class="text-base-content/80 hover:text-primary transition font-medium flex items-center gap-1">
          <.icon name="hero-chart-bar-micro" class="size-4" />
          <span>Dashboard</span>
        </.link>
        <.link navigate={~p"/subscriptions"} class="text-base-content/80 hover:text-primary transition font-medium flex items-center gap-1">
          <.icon name="hero-bell-micro" class="size-4" />
          <span>Subscriptions</span>
        </.link>
        <.theme_toggle />
      </nav>
    </header>

    <main class="w-full min-h-screen">
      {render_slot(@inner_block)}
    </main>

    <footer class="py-4 px-6 bg-base-200 border-t border-base-300 text-center text-sm text-base-content/60">
      <p>Telemetrix IoT Dashboard © <%= DateTime.utc_now().year %></p>
    </footer>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="relative inline-block">
      <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full shadow-sm hover:shadow transition-shadow">
        <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left] duration-300 ease-in-out" />

        <button
          phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "system"})}
          class="flex p-2 cursor-pointer w-1/3 items-center justify-center transition-opacity duration-200"
          aria-label="System theme"
        >
          <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
        </button>

        <button
          phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "light"})}
          class="flex p-2 cursor-pointer w-1/3 items-center justify-center transition-opacity duration-200"
          aria-label="Light theme"
        >
          <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
        </button>

        <button
          phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "dark"})}
          class="flex p-2 cursor-pointer w-1/3 items-center justify-center transition-opacity duration-200"
          aria-label="Dark theme"
        >
          <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
        </button>
      </div>
    </div>
    """
  end
end
