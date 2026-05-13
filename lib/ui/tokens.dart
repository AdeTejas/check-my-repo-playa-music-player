// Shared UI design tokens
import 'package:flutter/widgets.dart';

const double kSp = 8.0; // 8pt grid
const double kRadius = 14.0;
const double kNavHeight = 72.0;

// Typography (keep compact + consistent)
const double kTextXs = 12.0;
const double kTextSm = 14.0;
const double kTextMd = 16.0;
const double kTextLg = 18.0;
const double kTextXl = 20.0;

// Icons
const double kIconSm = 20.0;
const double kIconMd = 24.0;
const double kIconLg = 28.0;

// Common paddings
const EdgeInsets kPadScreen = EdgeInsets.all(kSp * 2);
const EdgeInsets kPadScreenCompactX = EdgeInsets.symmetric(
  horizontal: kSp * 1.5,
);

const kColorBg = Color(0xFF010104);
const kColorSurface = Color(0xFF090A0E);
const kColorCard = Color(0xFF11131A);
const kColorOn = Color(0xFFFFE7D0); // Saturated warm paper text
const kColorOn2 = Color(0xFFC89B73); // Rich bronze secondary text
const kColorAppAccent = Color(0xFFB11226); // Imperial red accent

// Glass tints (no blur):
// - BlackTint: default glass surface
// - Clear: for bottom nav / subtle overlays
const kColorGlassBlackTint = Color(0x66010104);
const kColorGlassClear = Color(0x1A010104);
