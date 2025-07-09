defmodule Membrane.FFmpeg.Transcoder do
  @moduledoc """
  Tasks as input an unparsed stream and provides on each pad an unparsed, transcoded stream
  with the desired properties.

  Input might be MPEG-TS or FLV but other streaming containers might work as well. If the
  input stream contains more than 1 video and 1 audio stream, which one will be picked is
  undefined behaviour.
  """
  use Membrane.Bin
  alias Membrane.FFmpeg.Transcoder

  require Membrane.Logger

  # FFmpeg always puts the first MPEGTS stream at this index,
  # the other ones follow.
  @mpeg_ts_sid_index_offset 256

  def_input_pad(:input,
    accepted_format: Membrane.RemoteStream
  )

  def_output_pad(:audio,
    accepted_format: Membrane.RemoteStream,
    availability: :on_request,
    options: [
      copy: [
        spec: boolean(),
        description: "If enabled, the stream will not be re-encoded",
        default: false
      ],
      bitrate: [
        spec: pos_integer(),
        description: "Maximum bitrate",
        default: 128_000
      ],
      sample_rate: [
        spec: pos_integer(),
        default: 48_000
      ],
      channels: [
        spec: pos_integer(),
        default: 2
      ]
    ]
  )

  def_output_pad(:video,
    accepted_format: Membrane.RemoteStream,
    availability: :on_request,
    options: [
      copy: [
        spec: boolean(),
        description: "If enabled, the stream will not be re-encoded",
        default: false
      ],
      resolution: [
        spec: {integer(), integer()},
        description: "Resolution of the given output.",
        default: {-2, 720}
      ],
      bitrate: [
        spec: pos_integer(),
        description: "Maximum bitrate",
        default: 3_300_000
      ],
      profile: [
        spec: atom(),
        description: "H264 Profile",
        default: :high
      ],
      crf: [
        spec: pos_integer(),
        default: 26
      ],
      preset: [
        spec: atom(),
        default: :high
      ],
      tune: [
        spec: atom(),
        default: :zerolatency
      ],
      fps: [
        spec: pos_integer(),
        default: 30
      ],
      gop_size: [
        spec: pos_integer(),
        default: 60
      ],
      b_frames: [
        spec: pos_integer(),
        default: 3
      ],
      level: [
        spec: String.t(),
        default: "3.1"
      ]
    ]
  )

  @impl true
  def handle_init(_ctx, _opts) do
    spec = [
      bin_input()
      |> child(:transcoder, Transcoder.Filter)
      |> child(:demuxer, Membrane.MPEG.TS.Demuxer)
    ]

    {[spec: spec], %{sid_to_pad: %{}}}
  end

  @impl true
  def handle_pad_added(_pad, ctx, _state) when ctx.playback == :playing,
    do:
      raise(
        "New pads can be added to #{inspect(__MODULE__)} only before playback transition to :playing"
      )

  def handle_pad_added(pad, ctx, state) do
    sid = Enum.count(state.sid_to_pad) + @mpeg_ts_sid_index_offset

    spec = [
      # Pad needs to be attached straight away. We use a funnel to allow the
      # playlist to go to playing state, so we can let the demuxer find the pmt
      # table and connect the everything.
      child({:funnel, sid}, Transcoder.Adapter)
      |> bin_output(pad)
    ]

    actions =
      [
        spec: spec,
        notify_child: {:transcoder, {:stream_added, {Pad.name_by_ref(pad), sid}, ctx.pad_options}}
      ]

    state = put_in(state, [:sid_to_pad, sid], pad)
    {actions, state}
  end

  @impl true
  def handle_child_notification(
        {:mpeg_ts_pmt, pmt = %MPEG.TS.PMT{streams: streams}},
        :demuxer,
        _ctx,
        state
      ) do
    Membrane.Logger.debug("PMT table received: #{inspect(pmt)}")
    # We expect a stream in the PMT for each pad attached.
    actions =
      state.sid_to_pad
      |> Enum.flat_map(fn {sid, _pad} ->
        info = Map.fetch!(streams, sid)

        spec = [
          get_child(:demuxer)
          |> via_out(Pad.ref(:output, {:stream_id, sid}))
          |> get_child({:funnel, sid})
        ]

        [
          {:notify_child,
           {{:funnel, sid}, {:stream_format, %Membrane.RemoteStream{content_format: info}}}},
          {:spec, spec}
        ]
      end)

    {actions, state}
  end
end
