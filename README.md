# Running a mix project interactively using IEX
This repository is an example of how to resolve a problem I've encountered
when working with Elixir and IEX in particular. There have been times I have been using IEX as a debugging tool and I find that I can't enter text into IEX. This issue stumped me when I first encountered it and I am sure I am not the only one that has run across it. I am capturing my own experience with this issue in order solidify my own understanding and possibly help others who also encounter this particular issue.  

#### Here is the scenario:

* Assuming you have a mix project
* The application involves long running processes, possibly running indefinitely
* You would like to run the application interactively with IEX
* When you run the following command on the command line ```iex -S mix``` the application runs, but... You quickly discover that you can't interact with IEX. It does not allow you to type!

This repository demonstrates this problem as well as its resolution. Cloning this repository or browsing the source code may help create some understanding around this issue.

#### So what is going on here?
Let's start by replicating the problem. Let's suppose we want to create a server that outputs the current time every 5 seconds. We might start to define it using something like this.

```elixir
defmodule TimeTracker do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  # function that outputs the current time every 5 seconds
  def run do
    receive do
    after 5000 -> IO.puts NaiveDateTime.utc_now()
    end
    run()
  end
end
```
We might also create another module to run this server that might look something like this.

```elixir
defmodule IexBlocked do
  def start(_type, _args) do
    TimeTracker.start_link()
    TimeTracker.run()

    {:ok, self()}
  end
end
```

We then decide that we would really like this server to be initialized with some sort of message that can be recovered and displayed later while the server is still running. We modify the start_link function to take a parameter.
```elixir
defmodule TimeTracker
use GenServer
...
def start_link(message) do
  GenServer.start_link(__MODULE__, %{message: message}, name: __MODULE__)
end
...
end
```

We add additional code to recover and display the message. We end up with.

```elixir
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

    run()
  end

  # Gets the message the GenServer was initialized with
  def message do
     GenServer.call(__MODULE__, :message)
  end

  def handle_call(:message, _from, state) do
    {:reply, state.message, state}
  end
end
```

The idea behind these changes is that we can start this application in an IEX session using ```iex -S mix``` and interact with the server while it is still running. We intend to call ```TimeTracker.message()``` and expect the message the GenServer was started with should output to the terminal. When this is attempted, we don't get the behavior hoped for. We can't enter text in the IEX session, so we can't make the
```TimeTracker.message()``` call. This illustrates the problem we are trying to address.

It turns out that when you run an application that involves long running processes in this fashion, the application takes over the terminal that IEX is running in. At this point you can no longer type in IEX or interact with it effectively. You are forced to hit ```ctrl+c``` twice to exit.

#### So how do we fix this?
The key to fixing this is that we need to find a way to separate the IEX session process from the process our application is running.

A strategy for doing this is to some how create two concurrent IEX sessions that somehow know about each other. It turns out that doing that is actually fairly simple.

It turns out that Elixir uses something called nodes. Nodes are part of its distributed processing model. More [information about nodes](http://elixir-lang.org/getting-started/mix-otp/distributed-tasks-and-configuration.html). We can take advantage of nodes to resolve our specific issue. Here is how. We have been using a standard command for running IEX

```iex -S mix```

What would be more helpful would be is to associate an IEX session with named node. We can use the following command instead

```iex --name bob@127.0.0.1

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `iex_blocked` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:iex_blocked, "~> 0.1.0"}]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/iex_blocked](https://hexdocs.pm/iex_blocked).
