# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Testing
- `mix test` - Run all tests
- `mix test test/membrane/ffmpeg/transcoder_test.exs` - Run specific test file
- `mix test test/membrane/ffmpeg/transcoder_test.exs:97` - Run specific test line
- `MEMBRANE_LOG_LEVEL=info mix test test/membrane/ffmpeg/transcoder_test.exs:97 --trace` - Run test with detailed logging

### Development
- `mix deps.get` - Install dependencies
- `mix compile` - Compile the project
- `mix format` - Format code

## Architecture

### Core Components

**Membrane.FFmpeg.Transcoder** (`lib/membrane/ffmpeg/transcoder.ex`)
- Main bin component that coordinates transcoding pipeline
- Accepts unparsed streams (MPEG-TS, FLV) and provides transcoded outputs
- Uses dynamic pad creation for multiple quality outputs
- Handles video (:video), audio (:audio), and text (:text) output pads with configurable options

**Membrane.FFmpeg.Transcoder.Filter** (`lib/membrane/ffmpeg/transcoder/filter.ex`)
- Internal filter that interfaces with FFmpeg via erlexec
- Builds complex FFmpeg command lines with filter graphs for multi-output transcoding
- Manages FFmpeg process lifecycle and resource cleanup
- Supports video copy mode, multi-quality transcoding, and teletext subtitle extraction

**Membrane.FFmpeg.Transcoder.Adapter** (`lib/membrane/ffmpeg/transcoder/adapter.ex`)
- Bridges demuxed streams to output pads
- Handles stream format propagation

### Data Flow
1. Input stream → Transcoder.Filter (FFmpeg) → MPEG-TS output
2. MPEG-TS → Membrane.MPEG.TS.Demuxer → Individual streams
3. Demuxed streams → Adapters → Output pads (video/audio/text)

### Key Features
- Multi-quality video transcoding with configurable resolution, bitrate, profile, CRF
- Audio transcoding to AAC with configurable bitrate, sample rate, channels
- Stream copy mode (no re-encoding) for compatible streams
- Teletext subtitle extraction to SRT format
- Stream ID mapping for MPEG-TS compatibility
- Resource guards for clean FFmpeg process termination

### Dependencies
- **erlexec**: Process management for FFmpeg
- **membrane_core**: Core Membrane framework
- **membrane_mpeg_ts_plugin**: MPEG-TS demuxing
- **kim_subtitle**: Subtitle format handling
- Requires **ffmpeg** binary in system PATH

### Test Data
- `test/data/av-sync-test.ts` - Main test video file for transcoding tests
- `test/data/subtitle-test.ts` - Video with teletext subtitles for subtitle extraction tests