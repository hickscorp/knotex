# Knotex

## Statuses

- [Docs as Github Pages](https://hickscorp.github.io/knotex/api-reference.html).
- [![CircleCI Tests](https://circleci.com/gh/hickscorp/knotex.svg?style=svg&circle-token=bffe8f3aedce6ff2bb73a000894e2d7b8acc0109)](https://circleci.com/gh/hickscorp/knotex)
- [![Coverage Status](https://coveralls.io/repos/github/hickscorp/knotex/badge.svg?branch=master)](https://coveralls.io/github/hickscorp/knotex?branch=master)

## Tooling

- To fetch the project dependencies, run `mix deps.get`.
- To compile, run `mix compile`.

Sanity tools:

- To run the tests, issue `mix test`.
- Dialyzer for static analysis: `mix dialyzer`.
- Credo for style: `mix credo`.

You can also generate the docs by running `mix docs` and by then
opening `docs/index.html`.

To generate the documentation, simply run `mix docs` and `open doc/index.html`.

## Blocks

## Nodes

### Overview

Knotex uses the concept of nodes to establish its mesh network and propagate
blocks across it. Because Elixir already has a module named `Node` defining
a VM instance, we decided to name Knotex's nodes a `Knot`. All node-related
code and behavior is therefore located within the [`Knot`](apps/knot) application.

### Quick Setup

If you want to play with Knot and need to understand its basic principles, here
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

```elixir
# Start the node.
Knot.start "tcp://0.0.0.0:4001", Knot.Block.application_genesis()
```

At this point, a node is running on port 4001. Then from whenever you want, even
in another BEAM VM, or on another computer if you adjust the endpoint addresses:

```elixir
# Make sure to use the same genesis block.
# Start another node, on another port...
gina = Knot.start "tcp://0.0.0.0:4002", Knot.Block.application_genesis()
# Connect to the first node we started and start chatting.
Knot.Client.Connector.start gina, "tcp://0.0.0.0:4001"
```

A `mix` task has been put together within the `Knot` application, and will do
exactly that. You can run it by issuing the following command:

```elixir
iex -S mix knot.assert_coms
```

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
You should obtain the following output:

```
16:47:13.427 [info]  [0.0.0.0:4002] Terminating listener: :shutdown.
16:47:13.427 [info]  [0.0.0.0:4001] Terminating listener: :shutdown.
16:47:13.427 [info]  [0.0.0.0:4002] Logic is terminating: shutdown. Notifying 1 client(s)...
16:47:13.427 [info]  [0.0.0.0:4001] Logic is terminating: shutdown. Notifying 1 client(s)...
```

Also see the mix task `knot.start` allowing a  more granular setup, eg:

```
iex -S mix knot.start --bind tcp://0.0.0.0:4001 \
                      --connect tcp://0.0.0.0:4002 \
                      --connect tcp://0.0.0.0:4003
```

## Protocol

### Ping

A simple query can be issued to any running node to ensure that it is up and able
to process queries.

Issuing a `:ping` to a node should yield a `:pong` message in return. This sanity
check process is also useful to ensure that a client doesn't timeout.

### Queries

Nodes answer to queries. Within a query, providing a block hash
identifier is compulsory, except for the `:genesis` and `:head` variations.

A query is always issued using a `{:query, query}` tuple. A block
query when successful would yield a response with content usually equal to
`{:response, {query_atom, response_data}}`.

#### Genesis

- Example: `{:query, :genesis}`
- Success: `{:response, {:genesis, %Block{}}}`

The `:genesis` query returns the genesis block header used by the node to
which the client is connected.

#### Highest

- Example: `{:query, :head}`
- Success: `{:response, {:head, %Block{}}}`

The `:head` query returns the highest block known to the node to which
the client is connected. In most cases, it's the latest mined block, unless it has
not been propagated to the network yet.

When a client queries the highest block from multiple nodes, and if the answers
are different, it's the client's job to perform a sanity check and consider each
fork's strength.

This query has an important role for reaching consensus, see the **Concensus**
paragraph.

#### Merkle Root

- Example: `{:query, {:merkle_root, block_hash}}`
- Success: `{:response, {:merkle_root, ^block_hash, %MerkleRoot{}}}`

This query allows to retrieve the full Merkle chain for any given block using its
hash. When the highest block from two nodes differ, the one with the lowest one
would usually issue this command to determine where exactly it fell out of sync,
allowing correction.

#### Ancestry up to Genesis

- Example: `{:query, {:ancestry, block_hash}}`
- Success: `{:response, {:ancestry, ^block_hash, blocks}}`

Allows to retrieve the full ancestry to a given block, all the way to the genesis
block.

In the response, the `blocks` variable is a list of `%Block{}`, with its first
element being the closest ancestor to the `block_hash` and its last element being
the first child of the genesis block.

## JSON API

Several endpoints are available if you decide to run the phoenix app.
To do so, issue the command `iex -S mix phx.server`. Once your server is up and
running, you can seed your node with simple mining data by issuing:

```
handle  = Knot.start "tcp://127.0.0.1:4001", Knot.Block.application_genesis()
Knot.Logic.seed handle.logic, 128
```


## GraphQL API

A GraphQL is available and the Graphiql tool can
be [accessed here](http://localhost:4000/graphiql).

You can then issue GraphQL queries, for example:

Query:

```graphql
query Block($id: String!, $top: Int) {
  block(id: $id) {
    ...blockFields
    ancestry(top: $top) {...blockFields}
  }
}
fragment blockFields on Block {hash, height}
```

Variables:

```json
{"id": "a", "top": 3}
```