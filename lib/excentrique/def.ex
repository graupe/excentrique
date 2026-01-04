defmodule Excentrique.Def do
  @moduledoc """
  Provides a `def` macro with extended features over the `Kernel.def` macro.
  """

  defmacro __using__(_opts) do
    quote do
      import Kernel, except: [def: 2, defp: 2]
      import Excentrique.Def
    end
  end

  @doc ~S"""
  Extends the Elixir `def` macro to support `<-` assigments on the top-level
  do-block.

  ## Examples

  The following
  ```elixir
  defmodule TestModule do
    require Logger
    def some_function do
      data when is_binary(data) <- IO.read(:eof)
      computed_data =
        if length(data) > 3 do
          "default"
        else
          data
        end
      some_unrelated_call(computed_data)
      {:ok, value} <- Sketchy.IO.call(computed_data) \\ :sketchy_call
      value
    else
      {:sketchy_call, error} ->
        Logger.warning("Sketchy.IO.call/1 failed: #{inspect(error}")
        ""
      {:error, reason} ->
        Logger.error("IO.read/1 error (rare): #{inspect(reason}")
        ""
      :eof -> ""
    end
  end
  ```

  gets translated to
  ```elixir
  defmodule TestModule do
    require Logger
    def some_function do
      with data when is_binary(data) <- IO.read(:eof),
          computed_data = if(length(data) > 3, do: "default", else: data),
          some_unrelated_call(computed_data),
          {:sketchy_call, {:ok, value}} <- {:sketchy_call, Sketchy.IO.call(computed_data)} do
        value
      else
        {:sketchy_call, error} ->
          Logger.warning("Sketchy.IO.call failed: #{inspect(error}")
          ""
        {:error, reason} ->
          Logger.error("IO.read/1 error (rare): #{inspect(reason}")
          ""
        :eof -> ""
      end
    end
  end
  ```
  """
  defmacro def(definition, opts) do
    opts = def_opts(opts, __CALLER__)

    quote do
      Kernel.def(unquote(definition), unquote(opts))
    end
  end

  defmacro defp(definition, opts) do
    opts = def_opts(opts, __CALLER__)

    quote do
      Kernel.defp(unquote(definition), unquote(opts))
    end
  end

  defp def_opts(opts, caller) do
    if not Keyword.has_key?(opts, :do) or not has_excentrique?(opts[:do]) do
      opts
    else
      deny_block(opts, :catch, caller)
      deny_block(opts, :rescue, caller)

      {result, clauses} = extract_do(opts[:do])

      prepared_clauses = apply_special_forms(clauses)

      deny_implicit_results(result, caller)

      with_block =
        quote do
          # credo:disable-for-next-line Credo.Check.Refactor.WithClauses
          with unquote_splicing(prepared_clauses) do
            unquote(result)
          else
            unquote(else_clauses(opts))
          end
        end

      [do: with_block]
    end
  end

  defp else_clauses(opts) do
    if Keyword.has_key?(opts, :else) do
      opts[:else]
    else
      quote do
        unmatched -> unmatched
      end
    end
  end

  defp apply_special_forms([]), do: []

  defp apply_special_forms([clause | clauses]),
    do: [apply_special_form(clause) | apply_special_forms(clauses)]

  defp apply_special_form({:\\, _meta, [{:<-, meta, [match, expression]}, reference]}),
    do:
      {:<-, meta, [apply_special_form_promote_guards(reference, match), {reference, expression}]}

  defp apply_special_form(clause), do: clause

  defp apply_special_form_promote_guards(reference, {:when, meta, [match | guards]}),
    do: {:when, meta, [{reference, match} | guards]}

  defp apply_special_form_promote_guards(reference, match), do: {reference, match}

  defp extract_do({:__block__, _, expressions}), do: List.pop_at(expressions, -1)
  defp extract_do(otherwise), do: {otherwise, []}

  defp has_excentrique?({:<-, _, _}), do: true
  defp has_excentrique?({:\\, _, [left, _]}), do: has_excentrique?(left)
  defp has_excentrique?({:__block__, _, nodes}), do: Enum.any?(nodes, &has_excentrique?/1)
  defp has_excentrique?(_), do: false

  defp deny_block(opts, block_key, caller) do
    if Keyword.has_key?(opts, block_key) do
      meta =
        case opts[block_key] do
          [{_, meta, _} | _] -> meta
          {_, meta, _} -> meta
          _otherwise -> []
        end

      raise SyntaxError,
        description: "Don't mix `#{block_key}` blocks and Excentrique syntax",
        line: meta[:line],
        column: meta[:column],
        file: caller.file
    end
  end

  defp deny_implicit_results(result, caller) do
    with {:<-, meta, _} <- result do
      raise SyntaxError,
        description:
          "Expected last expression in do-block to be result but got: #{Macro.to_string(result)}",
        line: meta[:line],
        column: meta[:column],
        file: caller.file
    end
  end
end
