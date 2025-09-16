defmodule Membrane.FFmpeg.Transcoder.Adapter do
  @moduledoc """
  Element used to connect outputs of the bin before connecting the input, which
  is known after the transcoder starts producing data and the PMT table is received.

  Waits for a {:stream_format, format} notification that specifies the stream format;
  it is illegal to send buffers through this element before the notification is received.
  """

  use Membrane.Filter

  def_input_pad(:input, accepted_format: _any, flow_control: :auto, availability: :on_request)
  def_output_pad(:output, accepted_format: _any, flow_control: :auto)

  @impl true
  def handle_init(_ctx, _opts) do
    {[], %{stream_format: nil}}
  end

  @impl true
  def handle_buffer(Pad.ref(:input, _id), _buffer, _ctx, %{stream_format: nil}) do
    raise RuntimeError, "not allowed to send buffers before stream_format has been configured"
  end

  def handle_buffer(Pad.ref(:input, _id), buffer, _ctx, state) do
    {[buffer: {:output, buffer}], state}
  end

  @impl true
  def handle_parent_notification({:stream_format, format}, _ctx, state) do
    {[stream_format: {:output, format}], put_in(state, [:stream_format], format)}
  end

  def handle_parent_notification(:close, ctx, state) do
    if ctx.pads.output.end_of_stream? do
      {[], state}
    else
      {[end_of_stream: :output], state}
    end
  end

  @impl true
  def handle_stream_format(_pad, _format, _ctx, state) do
    {[], state}
  end

  @impl true
  def handle_pad_added(Pad.ref(:input, _id), _ctx, state) do
    {[], state}
  end

  @impl true
  def handle_end_of_stream(Pad.ref(:input, _id), ctx, state) do
    if ctx |> inputs_data() |> Enum.all?(& &1.end_of_stream?) do
      {[end_of_stream: :output], state}
    else
      {[], state}
    end
  end

  defp inputs_data(ctx) do
    Enum.flat_map(ctx.pads, fn
      {Pad.ref(:input, _id), data} -> [data]
      _output -> []
    end)
  end
end
