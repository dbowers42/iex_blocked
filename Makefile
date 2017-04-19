server:
	TT_NODE_TYPE=server TT_SERVER_NODE=bob@127.0.0.1 iex --name bob@127.0.0.1 -S mix

client:
	TT_NODE_TYPE=client TT_SERVER_NODE=bob@127.0.0.1 iex --name fred@127.0.0.1 -S mix
