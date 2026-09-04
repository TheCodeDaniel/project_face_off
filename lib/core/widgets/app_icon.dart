import 'package:flutter/widgets.dart';
import 'package:hugeicons/hugeicons.dart';

/// Thin wrapper around [HugeIcon] (the `hugeicons` stroke-rounded set — the
/// icon language used everywhere in this app instead of Material's default
/// icon font) so call sites read like the built-in [Icon] widget:
/// `AppIcon(HugeIcons.strokeRoundedZap)`. Falls back to the ambient
/// [IconTheme] for size/color when not given explicitly.
class AppIcon extends StatelessWidget {
  const AppIcon(this.icon, {super.key, this.size, this.color, this.strokeWidth});

  final List<List<dynamic>> icon;
  final double? size;
  final Color? color;
  final double? strokeWidth;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    return HugeIcon(
      icon: icon,
      size: size ?? iconTheme.size ?? 24,
      color: color ?? iconTheme.color,
      strokeWidth: strokeWidth,
    );
  }
}
