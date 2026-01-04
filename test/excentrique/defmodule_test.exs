defmodule Excentrique.DefmoduleTest do
  use ExUnit.Case, async: false
  doctest Excentrique.Defmodule, import: true

  test "Excentrique extended behaviour" do
    Code.compile_string(~S"""
    use Excentrique
    defmodule Excentrique.DefmoduleTest.Test do
      default_value = 10
      defstruct do
        excentrique :: any() \\ %{default_value: default_value}
      end
    end
    """)
  end
end
