require Logger

defmodule TimeTracker do
  use GenServer

  def start_link(message) do
    GenServer.start_link(__MODULE__, %{message: message}, name: __MODULE__)
  end

  # function that outputs the current time every 5 seconds
  def run do
    receive do
    after 5000 -> IO.puts NaiveDateTime.utc_now()
    end

    # This is what is blocking iex
    run() # infinite recursion!
  end

  # Displays the message the GenServer was initialized with
  def message do
     IO.puts GenServer.call(__MODULE__, :message)
  end

  def handle_call(:message, _from, state) do
    {:reply, state.message, state}
  end

  def start(_type, _args) do
    tt_server_node = System.get_env("TT_SERVER_NODE") |> String.to_atom()
    tt_node_type = System.get_env("TT_NODE_TYPE") |> String.to_atom()

    case tt_node_type do
      :server ->
        Logger.info "Running Server #{node()}"
        import Supervisor.Spec, warn: false
        children = [worker(TimeTracker, ["Hello World"])]
        Supervisor.start_link(children, strategy: :one_for_one)
        run()
      :client ->
        Logger.info "Running Client #{node()}"
        Node.connect(tt_server_node)
        {:ok, self()}
    end
  end
end
