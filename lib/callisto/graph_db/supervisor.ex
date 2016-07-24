defmodule Callisto.GraphDB.Supervisor do
  @moduledoc false
  use Supervisor

  @doc """
  Starts the repo supervisor.

  Note: most of this is taken from or inspired by Ecto; Florin
  """
  def start_link(repo, otp_app, adapter, opts) do
    opts = config(repo, otp_app, opts)
    name = opts[:name] || Application.get_env(otp_app, repo)[:name] || repo
    IO.inspect(__MODULE__)
    Supervisor.start_link(__MODULE__, {repo, otp_app, adapter, opts}, [name: name])
  end

  @doc """
  Retrieves and normalizes the configuration for `repo` in `otp_app`.
  """
  def config(repo, otp_app, custom) do
    if config = Application.get_env(otp_app, repo) do
      config = Keyword.merge(config, custom)
      {url, config} = Keyword.pop(config, :url)
      [otp_app: otp_app, repo: repo] ++ Keyword.merge(config, parse_url(url || ""))
    else
      raise ArgumentError,
        "configuration for #{inspect repo} not specified in #{inspect otp_app} environment"
    end
  end

  @doc """
  Parses the OTP configuration for compile time.
  """
  def parse_config(repo, opts) do
    otp_app = Keyword.fetch!(opts, :otp_app)
    config  = Application.get_env(otp_app, repo, [])
    adapter = opts[:adapter] || config[:adapter]

    unless adapter do
      raise ArgumentError, "missing :adapter configuration in " <>
                           "config #{inspect otp_app}, #{inspect repo}"
    end

    unless Code.ensure_loaded?(adapter) do
      raise ArgumentError, "adapter #{inspect adapter} was not compiled, " <>
                           "ensure it is correct and it is included as a project dependency"
    end

    {otp_app, adapter, config}
  end

  def parse_url(""), do: []

  def parse_url({:system, env}) when is_binary(env) do
    parse_url(System.get_env(env) || "")
  end

  def parse_url(url) when is_binary(url) do
     info = url |> URI.decode() |> URI.parse()

     if is_nil(info.host) do
       raise "#{url} invalid, missing host"
     end

     # todo: Add more options and validate them too; Florin
     opts = [url: url]

     Enum.reject(opts, fn {_k, v} -> is_nil(v) end)
   end

  ## Callbacks

  def init({repo, _otp_app, adapter, opts}) do
    children = [adapter.child_spec(repo, opts)]
    supervise(children, strategy: :one_for_one)
  end
end
