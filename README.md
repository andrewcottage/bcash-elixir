# Bcash
[![Coverage Status](https://coveralls.io/repos/github/andrewcottage/bcash-elixir/badge.svg?branch=master)](https://coveralls.io/github/andrewcottage/bcash-elixir?branch=master)

Bcash is an API wrapper for the bcash Bitcoin Cash implementation.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `bcash` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:bcash, "~> 0.1.0"}
  ]
end
```

Install and start a bcash server here https://github.com/bcoin-org/bcash

Setup your configuration like this
```
config :bcash, [
  api_key: 12345678,
  port: 18334,
  fee: 1000
]
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/bcash](https://hexdocs.pm/bcash).

# bcash-elixir

You can call into Bcash like this

```
Bcash.create_wallet(wallet_id, passphrase)
```

List of all functions are here https://hexdocs.pm/bcash/Bcash.html#summary
