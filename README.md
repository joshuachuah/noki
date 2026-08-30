# Noki

A macOS app that turns the MacBook notch into a dynamic island for Spotify: it peeks while a track is loaded and expands on hover to show the track, transport controls, and Pins. Named after 軒 (noki), Japanese for the eave of a roof.

## Setup

The Xcode project is generated from `project.yml` and not checked in.

```sh
brew install xcodegen
xcodegen generate
./script/build_and_run.sh
```

## Language

**Notch**:
The physical camera cutout at the top of the built-in MacBook display. Hardware, not something the app draws.
_Avoid_: island, cutout

**Island**:
The single UI element the app draws around the Notch. It is always in exactly one Island State.
_Avoid_: pill, overlay, notch window, panel

### Island States

**Idle**:
A slim strip flanking the Notch with a moon on the left and a flat Visualizer on the right. It still responds to hover. The Island is Idle when there is no Now Playing, or Now Playing has been paused for 3 minutes or more.
_Avoid_: hidden, collapsed, closed

**Peek**:
A slim strip flanking the Notch (album art on the left, Visualizer on the right), matching the Notch's black. Shown while Now Playing exists and is playing or has been paused for under 3 minutes. Clicking the artwork opens the song in Spotify. Hovering the Visualizer replaces it with play or pause without expanding. Only hovering the space between them enters Expanded.
_Avoid_: compact, mini, collapsed

**Expanded**:
The full panel dropped down from the Notch. Entered by hovering the Notch while Idle or the middle of Peek; exited when the pointer leaves it. Shows Now Playing (art, title, artist, elapsed and remaining time, playback progress) with volume, previous, play/pause, next, and shuffle controls when Now Playing exists, otherwise shows the Pins. Scrolling the volume control adjusts Spotify's volume, and clicking it mutes or restores the previous level. The artwork opens the song and the artist name opens an artist search in Spotify.
_Avoid_: open, hover state, full view

### Music

**Now Playing**:
The track Spotify currently has loaded, whether playing or paused. Absent when Spotify is not running or has no track loaded.
_Avoid_: current track, current song, playing track

**Visualizer**:
The animated bars on the right side of the Peek strip. Decorative: it animates while Now Playing is playing and drops flat when paused. It is not driven by audio. Drawn in the Accent colour.
_Avoid_: equalizer, spectrum, waveform

**Accent**:
The single colour taken from Now Playing's artwork. Used only for the Visualizer and the playback progress bar; text and controls stay white.
_Avoid_: theme colour, tint, brand colour, dominant colour

**Pin**:
A Spotify playlist or album the user has saved to the app by URI so it can be started from the Island in one tap. Pins are chosen by the user, not fetched from Spotify.
_Avoid_: favorite, preset, shortcut, quick play
