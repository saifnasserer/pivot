// Export all sections components
export 'sections_builder.dart';
export 'enhanced_section_list_item.dart';
export 'assistant_selection_dialog.dart';

// Keep the original function for backward compatibility
import 'package:flutter/material.dart';
import 'package:pivot/models/section_model.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/providers/section_provider.dart';
import 'package:pivot/providers/subject_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:provider/provider.dart';
import 'sections_builder.dart';

/// Keep the original function for backward compatibility
List<Widget> buildSectionsSlivers(BuildContext context) {
  return SectionsBuilder.buildSectionsSlivers(context, enableAnimations: true);
}
