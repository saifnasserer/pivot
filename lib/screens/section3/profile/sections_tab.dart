import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pivot/providers/section_provider.dart';
import 'package:pivot/screens/section3/profile_widgets/sections.dart';

class SectionsTab extends StatelessWidget {
  const SectionsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SectionProvider>(
      builder: (context, sectionProvider, child) {
        if (sectionProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (sectionProvider.error != null) {
          return Center(child: Text('Error: ${sectionProvider.error}'));
        }

        final sectionSlivers = buildSectionsSlivers(context);

        return CustomScrollView(slivers: sectionSlivers);
      },
    );
  }
}
