# Feature Implementation Plan: Professor, Assistant, and Student Linking

This document outlines the phased implementation of new features to support different user roles and create a linked, dynamic experience for students, assistants, and professors.

---

### **General Principles**

- **UI/UX Consistency:** All new UI components (screens, dialogs, buttons, fields) must adhere to the existing application theme. This includes colors, fonts, spacing, and overall visual language to ensure a seamless and consistent user experience.
- **Code Quality:** New code should be clean, readable, and well-documented. Services should be used to separate business logic from the UI.

---

### **Phase 1: Data Modeling & Initial Setup**

- [X] **Task 1.1: Create Subject Collection in Firestore**
  - [X] Set up a new root collection in Firestore called `subjects`.
  - [X] Define the structure for subject documents (e.g., `subjectName`, `year`, `code`, `department`).
  - [ ] **Action:** Awaiting the list of subjects from the user to populate this collection.

- [X] **Task 1.2: Update User Data Model**
  - [X] Modify the `users` collection to add role-specific fields:
    - [X] For **students**: Add `enrolledSubjects` (List of subject IDs).
    - [X] For **miniProfs/Profs**: Add `teachingSubjects` (List of subject IDs).

- [X] **Task 1.3: Create Plan File**
  - [X] This `todo.md` file has been created and is being maintained.

---

### **Phase 2: Subject Management for Professors & Assistants**

- [X] **Task 2.1: Create "Select Teaching Subjects" Screen**
  - [X] Built a generic `SubjectSelectionScreen` to display all subjects from the `subjects` collection.
  - [X] Allows `miniProf`/`prof` users to select/deselect the subjects they teach.

- [X] **Task 2.2: Add Conditional Profile Option**
  - [X] Added a "My Subjects" button to the profile options menu.
  - [X] Made this button visible **only** to `miniProf` and `prof` roles.

- [X] **Task 2.3: Save Selections to Firestore**
  - [X] Implemented `updateTeachingSubjects` logic in `UserProfileProvider` to update the user's document in Firestore.

---

### **Phase 3: Subject Enrollment for Students**

- [X] **Task 3.1: Create "Enroll in Courses" Screen**
  - [X] Reused the `SubjectSelectionScreen` for students to select their subjects.

- [X] **Task 3.2: Add Profile Option for Students**
  - [X] Added a "My Courses" button to the student profile options.

- [X] **Task 3.3: Save Enrollments to Firestore**
  - [X] Implemented `updateEnrolledSubjects` logic in `UserProfileProvider` to update the student's document.

---

### **Phase 4: Implement the `miniProf` Profile View**

- [X] **Task 4.1: Create `MiniProfProfile` Widget**
  - [X] Developed a new profile widget `miniprof_profile_view.dart`.

- [X] **Task 4.2: Implement Role-Based Profile Switching**
  - [X] Added logic to the main `Profile` screen to check the current user's role and display the appropriate view.

- [X] **Task 4.3: Display Teaching Subjects**
  - [X] The `Profile` screen now fetches and displays the list of subjects from the user's `teachingSubjects` or `enrolledSubjects` field.

---

### **Phase 5: Dynamic Content Filtering**

- [X] **Task 5.1: Filter Subjects Tab**
  - [X] Refactored the "Subjects" tab in the profile to only show subjects the user is enrolled in or teaches, using `SubjectProvider`.

- [X] **Task 5.2: Filter Sections Tab**
  - [X] Refactored the "Sections" tab to be dynamic.
  - [X] Created `Section` data model (`section_model.dart`).
  - [X] Created `SectionService` to fetch data from Firestore.
  - [X] Refactored `SectionProvider` to use the service and manage state.
  - [X] Fixed breaking changes caused by `SectionProvider` refactor.
  - [X] Integrated `SectionProvider` into the `Profile` screen.
  - [X] Refactored the `sections.dart` UI to display dynamic data.

- [X] **Task 5.3: Filter Tasks Tab**
  - [X] Associated tasks with subjects by adding `subjectId` to the `Task` model.
  - [X] Refactored the "Add/Edit Task" dialog to support subject and section selection.
  - [X] Filtered the "Week's Tasks" tab to show only tasks related to the student's enrolled subjects.

- [X] **Task 5.4: Implement Student Enrollment by Professors/Assistants**
  - [X] Created a `StudentEnrollmentScreen` to list all students.
  - [X] Allowed professors/assistants to select a student and manage their subject enrollments.
  - [X] Added an entry point in the profile options menu for this feature.
  - [X] Enhanced `UserProfileProvider` to fetch all users and update other users' profiles.

---

### **Phase 6: Content Management and Communication**

- [X] **Task 6.1: Global Subject Management for Admins**
  - [X] Created a screen for `Super Admins` to add, edit, and delete subjects globally.
  - [X] This provides a UI to manage the central `subjects` collection, accessible from the profile menu.
<!-- 
- [ ] **Task 6.2: Announcements Module**
  - [ ] Design and create an `announcements` collection in Firestore, linked to `subjectId`.
  - [ ] Build a UI for professors/assistants to post announcements for their subjects.
  - [ ] Create a UI for students to view announcements for their enrolled subjects.

- [ ] **Task 6.3: Course Materials Module**
  - [ ] Design and create a `materials` collection in Firestore, linked to `subjectId`.
  - [ ] Implement file upload functionality (e.g., to Firebase Storage).
  - [ ] Build a UI for professors to upload and manage materials.
  - [ ] Create a UI for students to view and download materials. -->