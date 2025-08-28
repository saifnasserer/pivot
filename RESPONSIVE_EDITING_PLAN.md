# Responsive Editing Plan

## Overview

This document identifies all places in the codebase where static numbers are used instead of responsive utilities from `responsive.dart`. These need to be updated to make the app fully responsive.

## Files Requiring Updates

### 1. `lib/screens/section2/super_admin_panel/update_management_screen.dart`

**Status**: Already uses responsive utilities in most places, but has some static values

**Static values to replace**:

- Line 983: `padding: const EdgeInsets.all(20)` → `Responsive.padding(context, size: Space.large)`
- Line 1091: `padding: const EdgeInsets.all(12)` → `Responsive.padding(context, size: Space.medium)`
- Line 1152: `padding: const EdgeInsets.all(16)` → `Responsive.padding(context, size: Space.medium)`
- Line 1162: `padding: const EdgeInsets.all(10)` → `Responsive.padding(context, size: Space.small)`
- Line 1345: `padding: const EdgeInsets.all(8)` → `Responsive.padding(context, size: Space.small)`
- Line 1397: `padding: const EdgeInsets.all(16)` → `Responsive.padding(context, size: Space.medium)`
- Line 1487: `padding: const EdgeInsets.all(16)` → `Responsive.padding(context, size: Space.medium)`
- Line 1497: `padding: const EdgeInsets.all(10)` → `Responsive.padding(context, size: Space.small)`
- Line 1586: `padding: const EdgeInsets.all(16)` → `Responsive.padding(context, size: Space.medium)`
- Line 1659: `padding: const EdgeInsets.all(8)` → `Responsive.padding(context, size: Space.small)`
- Line 1787: `padding: const EdgeInsets.all(12)` → `Responsive.padding(context, size: Space.medium)`

**Static SizedBox values**:

- Line 1002: `const SizedBox(height: 16)` → `SizedBox(height: Responsive.space(context, size: Space.medium))`
- Line 1115: `const SizedBox(height: 4)` → `SizedBox(height: Responsive.space(context, size: Space.tiny))`
- Line 1189: `const SizedBox(height: 2)` → `SizedBox(height: Responsive.space(context, size: Space.tiny) * 0.5)`
- Line 1238: `const SizedBox(height: 24)` → `SizedBox(height: Responsive.space(context, size: Space.large))`
- Line 1257: `const SizedBox(height: 16)` → `SizedBox(height: Responsive.space(context, size: Space.medium))`
- Line 1274: `const SizedBox(height: 20)` → `SizedBox(height: Responsive.space(context, size: Space.medium))`
- Line 1298: `const SizedBox(height: 16)` → `SizedBox(height: Responsive.space(context, size: Space.medium))`
- Line 1311: `const SizedBox(height: 16)` → `SizedBox(height: Responsive.space(context, size: Space.medium))`
- Line 1369: `const SizedBox(height: 2)` → `SizedBox(height: Responsive.space(context, size: Space.tiny) * 0.5)`
- Line 1420: `const SizedBox(height: 16)` → `SizedBox(height: Responsive.space(context, size: Space.medium))`
- Line 1524: `const SizedBox(height: 2)` → `SizedBox(height: Responsive.space(context, size: Space.tiny) * 0.5)`
- Line 1559: `const SizedBox(height: 24)` → `SizedBox(height: Responsive.space(context, size: Space.large))`
- Line 1584: `const SizedBox(height: 16)` → `SizedBox(height: Responsive.space(context, size: Space.medium))`
- Line 1615: `const SizedBox(height: 4)` → `SizedBox(height: Responsive.space(context, size: Space.tiny))`
- Line 1681: `const SizedBox(height: 20)` → `SizedBox(height: Responsive.space(context, size: Space.medium))`
- Line 1785: `const SizedBox(height: 16)` → `SizedBox(height: Responsive.space(context, size: Space.medium))`
- Line 1815: `const SizedBox(height: 8)` → `SizedBox(height: Responsive.space(context, size: Space.small))`
- Line 1823: `const SizedBox(height: 4)` → `SizedBox(height: Responsive.space(context, size: Space.tiny))`
- Line 1831: `const SizedBox(height: 4)` → `SizedBox(height: Responsive.space(context, size: Space.tiny))`

