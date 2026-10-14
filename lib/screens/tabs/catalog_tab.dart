import 'package:flutter/material.dart';

import 'placeholder_tab.dart';

class CatalogTab extends StatelessWidget {
  const CatalogTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderTab(
      icon: Icons.grid_view_rounded,
      title: 'Catalog',
      subtitle: 'Products will show here in the next update.',
    );
  }
}