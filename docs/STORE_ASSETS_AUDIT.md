# Store Assets Audit

Google Play preview asset requirements should be checked in Play Console before final upload, but the current official guidance says:

- App icon: 512 x 512 PNG, maximum 1024 KB.
- Feature graphic: 1024 x 500 JPEG or 24-bit PNG with no alpha.
- Screenshots: JPEG or 24-bit PNG with no alpha, minimum dimension 320 px, maximum dimension 3840 px, and the long side cannot be more than twice the short side.
- Store listing needs at least two screenshots. Four or more high-quality phone screenshots are strongly recommended.

Sources:

- https://support.google.com/googleplay/android-developer/answer/1078870
- https://support.google.com/googleplay/android-developer/answer/9866151

## Existing Root Images

| File | Size | Notes |
| --- | ---: | --- |
| `reference_turntable.jpg` | 932 x 733 | Not a phone screenshot. Useful only as reference material. |
| `roci.jpg` | 1920 x 1080 | Landscape image; not clearly an app screenshot. |
| `roci.png` | 26639 x 14985 | Too large for Play screenshot max dimension. Do not upload as-is. |
| `Screenshot 2025-11-18 021327.png` | 1096 x 767 | Not a standard phone portrait screenshot. |
| `Screenshot 2025-11-18 115719.png` | 2159 x 1820 | Valid dimensions, but not standard phone portrait. Review content before upload. |
| `Screenshot 2025-11-18 121206.png` | 1199 x 1414 | Valid dimensions. Review content before upload. |
| `Screenshot 2025-11-21 191010.png` | 1060 x 388 | Long side is more than twice the short side; not suitable as-is. |
| `Screenshot_20251120_094620.jpg` | 3147 x 906 | Long side is more than twice the short side; not suitable as-is. |
| `wood.jpg` | 896 x 1942 | Long side is more than twice the short side; not suitable as-is. |

## Recommendation

Do not rely on the current root screenshots for final Play Store marketing. Capture fresh screenshots from the signed/internal Android build.

Best set:

- 4-8 portrait phone screenshots, ideally 1080 x 1920 or similar 9:16.
- 1 feature graphic at exactly 1024 x 500.
- 1 app icon at exactly 512 x 512 and under 1024 KB.

Screenshot content should show only the app UI. Avoid private music libraries, private notifications, email addresses, file paths, and copyrighted album art you cannot use for marketing.
