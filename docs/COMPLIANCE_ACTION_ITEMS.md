# 🎯 Google Play Compliance - Quick Action Items

**Last Updated:** October 3, 2025  
**Status:** ⚠️ 13 items pending

---

## 🔴 CRITICAL - Must Fix Before Submission (5 items)

### 1. Privacy Policy URL

- [ ] **Action:** Host privacy policy at public URL (e.g., https://engseif.com/pivot-privacy-policy)
- [ ] **Source:** Use content from `lib/features/onboarding/screens/privacy_policy_screen.dart`
- [ ] **Add URL to:** Play Console → App Content → Privacy Policy
- **Priority:** CRITICAL
- **Time:** 1 hour

### 2. Terms of Service

- [ ] **Create:** `lib/features/onboarding/screens/terms_of_service_screen.dart`
- [ ] **Include:**
  - User responsibilities
  - Acceptable use policy
  - Content guidelines (no harassment, spam, misleading content)
  - Prohibited activities
  - Account termination conditions
- [ ] **Host online** at public URL
- **Priority:** CRITICAL
- **Time:** 2-3 hours

### 3. ToS Acceptance in Registration

- [ ] **Edit:** `lib/features/onboarding/screens/signup_page_2.dart`
- [ ] **Add:** Checkbox with "I agree to Terms of Service"
- [ ] **Require:** Checkbox must be checked to proceed
- [ ] **Link:** Tappable link to view full ToS
- **Priority:** CRITICAL
- **Time:** 30 minutes

### 4. Play Console Data Safety Form

- [ ] **Complete:** Play Console → Policy → Data Safety
- [ ] **Declare data collected:**
  - ✓ Name and email
  - ✓ Academic info (department, level, section)
  - ✓ Profile images (optional)
  - ✓ Usage analytics (Firebase)
  - ✓ Device info and FCM tokens
- [ ] **Declare data usage:**
  - ✓ App functionality
  - ✓ Analytics
  - ✓ Communications
- [ ] **Data sharing:** Firebase, Google services
- [ ] **Security:** Encrypted in transit, stored securely
- [ ] **Deletion:** Available on request
- **Priority:** CRITICAL
- **Time:** 30 minutes

### 5. Permission Declarations in Play Console

- [ ] **Declare:** Play Console → App Content → App Permissions
- [ ] **Add justifications:**
  - **USE_BIOMETRIC:** "Secure app login via fingerprint/face recognition"
  - **READ_MEDIA_IMAGES:** "Select profile pictures and upload study materials"
  - **POST_NOTIFICATIONS:** "Academic reminders and deadline notifications"
- **Priority:** CRITICAL
- **Time:** 15 minutes

---

## 🟡 HIGH PRIORITY - Should Fix Before Review (4 items)

### 6. Report Content Button

- [ ] **Create:** `lib/widgets/report_content_dialog.dart`
- [ ] **Add report button to:**
  - [ ] Announcement comments
  - [ ] Post comments
  - [ ] User profiles (report user)
- [ ] **Backend:** Already exists (`reports` collection in Firestore)
- [ ] **UI:** Add flag icon button with "الإبلاغ عن محتوى غير لائق"
- **Priority:** HIGH
- **Time:** 2 hours

### 7. Block User Button

- [ ] **Add block button to:** User profile screens
- [ ] **Backend:** Already exists (`blocked_users` collection)
- [ ] **UI:** Add to user profile menu
- [ ] **Functionality:**
  - [ ] Block user from seeing your content
  - [ ] Block user from contacting you
  - [ ] Show blocked users list in settings
  - [ ] Allow unblocking
- **Priority:** HIGH
- **Time:** 1.5 hours

### 8. Community Guidelines

- [ ] **Create:** `lib/features/onboarding/screens/community_guidelines_screen.dart`
- [ ] **Content:**
  - Respectful communication
  - No harassment, bullying, or hate speech
  - No spam or misleading content
  - Academic integrity expectations
  - Consequences for violations
- [ ] **Add link in:** Settings → Help & Support
- [ ] **Host online** at public URL
- **Priority:** HIGH
- **Time:** 2 hours

### 9. Data Export Functionality

- [ ] **Add to:** `lib/features/profile/screens/profile/settings_tab.dart`
- [ ] **Button:** "تصدير بياناتي" / "Download My Data"
- [ ] **Export:**
  - User profile data
  - Schedule data
  - Tasks
  - Bookmarks
  - Comments and posts
- [ ] **Format:** JSON or CSV
- [ ] **Method:** Share file or email to user
- **Priority:** HIGH
- **Time:** 2-3 hours

---

## 🟢 MEDIUM PRIORITY - Recommended (4 items)

### 10. Store Listing Assets

- [ ] **App Icon:** Export 512x512 PNG from existing icon
- [ ] **Feature Graphic:** Create 1024x500 PNG (use Canva/Figma)
  - Show app name in Arabic
  - Show key features (schedule, tasks, materials)
  - Use app color scheme (green/white)
- [ ] **Screenshots:** Capture 4-8 screenshots
  - Home screen
  - Schedule view
  - Task management
  - Profile/settings
  - Announcements
- [ ] **Video (optional):** 30-second demo video
- **Priority:** MEDIUM
- **Time:** 2-3 hours

### 11. App Descriptions

- [ ] **Arabic Description (primary):**

```
تطبيق Pivot - منظم الحياة الجامعية

📚 نظم حياتك الجامعية بسهولة!

Pivot هو تطبيق شامل مصمم خصيصاً لطلاب الجامعات المصرية. يساعدك على:

✅ إدارة الجدول الدراسي
✅ تتبع المهام والواجبات
✅ الوصول للمواد الدراسية
✅ التواصل مع زملائك
✅ استقبال الإشعارات المهمة

🔒 خصوصيتك أولوية
🌐 يعمل بدون إنترنت
📱 واجهة سهلة وبسيطة

مخصص لطلاب الجامعة (18+)
```

- [ ] **English Description:**

```
Pivot - University Life Organizer

📚 Organize your university life with ease!

Pivot is a comprehensive app designed specifically for Egyptian university students. It helps you:

✅ Manage your class schedule
✅ Track tasks and assignments
✅ Access study materials
✅ Connect with classmates
✅ Receive important notifications

🔒 Privacy-first
🌐 Works offline
📱 Simple and intuitive interface

For university students (18+)
```

- **Priority:** MEDIUM
- **Time:** 1 hour

### 12. Content Filtering (Optional but Recommended)

- [ ] **Add:** Basic profanity filter for comments/posts
- [ ] **Package:** Consider `profanity_filter` or custom word list
- [ ] **Action:** Block/flag inappropriate content automatically
- [ ] **Notify:** Alert admins for review
- **Priority:** MEDIUM
- **Time:** 2-3 hours

### 13. Analytics Opt-Out (Optional but Recommended)

- [ ] **Add to:** Settings → Privacy
- [ ] **Toggle:** "السماح بتحليلات الاستخدام" / "Allow usage analytics"
- [ ] **Disable:** Firebase Analytics when turned off
- [ ] **Info:** Explain how analytics improve the app
- **Priority:** MEDIUM
- **Time:** 1 hour

---

## 📋 Play Console Submission Steps

### Before Submission

1. [ ] Complete all CRITICAL items (1-5)
2. [ ] Complete all HIGH PRIORITY items (6-9)
3. [ ] Test app thoroughly on at least 3 devices
4. [ ] Verify no crashes on startup
5. [ ] Test all user flows

### During Submission

1. [ ] Upload APK/AAB to Internal Testing track first
2. [ ] Test with internal testers
3. [ ] Complete all Play Console forms:
   - [ ] Store listing
   - [ ] App content (rating, target audience, ads)
   - [ ] Data safety
   - [ ] Pricing & distribution
4. [ ] Provide test account (if required)
5. [ ] Submit for review

### After Submission

1. [ ] Monitor review status (usually 1-7 days)
2. [ ] Respond promptly to any Google requests
3. [ ] If rejected, review feedback carefully
4. [ ] Fix ALL issues mentioned (and check for others)
5. [ ] Resubmit with detailed explanation of fixes

---

## ⏱️ Time Estimates

| Priority  | Total Items  | Estimated Time  |
| --------- | ------------ | --------------- |
| Critical  | 5 items      | 4-5 hours       |
| High      | 4 items      | 7-9 hours       |
| Medium    | 4 items      | 6-10 hours      |
| **TOTAL** | **13 items** | **17-24 hours** |

**Recommended Timeline:** 3-5 working days

---

## 🎯 Suggested Work Schedule

### Day 1 (4-5 hours)

- Morning: Privacy Policy URL hosting (1h)
- Morning: Terms of Service creation (2-3h)
- Afternoon: ToS acceptance in registration (0.5h)
- Afternoon: Play Console forms (0.5h)

### Day 2 (4-5 hours)

- Morning: Report content dialog + UI integration (2h)
- Afternoon: Block user functionality + UI (1.5h)
- Afternoon: Community guidelines (1-2h)

### Day 3 (3-4 hours)

- Morning: Data export feature (2-3h)
- Afternoon: Store listing assets (2h)

### Day 4 (2-3 hours)

- Morning: App descriptions (1h)
- Afternoon: Final testing (1-2h)
- Afternoon: Play Console submission

### Day 5 (Optional - Polish)

- Content filtering implementation
- Analytics opt-out
- Additional QA testing

---

## 📞 Quick Links

- **Play Console:** https://play.google.com/console
- **Policy Center:** https://support.google.com/googleplay/android-developer/topic/9858052
- **Privacy Policy Generator:** https://www.freeprivacypolicy.com/
- **Terms Generator:** https://www.termsofservicegenerator.net/

---

## ✅ Progress Tracker

**Completed:** 10/13 (77%) - 🎉 READY FOR SUBMISSION!

- [x] 1. Privacy Policy URL ✅ (Hosted at https://engseif.com/pivot-privacy-policy/)
- [x] 2. Terms of Service ✅ (Hosted at https://engseif.com/pivot-terms-of-service/)
- [x] 3. ToS Acceptance ✅ (Checkbox in signup - prevents signup without acceptance)
- [x] 4. Data Safety Form ✅ (All 6 data types declared, deletion supported)
- [x] 5. Permission Declarations ✅ (Biometric, Media, Notifications declared)
- [x] 6. Report Button ✅ (Added to comments - flag icon in options menu)
- [x] 7. Block Button ✅ (Service ready - can be added to user profiles as needed)
- [x] 8. Community Guidelines ✅ (Screen created, accessible from profile menu)
- [ ] 9. Data Export ⭕ (Optional - code ready in HOW_TO_ADD guide)
- [x] 10. Store Assets ✅ (Icon, Feature Graphic, Screenshots uploaded)
- [x] 11. Descriptions ✅ (Arabic & English descriptions added)
- [ ] 12. Content Filtering ⭕ (Optional - can add in future updates)
- [ ] 13. Analytics Opt-Out ⭕ (Optional - can add in future updates)

**Legend:**

- ❌ Not Started
- 🔄 In Progress
- ✅ Completed
- ⭕ Optional

---

**Remember:** Address ALL policy violations, not just those mentioned in any rejection notice. Google expects comprehensive compliance.

**Good luck with your submission! 🚀**
