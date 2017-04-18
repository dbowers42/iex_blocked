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

  # Gets the message the GenServer was initialized with
  def message do
     GenServer.call(__MODULE__, :message)
  end

  def done do
    IO.puts "calling done"
    GenServer.cast(__MODULE__, :done)
  end

  def handle_call(:message, _from, state) do
    {:reply, state.message, state}
  end

  def handle_cast(:done, state) do
      IO.puts "Stop tracking"
     {:noreply, state}
  end
end
