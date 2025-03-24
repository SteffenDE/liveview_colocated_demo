defimpl Phoenix.LiveView.TagExtractor, for: Map do
  def extract(%{file: filename}, _attributes, text_content, _meta) do
    manifest_path = "assets/js/app.js"
    manifest = File.read!(manifest_path)

    inject = ~s[\nimport "./#{filename}"\n]
    File.write!("assets/js/#{filename}", text_content)

    File.open(manifest_path, [:append], fn file ->
      if !String.contains?(manifest, inject) do
        IO.binwrite(file, inject)
      end
    end)

    {:drop, %{}}
  end

  def postprocess_tokens(_map, %{}, tokens), do: tokens

  def prune(%{file: filename}, %{}) do
    manifest_path = "assets/js/app.js"

    File.rm!(Path.join("assets/js/", filename))

    new_file =
      manifest_path
      |> File.stream!()
      |> Enum.filter(fn line -> String.trim(line) != ~s[import "./#{filename}"] end)
      |> Enum.join("")
      |> String.trim()

    File.write!(manifest_path, new_file)
  end
end
