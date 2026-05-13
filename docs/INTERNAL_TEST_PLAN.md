# Internal Test Plan

Run this before promoting the app from Play Console Internal testing to closed/open/production tracks.

## Devices

Test at least:

- Android 11 or 12 device
- Android 13 device
- Android 14 or 15 device
- One Samsung device if available
- One device with a large local music library

## Install And First Launch

- Install from Play Console Internal testing.
- Launch fresh after install.
- Confirm app icon and app name show as `Playa`.
- Confirm permission prompts are understandable.
- Deny audio permission once and confirm the app handles it gracefully.
- Grant audio permission and confirm library scanning works.

## Playback

- Play a local MP3/M4A/OGG file.
- Pause, resume, seek, skip next, skip previous.
- Reorder queue items.
- Test shuffle and repeat modes.
- Lock the phone and confirm audio continues.
- Use notification controls while locked.
- Use headset/media buttons if available.

## Audiobook Features

- Play a long file.
- Add bookmarks at several timestamps.
- Edit a bookmark note.
- Jump back to a bookmark.
- Restart app and confirm bookmarks persist.

## Library And Playlists

- Create a playlist.
- Add and remove tracks.
- Delete a playlist.
- Check smart playlists update after playing tracks.
- Rate a track and confirm rating persists.

## Lyrics

- Use a track with known lyrics.
- Confirm lyrics lookup succeeds when online.
- Turn off internet and confirm the app fails gracefully.
- Confirm cached lyrics still display if already saved.

## Equalizer

- Open equalizer on an Android device.
- Enable/disable equalizer.
- Move bands and apply presets.
- Confirm unsupported devices do not crash.

## Widget

- Add the Playa home-screen widget.
- Start playback and confirm title/artist/artwork update.
- Rotate device or resize widget if supported.

## External Open With

- From a file manager, open an audio file with Playa.
- Confirm playback starts or queues correctly.

## Battery / Visuals

- Test screensaver/player visuals for a few minutes.
- Confirm no obvious stutter, black screen, or layout overlap.
- Confirm app does not heat the device unusually during normal playback.

## Store Review Notes

Before production:

- Verify privacy policy URL is public.
- Verify Play Data Safety answers match `PRIVACY_POLICY.md`.
- Verify release notes match the uploaded build.
- Verify version code was incremented.
