import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/lobby_palette.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/gradient_scaffold.dart';
import '../../../core/widgets/primary_pill_button.dart';
import '../domain/subscription_package.dart';
import 'profile_providers.dart';
import 'widgets/purchase_success_view.dart';
import 'widgets/subscription_package_card.dart';

/// Face Off Plus paywall (master prompt Section 11), triggered from
/// [SubscriptionSection] or any gated feature's natural touchpoint. The full
/// package-picker → purchase flow is real UI running against
/// [FakeProfileRepository]'s offerings/purchase methods — only the RevenueCat
/// API keys + dashboard Offerings catalog are pending; see CLAUDE.md. That
/// swap is a data-mapping change under `fetchOfferings`/`purchasePackage`,
/// not a UI rewrite.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  static const _perks = [
    (icon: HugeIcons.strokeRoundedVideo01, text: 'HD, watermark-free clip export'),
    (icon: HugeIcons.strokeRoundedDoorOpen, text: 'Unlimited private rooms'),
    (icon: HugeIcons.strokeRoundedGift, text: 'Early access to new cosmetics'),
  ];

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  String? _selectedPackageId;
  bool _purchasing = false;
  bool _purchased = false;

  Future<void> _purchase(String packageId) async {
    setState(() => _purchasing = true);
    final result = await ref.read(profileRepositoryProvider).purchasePackage(packageId);
    if (!mounted) return;
    setState(() => _purchasing = false);

    if (result.isSuccess) {
      setState(() => _purchased = true);
      // Auto-close once the confirmation has had a moment to register —
      // same pattern as AddFriendSheet's success state.
      Timer(const Duration(milliseconds: 1400), () {
        if (mounted) Navigator.of(context).pop();
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message ?? 'Purchase failed — please try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<LobbyPalette>() ?? LobbyPalette.standard;
    final offerings = ref.watch(subscriptionOfferingsProvider);

    return GradientScaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: Colors.white, elevation: 0),
      body: SafeArea(
        top: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _purchased
              ? const PurchaseSuccessView(key: ValueKey('success'))
              : ListView(
                  key: const ValueKey('paywall'),
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  children: [
                    Center(
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.18),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.4),
                        ),
                        alignment: Alignment.center,
                        child: AppIcon(HugeIcons.strokeRoundedDiamond, color: palette.coinGold, size: 44),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Face Off Plus',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.display.copyWith(color: Colors.white, fontSize: 30),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Unlock the full experience',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 28),
                    for (final perk in PaywallScreen._perks)
                      _PerkCard(icon: perk.icon, text: perk.text, palette: palette),
                    const SizedBox(height: 20),
                    offerings.when(
                      data: (packages) => _OfferingsPicker(
                        packages: packages,
                        selectedId: _selectedPackageId ??= _defaultSelection(packages),
                        purchasing: _purchasing,
                        onSelect: (id) => setState(() => _selectedPackageId = id),
                        onSubscribe: _purchase,
                      ),
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator(color: Colors.white)),
                      ),
                      error: (_, _) => Text(
                        "Couldn't load plans — check your connection and try again.",
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Cancel anytime from your device settings. Billed through the App Store / Google Play.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.label.copyWith(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  String? _defaultSelection(List<SubscriptionPackage> packages) {
    if (packages.isEmpty) return null;
    final badged = packages.where((p) => p.badge != null);
    return badged.isNotEmpty ? badged.first.id : packages.first.id;
  }
}

class _OfferingsPicker extends StatelessWidget {
  const _OfferingsPicker({
    required this.packages,
    required this.selectedId,
    required this.purchasing,
    required this.onSelect,
    required this.onSubscribe,
  });

  final List<SubscriptionPackage> packages;
  final String? selectedId;
  final bool purchasing;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onSubscribe;

  @override
  Widget build(BuildContext context) {
    if (packages.isEmpty) return const SizedBox.shrink();
    final selected = packages.where((p) => p.id == selectedId);
    final selectedLabel = selected.isNotEmpty ? selected.first.priceLabel : null;

    return Column(
      children: [
        Row(
          children: [
            for (final package in packages) ...[
              Expanded(
                child: SubscriptionPackageCard(
                  package: package,
                  selected: package.id == selectedId,
                  onTap: () => onSelect(package.id),
                ),
              ),
              if (package != packages.last) const SizedBox(width: 12),
            ],
          ],
        ),
        const SizedBox(height: 16),
        PrimaryPillButton(
          label: selectedLabel == null ? 'Subscribe' : 'Subscribe — $selectedLabel',
          icon: HugeIcons.strokeRoundedDiamond,
          loading: purchasing,
          onPressed: selectedId == null ? null : () => onSubscribe(selectedId!),
        ),
      ],
    );
  }
}

class _PerkCard extends StatelessWidget {
  const _PerkCard({required this.icon, required this.text, required this.palette});

  final List<List<dynamic>> icon;
  final String text;
  final LobbyPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: palette.coinGold.withValues(alpha: 0.25), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: AppIcon(icon, color: palette.coinGold, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(text, style: AppTextStyles.body.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
