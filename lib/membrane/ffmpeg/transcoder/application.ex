defmodule Membrane.FFmpeg.Transcoder.Application do
  use Application

  alias Membrane.FFmpeg.Transcoder

  def start(_type, _args) do
    children = [
      {Task.Supervisor, name: Transcoder.TaskSupervisor}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Transcoder.Supervisor)
  end
end
