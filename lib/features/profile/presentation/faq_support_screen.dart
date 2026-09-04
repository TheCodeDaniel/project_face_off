import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/lobby_palette.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/gradient_scaffold.dart';
import '../../../core/widgets/primary_pill_button.dart';
import '../../../core/widgets/shimmer_card.dart';

/// FAQ & support (master prompt Section 10): static content plus a support
/// contact action — implemented fully via a real `mailto:` intent rather
/// than a dead-end button.
class FaqSupportScreen extends StatelessWidget {
  const FaqSupportScreen({super.key});

  static const _faqs = [
    (
      q: 'How does the face tracking work?',
      a: 'Your device analyzes your expressions locally — no video is ever sent to the other player or to us.',
    ),
    (
      q: 'What counts as a "crack"?',
      a: 'Smiling or laughing at the wrong moment. The threshold is tuned to ignore normal resting expressions.',
    ),
    (
      q: 'Can I play without an opponent nearby?',
      a: 'Yes — Quick Match pairs you with anyone online, or challenge a friend directly from the Friends tab.',
    ),
    (q: 'How do I report bad behavior?', a: 'Open the offending player\'s profile from Friends and choose Report.'),
  ];

  Future<void> _contactSupport(BuildContext context) async {
    final uri = Uri(scheme: 'mailto', path: 'support@faceoffgame.app', query: 'subject=Face Off support request');
    final launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No email app available — reach us at support@faceoffgame.app')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text('FAQ & Support', style: AppTextStyles.headline.copyWith(color: Colors.white)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            for (final faq in _faqs) _FaqTile(question: faq.q, answer: faq.a),
            const SizedBox(height: 20),
            PrimaryPillButton(
              label: 'Contact Support',
              icon: HugeIcons.strokeRoundedMail01,
              onPressed: () => _contactSupport(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<LobbyPalette>() ?? LobbyPalette.standard;
    return ShimmerCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(HugeIcons.strokeRoundedQuestion, color: palette.gradientStart, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(question, style: AppTextStyles.body.copyWith(color: Colors.black87)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(answer, style: AppTextStyles.label.copyWith(color: Colors.black54)),
        ],
      ),
    );
  }
}
