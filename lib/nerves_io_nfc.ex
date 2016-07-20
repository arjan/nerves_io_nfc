defmodule Nerves.IO.NFC do

  @moduledoc """
  Worker module that spawns the NFC poller port process and handles all communication.
  """

  use GenServer

  require Logger

  def start_link(callback) do
    GenServer.start_link(__MODULE__, [callback], name: __MODULE__)
  end


  defmodule State do
    @moduledoc false
    defstruct port: nil, callback: nil
  end

  def init([callback]) do
    Logger.info "NFC worker starting"
    state = %State{callback: callback}
    {:ok, state, 0}
  end

  def handle_info({port, {:data, data}}, state = %State{port: port}) do
    cmd = :erlang.binary_to_term(data)
    handle_cmd(cmd, state)
    {:noreply, state}
  end

  def handle_info({port, {:exit_status, 1}}, state = %State{port: port}) do
    {:stop, {:error, :port_failure}, %State{state | port: nil}}
  end

  def handle_info({port, {:exit_status, s}}, state = %State{port: port}) when s > 1 do
    # restart after 2 sec
    IO.inspect "s: #{inspect s}"
    {:noreply, %State{state | port: nil}, 2000}
  end

  def handle_info(:timeout, state = %State{port: nil}) do
    {:noreply, restart(state)}
  end

  def handle_info(unknown, state) do
    Logger.info "Huh? #{inspect unknown}"
    {:noreply, state}
  end


  defp restart(state) do
    executable = :code.priv_dir(:nerves_io_nfc) ++ '/nfc_poller'
    port = Port.open({:spawn_executable, executable},
                     [{:args, []},
                      {:packet, 2},
                      :use_stdio,
                      :binary,
                      :exit_status])
    IO.inspect "port: #{inspect port}"

    %State{state | port: port}
  end

  defp handle_cmd({:tag, tag}, %State{callback: callback}) when is_function(callback) do
    callback.(tag)
  end

  defp handle_cmd({:tag, tag}, %State{callback: {m, f}}) do
    apply(m, f, [tag])
  end

end
