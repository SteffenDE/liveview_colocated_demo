defmodule ColocatedDemoWeb.ColocatedCSS do
  defstruct []
end

defimpl Phoenix.LiveView.TagExtractor, for: ColocatedDemoWeb.ColocatedCSS do
  def extract(_data, _attributes, text_content, meta) do
    %{file: file, line: line, column: column} = meta

    manifest_path = Path.join(File.cwd!(), "assets/css/app.css")
    hashed_name = (:md5 |> :crypto.hash(file) |> Base.encode16()) <> "_#{line}_#{column}"
    dir = "assets/css/colocated"

    File.mkdir_p!(dir)

    File.write!(
      Path.join(dir, "#{hashed_name}.css"),
      scope_css(text_content, "[data-phx-css=#{hashed_name}]")
    )

    if !File.exists?(manifest_path) do
      File.write!(manifest_path, "")
    end

    manifest = File.read!(manifest_path)

    File.open(manifest_path, [:append], fn file ->
      if !String.contains?(manifest, hashed_name) do
        IO.binwrite(
          file,
          ~s|\n@import "./colocated/#{hashed_name}.css";|
        )
      end
    end)

    {:drop, %{hashed_name: hashed_name}}
  end

  defp scope_css(text_content, selector) do
    ast = ColocatedDemoWeb.CSS.CSSParser.parse(text_content)

    ColocatedDemoWeb.CSS.CSSGenerator.generate(ast, %{scope_selector: selector})
  end

  def postprocess_tokens(_data, %{hashed_name: hashed_name}, tokens) do
    Enum.map(tokens, fn
      {:tag, name, attrs, meta} ->
        {:tag, name, add_data_attr(hashed_name, attrs), meta}

      {:local_component, name, attrs, meta} ->
        {:local_component, name, add_data_attr(hashed_name, attrs), meta}

      {:remote_component, name, attrs, meta} ->
        {:remote_component, name, add_data_attr(hashed_name, attrs), meta}

      other ->
        other
    end)
  end

  defp add_data_attr(hashed_name, attrs) do
    [Phoenix.LiveView.TagExtractorUtils.attribute("data-phx-css", hashed_name) | attrs]
  end

  def prune(_data, %{hashed_name: hashed_name}) do
    manifest_path = "assets/css/app.css"
    dir = "assets/css/colocated"

    case File.ls(dir) do
      {:ok, files} ->
        for file <- files do
          if String.starts_with?(file, hashed_name) do
            File.rm!(Path.join(dir, file))

            if File.exists?(manifest_path) do
              new_file =
                manifest_path
                |> File.stream!()
                |> Enum.filter(fn line -> !String.contains?(line, hashed_name) end)
                |> Enum.join("")
                |> String.trim()

              File.write!(manifest_path, new_file)
            end
          else
            :noop
          end
        end

      _ ->
        :noop
    end
  end
end
