defmodule Excentrique do
  @moduledoc ~S"""
  > #### WARNING {: .warning}
  >
  > This has been used in my private endeavours. More testing and community
  > feed-back would make this production ready.

  Excentrique contains some syntactic/grammatical extensions for Elixir. Opposed to
  some other packages that provide similar functionality, this package actually
  overrides core syntactic elements.

  Excentrique is a personal experiment.

  Use it in your project by adding it to your `mix.exs` dependencies
  ```elixir
  def deps do
    [
      {:excentrique, github: "graupe/excentrique", tag: "1.1.0", runtime: false}
    ]
  end
  ```
  and invoking it in your modules of choice
  ```elixir
  defmodule SomeModule do
    use Excentrique
    ...
  end
  ```
  """

  defmacro __using__(_opts) do
    if __CALLER__.module do
      quote do
        use Excentrique.Defstruct
        use Excentrique.Def
      end
    else
      quote do
        use Excentrique.Defmodule
      end
    end
  end
end
