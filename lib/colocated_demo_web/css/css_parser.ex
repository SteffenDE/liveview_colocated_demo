defmodule ColocatedDemoWeb.CSS.CSSParser do
  # for demonstration purposes only!
  # original code: https://git.sr.ht/~garrisonc/corp_style/tree/master/item/lib/corp_style/css_parser.ex

  @moduledoc """
  This module implements a simple CSS parser.

  The parser returns an AST made up of nested tuples
  which is documented via the typespecs declared in this module.
  """

  @type ast :: {:css_ast, [statement]}
  @type statement :: ruleset

  @type at_rule :: {:at_rule, String.t(), String.t(), [statement]}

  @type ruleset :: {:ruleset, [selector], block}
  @type selector :: [String.t()]
  @type block :: String.t()

  @whitespace_chars ~c"\n\t "

  @spec parse(String.t()) :: ast
  def parse(text) do
    statements = scan_ast(text, [])
    statements = Enum.reverse(statements)
    {:css_ast, statements}
  end

  @spec scan_ast(String.t(), [statement]) :: [statement]
  defp scan_ast("", statements) do
    statements
  end

  defp scan_ast(<<c::utf8, rest::binary>>, statements) when c in @whitespace_chars do
    scan_ast(rest, statements)
  end

  defp scan_ast("@" <> rest, statements) do
    {at_rule, text} = parse_at_rule(rest)
    scan_ast(text, [at_rule | statements])
  end

  defp scan_ast(text, statements) do
    {ruleset, text} = parse_ruleset(text)
    scan_ast(text, [ruleset | statements])
  end

  defp parse_at_rule(text) do
    {identifier_buffer, text} = scan_at_rule_identifier(text, [])
    {content_buffer, text} = scan_at_rule_content(text, [])

    "{" <> text = text
    {statements, text} = scan_at_rule_block(text, [])
    "}" <> text = text

    identifier = buffer_to_string(identifier_buffer)
    content = buffer_to_string(content_buffer) |> String.trim()
    statements = Enum.reverse(statements)
    at_rule = {:at_rule, identifier, content, statements}

    {at_rule, text}
  end

  defp scan_at_rule_identifier(" " <> rest, buffer), do: {buffer, rest}
  defp scan_at_rule_identifier("{" <> _ = text, buffer), do: {buffer, text}

  defp scan_at_rule_identifier(<<c::utf8, rest::binary>>, buffer),
    do: scan_at_rule_identifier(rest, [c | buffer])

  defp scan_at_rule_content("{" <> _ = text, buffer), do: {buffer, text}

  defp scan_at_rule_content(<<c::utf8, rest::binary>>, buffer),
    do: scan_at_rule_content(rest, [c | buffer])

  defp scan_at_rule_block("}" <> _ = text, statements), do: {statements, text}

  defp scan_at_rule_block(<<c::utf8, rest::binary>>, statements) when c in @whitespace_chars do
    scan_at_rule_block(rest, statements)
  end

  defp scan_at_rule_block(text, statements) do
    {ruleset, text} = parse_ruleset(text)
    scan_at_rule_block(text, [ruleset | statements])
  end

  @spec parse_ruleset(String.t()) :: {ruleset, String.t()}
  defp parse_ruleset(text) do
    {selectors, text} = parse_selector_group(text)
    "{" <> text = text
    {block_buffer, text} = scan_ruleset_block(text, [])
    "}" <> text = text

    block = buffer_to_string(block_buffer)
    ruleset = {:ruleset, selectors, block}

    {ruleset, text}
  end

  defp parse_selector_group(text) do
    {selectors, text} = scan_selector_group(text, [])

    selectors =
      selectors
      |> Enum.map(fn selector_parts ->
        selector_parts
        |> Enum.filter(&(&1 != []))
        |> Enum.map(&buffer_to_string/1)
        |> Enum.map(&String.trim/1)
        |> Enum.reverse()
      end)
      |> Enum.reverse()

    {selectors, text}
  end

  defp scan_selector_group("{" <> _ = text, selectors), do: {selectors, text}
  defp scan_selector_group("," <> rest, selectors), do: scan_selector_group(rest, selectors)
  defp scan_selector_group(" " <> rest, selectors), do: scan_selector_group(rest, selectors)

  defp scan_selector_group(text, selectors) do
    {selector, text} = scan_selector(text, [], [])
    scan_selector_group(text, [selector | selectors])
  end

  defp scan_selector(<<c::utf8, _::binary>> = text, parts, buffer) when c in ~c"{,",
    do: {[buffer | parts], text}

  defp scan_selector(" " <> rest, parts, buffer), do: scan_selector(rest, [buffer | parts], [])

  defp scan_selector("(" <> rest, parts, buffer) do
    # Scans until parentheses are balanced to ignore commas inside selectors, e.g. :is(.one, .two)
    {parens_content, text} = scan_parens_content(rest, [])
    scan_selector(text, parts, [parens_content | ["(" | buffer]])
  end

  defp scan_selector(<<c::utf8, rest::binary>>, parts, buffer),
    do: scan_selector(rest, parts, [c | buffer])

  defp scan_ruleset_block("}" <> _rest = text, buffer), do: {buffer, text}

  defp scan_ruleset_block(<<c::utf8, rest::binary>>, buffer),
    do: scan_ruleset_block(rest, [c | buffer])

  defp scan_parens_content(")" <> _ = text, buffer), do: {buffer, text}

  defp scan_parens_content("(" <> rest, buffer) do
    # Recursively scan nested parentheses
    {sub_buffer, text} = scan_parens_content(rest, [])
    ")" <> text = text
    buffer = [")" | [sub_buffer | ["(" | buffer]]]
    scan_parens_content(text, buffer)
  end

  defp scan_parens_content(<<c::utf8, rest::binary>>, buffer),
    do: scan_parens_content(rest, [c | buffer])

  @spec buffer_to_string(iolist) :: String.t()
  defp buffer_to_string(buffer) do
    buffer
    |> IO.chardata_to_string()
    |> String.reverse()
  end
end
