defmodule Lesson02 do
  @behaviour :wx_object
  use Bitwise, only_operators: true
  require Record
  Record.defrecordp :wx, Record.extract(:wx, from_lib: "wx/include/wx.hrl")
  Record.defrecordp :wxSize, Record.extract(:wxSize, from_lib: "wx/include/wx.hrl")

  defmodule State, do: defstruct ~w(parent config canvas timer time)a

  def start(config), do: :wx_object.start_link __MODULE__, config, []

  def init(config), do: :wx.batch fn -> do_init config end

  def do_init(config) do
    parent = :proplists.get_value :parent, config
    size = :proplists.get_value :size, config
    opts = [size: size, style: :wx_const.wxSUNKEN_BORDER]
    gl_attrib = [
      attribList: [
        :wx_const.wx_GL_RGBA,
        :wx_const.wx_GL_DOUBLEBUFFER,
        :wx_const.wx_GL_MIN_RED, 8,
        :wx_const.wx_GL_MIN_GREEN, 8,
        :wx_const.wx_GL_MIN_BLUE, 8,
        :wx_const.wx_GL_DEPTH_SIZE, 24, 0
      ]
    ]
    canvas = :wxGLCanvas.new parent, opts ++ gl_attrib
    :wxWindow.hide parent
    :wxWindow.reparent canvas, parent
    :wxWindow.show parent
    :wxGLCanvas.setCurrent canvas
    setup_gl canvas
    timer = :timer.send_interval 20, self, :update

    {parent, %State{parent: parent, config: config, canvas: canvas, timer: timer}}
  end

  # GLvoid ReSizeGLScene(GLsizei w, GLsizei h)
  def handle_event(wx(event: wxSize(size: {w, h})), state) when 0 in [w, h], do: {:noreply, state}
  def handle_event(wx(event: wxSize(size: {w, h})), state) do
    resize_gl_scene w, h
    {:noreply, state}
  end

  def handle_info(:update, state) do
    :wx.batch fn -> render state end
    {:noreply, state}
  end

  def handle_info(:stop, state) do
    :timer.cancel state.timer
    try do
      :wxGLCanvas.destroy state.canvas
    catch
      error, reason -> {error, reason}
    end
    {:stop, :normal, state}
  end

  def handle_call(msg, _from, state) do
    IO.puts "Call: #{inspect msg}"
    {:reply, :ok, state}
  end

  def code_change(_, _, state), do: {:stop, :not_yet_implemented, state}

  def terminate(_reason, state) do
    try do
      :wxGLCanvas.destroy state.canvas
    catch
      error, reason -> {error, reason}
    end
    :timer.cancel state.timer
    :timer.sleep 300
  end

  def resize_gl_scene(width, height) do
    :gl.viewport 0, 0, width, height
    :gl.matrixMode :gl_const.gl_PROJECTION
    :gl.loadIdentity
    :glu.perspective 45.0, width / height, 0.1, 100.0
    :gl.matrixMode :gl_const.gl_MODELVIEW
    :gl.loadIdentity
  end

  # int InitGL(GLvoid)
  def setup_gl(win) do
    {w, h} = :wxWindow.getClientSize win # oddly, you need to do this or resizing doesn't happen. period.
    resize_gl_scene w, h # and you need to do this, or OpenGL doesn't actually display?
    :gl.shadeModel :gl_const.gl_SMOOTH
    :gl.clearColor 0.0, 0.0, 0.0, 0.0
    :gl.clearDepth 1.0
    :gl.enable :gl_const.gl_DEPTH_TEST
    :gl.depthFunc :gl_const.gl_LEQUAL
    :gl.hint :gl_const.gl_PERSPECTIVE_CORRECTION_HINT, :gl_const.gl_NICEST
    :ok
  end

  def render(state) do
    draw()
    :wxGLCanvas.swapBuffers state.canvas
  end

  # int DrawGLScene(GLvoid)
  def draw do
    :gl.clear :gl_const.gl_COLOR_BUFFER_BIT ||| :gl_const.gl_DEPTH_BUFFER_BIT
    :gl.loadIdentity

    :gl.translatef -1.5, 0.0, -6.0
    :gl.begin :gl_const.gl_TRIANGLES
    :gl.vertex3f 0.0, 1.0, 0.0
    :gl.vertex3f -1.0, -1.0, 0.0
    :gl.vertex3f 1.0, -1.0, 0.0
    :gl.end
    :gl.translatef 3.0, 0.0, 0.0
    :gl.begin :gl_const.gl_QUADS
    :gl.vertex3f -1.0, 1.0, 0.0
    :gl.vertex3f 1.0, 1.0, 0.0
    :gl.vertex3f 1.0, -1.0, 0.0
    :gl.vertex3f -1.0, -1.0, 0.0
    :gl.end

    :ok
  end
end
