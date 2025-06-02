defmodule Tus.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Tus.Supervisor]
    Supervisor.start_link(get_children(), opts)
  end

  defp get_children do
    Application.get_env(:tus, :controllers, [])
    |> Enum.map(&child_spec/1)
  end

  defp child_spec(controller) do
    config =
      Application.get_env(:tus, controller)
      |> Enum.into(%{})
      |> Map.put(:cache_name, Module.concat(controller, TusCache))

    {config.cache, config}
  end
end
