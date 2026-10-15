import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/dashboard_service.dart';
import '../../core/models.dart';
import '../../widgets/app_widgets.dart';

class HomeTab extends StatefulWidget {
  final Session session;
  const HomeTab({super.key, required this.session});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  late Future<RetailerDashboard> _future;

  @override
  void initState() {
    super.initState();
    _future = DashboardService.getRetailer();
  }

  Future<void> _refresh() async {
    final next = DashboardService.getRetailer();
    setState(() => _future = next);
    try {
      await next;
    } on ApiException {
      // error is surfaced by the FutureBuilder
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<RetailerDashboard>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
            return const _CenteredListView(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            final error = snap.error;
            final message = error is ApiException ? error.message : 'Something went wrong.';
            return _CenteredListView(
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
                  FilledButton(onPressed: _refresh, child: const Text('Retry')),
                ],
              ),
            );
          }
          return _DashboardBody(dashboard: snap.data!);
        },
      ),
    );
  }
}

class _CenteredListView extends StatelessWidget {
  final Widget child;
  const _CenteredListView({required this.child});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        Center(child: child),
      ],
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final RetailerDashboard dashboard;
  const _DashboardBody({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final d = dashboard;
    final schemes = d.allSchemes;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _TodayRow(today: d.today),
        const SizedBox(height: 16),
        _CountsRow(counts: d.counts, pendingTotal: d.pendingPaymentsTotal),
        const SizedBox(height: 16),
        _CreditCard(credit: d.credit),
        const SizedBox(height: 16),
        _BankCardCard(bankCard: d.bankCard),
        if (d.banners.isNotEmpty) ...[
          const SizedBox(height: 20),
          const _SectionTitle('Offers & Updates'),
          const SizedBox(height: 10),
          _BannerCarousel(banners: d.banners),
        ],
        if (schemes.isNotEmpty) ...[
          const SizedBox(height: 20),
          const _SectionTitle('Active Schemes'),
          const SizedBox(height: 10),
          _SchemeList(schemes: schemes),
        ],
        if (d.quickActions.isNotEmpty) ...[
          const SizedBox(height: 20),
          const _SectionTitle('Quick Actions'),
          const SizedBox(height: 10),
          _QuickActions(actions: d.quickActions),
        ],
        if (d.latestOrders.isNotEmpty) ...[
          const SizedBox(height: 20),
          const _SectionTitle('Latest Orders'),
          const SizedBox(height: 10),
          _LatestOrders(orders: d.latestOrders),
        ],
        if (d.pendingPayments.isNotEmpty) ...[
          const SizedBox(height: 20),
          const _SectionTitle('Pending Payments'),
          const SizedBox(height: 10),
          _PendingPayments(payments: d.pendingPayments),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}

/* ----------------------------- credit ----------------------------- */

class _CreditCard extends StatelessWidget {
  final DashboardCredit credit;
  const _CreditCard({required this.credit});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined,
                  size: 18, color: AppColors.blue),
              const SizedBox(width: 8),
              const Text(
                'Credit',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              const Spacer(),
              if (credit.creditDays > 0)
                Text(
                  '${credit.creditDays} days',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _AmountBlock(
                  label: 'Available',
                  value: credit.availableCredit,
                  color: AppColors.successText,
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.border),
              Expanded(
                child: _AmountBlock(
                  label: 'Used',
                  value: credit.currentBalance,
                  color: AppColors.dangerText,
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.border),
              Expanded(
                child: _AmountBlock(
                  label: 'Limit',
                  value: credit.limit,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: credit.usedRatio,
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation(AppColors.blue),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountBlock extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _AmountBlock({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          formatInr(value, decimals: false),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
      ],
    );
  }
}

/* ----------------------------- today ----------------------------- */

class _TodayRow extends StatelessWidget {
  final DashboardToday today;
  const _TodayRow({required this.today});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.shopping_bag_outlined,
            label: "Today's Orders",
            value: '${today.ordersCount}',
            tint: AppColors.blue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            icon: Icons.trending_up,
            label: 'Sales',
            value: formatInr(today.salesValue, decimals: false),
            tint: AppColors.green,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            icon: Icons.payments_outlined,
            label: 'Paid',
            value: formatInr(today.paidValue, decimals: false),
            tint: AppColors.successText,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color tint;
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: tint),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

/* ----------------------------- counts ----------------------------- */

class _CountsRow extends StatelessWidget {
  final DashboardCounts counts;
  final double pendingTotal;
  const _CountsRow({required this.counts, required this.pendingTotal});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_outlined, size: 18, color: AppColors.blue),
              const SizedBox(width: 8),
              const Text(
                'Overview',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniCount(
                  value: '${counts.pendingOrders}',
                  label: 'Pending Orders',
                ),
              ),
              Expanded(
                child: _MiniCount(
                  value: '${counts.dispatched}',
                  label: 'Dispatched',
                ),
              ),
              Expanded(
                child: _MiniCount(
                  value: '${counts.pendingPayments}',
                  label: 'Pending Pay',
                ),
              ),
            ],
          ),
          if (pendingTotal > 0) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.dangerBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Total pending payments: ${formatInr(pendingTotal)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dangerText,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniCount extends StatelessWidget {
  final String value;
  final String label;
  const _MiniCount({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
      ],
    );
  }
}

/* ----------------------------- bank card ----------------------------- */

class _BankCardCard extends StatelessWidget {
  final DashboardBankCard bankCard;
  const _BankCardCard({required this.bankCard});

  @override
  Widget build(BuildContext context) {
    final status = bankCard.status;
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

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.credit_card, size: 18, color: AppColors.blue),
              const SizedBox(width: 8),
              const Text(
                'Bank Credit Card',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
          if (bankCard.message.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              bankCard.message,
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          ],
          if ((bankCard.action ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => showStatus(context, '${bankCard.action} - coming soon'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.blue,
                side: const BorderSide(color: AppColors.blue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(bankCard.action!),
            ),
          ],
        ],
      ),
    );
  }
}

/* ----------------------------- banners ----------------------------- */

class _BannerCarousel extends StatefulWidget {
  final List<DashboardBanner> banners;
  const _BannerCarousel({required this.banners});

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  final PageController _controller = PageController(viewportFraction: 0.94);
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    if (widget.banners.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted || !_controller.hasClients) return;
        _page = (_page + 1) % widget.banners.length;
        _controller.animateToPage(
          _page,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = 170.0;
    return Column(
      children: [
        SizedBox(
          height: height,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.banners.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _BannerTile(banner: widget.banners[i]),
            ),
          ),
        ),
        if (widget.banners.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.banners.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _page ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _page ? AppColors.blue : AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _BannerTile extends StatelessWidget {
  final DashboardBanner banner;
  const _BannerTile({required this.banner});

  @override
  Widget build(BuildContext context) {
    final url = banner.streamUrl ?? banner.mediaUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: AppColors.border),
          if (!banner.isVideo && (url ?? '').isNotEmpty)
            Image.network(
              url!,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : const ColoredBox(color: AppColors.border),
              errorBuilder: (context, error, stack) => _bannerFallback(),
            )
          else if (banner.isVideo)
            _videoFallback(banner.title)
          else
            _bannerFallback(),
        ],
      ),
    );
  }

  Widget _bannerFallback() => const Center(
        child: Icon(Icons.image_outlined, size: 40, color: AppColors.muted),
      );

  Widget _videoFallback(String? title) => Container(
        color: const Color(0xFF0F172A),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_circle_fill, size: 48, color: Colors.white70),
            if ((title ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  title!,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ],
        ),
      );
}

