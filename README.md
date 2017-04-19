# Running a mix project interactively using IEX
This repository is an example of how to resolve an issue I've encountered
when working with Elixir and IEX in particular. There have been times I have been using IEX as a debugging tool and I find that I can't enter text into IEX. This stumped me at first. I am capturing my experience with resolving this issue in order to solidify my own understanding and possibly help others who also encounter this particular issue.  

#### Here is the scenario:

* Assuming you have a mix project
* The application involves long running processes, possibly running indefinitely
* You would like to run the application interactively with IEX
* When you run the following command on the command line ```iex -S mix``` the application runs, but... You quickly discover that you can't interact with IEX. It does not allow you to type!

This repository demonstrates this problem as well as its resolution.

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

  # Displays the message the GenServer was initialized with
  def message do
     IO.puts GenServer.call(__MODULE__, :message)
  end

  def handle_call(:message, _from, state) do
    {:reply, state.message, state}
  end
end
```

The idea behind these changes is that we can start this server in an IEX session and interact with it while it is still running. For example:

when we run ```iex -S mix``` from the command line

then we try:

```elixir
  iex(1)> TimeTracker.start_link("Hello World")
  {:ok, #PID<0.108.0>}
  iex(2)>TimeTracker.run()
```

The server successfully starts. The current time starts being displayed every 5 seconds, but we can no longer interact with the terminal. This illustrates the problem we are trying to address.

It turns out that when you run an application that involves long running processes in this fashion, the application takes over the terminal that IEX is running in. At this point you can no longer type in IEX or interact with it effectively. You are forced to hit ```ctrl+c``` twice to exit.

#### So how do we fix this?
The key to fixing this is that we need to find a way to separate the IEX session process from the process our application is running.

A strategy for doing this is to create two concurrent IEX sessions that somehow know about each other. It turns out that doing that is actually fairly simple.

Elixir uses something called nodes. Nodes are part of its distributed processing model. More [information about. nodes](http://elixir-lang.org/getting-started/mix-otp/distributed-tasks-and-configuration.html). An IEX session can be associated with a node and nodes can communicate with each other. We can take advantage of nodes to resolve our specific issue. What we need to do is create two IEX session where each session is associated with its own node.

Here is how. We have been using a standard command for running IEX

```iex -S mix```

What would be more helpful would be is to associate an IEX session with a named node. We can use the following command instead.

```iex --name bob@127.0.0.1 -S mix```

and then in a separate terminal window/pane

```iex --name fred@127.0.0.1 -S mix```

We now have 2 independent IEX sessions that each have their own node. We can connect like this.

```elixir
   iex(fred@127.0.0.1)> Node.connect(:"bob@127.0.0.1")
   true
```

We can verify this.

```elixir
   iex(fred@127.0.0.1)> Node.list()
   [:"bob@127.0.0.1"]
```

Notice we are connecting to the opposite node of the one we are on. Connecting to a
node is automatically bi-directional.

```elixir
   iex(bob@127.0.0.1)> Node.list()
   [:"fred@127.0.0.1"]
```
Now we can do this

```elixir
   iex(fred@127.0.0.1)> Node.spawn(:"bob@127.0.0.1", TimeTracker, :start_link, ["Hello World"])
   #PID<13640.117.0>
   iex(fred@127.0.0.1)> Node.spawn(:"bob@127.0.0.1", TimeTracker, :run, [])
```
You will notice that the server now starts outputting the current time every 5 seconds. The server is running in its own process. It is no longer blocking iex!

Now we can try

```elixir
  iex(fred@127.0.0.1)> Node.spawn(:"bob@127.0.0.1", TimeTracker, :message, [])
  Hello World  
```

Every 5 seconds the server will continue outputting the current time, but it will also respond when we request it to display the message the server was initialized with.

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
