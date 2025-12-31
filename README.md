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

The motivation for this package was to have something akin to feature flags for
the Elixir syntax/compiler.

## Installation

`Excentrique` is [available on GitHub](https://github.com/graupe/excentrique) and can be installed
by adding `excentrique` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:excentrique, github: "graupe/excentrique", tag: "1.1.0", runtime: false}
  ]
end
```
<!--MODDOC_START-->

## Features

All features can be activated by including `use Excentrique` in a module's
body. Sub-features can be activated in isolation by including `use
Excentrique.Def` or `use Excentrique.Defstruct`.

If `use Excentrique` was called per default on each file, even if they don't make use of the extended grammar, most, if not all code should still result in the same byte-code as without `use Excentrique`. Exceptions probably being modules that also hook into the core macro-expansion of core language.

### Struct definition (`defstruct`) with types

Motivation: backwards compatible, terse grammar, seamless integration

Define a `struct()` and it's type in one go. This is similar in syntax to what
[Algae `defdata`](https://hexdocs.pm/algae/Algae.html#defdata/1) is doing but we
redefine `defstruct`. Also none of the algebraic datatype stuff. As a caveat
the struct's type is always `t() :: %SomeStruct{...}` without type arguments
that could be passed on use. This might be implemented at some point.

It must be noted that any field, that doesn't have a default value, will be part of
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

### Function definition (`def`) with implicit `with`

Motivation: backwards compatible, make `with` same class citizen as `try`,
better routing for "sad path"

Enables the use of `with`-style syntax on the top-level block of a function
definition. By default the `def`-level `else`-block is used in conjunction with
the implicit `try` that wraps the function body. It get's executed when no
errors are being raised.

If we use the `<-/2` match assignment on the top-level of a do-block of a
"eccentrical" `def` the statements get automatically wrapped into a `with`
clause.

For example:

```elixir
defmodule SomeModule do
  use Excentrique
  def some_function(arg) do
    {:ok, value} <- external_function(arg)
    IO.puts("Make more stuff here")
    {:ok, value} <- more_function(value) \\ :else_value_123
    value
  else
    {:else_value_123, {:error, reason}} -> {:more_function_failed, reason}
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
         IO.puts("Make more stuff here"),
         {:else_value_123, {:ok, value}} <- {:else_value_123, more_function(value)} do
      value
    else
      {:else_value_123, {:error, reason}} -> {:more_function_failed, reason}
      {:error, reason} -> {:error, reason}
     end
  end
end

```

</details>

You cannot mix `rescue` nor `catch` when using the implicit `with` to maintain
some clarity of what the `else` is about: `with` or `try`. An error will be
raised when compiling if in conflict of this rule. That said, regular behaviour
is preserved and you can use `rescue` and `catch` and even `else` in the usual
way if you don't employ any `<-/2` assignments in the top-level body.
