import 'package:flutter/material.dart';
import 'notification.dart';

/// Manages in-app notifications
class NotificationManager with ChangeNotifier {
  final List<GameNotification> _notifications = [];
  
  // Getters
  List<GameNotification> get notifications => List.unmodifiable(_notifications);
  List<GameNotification> get unreadNotifications => 
      _notifications.where((notification) => !notification.isRead).toList();
  int get unreadCount => unreadNotifications.length;
  
  /// Add a new notification
  void addNotification(GameNotification notification) {
    _notifications.add(notification);
    notifyListeners();
  }
  
  /// Mark a notification as read
  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }
  
  /// Mark all notifications as read
  void markAllAsRead() {
    for (var i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    notifyListeners();
  }
  
  /// Clear a specific notification
  void removeNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();
  }
  
  /// Clear all notifications
  void clearAllNotifications() {
    _notifications.clear();
    notifyListeners();
  }
}
