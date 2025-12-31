# `Excentrique`

> [!WARNING]
>
> This has been used in my private endeavours. More testing and community
> feed-back would make this production ready.

[![Elixir CI](https://github.com/graupe/excentrique/actions/workflows/elixir.yml/badge.svg)](https://github.com/graupe/excentrique/actions/workflows/elixir.yml)

`Excentrique` contains some syntactic/grammatical extensions for Elixir. Opposed to
other packages that provide some of these features, this package actually
overrides core syntactic elements to give cleaner feel and syntactic editor
support without special treatments.

`Excentrique` is a personal experiment.

## Installation

`Excentrique` is [available on GitHub](https://github.com/graupe/excentrique) and can be installed
by adding `axent` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:excentrique, github: "graupe/excentrique", runtime: false}
  ]
end
```
<!--MODDOC_START-->

## Features

### Function definition (`def`)

Allow the use of `with`-style syntax on the top-level block of a function
definition. By default the `def`-level `else`-block is used in conjunction with
the implicit `try` that wraps the function body. It get's executed when no
errors are being raised.

If no implicit `try` is being wrapped, we instead wrap the function body with a
`with` statement. This allows the use of `<-` assignments on the top-level of
the function body.

For example:

```elixir
defmodule SomeModule do
  use Excentrique
  def some_function(arg) do
    {:ok, value} <- external_function(arg)
    {:ok, value} <- more_function(value) \\ :else_value_123
    value
  else
    {:else_value_123, {:error, reason}} -> {}
    {:error, reason} -> {:error, reason}
  end
end
```

<details>
<summary>Transformed result</summary>

```elixir
defmodule SomeModule do
  def some_function(arg) do
    with {:ok, value} <- external_function(arg),
         {:else_value_123, {:ok, value}} <- {:else_value_123, more_function(value)} do
      value
    else
      {:else_value_123, {:error, reason}} -> {}
      {:error, reason} -> {:error, reason}
     end
  end
end

```

</details>

### Struct definition (`defstruct`) with types

Define a struct, and it's type in one go. This is similar to [Algae
`defdata`](https://hexdocs.pm/algae/Algae.html#defdata/1) but using
`defstruct` and none of the algebraic data type stuff. In addition, this code
is not tested thoroughly, yet. Also, the struct type is always `t() ::
%SomeStruct{...}` without any type arguments. This remains a TODO.

Notable is, that any field, that doesn't have a default value, will be part of
`@enforce_keys`. Defaults are denoted by a `\\` at the end of a field definition.

For example:

```elixir
defmodule SomeStruct do
  use Excentrique
  defstruct do
    id :: non_neg_integer()
    name :: binary() | nil \\ nil
  end
end
```

<details>
<summary>Transformed result</summary>

```elixir
defmodule SomeStruct do
  @type t() :: %SomeStruct{
                 id: non_neg_integer(),
                 name: binary()
               }
  @enforce_keys [:id]
  defstruct [:id, name: nil]
end

```

</details>

The regular syntax of writing `defstruct [:some, :field]` remains in tact.
