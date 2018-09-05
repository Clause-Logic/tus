defmodule Tus.Storage do
  @moduledoc false

  @doc false
  def create(%Tus.File{} = file, %{storage: storage} = config) do
    storage.create(file, config)
  end

  @doc false
  def append(%Tus.File{} = file, %{storage: storage} = config, data) do
    storage.append(file, config, data)
  end

  @doc false
  def complete_upload(%Tus.File{} = file, %{storage: storage} = config) do
    storage.complete_upload(file, config)
  end

  @doc false
  def delete(%Tus.File{} = file, %{storage: storage} = config) do
    storage.delete(file, config)
  end

  @doc """
  Get uid file path.
  """
  def file_path(uid, %{storage: storage} = config) do
    storage.file_path(uid, config)
  end

  @doc """
  Get uid file url.
  """
  def url(uid, %{storage: storage} = config) do
    storage.url(uid, config)
  end
end
