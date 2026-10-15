import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../core/api_client.dart';
import '../core/dashboard_service.dart';
import '../core/models.dart';
import '../widgets/app_widgets.dart';

/// Bank credit card details, opened from the "Apply For Card" app-bar action.
class BankCardScreen extends StatefulWidget {
  const BankCardScreen({super.key});

  @override
  State<BankCardScreen> createState() => _BankCardScreenState();
}

class _BankCardScreenState extends State<BankCardScreen> {
  late Future<RetailerDashboard> _future;

  @override
  void initState() {
    super.initState();
    _future = DashboardService.getRetailer();
  }

  void _retry() {
    setState(() => _future = DashboardService.getRetailer());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Credit Card'),
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Back',
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedChevronLeft,
            color: AppColors.text,
            strokeWidth: 1.5,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: FutureBuilder<RetailerDashboard>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            final error = snap.error;
            final message =
                error is ApiException ? error.message : 'Something went wrong.';
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off, size: 40, color: AppColors.muted),
                    const SizedBox(height: 12),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.dangerText),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _retry, child: const Text('Retry')),
                  ],
                ),
              ),
            );
          }
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [_BankCardDetail(bankCard: snap.data!.bankCard)],
          );
        },
      ),
    );
  }
}

class _BankCardDetail extends StatelessWidget {
  final DashboardBankCard bankCard;
  const _BankCardDetail({required this.bankCard});

  @override
  Widget build(BuildContext context) {
    final Color fg;
    final Color bg;
    if (bankCard.isActive) {
      fg = AppColors.successText;
      bg = AppColors.successBg;
    } else if (bankCard.isPending) {
      fg = const Color(0xFF92400E);
      bg = const Color(0xFFFDE68A);
    } else {
      fg = AppColors.dangerText;
      bg = AppColors.dangerBg;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A1E2A3B),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.credit_card, size: 22, color: AppColors.blue),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Bank Credit Card',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  bankCard.status,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
          if (bankCard.message.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              bankCard.message,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: AppColors.muted,
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => showStatus(
                context,
                '${bankCard.action ?? 'Application'} - coming soon',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.blue,
                side: const BorderSide(color: AppColors.blue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.credit_score_outlined, size: 20),
              label: Text(
                (bankCard.action ?? '').isNotEmpty
                    ? bankCard.action!
                    : 'Apply For Card',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
