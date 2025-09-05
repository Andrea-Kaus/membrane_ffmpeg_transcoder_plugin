defmodule Membrane.FFmpeg.Transcoder.SrtParsingFilter do
  use Membrane.Filter

  def_input_pad(:input,
    accepted_format: Membrane.RemoteStream
  )

  def_output_pad(:output,
    accepted_format: Membrane.Text
  )

  @impl true
  def handle_init(_ctx, _opts) do
    {[], %{partial: []}}
  end

  @impl true
  def handle_stream_format(_pad, _stream_format, _ctx, state) do
    {[stream_format: {:output, %Membrane.Text{}}], state}
  end

  @impl true
  def handle_buffer(:input, buffer, _ctx, state) do
    {cues, partial} =
      case Subtitle.SRT.parse_body([state.partial, buffer.payload]) do
        {:ok, cues} -> {cues, []}
        {:partial, cues, partial} -> {cues, partial}
      end

    {[buffer: {:output, Enum.map(cues, &cue_to_buffer/1)}], %{state | partial: partial}}
  end

  def cue_to_buffer(cue) do
    from = Membrane.Time.milliseconds(cue.from)
    to = Membrane.Time.milliseconds(cue.to)

    %Membrane.Buffer{
      payload: cue.text,
      pts: from,
      metadata: %{to: to, duration: to - from}
    }
  end
end