**Static width values**:

- Line 1102: `const SizedBox(width: 16)` → `SizedBox(width: Responsive.space(context, size: Space.medium))`
- Line 1173: `const SizedBox(width: 12)` → `SizedBox(width: Responsive.space(context, size: Space.medium))`
- Line 1356: `const SizedBox(width: 16)` → `SizedBox(width: Responsive.space(context, size: Space.medium))`
- Line 1409: `const SizedBox(width: 8)` → `SizedBox(width: Responsive.space(context, size: Space.small))`
- Line 1508: `const SizedBox(width: 12)` → `SizedBox(width: Responsive.space(context, size: Space.medium))`
- Line 1599: `const SizedBox(width: 12)` → `SizedBox(width: Responsive.space(context, size: Space.medium))`
- Line 1670: `const SizedBox(width: 12)` → `SizedBox(width: Responsive.space(context, size: Space.medium))`
- Line 1723: `const SizedBox(width: 16)` → `SizedBox(width: Responsive.space(context, size: Space.medium))`
- Line 1799: `const SizedBox(width: 8)` → `SizedBox(width: Responsive.space(context, size: Space.small))`

**Static height values**:

- Line 1688: `height: 56` → `height: Responsive.space(context, size: Space.xlarge) * 1.75`
- Line 1726: `height: 56` → `height: Responsive.space(context, size: Space.xlarge) * 1.75`
- Line 1754: `height: 20` → `height: Responsive.space(context, size: Space.medium)`

**Static fontSize values**:

- Line 1709: `fontSize: 16` → `fontSize: Responsive.text(context, size: TextSize.medium)`
- Line 1767: `fontSize: 16` → `fontSize: Responsive.text(context, size: TextSize.medium)`

### 2. `lib/screens/section4/doctor/profile/subjects_section.dart`

**Static values to replace**:

- Line 215: `SizedBox(height: 16)` → `SizedBox(height: Responsive.space(context, size: Space.medium))`
- Line 228: `SizedBox(height: 16)` → `SizedBox(height: Responsive.space(context, size: Space.medium))`
- Line 234: `SizedBox(height: 16)` → `SizedBox(height: Responsive.space(context, size: Space.medium))`
- Line 254: `SizedBox(height: 16)` → `SizedBox(height: Responsive.space(context, size: Space.medium))`
- Line 260: `SizedBox(height: 8)` → `SizedBox(height: Responsive.space(context, size: Space.small))`
- Line 310: `SizedBox(height: 16)` → `SizedBox(height: Responsive.space(context, size: Space.medium))`
- Line 319: `SizedBox(height: 8)` → `SizedBox(height: Responsive.space(context, size: Space.small))`
- Line 257: `fontSize: 16` → `fontSize: Responsive.text(context, size: TextSize.medium)`
- Line 263: `fontSize: 14` → `fontSize: Responsive.text(context, size: TextSize.small)`

### 3. `lib/screens/section4/doctor/profile/material_links_screen.dart`

**Static values to replace**:

