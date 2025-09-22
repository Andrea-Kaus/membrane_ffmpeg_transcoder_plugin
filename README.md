# Membrane.FFmpeg.Transcoder
![Hex.pm Version](https://img.shields.io/hexpm/v/membrane_ffmpeg_transcoder_plugin)

Membrane plugin to transcode video into different qualities using FFmpeg and Exile.

## Requirements
- ffmpeg

## Usage

### Basic Multi-Quality Transcoding

```elixir
spec = [
  child(:source, %Membrane.File.Source{location: "input.ts"})
  |> child(:transcoder, Membrane.FFmpeg.Transcoder)
  |> via_out(:video, options: [resolution: {-2, 1080}, bitrate: 6_500_000, fps: 30])
  |> child(:hd_sink, %Membrane.File.Sink{location: "hd.h264"}),

  get_child(:transcoder)
  |> via_out(:video, options: [resolution: {-2, 720}, bitrate: 3_300_000, fps: 30])
  |> child(:sd_sink, %Membrane.File.Sink{location: "sd.h264"}),

  get_child(:transcoder)
  |> via_out(:audio, options: [bitrate: 128_000, sample_rate: 48_000, channels: 2])
  |> child(:audio_sink, %Membrane.File.Sink{location: "audio.aac"})
]
```

### Stream Copy (No Re-encoding)

```elixir
spec = [
  child(:source, %Membrane.File.Source{location: "input.ts"})
  |> child(:transcoder, Membrane.FFmpeg.Transcoder)
  |> via_out(:video, options: [copy: true])
  |> child(:video_sink, %Membrane.File.Sink{location: "video.h264"}),

  get_child(:transcoder)
  |> via_out(:audio, options: [copy: true])
  |> child(:audio_sink, %Membrane.File.Sink{location: "audio.aac"})
]
```

### MP4 Output with Parsers

```elixir
spec = [
  child(:source, %Membrane.File.Source{location: "input.ts"})
  |> child(:transcoder, Membrane.FFmpeg.Transcoder)
  |> via_out(:video, options: [resolution: {-2, 720}, bitrate: 3_300_000])
  |> child(:h264_parser, %Membrane.H264.Parser{output_stream_structure: :avc1})
  |> child(:mp4_muxer, %Membrane.MP4.Muxer.ISOM{fast_start: true})
  |> child(:sink, %Membrane.File.Sink{location: "output.mp4"})
]
```

### Teletext Subtitle Extraction

```elixir
spec = [
  child(:source, %Membrane.File.Source{location: "input_with_teletext.ts"})
  |> child(:transcoder, Membrane.FFmpeg.Transcoder)
  |> via_out(:text, options: [source: {:dvb_teletext, 777}])
  |> child(:subtitle_sink, %Membrane.Testing.Sink{})
]
```

### Video Options
- `resolution`: `{width, height}` (use `-2` for auto-calculated dimension)
- `bitrate`: Maximum bitrate in bits/second
- `fps`: Target framerate
- `profile`: `:baseline`, `:main`, `:high`
- `crf`: Constant rate factor (18-28, lower = higher quality)
- `preset`: `:ultrafast`, `:veryfast`, `:fast`, `:medium`, `:slow`
- `tune`: `:zerolatency`, `:film`, `:animation`
- `gop_size`: GOP size in frames
- `b_frames`: Number of B-frames
- `copy`: Skip re-encoding (boolean)

### Audio Options
- `bitrate`: Target bitrate in bits/second
- `sample_rate`: Sample rate in Hz
- `channels`: Number of audio channels
- `copy`: Skip re-encoding (boolean)

## Features
- buffers come with pts and dts values
- same performance as ffmpeg
- simple API: attach an output with options, that's it (check the test)
- constrains the bitrate
- by adding a Membrane.h264.Parser in the middle, it is compatible with Membrane.MP4.Muxer.CMAF and Membrane.MP4.Muxer.ISOM
- transcodes to AAC and H264

## Copyright and License
Copyright 2024, [KIM Keep In Mind GmbH](https://www.keepinmind.info/)
Licensed under the [Apache License, Version 2.0](LICENSE)

