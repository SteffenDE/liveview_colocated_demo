defmodule ColocatedDemoWeb.CSS.CSSGenerator do
  # for demonstration purposes only!
  # original code: https://git.sr.ht/~garrisonc/corp_style/tree/master/item/lib/corp_style/css_generator.ex
  alias ColocatedDemoWeb.CSS.CSSParser

  @type context :: %{
          scope_selector: String.t() | nil,
          variables: %{String.t() => String.t()}
        }

  @doc """
  Generate scoped CSS from the given AST and context.

  The `context` should be a map containing the following:
  - `scope_selector`: the scope selector
  - `variables`: a map of %{String.t => String.t} containing variable name/value pairs
  """
  @spec generate(CSSParser.ast(), context) :: String.t()
  def generate(ast, context) do
    context = Map.put(context, :indentation, 0)
    gen(ast, context)
  end

  defp gen({:css_ast, statements}, ctx) do
    statements_text =
      statements
      |> Enum.map(&gen(&1, ctx))
      |> Enum.join("\n")

    statements_text
  end

  defp gen({:at_rule, identifier, content, statements}, ctx) do
    nested_ctx = %{ctx | indentation: ctx.indentation + 2}
    statements_text = statements |> Enum.map(&gen(&1, nested_ctx)) |> Enum.join("\n")

    content = inject_variables(content, ctx.variables)

    "@#{identifier} #{content} {\n#{statements_text}}\n"
  end

  defp gen({:ruleset, selectors, block}, ctx) do
    ind = String.duplicate(" ", ctx.indentation)
    nl = "\n" <> ind

    selectors_text =
      selectors
      |> Enum.map(fn selector_parts ->
        selector_parts
        |> Enum.map(&scope_selector_part(&1, ctx.scope_selector))
        |> Enum.join(" ")
      end)
      |> Enum.join("," <> nl)

    block =
      block
      |> String.trim()
      |> String.split("\n")
      |> Enum.map(&String.trim/1)
      |> Enum.join(nl <> "  ")
      |> rewrite_variables()

    ind <> selectors_text <> " {" <> nl <> "  " <> block <> nl <> "}" <> "\n"
  end

  defp scope_selector_part(part, nil) when is_binary(part), do: part

  @combinators [">", "~", "+"]

  defp scope_selector_part(part, scope_selector)
       when is_binary(part) and is_binary(scope_selector) do
    case Regex.run(~r"^:global\((.*)\)$", part) do
      [_, match] ->
        if String.contains?(match, ","), do: ":is(#{match})", else: match

      nil ->
        if part in @combinators do
          part
        else
          case String.split(part, "::", parts: 2) do
            # Insert scoped attribute selector before pseudo-elements
            [first, second] -> "#{first}#{scope_selector}::#{second}"
            [part] -> "#{part}#{scope_selector}"
          end
        end
    end
  end

  @variable_regex ~r"\$([a-zA-Z0-9-_]+)"

  defp rewrite_variables(text),
    do: Regex.replace(@variable_regex, text, fn _, name -> "var(--#{name})" end)

  @spec inject_variables(String.t(), %{String.t() => String.t()}) :: String.t()
  def inject_variables(text, variables) when is_binary(text) and is_map(variables) do
    Regex.replace(@variable_regex, text, fn _, name ->
      variables[name] || raise ~s/Unknown variable "#{name}" found!/
    end)
  end
end
