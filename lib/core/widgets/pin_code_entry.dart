import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

import '../theme/app_text_styles.dart';
import '../theme/lobby_palette.dart';
import 'app_icon.dart';

/// 6-box code entry with a "Room found!" confirmation state (Blueprint Section
/// 1, Image 2). Reused for the Friends-tab invite-code join flow. Demo:
/// ```dart
/// PinCodeEntry(onCompleted: (code) {}, found: false)
/// ```
class PinCodeEntry extends StatefulWidget {
  const PinCodeEntry({super.key, required this.onCompleted, this.found = false, this.length = 6});

  final ValueChanged<String> onCompleted;
  final bool found;
  final int length;

  @override
  State<PinCodeEntry> createState() => _PinCodeEntryState();
}

class _PinCodeEntryState extends State<PinCodeEntry> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _nodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _nodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _onChanged(int index, String value) {
    if (value.isNotEmpty && index < widget.length - 1) {
      _nodes[index + 1].requestFocus();
    }
    final code = _controllers.map((c) => c.text).join();
    if (code.length == widget.length) {
      widget.onCompleted(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<LobbyPalette>() ?? LobbyPalette.standard;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < widget.length; i++) ...[
              _PinBox(
                controller: _controllers[i],
                focusNode: _nodes[i],
                onChanged: (v) => _onChanged(i, v),
                highlighted: widget.found,
                accent: palette.gradientMid,
              ),
              if (i != widget.length - 1) const SizedBox(width: 8),
            ],
          ],
        ),
        if (widget.found) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon(HugeIcons.strokeRoundedCheckmarkCircle02, color: palette.gradientMid, size: 18),
              const SizedBox(width: 6),
              Text('Room found!', style: AppTextStyles.label.copyWith(color: palette.gradientMid)),
            ],
          ),
        ],
      ],
    );
  }
}

class _PinBox extends StatelessWidget {
  const _PinBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.highlighted,
    required this.accent,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final bool highlighted;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 52,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        textAlign: TextAlign.center,
        maxLength: 1,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: AppTextStyles.headline.copyWith(color: Colors.black87),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: highlighted ? accent.withValues(alpha: 0.12) : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: highlighted ? accent : Colors.black12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: accent, width: 2),
          ),
        ),
      ),
    );
  }
}
