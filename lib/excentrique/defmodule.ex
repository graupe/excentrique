defmodule Excentrique.Defmodule do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      import Kernel, except: [defmodule: 2]
      import Excentrique.Defmodule
      :ok
    end
  end

  defmacro defmodule(module_alias, do: body) do
    quote do
      Kernel.defmodule unquote(module_alias) do
        use Excentrique
        unquote(body)
      end
    end
  end

  defmacro defmodule(module_alias, opts) do
    quote do
      Kernel.defmodule(unquote(module_alias), unquote(opts))
    end
  end
end
