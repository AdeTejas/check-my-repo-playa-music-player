# Play Console Data Safety Guide

Use this as a guide when filling Play Console. Treat the Play Console wording as the source of truth if Google changes the form.

## Data Collection

Suggested answer: the app does not collect data to your own server.

Playa stores library metadata, playlists, bookmarks, ratings, settings, play counts, cached lyrics, and performance/error diagnostics locally on the user's device.

## Data Shared With Third Parties

Suggested disclosure: lyrics lookup may send limited song query details to LRCLIB.

When the lyrics feature is used, Playa may send:

- Song title
- Artist name
- Track duration

Purpose: app functionality, to find synced or plain lyrics.

Third party: LRCLIB (`lrclib.net`).

The app does not send local audio files, playlists, bookmarks, ratings, settings, or the user's full library to LRCLIB.

## Security Practices

- Data is stored locally on device.
- No account required.
- No advertising SDKs.
- No in-app purchases in the current repo state.
- No custom backend operated by the app owner.

## Permissions To Explain

- `READ_MEDIA_AUDIO`: scan and play local audio files.
- `READ_EXTERNAL_STORAGE` with `maxSdkVersion=32`: support older Android versions.
- `POST_NOTIFICATIONS`: show background playback controls.
- `FOREGROUND_SERVICE` and `FOREGROUND_SERVICE_MEDIA_PLAYBACK`: keep playback controls active while audio plays.
- `WAKE_LOCK`: support uninterrupted playback behavior.
- `INTERNET`: optional lyrics lookup.

## Suggested App Access Answer

All app functionality is available without a login. No special credentials are required for Play review.

## Suggested Ads Answer

No, the app does not contain ads.

## Suggested Target Audience

General audience. The app is a local music and audiobook player and does not target children.

## Suggested Content Rating Notes

The app plays user-owned local audio files. Content depends on the user's own library. The app itself does not provide streaming music, social features, user-generated uploads, gambling, or shopping.
