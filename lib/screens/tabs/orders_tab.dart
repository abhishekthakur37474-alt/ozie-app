import 'package:flutter/material.dart';

import 'placeholder_tab.dart';

class OrdersTab extends StatelessWidget {
  const OrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderTab(
      icon: Icons.receipt_long,
      title: 'View Orders',
      subtitle: 'Your orders will show here in the next update.',
    );
  }
}