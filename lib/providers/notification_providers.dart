import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification.dart';
import '../models/notification_manager.dart';
import 'auth_providers.dart';
import 'firestore_providers.dart';

/// Provider for the notification manager
final notificationManagerProvider = ChangeNotifierProvider<NotificationManager>((ref) {
  return NotificationManager();
});

/// Provider for user's notifications from Firestore
final notificationsProvider = StreamProvider<List<GameNotification>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  
  return ref.watch(firestoreServiceProvider).getNotifications(user.uid);
});

/// Provider for unread notification count
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider);
  return notifications.when(
    data: (notifications) => 
        notifications.where((n) => !n.isRead).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider for the most recent notification
final latestNotificationProvider = Provider<GameNotification?>((ref) {
  final notifications = ref.watch(notificationsProvider);
  return notifications.when(
    data: (notifications) => 
        notifications.isEmpty ? null : notifications.first,
    loading: () => null,
    error: (_, __) => null,
  );
});
