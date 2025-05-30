defmodule Tus.Patch do
  @moduledoc """
  """
  import Plug.Conn

  def patch(conn, %{version: version} = config) when version == "1.0.0" do
    with {:ok, %Tus.File{} = file} <- get_file(config),
         :ok <- offsets_match?(conn, file),
         {:ok, data, conn} <- get_body(conn),
         data_size <- byte_size(data),
         :ok <- valid_size?(file, data_size),
         {:ok, file} <- append_data(file, config, data),
         {:ok, file} <- maybe_upload_completed(conn, file, config) do
      conn
      |> put_resp_header("tus-resumable", config.version)
      |> put_resp_header("upload-offset", "#{file.offset}")
      |> resp(:no_content, "")
    else
      :file_not_found ->
        conn |> resp(:not_found, "File not found")

      :offsets_mismatch ->
        conn |> resp(:conflict, "Offset don't match")

      :no_body ->
        conn |> resp(:bad_request, "No body")

      :too_large ->
        conn |> resp(:request_entity_too_large, "Data is larger than expected")

      :too_small ->
        conn |> resp(:conflict, "Data is smaller than what the storage backend can handle")

      {:error, reason} when is_binary(reason) ->
        conn |> resp(:bad_request, reason)

      {:error, _reason} ->
        conn |> resp(:bad_request, "Unable to save file")
    end
  end

  defp maybe_upload_completed(conn, file, config) do
    Tus.Cache.put(file, config)

    if upload_completed?(file) do
      Tus.Storage.complete_upload(file, config)

      callback_result =
        config.on_complete_upload.(conn, file, config)
        |> case do
          {:error, _} = res -> res
          _other -> {:ok, file}
        end

      Tus.Cache.delete(file, config)

      callback_result
    else
      {:ok, file}
    end
  end

  defp get_file(config) do
    case Tus.Cache.get(config) do
      %Tus.File{} = file -> {:ok, file}
      _ -> :file_not_found
    end
  end

  defp offsets_match?(conn, file) do
    if file.offset == get_offset(conn) do
      :ok
    else
      :offsets_mismatch
    end
  end

  defp get_offset(conn) do
    conn
    |> get_req_header("upload-offset")
    |> List.first()
    |> Kernel.||("0")
    |> String.to_integer()
  end

  defp get_body(conn) do
    case read_body(conn) do
      {_, binary, conn} -> {:ok, binary, conn}
      _ -> :no_body
    end
  end

  defp valid_size?(file, data_size) do
    if file.offset + data_size > file.size do
      :too_large
    else
      :ok
    end
  end

  defp append_data(file, config, data) do
    case Tus.Storage.append(file, config, data) do
      {:ok, file} -> {:ok, %Tus.File{file | offset: file.offset + byte_size(data)}}
      {:ok, file, new_offset} -> {:ok, %Tus.File{file | offset: new_offset}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp upload_completed?(file) do
    file.size == file.offset
  end
end