/* ----------------------------- schemes ----------------------------- */

class _SchemeList extends StatelessWidget {
  final List<DashboardScheme> schemes;
  const _SchemeList({required this.schemes});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 205,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: schemes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) => SizedBox(
          width: 210,
          child: _SchemeCard(scheme: schemes[i]),
        ),
      ),
    );
  }
}

class _SchemeCard extends StatelessWidget {
  final DashboardScheme scheme;
  const _SchemeCard({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  scheme.isPaper ? 'Paper Scheme' : 'Standard Scheme',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.blue,
                  ),
                ),
              ),
              if (!scheme.isAvailable)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Out of stock',
                    style: TextStyle(fontSize: 9, color: AppColors.dangerText),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if ((scheme.giftImageUrl ?? '').isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                scheme.giftImageUrl!,
                height: 60,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => _giftFallback(),
              ),
            )
          else
            _giftFallback(),
          const SizedBox(height: 8),
          Text(
            scheme.title ?? scheme.schemeType ?? 'Scheme',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            scheme.productName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
          const Spacer(),
          if ((scheme.minText ?? '').isNotEmpty)
            Text(
              scheme.minText!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppColors.text),
            ),
          if ((scheme.giftName ?? '').isNotEmpty)
            Text(
              'Gift: ${scheme.giftName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.successText,
              ),
            ),
          if ((scheme.endDate ?? '').isNotEmpty)
            Text(
              'Valid till ${formatDate(scheme.endDate)}',
              style: const TextStyle(fontSize: 10, color: AppColors.muted),
            ),
        ],
      ),
    );
  }

  Widget _giftFallback() => Container(
        height: 60,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.successBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.card_giftcard, color: AppColors.successText),
      );
}

