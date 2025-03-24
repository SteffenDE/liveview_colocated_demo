defmodule ColocatedDemoWeb.LiveDashboard.Hooks do
  import Phoenix.LiveView
  import Phoenix.Component

  alias Phoenix.LiveDashboard.PageBuilder

  def on_mount(:default, _params, _session, socket) do
    {:cont, PageBuilder.register_after_opening_head_tag(socket, &after_opening_head_tag/1)}
  end

  defp after_opening_head_tag(assigns) do
    ~H"""
    <script nonce={@csp_nonces[:script]} src="https://unpkg.com/@xterm/xterm@5.5.0/lib/xterm.js">
    </script>
    <script nonce={@csp_nonces[:script]} src="https://unpkg.com/@xterm/addon-fit@0.10.0/lib/addon-fit.js">
    </script>
    <link rel="stylesheet" nonce={@csp_nonces[:style]} href="https://unpkg.com/@xterm/xterm@5.5.0/css/xterm.css" />
    """
  end
end
