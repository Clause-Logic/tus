defmodule Tus.Cache do
  @moduledoc false

  @doc false
  def get(%{cache: cache, cache_name: cache_name, uid: uid}) do
    cache.get(cache_name, uid)
  end

  @doc false
  def put(%Tus.File{uid: uid} = file, %{cache: cache, cache_name: cache_name}) do
    cache.put(cache_name, uid, file)
  end

  @doc false
  def delete(%Tus.File{uid: uid}, %{cache: cache, cache_name: cache_name}) do
    cache.delete(cache_name, uid)
  end
end
