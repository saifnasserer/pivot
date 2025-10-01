// Export all sections components
export 'sections_builder.dart';
export 'enhanced_section_list_item.dart';
export 'assistant_selection_dialog.dart';

// Keep the original function for backward compatibility
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sections_builder.dart';

/// Keep the original function for backward compatibility
List<Widget> buildSectionsSlivers(BuildContext context, WidgetRef ref) {
  return SectionsBuilder.buildSectionsSlivers(
    context,
    ref,
    enableAnimations: true,
  );
}