- Line 157: `SizedBox(height: 16)` → `SizedBox(height: Responsive.space(context, size: Space.medium))`
- Line 163: `SizedBox(height: 16)` → `SizedBox(height: Responsive.space(context, size: Space.medium))`
- Line 427: `SizedBox(height: 4)` → `SizedBox(height: Responsive.space(context, size: Space.tiny))`
- Line 550: `SizedBox(height: 16)` → `SizedBox(height: Responsive.space(context, size: Space.medium))`
- Line 559: `SizedBox(height: 8)` → `SizedBox(height: Responsive.space(context, size: Space.small))`
- Line 723: `SizedBox(height: 8)` → `SizedBox(height: Responsive.space(context, size: Space.small))`
- Line 521: `SizedBox(width: 4)` → `SizedBox(width: Responsive.space(context, size: Space.tiny))`
- Line 451: `height: 50` → `height: Responsive.space(context, size: Space.xlarge) * 1.56`
- Line 716: `height: 20` → `height: Responsive.space(context, size: Space.medium)`
- Line 725: `height: 16` → `height: Responsive.space(context, size: Space.medium)`
- Line 332: `fontSize: 14` → `fontSize: Responsive.text(context, size: TextSize.small)`
- Line 431: `fontSize: 18` → `fontSize: Responsive.text(context, size: TextSize.medium)`
- Line 438: `fontSize: 12` → `fontSize: Responsive.text(context, size: TextSize.small)`

### 4. `lib/screens/section3/profile/sections_tab.dart`

**Static values to replace**:

- Line 247: `SizedBox(height: 16)` → `SizedBox(height: Responsive.space(context, size: Space.medium))`
- Line 253: `SizedBox(height: 16)` → `SizedBox(height: Responsive.space(context, size: Space.medium))`
- Line 250: `fontSize: 16` → `fontSize: Responsive.text(context, size: TextSize.medium)`

### 5. `lib/screens/section3/profile/schedule_tab.dart`

**Static values to replace**:

- Line 128: `SizedBox(height: 16)` → `SizedBox(height: Responsive.space(context, size: Space.medium))`
- Line 141: `SizedBox(height: 16)` → `SizedBox(height: Responsive.space(context, size: Space.medium))`
- Line 147: `SizedBox(height: 16)` → `SizedBox(height: Responsive.space(context, size: Space.medium))`
- Line 168: `SizedBox(height: 16)` → `SizedBox(height: Responsive.space(context, size: Space.medium))`
- Line 174: `SizedBox(height: 16)` → `SizedBox(height: Responsive.space(context, size: Space.medium))`
- Line 171: `fontSize: 16` → `fontSize: Responsive.text(context, size: TextSize.medium)`

### 6. `lib/screens/section1/auth_wrapper.dart`

**Static values to replace**:

- Line 74: `SizedBox(height: 24)` → `SizedBox(height: Responsive.space(context, size: Space.large))`
- Line 78: `fontSize: 18` → `fontSize: Responsive.text(context, size: TextSize.medium)`

### 7. `lib/screens/section3/bookmarks_screen.dart`

**Static values to replace**:

- Line 263: `SizedBox(height: 16)` → `SizedBox(height: Responsive.space(context, size: Space.medium))`

### 8. `lib/screens/section4/doctor/profile/video_player_screen.dart`

**Static values to replace**:

- Line 171: `SizedBox(height: 16)` → `SizedBox(height: Responsive.space(context, size: Space.medium))`

### 9. `lib/screens/section4/doctor/profile/pdf_viewer_screen.dart`

**Static values to replace**:

- Line 107: `SizedBox(height: 16)` → `SizedBox(height: Responsive.space(context, size: Space.medium))`

### 10. `lib/screens/section2/landing.dart`

**Static values to replace**:

- Line 213: `padding: const EdgeInsets.symmetric(horizontal: 8.0)` → `Responsive.paddingHorizontal(context, size: Space.small)`

### 11. `lib/screens/section3/profile/profile_screen.dart`

**Static values to replace**:

- Line 296: `padding: const EdgeInsets.symmetric(vertical: 8)` → `Responsive.paddingVertical(context, size: Space.small)`

### 12. `lib/screens/section4/assistants/all_tasks.dart`

**Static values to replace**:

