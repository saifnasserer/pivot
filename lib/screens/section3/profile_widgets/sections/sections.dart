// Export all sections components
export 'sections_builder.dart';
export 'enhanced_section_list_item.dart';
export 'assistant_selection_dialog.dart';

// Keep the original function for backward compatibility
import 'package:flutter/material.dart';
import 'sections_builder.dart';

/// Keep the original function for backward compatibility
List<Widget> buildSectionsSlivers(BuildContext context) {
  return SectionsBuilder.buildSectionsSlivers(context, enableAnimations: true);
}
