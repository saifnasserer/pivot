# Offline Support - Quick Testing Checklist ✅

## 🚀 **5-Minute Smoke Test**

### **Quick Test 1: Basic Offline Login** (2 mins)

```
1. [ ] Login with internet ✓
2. [ ] Close app completely
3. [ ] Turn OFF WiFi & Mobile Data
4. [ ] Reopen app
5. [ ] ✅ Should see profile + orange banner
```

### **Quick Test 2: Connectivity Toggle** (1 min)

```
1. [ ] Start app offline (from Test 1)
2. [ ] Turn ON internet
3. [ ] ✅ Orange banner should disappear immediately
4. [ ] Turn OFF internet
5. [ ] ✅ Orange banner should reappear
```

### **Quick Test 3: Profile Access** (1 min)

```
1. [ ] Go to Profile tab (online)
2. [ ] Turn OFF internet
3. [ ] Navigate away and back to Profile
4. [ ] ✅ Profile should load from cache (no errors)
```

### **Quick Test 4: First Launch Offline** (1 min)

```
1. [ ] Logout OR fresh install
2. [ ] Turn OFF internet
3. [ ] Try to login
4. [ ] ✅ Should show: "يجب الاتصال بالإنترنت لأول مرة"
```

---

## 📋 **Detailed Feature Checklist**

### **Authentication & Session**

- [ ] Offline login works after first online login
- [ ] Session persists across app restarts
- [ ] Logout clears cached credentials
- [ ] Session expires after 30 days
- [ ] Clear error messages for offline login attempts

### **UI Indicators**

- [ ] Orange banner appears when offline
- [ ] Banner disappears when online
- [ ] Blue sync banner shows when operations pending
- [ ] Sync button works in sync banner
- [ ] No Firebase errors visible to users

### **Profile & Data**

- [ ] Profile loads from cache when offline
- [ ] User data displays correctly offline
- [ ] No "Failed to connect" errors
- [ ] isOffline flag works in UserProfileState

### **Offline Queue**

- [ ] Operations queue when offline
- [ ] Queue count displays correctly
- [ ] Automatic sync when connection restored
- [ ] Manual sync button works
- [ ] Failed operations retry (max 3 times)
- [ ] Old operations cleanup (7+ days)

### **Connectivity Monitoring**

- [ ] Real-time detection of connection changes
- [ ] Smooth transitions between online/offline
- [ ] No crashes during connectivity changes
- [ ] OfflineService initializes properly

### **Cache Management**

- [ ] User profile caches correctly
- [ ] Cached data loads quickly (<1 sec)
- [ ] Cache survives app restarts
- [ ] Cache cleared on logout

---

## 🐛 **Bug Testing**

### **Crash Tests**

- [ ] App doesn't crash when going offline
- [ ] App doesn't crash when coming online
- [ ] App doesn't crash on rapid connectivity changes
- [ ] Force kill and restart works offline

### **Edge Cases**

- [ ] Multiple rapid login/logout cycles
- [ ] Large queue (50+ operations)
- [ ] Intermittent connection
- [ ] Airplane mode toggle
- [ ] Corrupted cache handling

### **Performance**

- [ ] Offline login < 2 seconds
- [ ] Cached profile load < 1 second
- [ ] Connectivity detection < 100ms
- [ ] No memory leaks from listeners

---

## 📊 **Console Log Verification**

### **On App Start (Offline):**

```
✅ Expected logs:
🔌 Initializing OfflineService...
📡 OfflineService initialized - Connection: ❌ Offline
📦 Initializing OfflineQueueService...
✅ OfflineQueueService initialized
🔐 Checking active session...
📡 Connection: Offline
💾 Cached session: Available
🔌 Offline mode with cached session - loading cached profile
📦 Loading offline profile for: [userId]
✅ Loaded cached profile: [userName]
```

### **On App Start (Online):**

```
✅ Expected logs:
🔌 Initializing OfflineService...
📡 OfflineService initialized - Connection: ✅ Online
📦 Initializing OfflineQueueService...
✅ OfflineQueueService initialized
🔐 Checking active session...
🔥 Firebase session found: [userEmail]
```

### **When Going Offline:**

```
✅ Expected logs:
📡 Connectivity changed: ❌ Went Offline
```

### **When Coming Online:**

```
✅ Expected logs:
📡 Connectivity changed: ✅ Back Online
✅ Connection restored - triggering queue sync
🔄 Syncing [X] queued operations...
```

---

## 🎯 **Success Criteria**

All items below should be TRUE:

### **Functionality**

- ✅ Can login offline with cached credentials
- ✅ Profile loads without errors when offline
- ✅ Clear visual indicators of offline state
- ✅ Operations queue and sync properly
- ✅ No crashes during connectivity changes

### **User Experience**

- ✅ No Firebase errors shown to users
- ✅ Clear Arabic error messages
- ✅ Smooth online/offline transitions
- ✅ Fast cached data loading
- ✅ Helpful user guidance

### **Technical**

- ✅ All services initialize properly
- ✅ No console errors
- ✅ Memory usage stable
- ✅ No infinite loops
- ✅ Clean architecture

---

## 🚨 **If Something Fails**

### **Issue: Offline banner not showing**

```dart
// Check in any widget:
final isOnline = ref.watch(isOnlineProvider);
print('Is online: $isOnline');

// Check service:
print('Connection: ${OfflineService().hasConnection}');
```

### **Issue: Can't login offline**

```dart
// Check session:
final hasCached = await SessionPersistenceService().hasCachedSession();
print('Has cached session: $hasCached');

// Check session info:
final info = await SessionPersistenceService().getSessionInfo();
print('Session info: $info');
```

### **Issue: Queue not syncing**

```dart
// Check queue:
final count = OfflineQueueService().getQueueCount();
print('Queue count: $count');

// Check queue stats:
final stats = OfflineQueueService().getQueueStats();
print('Queue stats: $stats');
```

### **Issue: Profile not loading offline**

```dart
// Check cache:
final userId = 'your_user_id';
final cached = CacheService.instance.getCachedUserProfile(userId);
print('Cached profile: ${cached?.name}');
```

---

## 📱 **Device-Specific Tests**

### **Android**

- [ ] Test on Android 8+
- [ ] Test with WiFi only
- [ ] Test with Mobile Data only
- [ ] Test airplane mode
- [ ] Test background/foreground transitions

### **iOS**

- [ ] Test on iOS 12+
- [ ] Test with WiFi only
- [ ] Test with Mobile Data only
- [ ] Test airplane mode
- [ ] Test background/foreground transitions

---

## ✅ **Final Verification**

Before marking complete, verify:

1. **Core Features**

   - [ ] Offline login works
   - [ ] Profile loads offline
   - [ ] Sync works when back online

2. **UI/UX**

   - [ ] Indicators visible and correct
   - [ ] No technical errors to users
   - [ ] Smooth transitions

3. **Stability**

   - [ ] No crashes
   - [ ] No memory leaks
   - [ ] Clean console logs

4. **Documentation**
   - [ ] README updated
   - [ ] API docs clear
   - [ ] Testing guide complete

---

## 🎉 **Testing Complete!**

Once all items are checked, your offline support is:

- ✅ **Fully Functional**
- ✅ **User-Friendly**
- ✅ **Production Ready**

**Congratulations! Your app now works seamlessly offline! 🚀**

---

## 📞 **Need Help?**

1. Check console logs first
2. Review `OFFLINE_IMPLEMENTATION_COMPLETE.md`
3. Verify services initialized in `main.dart`
4. Test on physical device (not simulator)
5. Check this checklist for debugging tips

**Happy Testing! 🧪**