- Line 74: `padding: const EdgeInsets.fromLTRB(8, 8, 8, 80)` → `EdgeInsets.fromLTRB(Responsive.space(context, size: Space.small), Responsive.space(context, size: Space.small), Responsive.space(context, size: Space.small), Responsive.space(context, size: Space.xlarge) * 2.5)`

### 13. `lib/screens/section2/adminstration/add_user_screen.dart`

**Static values to replace**:

- Line 778: `margin: const EdgeInsets.only(top: 8, bottom: 16)` → `EdgeInsets.only(top: Responsive.space(context, size: Space.small), bottom: Responsive.space(context, size: Space.medium))`
- Line 845: `margin: const EdgeInsets.only(bottom: 24)` → `EdgeInsets.only(bottom: Responsive.space(context, size: Space.large))`

### 14. `lib/screens/section3/profile_widgets/bookmark_card.dart`

**Static values to replace**:

- Line 102: `margin: const EdgeInsets.only(top: 32)` → `EdgeInsets.only(top: Responsive.space(context, size: Space.xlarge))`
- Line 449: `padding: const EdgeInsets.only(top: 4.0)` → `EdgeInsets.only(top: Responsive.space(context, size: Space.tiny))`
- Line 542: `margin: const EdgeInsets.only(left: 8.0)` → `EdgeInsets.only(left: Responsive.space(context, size: Space.small))`
- Line 788: `margin: const EdgeInsets.only(top: 32)` → `EdgeInsets.only(top: Responsive.space(context, size: Space.xlarge))`

### 15. `lib/screens/section2/announcement_card.dart`

**Static values to replace**:

- Line 140: `padding: const EdgeInsets.only(top: 2.0)` → `EdgeInsets.only(top: Responsive.space(context, size: Space.tiny) * 0.5)`

### 16. `lib/screens/models/notification_test_widget.dart`

**Static values to replace**:

- Line 107: `padding: const EdgeInsets.only(bottom: 8.0)` → `EdgeInsets.only(bottom: Responsive.space(context, size: Space.small))`
- Line 363: `padding: const EdgeInsets.only(bottom: 8.0)` → `EdgeInsets.only(bottom: Responsive.space(context, size: Space.small))`
- Line 592: `padding: const EdgeInsets.only(bottom: 4.0)` → `EdgeInsets.only(bottom: Responsive.space(context, size: Space.tiny))`
- Line 738: `padding: const EdgeInsets.only(bottom: 4.0)` → `EdgeInsets.only(bottom: Responsive.space(context, size: Space.tiny))`
- Line 129: `fontSize: 14` → `fontSize: Responsive.text(context, size: TextSize.small)`
- Line 398: `fontSize: 12` → `fontSize: Responsive.text(context, size: TextSize.small)`
- Line 406: `fontSize: 12` → `fontSize: Responsive.text(context, size: TextSize.small)`
- Line 596: `fontSize: 14` → `fontSize: Responsive.text(context, size: TextSize.small)`
- Line 599: `fontSize: 14` → `fontSize: Responsive.text(context, size: TextSize.small)`
- Line 741: `fontSize: 12` → `fontSize: Responsive.text(context, size: TextSize.small)`
- Line 748: `fontSize: 12` → `fontSize: Responsive.text(context, size: TextSize.small)`

## BorderRadius Values to Replace

### Files with static BorderRadius values:

