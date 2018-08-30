defmodule Tus.Controller do
  defmacro __using__(_) do
    quote do
      def options(conn, config \\ %{}) do
        Tus.Controller.call_method(__MODULE__, conn, config)
      end

      def head(conn, %{"uid" => uid} = config) do
        Tus.Controller.call_method(__MODULE__, conn, config |> Map.put(:uid, uid))
      end

      def post(conn, config \\ %{}) do
        Tus.Controller.call_method(__MODULE__, conn)
      end

      def patch(conn, %{"uid" => uid} = config) do
        Tus.Controller.call_method(__MODULE__, conn, config |> Map.put(:uid, uid))
      end

      def delete(conn, %{"uid" => uid} = config) do
        Tus.Controller.call_method(__MODULE__, conn, config |> Map.put(:uid, uid))
      end

      def on_begin_upload(_conn, _file, _config) do
        :ok
      end

      def on_complete_upload(_conn, _file, _config) do
      end

      defoverridable on_begin_upload: 3, on_complete_upload: 3
    end
  end

  def call_method(module, conn, config \\ %{}) do
    config = update_config(module, conn, config)
    conn = override_method(conn)

    call_versioned_method(
      conn.method |> String.downcase() |> String.to_atom(),
      conn,
      config
    )
  end

  def update_config(module, conn, config) do
    app_env =
      Application.get_env(:tus, module, [])
      |> Enum.into(%{})
      |> Map.put(:cache_name, Module.concat(module, TusCache))
      |> Map.put(:version, get_version(conn))
      |> Map.put(:on_begin_upload, &module.on_begin_upload/3)
      |> Map.put(:on_complete_upload, &module.on_complete_upload/3)

    Map.merge(app_env, config)
  end

  def get_version(conn) do
    Plug.Conn.get_req_header(conn, "tus-resumable") |> List.first()
  end

  def override_method(conn) do
    override_original_method(conn.method, conn)
  end

  @allowed_methods ~w(OPTIONS HEAD PATCH DELETE)

  def override_original_method("POST", conn) do
    new_method = Plug.Conn.get_req_header(conn, "x-http-method-override") |> List.first()

    if new_method in @allowed_methods do
      %{conn | method: new_method}
    else
      conn
    end
  end

  def override_original_method(_, conn), do: conn

  def call_versioned_method(:options, conn, config) do
    Tus.options(conn, config)
  end

  def call_versioned_method(_method, conn, %{version: nil}) do
    Plug.Conn.resp(conn, :bad_request, "API version not specified")
  end

  def call_versioned_method(method, conn, config) do
    apply(Tus, method, [conn, config])
  end
end
