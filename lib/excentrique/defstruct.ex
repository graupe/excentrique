defmodule Excentrique.Defstruct do
  @moduledoc """
  Unit tests for struct definitions using `Excentrique.Struct.defstruct/1`.

  The implementation mirrors `Kernel.struct/2` behavior for field validation
  while adding extended type specifications.
  """

  defmacro __using__(_args) do
    quote do
      import Kernel, except: [defstruct: 1]
      import Excentrique.Defstruct
    end
  end

  defp parse_field_def({:\\, _, [spec, default]}), do: normalize_spec(spec, default)
  defp parse_field_def(spec), do: parse_field_def({:\\, [], [spec, :__excentrique_forced_key__]})

  defp normalize_spec({:"::", _, [{name, _, nil}, type]}, default), do: {name, type, default}

  @doc ~S"""
  Extends the `Kernel.defstruct` macro to support typed notation similar to
  that of Algae. The implementation is largely compatible with the native
  `Kernel.defstruct`

  ## Example

  The following
  ```elixir
   defmodule Elixir.TestStruct do
     use Excentrique.Defstruct
     defstruct do
       enforced_field :: term()
       another_field :: any() \\ nil
       some_field :: binary() \\ "default_value"
     end
   end
  ```

  gets translated to
  ```elixir
   defmodule Elixir.TestStruct do
     @type t :: %__MODULE__{
                  another_field: any(),
                  some_field: binary(),
                  enforced_field: term()
                }
     defstruct [
       :another_field,
       :enfoced_field,
       some_field: "default_value"
     ]
     @enforce_keys [:enforced_field]
   end
   ```
  """
  defmacro defstruct(do: [{:->, _meta, [args, field_defs]}]) do
    quote do
      defstruct type_args: unquote(args), do: unquote(field_defs)
    end
  end

  defmacro defstruct(do: body) do
    {field_types, enforced_keys, defstruct_args} = parse_do_body(body)

    quote do
      @type t() :: %__MODULE__{unquote_splicing(field_types)}
      @enforce_keys unquote(enforced_keys)
      Kernel.defstruct(unquote(defstruct_args))
    end
  end

  defmacro defstruct(fields) do
    quote do: Kernel.defstruct(unquote(fields))
  end

  defp parse_do_body({:__block__, _meta, field_defs}) do
    parsed =
      for field_def <- field_defs do
        parse_field_def(field_def)
      end

    field_types =
      for {name, type, _default} <- parsed do
        {name, type}
      end

    defstruct_args =
      for {name, _type, default} <- parsed do
        if default === :__excentrique_forced_key__ do
          {name, nil}
        else
          {name, default}
        end
      end

    enforced_keys =
      for {name, _type, :__excentrique_forced_key__} <- parsed do
        name
      end

    {field_types, enforced_keys, defstruct_args}
  end

  defp parse_do_body(body) do
    parse_do_body({:__block__, [], [body]})
  end
end
