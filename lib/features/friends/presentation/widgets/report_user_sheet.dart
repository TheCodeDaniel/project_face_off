import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/lobby_palette.dart';
import '../../../../core/widgets/primary_pill_button.dart';
import '../../domain/report_reason.dart';
import '../friends_providers.dart';

/// Report flow (master prompt Section 9): reason selection is required, an
/// optional free-text detail field, submitted for later moderation review —
/// no automated moderation pipeline for v1, just reliable capture.
class ReportUserSheet extends ConsumerStatefulWidget {
  const ReportUserSheet({super.key, required this.userId, required this.displayName});

  final String userId;
  final String displayName;

  static Future<void> show(BuildContext context, {required String userId, required String displayName}) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportUserSheet(userId: userId, displayName: displayName),
    );
  }

  @override
  ConsumerState<ReportUserSheet> createState() => _ReportUserSheetState();
}

class _ReportUserSheetState extends ConsumerState<ReportUserSheet> {
  ReportReason? _reason;
  final _detailsController = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reason;
    if (reason == null) return;
    await ref.read(friendsRepositoryProvider).reportUser(widget.userId, reason, _detailsController.text.trim());
    if (mounted) setState(() => _submitted = true);
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<LobbyPalette>() ?? LobbyPalette.standard;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
          child: _submitted ? _ThankYou(displayName: widget.displayName) : _buildForm(palette),
        ),
      ),
    );
  }

  Widget _buildForm(LobbyPalette palette) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)),
          ),
        ),
        const SizedBox(height: 20),
        Text('Report ${widget.displayName}', style: AppTextStyles.headline.copyWith(color: Colors.black87)),
        const SizedBox(height: 16),
        RadioGroup<ReportReason>(
          groupValue: _reason,
          onChanged: (v) => setState(() => _reason = v),
          child: Column(
            children: [
              for (final reason in ReportReason.values)
                RadioListTile<ReportReason>(
                  value: reason,
                  activeColor: palette.gradientStart,
                  contentPadding: EdgeInsets.zero,
                  title: Text(reason.label, style: AppTextStyles.body.copyWith(color: Colors.black87)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _detailsController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Additional details (optional)',
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.04),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 20),
        PrimaryPillButton(label: 'Submit Report', onPressed: _reason == null ? null : _submit),
      ],
    );
  }
}

class _ThankYou extends StatelessWidget {
  const _ThankYou({required this.displayName});

  final String displayName;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Report submitted', style: AppTextStyles.headline.copyWith(color: Colors.black87)),
        const SizedBox(height: 8),
        Text(
          'Thanks for flagging $displayName — our team will review it.',
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(color: Colors.black54),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
