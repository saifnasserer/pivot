// Import scripts required by Firebase
importScripts('https://www.gstatic.com/firebasejs/10.8.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.8.0/firebase-messaging-compat.js');

// Initialize the Firebase app in the service worker by passing in your app's Firebase config object
firebase.initializeApp({
  apiKey: "AIzaSyBVINq4q-n6WxDMQugnktHYg_r_zwRKD7w",
  authDomain: "pivot-28563.firebaseapp.com",
  projectId: "pivot-28563",
  storageBucket: "pivot-28563.firebasestorage.app",
  messagingSenderId: "961104767168",
  appId: "1:961104767168:web:3494534af9801736cb2525",
  measurementId: "G-MTDPKDS6WJ"
});

// Retrieve an instance of Firebase Messaging so that it can handle background messages
const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  // Customize notification here to match mobile look
  const notification = payload.notification || {};
  const data = payload.data || {};
  const imageUrl = data.image_url || notification.image;
  const notificationTitle = notification.title || 'Pivot';
  const notificationOptions = {
    body: notification.body,
    icon: imageUrl || '/icons/ic_notification.png', // Use ic_notification.png for fallback
    badge: '/icons/ic_notification.png',
    image: imageUrl, // Show big image if present
    data: data,
    tag: 'pivot-message',
    renotify: true,
    requireInteraction: true
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
}); 