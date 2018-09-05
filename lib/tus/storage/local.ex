defmodule Tus.Storage.Local do
  @default_base_path "priv/static/files/"

  def file_path(uid, config) do
    [base_path(config), slice_path(uid, config)]
    |> Path.join()
  end

  def url(uid, config) do
    file_path(uid, config)
    |> local_path(config)
    |> URI.encode()
  end

  @doc """
  Get config base_path.
    Default: #{@default_base_path}
  """
  def base_path(config) do
    config
    |> Map.get(:base_path, @default_base_path)
  end

  defp local_path(path, config) do
    [destination_dir(config), path]
    |> Path.join()
  end

  defp destination_dir(config) do
    config
    |> base_path()
    |> Path.expand()
  end

  @doc false
  def slice_path(uid, %{slice_path: true} = _config) do
    uid
    |> String.split("")
    |> Enum.slice(1, 3)
    |> Enum.concat([uid])
    |> Path.join()
  end

  def slice_path(uid, _config), do: uid

  def make_basepath(filepath) do
    filepath
    |> Path.dirname()
    |> File.mkdir_p!()

    filepath
  end

  def create(%{uid: uid} = file, config) do
    path = file_path(uid, config)

    path
    |> local_path(config)
    |> make_basepath()
    |> File.open!([:write])
    |> File.close()

    %Tus.File{file | path: path}
  end

  def append(%{path: path} = file, config, body) do
    local_path(path, config)
    |> File.open([:append, :binary, :delayed_write, :raw])
    |> case do
      {:ok, filesto} ->
        IO.binwrite(filesto, body)
        File.close(filesto)
        {:ok, file}

      {:error, error} ->
        {:error, error}
    end
  end

  def complete_upload(file, _config) do
    {:ok, file}
  end

  def delete(%{path: path}, config) do
    local_path(path, config)
    |> File.rm()
  end
end