1. `lib/screens/section2/super_admin_panel/update_management_screen.dart` (multiple lines)
2. `lib/screens/section2/super_admin_panel/super_admin_panel_screen.dart` (multiple lines)
3. `lib/screens/section2/super_admin_panel/analytics_screen.dart` (multiple lines)
4. `lib/screens/section2/adminstration/user_management_page.dart` (multiple lines)
5. `lib/screens/section3/subject_selection_screen.dart` (multiple lines)
6. `lib/screens/section4/doctor_details.dart` (multiple lines)
7. `lib/services/update_service.dart` (multiple lines)
8. `lib/screens/section1/introduction_screen.dart` (multiple lines)
9. `lib/screens/section2/super_admin_panel/upcoming_notifications_screen.dart` (multiple lines)
10. `lib/screens/section4/doctor/profile/material_links_screen.dart` (multiple lines)
11. `lib/screens/section3/profile_widgets/sections.dart` (multiple lines)
12. `lib/screens/section3/profile_widgets/schadule.dart` (multiple lines)
13. `lib/screens/section2/adminstration/add_announcement_stepped_dialog.dart` (multiple lines)
14. `lib/screens/section4/assistants/add_edit_section_dialog.dart` (multiple lines)
15. `lib/screens/section3/edit_profile/profile_image_section.dart` (multiple lines)
16. `lib/screens/section2/adminstration/announcement/steps/material_browser_bottom_sheet.dart` (multiple lines)
17. `lib/screens/section4/doctor/profile/material_card.dart` (multiple lines)
18. `lib/screens/section2/super_admin_panel/upcoming_notifications_screen.dart` (multiple lines)
19. `lib/screens/section1/introduction_screen.dart` (multiple lines)
20. `lib/screens/models/card_model.dart` (multiple lines)
21. `lib/widgets/ios_install_instructions_screen.dart` (multiple lines)
22. `lib/widgets/comment_section.dart` (multiple lines)
23. `lib/screens/section3/profile_widgets/week_tasks.dart` (multiple lines)

## Height/Width Values to Replace

### Files with static height/width values:

1. `lib/screens/section4/assistants/profile/assistant_profile_main.dart` - Line 360: `height: 80`
2. `lib/screens/section3/subject_selection_screen.dart` - Multiple height values (24, 200)
3. `lib/screens/section3/feedback_screen.dart` - Multiple height values (120, 200, 56, 20, 1024)
4. `lib/screens/section3/edit_profile/profile_image_section.dart` - Multiple height values (1024, 20, 400)
5. `lib/screens/section2/teams.dart` - Line 325: `height: 50`
6. `lib/screens/section3/profile_widgets/week_tasks.dart` - Line 534: `height: 20`
7. `lib/screens/models/instructors_gate.dart` - Line 620: `height: 20`
8. `lib/screens/section2/super_admin_panel/super_admin_panel_screen.dart` - Line 334: `height: 1`

## Implementation Priority

### High Priority (Core UI Components)

1. `lib/screens/section2/super_admin_panel/update_management_screen.dart`
2. `lib/screens/section4/doctor/profile/subjects_section.dart`
3. `lib/screens/section4/doctor/profile/material_links_screen.dart`
4. `lib/screens/section3/profile/sections_tab.dart`
5. `lib/screens/section3/profile/schedule_tab.dart`

### Medium Priority (Secondary UI Components)

1. `lib/screens/section1/auth_wrapper.dart`
2. `lib/screens/section3/bookmarks_screen.dart`
3. `lib/screens/section4/doctor/profile/video_player_screen.dart`
4. `lib/screens/section4/doctor/profile/pdf_viewer_screen.dart`
5. `lib/screens/section2/landing.dart`

### Low Priority (Utility Components)

1. `lib/screens/models/notification_test_widget.dart`
2. `lib/screens/section2/announcement_card.dart`
3. `lib/screens/section3/profile_widgets/bookmark_card.dart`
4. `lib/screens/section2/adminstration/add_user_screen.dart`

## Notes

- All `const` values that should remain const (like `const SizedBox(height: 1)` for dividers) should be kept as is
- BorderRadius values should be replaced with `Responsive.space(context, size: Space.medium)` or appropriate space size
- FontSize values should be replaced with `Responsive.text(context, size: TextSize.small/medium/heading)`
- Height/Width values should be replaced with `Responsive.space(context, size: Space.tiny/small/medium/large/xlarge)` or calculated values
- Padding/Margin values should be replaced with `Responsive.padding()` or `Responsive.paddingHorizontal()`/`Responsive.paddingVertical()`

