import 'package:flutter/material.dart';

extension ContextExtensions on BuildContext {
  /// MediaQuery shortcut
  MediaQueryData get mq => MediaQuery.of(this);

  /// Theme shortcut
  ThemeData get theme => Theme.of(this);

  /// Screen size
  double get screenWidth => mq.size.width;
  double get screenHeight => mq.size.height;

  /// Safe area paddings
  double get safeTop => mq.padding.top;
  double get safeBottom => mq.padding.bottom;
  double get safeLeft => mq.padding.left;
  double get safeRight => mq.padding.right;

  /// Orientation
  Orientation get orientation => mq.orientation;
  bool get isPortrait => orientation == Orientation.portrait;
  bool get isLandscape => orientation == Orientation.landscape;

  /// Pixel density & scaling
  double get pixelRatio => mq.devicePixelRatio;
  // double get textScale => mq.textScaleFactor;

  /// Common device types
  bool get isSmallPhone => screenWidth < 380;
  bool get isPhone => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 1024;
  bool get isDesktop => screenWidth >= 1024;

  /// Foldable (experimental)
  bool get isFoldable => screenWidth >= 800;
  bool get isFoldableClosed => screenHeight >= 750 && screenHeight < 800;

  /// Breakpoints (Material Design guidelines)
  bool get isSmallScreen => screenWidth < 600;
  bool get isMediumScreen => screenWidth >= 600 && screenWidth < 1240;
  bool get isLargeScreen => screenWidth >= 1240;

  /// Responsive utility: percentage width/height
  double widthPct(double percent) => screenWidth * percent;
  double heightPct(double percent) => screenHeight * percent;
}
