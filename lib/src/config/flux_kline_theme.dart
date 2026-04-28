import 'dart:ui';

/// Theme configuration for FluxKline charts.
class FluxKlineTheme {
  const FluxKlineTheme({
    required this.upColor,
    required this.downColor,
    required this.backgroundColor,
    required this.dialogColor,
    required this.cardColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.tertiaryTextColor,
    required this.titleTextColor,
    required this.disableTextColor,
    required this.blackColor,
    required this.dividerColor,
    required this.brandColor,
  });

  /// Up / bullish candle color.
  final Color upColor;

  /// Down / bearish candle color.
  final Color downColor;

  /// Chart background color.
  final Color backgroundColor;

  /// Dialog / overlay background color.
  final Color dialogColor;

  /// Card / border color.
  final Color cardColor;

  /// Primary text color.
  final Color primaryTextColor;

  /// Secondary text color.
  final Color secondaryTextColor;

  /// Tertiary / muted text color.
  final Color tertiaryTextColor;

  /// Title / highlight text color.
  final Color titleTextColor;

  /// Disabled text color.
  final Color disableTextColor;

  /// Black color (used for real-time price text).
  final Color blackColor;

  /// Divider line color.
  final Color dividerColor;

  /// Brand / accent color.
  final Color brandColor;

  /// Dark theme preset.
  factory FluxKlineTheme.dark() {
    return const FluxKlineTheme(
      upColor: Color(0xFF00C076),
      downColor: Color(0xFFFF4D4F),
      backgroundColor: Color(0xFF131722),
      dialogColor: Color(0xFF1E222D),
      cardColor: Color(0xFF2A2E39),
      primaryTextColor: Color(0xFFD1D4DC),
      secondaryTextColor: Color(0xFF787B86),
      tertiaryTextColor: Color(0xFF6A6D78),
      titleTextColor: Color(0xFFFFFFFF),
      disableTextColor: Color(0xFF434651),
      blackColor: Color(0xFF000000),
      dividerColor: Color(0x40FFFFFF),
      brandColor: Color(0xFFF0B90B),
    );
  }

  /// Light theme preset.
  factory FluxKlineTheme.light() {
    return const FluxKlineTheme(
      upColor: Color(0xFF00C076),
      downColor: Color(0xFFFF4D4F),
      backgroundColor: Color(0xFFFFFFFF),
      dialogColor: Color(0xFFF5F5F5),
      cardColor: Color(0xFFE0E3EB),
      primaryTextColor: Color(0xFF131722),
      secondaryTextColor: Color(0xFF787B86),
      tertiaryTextColor: Color(0xFF9598A1),
      titleTextColor: Color(0xFF131722),
      disableTextColor: Color(0xFFB2B5BE),
      blackColor: Color(0xFFFFFFFF),
      dividerColor: Color(0x26000000),
      brandColor: Color(0xFFF0B90B),
    );
  }
}
