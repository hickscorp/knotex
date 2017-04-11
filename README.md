# Blockade

## Tooling

A [sublime project](blockade.sublime-project) is provided with proper exclusions
and tooling, including:

- Compile (Pretty much just runs `mix compile`),
- Test (Runs the `ExUnit` suite),
- Dializer (Static code analysis),
- Credo (Lints and reports style issues),
- Dogma (Even stricter linting).

Those tools have correct regex extraction defined and will highlight the problematic
bits of code when you run them.

## Blocks

Blockchains are built around the concept of blocks. In Blockade, the
[`Block`](apps/block) application.

## Nodes

### Overview

Blockade uses the concept of nodes to establish its mesh network and propagate
blocks across it. Because Elixir already has a module named `Node` defining
a VM instance, we decided to name Blockade's nodes a `Knot`. All node-related
code and behavior is therefore located within the [`Knot`](apps/knot) application.

The [`Knot`](apps/knot) extensively uses blocks under the hood, so it is linked to
the [`Block`](apps/block) through dependency in its [`mix`](apps/knot/mix.exs)
file.

### Quick Setup

If you want to play with Blockade and need to understand its basic principles, here
is how to get started.

First you'll need to start at least two nodes. A node is started using the
[`Knot.start/1`](apps/knot/lib/knot.ex) function, its only argument being an URI.
It returns a `%Knot.Handle{}`, containing useful information to later interact with
this node:

      %Knot.Handle{uri: ..., listener: ..., logic: ..., node: ...}

Once two nodes are running, you can get one to connect to the other using
the [`Knot.Client.Connector.start/2`](apps/knot/lib/knot/client/connector.ex)
function. It takes the URI to connect to as well as the running node `Knot.Logic`
instance to be used to handle messages.

To summarize:

      # Starts a node listening on local addresses, port 4001:
      pierre = Knot.start "tcp://0.0.0.0:4001"
      # Starts a node listening on local addresses, port 4002:
      gina = Knot.start "tcp://0.0.0.0:4002"
      # Connect Gina's node to Pierre's:
      Knot.Client.Connector.start pierre.uri, gina.logic

A `mix` task has been put together within the `Knot` application, and will do
exactly that. You can run it by issuing the following command:

      iex -S mix knot.assert_coms

You should start seeing messages in the `iex` console indicating that Gina's node
is issuing `:ping` messages, and Pierre's node is responding with `:pong` messages:

```
Erlang/OTP 19 [erts-8.3] [source] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false]
Interactive Elixir (1.4.4) - press Ctrl+C to exit (type h() ENTER for help)

15:42:39.215 [info]  Starting an ETS backed store.
15:42:39.239 [info]  [0.0.0.0:4001] Starting logic.
15:42:39.241 [info]  [0.0.0.0:4001] Starting listener.
15:42:39.246 [info]  [0.0.0.0:4002] Starting logic.
15:42:39.246 [info]  [0.0.0.0:4002] Starting listener.
15:42:39.249 [info]  [0.0.0.0:4002] New outbound client socket.
15:42:39.249 [info]  [0.0.0.0:4001] New inbound client socket.
15:42:39.777 [info]  [0.0.0.0:4001] Received ping at 1495896159 from #PID<0.203.0>.
15:42:39.777 [info]  [0.0.0.0:4002] Received pong from #PID<0.206.0>.
15:42:44.763 [info]  [0.0.0.0:4001] Received ping at 1495896164 from #PID<0.203.0>.
15:42:44.763 [info]  [0.0.0.0:4002] Received pong from #PID<0.206.0>.
```

When you're done testing, you can issue `:init.stop()` so all process exit cleanly
and no port is left open on a deadlock by the BEAM VM.
