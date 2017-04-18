defmodule IexBlocked do
  def start(_type, _args) do
    TimeTracker.start_link("Hello World")
    TimeTracker.run()

    {:ok, self()}
  end
end
