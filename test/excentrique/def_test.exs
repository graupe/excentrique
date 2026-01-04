defmodule Excentrique.DefTest do
  use ExUnit.Case, async: false
  doctest Excentrique.Def, import: true

  # the module is only created within the test
  @compile {:no_warn_undefined, [Test]}

  setup do
    if Code.loaded?(Test) do
      module = Test.module_info(:module)
      :code.purge(module)
      :code.delete(module)
    end

    :ok
  end

  @test_ok ~S"""
      defmodule Test do
        use Excentrique.Def

        def test do
          {:ok, value} <- {:ok, :some_value}
          value
        else
          _ -> :error
        end
      end
  """
  @test_ok_private ~S"""
      defmodule Test do
        use Excentrique.Def

        def test, do: testp()

        defp testp do
          {:ok, value} <- {:ok, :some_value}
          value
        else
          _ -> :error
        end
      end
  """

  @test_ok_complex_result ~S"""
      defmodule Test do
        use Excentrique.Def

        def test do
          {:ok, value} <- {:ok, 4}
          if value > 3 do
            :too_large
          else
            value
          end
        else
          _ -> :error
        end
      end
  """
  @test_ok_complex_intermediate ~S"""
      defmodule Test do
        use Excentrique.Def

        def test do
          {:ok, value} <- {:ok, 4}
          value =
            if value > 3 do
              :too_large
            else
              value
            end
          value
        else
          _ -> :error
        end
      end
  """
  @test_ok_no_else ~S"""
      defmodule Test do
        use Excentrique.Def

        def test do
          {:ok, value} <- {:ok, :some_value}
          value
        end
      end
  """
  @test_ok_with_warning ~S"""
      defmodule Test do
        use Excentrique.Def

        def test do
          {:ok, _value} <- {:ok, :some_value}
        else
          _ -> :error
        end
      end
  """

  @test_ok_with_catch_discurage ~S"""
      defmodule Test do
        use Excentrique.Def

        def test do
          {:ok, value} <- {:ok, :some_value}
          :ok
        catch
          _ -> raise "SomeError"
        else
          _ -> :error
        end
      end
  """
  @test_ok_with_rescue_discurage ~S"""
      defmodule Test do
        use Excentrique.Def

        def test do
          {:ok, _value} <- {:ok, :some_value}
          :ok
        rescue
          _ -> raise "SomeError"
        else
          _ -> :error
        end
      end
  """
  @test_error ~S"""
      defmodule Test do
        use Excentrique.Def

        def test(input) do
          {:ok, value} <- input
          value
        else
          _ -> :error
        end
      end
  """
  @test_error_with_reference ~S"""
      defmodule Test do
        use Excentrique.Def

        def test(first, second) do
          {:ok, value1} <- first \\ :first_match
          {:ok, value2} <- second \\ :second_match
          {value1, value2}
        else
          {:first_match, {:error, reason}} -> {:error, "first match failed: #{reason}"}
          {:second_match, {:error, reason}} -> {:error, "second match failed: #{reason}"}
        end
      end
  """
  @test_guard_error_with_reference ~S"""
      defmodule Test do
        use Excentrique.Def

        def test(first, second) do
          str when is_binary(str) <- first \\ :not_binary
          {:ok, value2} <- second \\ :second_match
          {str, value2}
        else
          {:not_binary, value} -> {:error, "guarded match failed, got: #{inspect(value)}"}
          {:second_match, {:error, reason}} -> {:error, "second match failed: #{reason}"}
        end
      end
  """
  @test_normal_def ~S"""
    defmodule Test do
      use Excentrique.Def
      def normal_fn
      def normal_fn, do: :original

      def normal_fn_with_rescue do
        raise "error"
      rescue
        _ -> :error
      end

      def normal_fn_with_rescue_and_catch do
        throw(:something)
      rescue
        _ -> :error
      catch
        :something -> :caught
      end
    end
  """

  describe "Excentrique extended behaviour" do
    test "excentrique def" do
      Code.compile_string(@test_ok)
      assert Test.test() == :some_value
    end

    test "excentrique defp" do
      Code.compile_string(@test_ok_private)
      assert Test.test() == :some_value
    end

    test "excentrique def complex result" do
      Code.compile_string(@test_ok_complex_result)
      assert Test.test() == :too_large
    end

    test "excentrique def complex intermediate" do
      Code.compile_string(@test_ok_complex_intermediate)
      assert Test.test() == :too_large
    end

    test "excentrique def no else" do
      Code.compile_string(@test_ok_no_else)
      assert Test.test() == :some_value
    end

    test "excentrique def error on implicit nil return" do
      assert_raise SyntaxError,
                   ~r"Expected last expression in do-block to be result but got",
                   fn ->
                     Code.compile_string(@test_ok_with_warning)
                   end
    end

    test "excentrique def error on `<-` with `rescue` or `catch`" do
      assert_raise SyntaxError, ~r"Don't mix `rescue` blocks and Excentrique syntax", fn ->
        Code.compile_string(@test_ok_with_rescue_discurage)
      end

      assert_raise SyntaxError, ~r"Don't mix `catch` blocks and Excentrique syntax", fn ->
        Code.compile_string(@test_ok_with_catch_discurage)
      end
    end

    test "excentrique def with :error case" do
      Code.compile_string(@test_error)
      assert Test.test({:ok, :value}) == :value
      assert Test.test(:not_ok) == :error
    end

    test "excentrique def with :error case and `\\\\` reference" do
      Code.compile_string(@test_error_with_reference)

      assert Test.test({:ok, :first_value}, {:ok, :second_value}) ==
               {:first_value, :second_value}

      assert Test.test({:ok, :first_value}, {:error, :second_reason}) ==
               {:error, "second match failed: second_reason"}

      assert Test.test({:error, :first_reason}, {:ok, :first_value}) ==
               {:error, "first match failed: first_reason"}
    end

    test "excentrique def with guard :error case and `\\\\` reference" do
      Code.compile_string(@test_guard_error_with_reference)

      assert Test.test("some binary", {:ok, :second_value}) ==
               {"some binary", :second_value}

      assert Test.test("some binary", {:error, :second_reason}) ==
               {:error, "second match failed: second_reason"}

      assert Test.test(:atom, {:ok, :second_value}) ==
               {:error, "guarded match failed, got: #{inspect(:atom)}"}
    end
  end

  describe "Kernel (default) behaviour" do
    test "standard def behavior preserved" do
      Code.compile_string(@test_normal_def)
      assert Test.normal_fn() == :original
      assert Test.normal_fn_with_rescue() == :error
      assert Test.normal_fn_with_rescue_and_catch() == :caught
    end
  end
end
