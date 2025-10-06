import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/subjects/screens/screens.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/features/administration/providers/sections_provider.dart';
import 'package:pivot/features/user/providers/user_profile_provider.dart';
import 'package:pivot/features/subjects/providers/subject_provider.dart';
import 'package:pivot/models/subject_model.dart';

class AssistantProfileController {
  static void fetchData(
    WidgetRef ref,
    BuildContext context,
    UserProfile? displayedProfile,
    Function(List<Subject>) onSubjectsLoaded,
    Function(int) onSubjectSelected,
  ) {
    if (displayedProfile == null) return;

    // Use a safer approach to access providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;

      try {
        // Fetch all users for admin functionality
        ref.read(userProfileProvider.notifier).fetchAllUsers().then((_) {
          ref
              .read(SubjectProviderProvider.notifier)
              .fetchAndFilterSubjects(displayedProfile)
              .then((_) {
                if (context.mounted) {
                  try {
                    final subjects =
                        ref.read(SubjectProviderProvider).filteredSubjects;
                    onSubjectsLoaded(subjects);

                    if (subjects.isNotEmpty) {
                      onSubjectSelected(0);
                    }
                  } catch (e) {}
                }
              });
        });
        // Fetch sections for this specific assistant
        ref
            .read(sectionsProvider.notifier)
            .fetchSectionsForAssistant(displayedProfile.id);
      } catch (e) {}
    });
  }

  static TabController updateSubjectTabController(
    List<Subject> subjects,
    TabController currentController,
    TickerProvider vsync,
    Function(int) onSubjectSelected,
  ) {
    if (currentController.length != subjects.length) {
      currentController.dispose();
      final newController = TabController(
        length: subjects.length,
        vsync: vsync,
        initialIndex: subjects.isNotEmpty ? subjects.length - 1 : 0,
      );
      newController.addListener(() {
        if (newController.indexIsChanging) {
          onSubjectSelected(newController.index);
        }
      });
      return newController;
    }
    return currentController;
  }

  static TabController getSubjectTabController(
    List<Subject> subjects,
    TabController currentController,
    TickerProvider vsync,
    Function(int) onSubjectSelected,
  ) {
    if (currentController.length != subjects.length) {
      currentController.dispose();
      final newController = TabController(
        length: subjects.length,
        vsync: vsync,
        initialIndex: subjects.isNotEmpty ? subjects.length - 1 : 0,
      );
      newController.addListener(() {
        if (newController.indexIsChanging) {
          onSubjectSelected(newController.index);
        }
      });
      return newController;
    }
    return currentController;
  }

  static bool shouldShowEditIcon(
    UserProfile? loggedInUser,
    UserProfile? displayedProfile,
  ) {
    final isSuperAdmin = loggedInUser?.role == 'Super Admin';
    final isViewingOtherUser = loggedInUser?.id != displayedProfile?.id;
    final isProfessorOrMiniProfessor =
        displayedProfile?.role == 'Professor' ||
        displayedProfile?.role == 'miniProfessor';

    return isSuperAdmin && isViewingOtherUser && isProfessorOrMiniProfessor;
  }

  static Future<void> editTeachingSubjects(
    WidgetRef ref,
    BuildContext context,
    UserProfile displayedProfile,
    Function(UserProfile) onProfileUpdated,
    Function() onDataFetched,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => SubjectSelectionScreenWithProviders(
              previouslySelectedIds: displayedProfile.teachingSubjects,
              targetUserId: displayedProfile.id,
              targetUserRole: displayedProfile.role,
            ),
      ),
    );

    if (result == true && context.mounted) {
      // Fetch updated profile data using Riverpod
      final updatedProfile = await ref
          .read(userProfileProvider.notifier)
          .getUserProfileById(displayedProfile.id);

      if (updatedProfile != null) {
        onProfileUpdated(updatedProfile);
        onDataFetched();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث المواد المدرسية بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}
