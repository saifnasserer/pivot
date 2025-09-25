import 'package:flutter/material.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/providers/section_provider.dart';
import 'package:pivot/providers/subject_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/screens/section3/subject_selection_screen.dart';
import 'package:provider/provider.dart';
import 'package:pivot/models/subject_model.dart';

class AssistantProfileController {
  static void fetchData(
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
        final subjectProvider = Provider.of<SubjectProvider>(
          context,
          listen: false,
        );
        final sectionProvider = Provider.of<SectionProvider>(
          context,
          listen: false,
        );
        final userProfileProvider = Provider.of<UserProfileProvider>(
          context,
          listen: false,
        );

        // Fetch all users for admin functionality
        userProfileProvider.fetchAllUsers(forceAll: true).then((_) {
          subjectProvider.fetchAndFilterSubjects(displayedProfile).then((_) {
            if (context.mounted) {
              try {
                final subjects = subjectProvider.filteredSubjects;
                onSubjectsLoaded(subjects);

                if (subjects.isNotEmpty) {
                  onSubjectSelected(0);
                }
              } catch (e) {
              }
            }
          });
        });
        // Fetch sections for this specific assistant
        sectionProvider.fetchSectionsForAssistant(displayedProfile.id);
      } catch (e) {
      }
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
    BuildContext context,
    UserProfile displayedProfile,
    Function(UserProfile) onProfileUpdated,
    Function() onDataFetched,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => SubjectSelectionScreen(
              previouslySelectedIds: displayedProfile.teachingSubjects,
              targetUserId: displayedProfile.id,
              targetUserRole: displayedProfile.role,
            ),
      ),
    );

    if (result == true && context.mounted) {
      // Refresh the displayed profile data
      final userProfileProvider = Provider.of<UserProfileProvider>(
        context,
        listen: false,
      );

      // Fetch updated profile data
      final updatedProfile = await userProfileProvider.getUserProfileById(
        displayedProfile.id,
      );
      if (updatedProfile != null) {
        onProfileUpdated(updatedProfile);
        onDataFetched();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث المواد المدرسية بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
