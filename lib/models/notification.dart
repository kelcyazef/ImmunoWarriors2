import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Different types of alerts in the game
enum NotificationType {
  attack,        // Player's base was attacked
  research,      // Research completed
  reward,        // Reward received 
  system,        // System message
}

/// Represents a notification/alert in the game
class GameNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final Map<String, dynamic>? additionalData;
  final bool isRead;
  
  const GameNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.additionalData,
    this.isRead = false,
  });
  
  /// Create a notification from Firestore data
  factory GameNotification.fromMap(Map<String, dynamic> map, String docId) {
    return GameNotification(
      id: docId,
      title: map['title'] ?? 'Notification',
      message: map['message'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.${map['type']}',
        orElse: () => NotificationType.system,
      ),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      additionalData: map['additionalData'],
      isRead: map['isRead'] ?? false,
    );
  }
  
  /// Convert notification to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'type': type.toString().split('.').last,
      'timestamp': FieldValue.serverTimestamp(),
      'additionalData': additionalData,
      'isRead': isRead,
    };
  }
  
  /// Create a copy of this notification with some properties changed
  GameNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? timestamp,
    Map<String, dynamic>? additionalData,
    bool? isRead,
  }) {
    return GameNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      additionalData: additionalData ?? this.additionalData,
      isRead: isRead ?? this.isRead,
    );
  }
  
  /// Get icon data for this notification type
  IconData get icon {
    switch (type) {
      case NotificationType.attack:
        return Icons.security;
      case NotificationType.research:
        return Icons.science;
      case NotificationType.reward:
        return Icons.emoji_events;
      case NotificationType.system:
        return Icons.notifications;
    }
  }
  
  /// Get color for this notification type
  Color get color {
    switch (type) {
      case NotificationType.attack:
        return Colors.red;
      case NotificationType.research:
        return Colors.blue;
      case NotificationType.reward:
        return Colors.amber;
      case NotificationType.system:
        return Colors.purple;
    }
  }
}

/// Create factory methods for common notification types
class NotificationFactory {
  /// Create attack notification
  static GameNotification createAttackNotification({
    required String id,
    required String attackerName,
    required bool wasSuccessful,
    required int resourcesLost,
    Map<String, dynamic>? battleDetails,
  }) {
    final outcome = wasSuccessful ? 'successful' : 'unsuccessful';
    
    return GameNotification(
      id: id,
      title: 'Base Attack',
      message: '$attackerName launched a ${outcome} attack on your base! ${wasSuccessful ? "You lost $resourcesLost resources." : "Your defenses held!"}',
      type: NotificationType.attack,
      timestamp: DateTime.now(),
      additionalData: {
        'attackerName': attackerName,
        'wasSuccessful': wasSuccessful,
        'resourcesLost': resourcesLost,
        'battleDetails': battleDetails,
      },
    );
  }
  
  /// Create research completed notification
  static GameNotification createResearchNotification({
    required String id,
    required String researchName,
    required String description,
  }) {
    return GameNotification(
      id: id,
      title: 'Research Completed',
      message: 'Your scientists have completed research on $researchName! $description',
      type: NotificationType.research,
      timestamp: DateTime.now(),
      additionalData: {
        'researchName': researchName,
        'description': description,
      },
    );
  }
  
  /// Create reward notification
  static GameNotification createRewardNotification({
    required String id,
    required int energyAmount,
    required int biomaterialsAmount,
    required String source,
  }) {
    return GameNotification(
      id: id,
      title: 'Reward Received',
      message: 'You received $energyAmount energy and $biomaterialsAmount biomaterials from $source!',
      type: NotificationType.reward,
      timestamp: DateTime.now(),
      additionalData: {
        'energyAmount': energyAmount,
        'biomaterialsAmount': biomaterialsAmount,
        'source': source,
      },
    );
  }
  
  /// Create system notification
  static GameNotification createSystemNotification({
    required String id,
    required String title,
    required String message,
  }) {
    return GameNotification(
      id: id,
      title: title,
      message: message,
      type: NotificationType.system,
      timestamp: DateTime.now(),
    );
  }
}
