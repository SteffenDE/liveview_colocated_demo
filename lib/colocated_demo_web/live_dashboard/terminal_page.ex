defmodule ColocatedDemoWeb.LiveDashboard.TerminalPage do
  @moduledoc false
  use Phoenix.LiveDashboard.PageBuilder, refresher?: false

  @impl true
  def mount(params, _session, socket) do
    tty =
      if connected?(socket) and not is_map_key(params, "node") do
        {:ok, tty} = ExTTY.start_link(handler: self())

        tty
      end

    socket
    |> assign(:tty, tty)
    |> assign(:nodes, [:self | Node.list()])
    |> assign(:node, :self)
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_params(%{"node" => node}, _uri, socket) do
    node = String.to_existing_atom(node)

    socket
    |> assign(:node, node)
    |> push_event("new-terminal", %{})
    |> connect_tty()
    |> then(&{:noreply, &1})
  end

  def handle_params(_, _, socket), do: {:noreply, socket}

  @impl true
  def menu_link(_, _) do
    {:ok, "IEx"}
  end

  def handle_event("terminal", data, socket) do
    ExTTY.send_text(socket.assigns.tty, data)

    {:noreply, socket}
  end

  def handle_event("resize", %{"rows" => rows, "cols" => cols}, socket) do
    ExTTY.window_change(socket.assigns.tty, cols, rows)

    {:noreply, socket}
  end

  defp connect_tty(socket) do
    if socket.assigns.tty do
      Process.unlink(socket.assigns.tty)
      Process.exit(socket.assigns.tty, :normal)
    end

    opts =
      case socket.assigns.node do
        :self -> [handler: self()]
        node -> [handler: self(), remsh: node]
      end

    {:ok, tty} = ExTTY.start_link(opts)

    assign(socket, tty: tty)
  end

  @impl true
  def handle_info({:tty_data, data}, socket) do
    {:noreply, push_event(socket, "terminal", %{"data" => data})}
  end

  def handle_info(_msg, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <script :extract={Phoenix.LiveView.ColocatedHook.new("TerminalPage", bundle_mode: :runtime)} nonce={@csp_nonces.script}>
      return {
        init() {
          if (this.terminal) this.terminal.dispose();
          this.terminal = new Terminal({
            theme: this.getTheme(),
          });
          const fitAddon = new FitAddon.FitAddon();
          this.fitAddon = fitAddon;
          this.terminal.loadAddon(fitAddon);
          this.terminal.open(this.el);
          fitAddon.fit();
          // send initial size (we need to wait for the first patch)
          this.pushEvent("resize", { cols: this.terminal.cols, rows: this.terminal.rows });
          this.terminal.onResize((size) => this.pushEvent("resize", { cols: size.cols, rows: size.rows }));
          this.terminal.onData((data) => this.pushEvent("terminal", data));
        },
        mounted() {
          this.init();
          this.handleEvent("new-terminal", () => this.init());
          this.handleEvent("terminal", ({ data }) => {
            if (this.terminal) this.terminal.write(data);
          });
          this.resizeHandler = this.handleResize.bind(this);
          window.addEventListener("resize", this.resizeHandler);
          window.addEventListener("terminal-removed", () => {
            this.destroyed();
          }, { once: true })
        },
        getTheme() {
          return {
            background: "#00000000",
            foreground: "#6C696E",
            selectionBackground: "#6C696E70",
            cursor: "#6C696E",
            cursorAccent: "#6C696E",
            black: "#FFFFFF",
            blue: "#775DFF",
            brightBlack: "#A7A5A8",
            brightBlue: "#775DFF",
            brightCyan: "#149BDA",
            brightGreen: "#17AD98",
            brightMagenta: "#AA17E6",
            brightRed: "#D8137F",
            brightWhite: "#322D34",
            brightYellow: "#DC8A0E",
            cyan: "#149BDA",
            green: "#17AD98",
            magenta: "#AA17E6",
            red: "#D8137F",
            white: "#6C696E",
            yellow: "#DC8A0E"
          };
        },
        handleResize() {
          if (this.fitAddon) this.fitAddon.fit();
        },
        destroyed() {
          window.removeEventListener("resize", this.resizeHandler);
        }
      }
    </script>

    <div :if={connected?(@socket)} id="terminal-page" phx-update="ignore" style="height: calc(100vh - 250px); padding: 4px; border: 1px solid #746f97; background: #00000005;">
      <div
        id="terminal"
        phx-hook="TerminalPage"
        style="height: 100%;"
      >
      </div>
    </div>
    """
  end
end
