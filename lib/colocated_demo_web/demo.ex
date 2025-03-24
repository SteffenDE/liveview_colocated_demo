defmodule ColocatedDemoWeb.Demo do
  use ColocatedDemoWeb, :live_view

  def mount(_params, %{"script_csp_nonce" => nonce}, socket) do
    {:ok, assign(socket, :nonce, nonce)}
  end

  def render(assigns) do
    ~H"""
    <.comp_with_hook />

    <.comp_with_runtime_hook nonce={@nonce} />

    <.comp_with_colocated_css />

    <.other_comp_with_colocated_css />

    <.comp_with_colocated_web_component />
    """
  end
end