/* ----------------------------- quick actions ----------------------------- */

class _QuickActions extends StatelessWidget {
  final List<DashboardQuickAction> actions;
  const _QuickActions({required this.actions});

  static const Map<String, IconData> _icons = {
    'approve_orders': Icons.check_circle_outline,
    'pack_orders': Icons.inventory_2_outlined,
    'dispatch': Icons.local_shipping_outlined,
    'invoice': Icons.receipt_long_outlined,
    'returns': Icons.assignment_return_outlined,
    'stock_check': Icons.warehouse_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Wrap(
        spacing: 8,
        runSpacing: 16,
        alignment: WrapAlignment.start,
        children: actions.map((a) {
          return SizedBox(
            width: (MediaQuery.of(context).size.width - 32 - 32 - 16) / 3,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => showStatus(context, '${a.label} - coming soon'),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.inputBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Icon(
                      _icons[a.key] ?? Icons.grid_view_outlined,
                      size: 20,
                      color: AppColors.blue,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    a.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.text),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/* ----------------------------- latest orders ----------------------------- */

class _LatestOrders extends StatelessWidget {
  final List<DashboardOrder> orders;
  const _LatestOrders({required this.orders});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < orders.length; i++) ...[
            if (i != 0) const Divider(height: 1, color: AppColors.border),
            _OrderRow(order: orders[i]),
          ],
        ],
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  final DashboardOrder order;
  const _OrderRow({required this.order});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.displayNumber.isNotEmpty
                      ? order.displayNumber
                      : 'ORD-${order.orderId}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${order.customer} · ${formatDate(order.createdAt)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatInr(order.total),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 2),
              _StatusBadge(
                text: order.isPaid ? 'Paid' : (order.paymentStatus ?? 'Pending'),
                positive: order.isPaid,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/* ----------------------------- pending payments ----------------------------- */

class _PendingPayments extends StatelessWidget {
  final List<DashboardPendingPayment> payments;
  const _PendingPayments({required this.payments});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < payments.length; i++) ...[
            if (i != 0) const Divider(height: 1, color: AppColors.border),
            _PaymentRow(payment: payments[i]),
          ],
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final DashboardPendingPayment payment;
  const _PaymentRow({required this.payment});

  @override
  Widget build(BuildContext context) {
    final amount = payment.dueAmount ?? payment.total;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.invoiceNumber ?? 'Order #${payment.orderId}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  (payment.dueDate ?? '').isNotEmpty
                      ? 'Due ${formatDate(payment.dueDate)}'
                      : (payment.paymentStatus ?? ''),
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatInr(amount),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 2),
              _StatusBadge(text: payment.badge, positive: !payment.isOverdue),
            ],
          ),
        ],
      ),
    );
  }
}

/* ----------------------------- shared ----------------------------- */

class _SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const _SectionCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;
  final bool positive;
  const _StatusBadge({required this.text, required this.positive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: positive ? AppColors.successBg : AppColors.dangerBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: positive ? AppColors.successText : AppColors.dangerText,
        ),
      ),
    );
  }
}
