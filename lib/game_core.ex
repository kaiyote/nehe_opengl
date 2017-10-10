defmodule GameCore do
  require Record
  Record.defrecordp :wx, Record.extract(:wx, from_lib: "wx/include/wx.hrl")
  Record.defrecordp :wxClose, Record.extract(:wxClose, from_lib: "wx/include/wx.hrl")

  defmodule State, do: defstruct ~w(win object)a

  def start_link, do: start_link []
  def start_link(config), do: :wx_object.start_link __MODULE__, config, []

  def init(config) do
    :wx.new config
    Process.flag :trap_exit, true

    frame = :wxFrame.new :wx.null, :wx_const.wxID_ANY, "NeHe Tutorial Launcher", [size: {300, 300}]
    :wxFrame.show frame
    {frame, %State{win: frame}}
  end

  def load(ref, module), do: :wx_object.call ref, {:load, module}

  def unload(ref), do: :wx_object.call ref, :unload

  def shutdown(ref), do: :wx_object.call ref, :stop

  def handle_info({:EXIT, _, :wx_deleted}, state), do: {:noreply, state}
  def handle_info({:EXIT, _, :normal}, state), do: {:noreply, state}
  def handle_info(msg, state) do
    IO.puts "Info: #{inspect msg}"
    {:noreply, state}
  end

  def handle_call({:load, module}, _from, state) do
    ref = apply module, :start, [[parent: state.win, size: :wxWindow.getClientSize(state.win)]]
    {:reply, ref, %State{state | object: ref}}
  end
  def handle_call(:unload, _from, state) do
    pid = :wx_object.get_pid state.object
    send pid, :stop
    {:reply, :ok, %State{state | object: :undefined}}
  end
  def handle_call(:stop, _from, state), do: {:stop, :normal, state}
  def handle_call(msg, _from, state) do
    IO.puts "Call: #{inspect msg}"
    {:reply, :ok, state}
  end

  def handle_event(wx(event: wxClose()), state) do
    IO.puts "#{inspect self()} Closing window"
    :ok = :wxFrame.setStatusText state.win, "Closing...", []
    {:stop, :normal, state}
  end
  def handle_event(ev, state) do
    IO.puts "#{__MODULE__} Event: #{inspect ev}"
    {:noreply, state}
  end

  def code_change(_, _, state), do: {:stop, :not_yet_implemented, state}

  def terminate(_reason, _state), do: :wx.destroy
end
