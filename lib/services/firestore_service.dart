import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../models/notification.dart';
import 'dart:math';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  // Create a new user profile with complete initialization
  Future<void> createUserProfile({
    required String userId,
    required String email,
  }) async {
    // Create a complete user profile with default values
    final userProfile = UserProfile(
      id: userId,
      displayName: email.split('@')[0], // Simple display name from email
      currentEnergie: 100,
      currentBiomateriaux: 50,
      immuneMemorySignatures: const [],
      researchPoints: 0,
      victories: 0,
      lastLogin: DateTime.now(),
    );

    // Convert to map and make sure all fields are explicitly set
    final userData = userProfile.toMap();
    
    // Create the user document with complete data
    await _firestore
        .collection('users')
        .doc(userId)
        .set(userData);
        
    print('New user profile created in Firestore: $userId');
  }

  // Get user profile stream
  Stream<UserProfile?> getUserProfile(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? UserProfile.fromDocument(doc) : null);
  }
  
  // Get user profile directly (not as a stream)
  Future<UserProfile?> getUserProfileOnce(String userId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .get();
    
    return doc.exists ? UserProfile.fromDocument(doc) : null;
  }

  // Update user profile
  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .update(data);
  }
  
  // Get viral bases from other users
  Stream<List<Map<String, dynamic>>> getEnemyBases(String currentUserId) {
    return _firestore
        .collection('viralBases')
        .where('ownerId', isNotEqualTo: currentUserId) // Exclude current user's bases
        .limit(10) // Limit to 10 bases for performance
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            // If no user bases found, return system-generated bases
            return _generateSystemBases();
          }
          
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id; // Add document ID
            return data;
          }).toList();
        });
  }
  
  // Create or update a viral base
  Future<void> saveViralBase(String userId, Map<String, dynamic> baseData) async {
    // Check if the user already has a base
    final existingBases = await _firestore
        .collection('viralBases')
        .where('ownerId', isEqualTo: userId)
        .get();
    
    if (existingBases.docs.isNotEmpty) {
      // Update existing base
      await _firestore
          .collection('viralBases')
          .doc(existingBases.docs.first.id)
          .update(baseData);
    } else {
      // Create new base
      baseData['ownerId'] = userId;
      baseData['createdAt'] = FieldValue.serverTimestamp();
      await _firestore
          .collection('viralBases')
          .add(baseData);
    }
  }
  
  // Record a battle in history
  Future<void> recordBattle({
    required String userId,
    required String enemyBaseName,
    required bool victory,
    required int rewardPoints,
    required int resourcesGained,
  }) async {
    final battleData = {
      'timestamp': FieldValue.serverTimestamp(),
      'enemyBaseName': enemyBaseName,
      'victory': victory,
      'rewardPoints': rewardPoints,
      'resourcesGained': resourcesGained,
    };
    
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('battles')
        .add(battleData);
        
    // Create a notification about the battle
    if (victory) {
      await createNotification(
        userId: userId,
        notification: NotificationFactory.createRewardNotification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          energyAmount: resourcesGained,
          biomaterialsAmount: resourcesGained ~/ 2,  // Assuming half the resources are biomaterials
          source: 'battle with $enemyBaseName',
        ),
      );
    } else {
      await createNotification(
        userId: userId,
        notification: NotificationFactory.createSystemNotification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'Battle Lost',
          message: 'Your forces were defeated in battle against $enemyBaseName. Regroup and try again!',
        ),
      );
    }
  }
  
  /// Completely reset a user's data in Firestore (profile data, battles, bases, etc.)
  Future<void> resetUserData(String userId, String email) async {
    
    try {
      // 1. Delete all battles in the subcollection
      final battles = await _firestore
          .collection('users')
          .doc(userId)
          .collection('battles')
          .get();
      
      for (var doc in battles.docs) {
        await doc.reference.delete();
      }
      
      // 2. Delete any viral bases owned by this user
      final bases = await _firestore
          .collection('viralBases')
          .where('ownerId', isEqualTo: userId)
          .get();
      
      for (var doc in bases.docs) {
        await doc.reference.delete();
      }
      
      // 3. Delete all notifications
      final notifications = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .get();
      
      for (var doc in notifications.docs) {
        await doc.reference.delete();
      }
      
      // 4. Reset the user profile to default values
      final defaultUserProfile = UserProfile(
        id: userId,
        displayName: email.split('@')[0],
        currentEnergie: 100,
        currentBiomateriaux: 50,
        immuneMemorySignatures: const [],
        researchPoints: 0,
        victories: 0,
        lastLogin: DateTime.now(),
      );
      
      // Update user profile with default values
      await _firestore
          .collection('users')
          .doc(userId)
          .set(defaultUserProfile.toMap());
      
      // Add a system notification about the reset
      await createNotification(
        userId: userId,
        notification: NotificationFactory.createSystemNotification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'Game Reset Complete',
          message: 'Your game has been completely reset to default values. All progress has been cleared.',
        ),
      );
      
      print('User data completely reset in Firestore for user: $userId');
    } catch (e) {
      print('Error resetting user data in Firestore: $e');
      rethrow;
    }
  }
  
  // Add a pathogen signature to the user's immune memory
  Future<void> addPathogenSignature(String userId, String pathogenName) async {
    // First check if the signature already exists to avoid duplicates
    final userDoc = await _firestore.collection('users').doc(userId).get();
    
    if (userDoc.exists) {
      final userData = userDoc.data() ?? {};
      final List<String> signatures = List<String>.from(userData['immuneMemorySignatures'] ?? []);
      
      // Only add if it doesn't already exist
      if (!signatures.contains(pathogenName)) {
        signatures.add(pathogenName);
        await _firestore.collection('users').doc(userId).update({
          'immuneMemorySignatures': signatures,
        });
      }
    }
  }
  
  // Get battle history for a user
  Stream<List<Map<String, dynamic>>> getBattleHistory(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('battles')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }
  
  /// Get notifications for a user
  Stream<List<GameNotification>> getNotifications(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(20) // Limit to most recent 20 notifications
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return GameNotification.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }
  
  /// Create a new notification
  Future<void> createNotification({
    required String userId,
    required GameNotification notification,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notification.id)
        .set(notification.toMap());
  }
  
  /// Mark a notification as read
  Future<void> markNotificationAsRead(String userId, String notificationId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }
  
  /// Mark all notifications as read
  Future<void> markAllNotificationsAsRead(String userId) async {
    final batch = _firestore.batch();
    final notifications = await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();
        
    for (var doc in notifications.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    
    await batch.commit();
  }
  
  /// Delete a notification
  Future<void> deleteNotification(String userId, String notificationId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }
  
  /// Delete a document from a specific collection
  Future<void> deleteDocument(String collection, String documentId) async {
    try {
      await _firestore
          .collection(collection)
          .doc(documentId)
          .delete();
      print('Document deleted: $collection/$documentId');
    } catch (e) {
      print('Error deleting document: $e');
      rethrow;
    }
  }
  
  // Generate system bases when not enough user bases are available
  List<Map<String, dynamic>> _generateSystemBases() {
    final threatLevels = ['Facile', 'Modéré', 'Difficile'];
    final pathogenTypes = ['Influenza Virus', 'Staphylococcus', 'Candida Albicans', 'E. Coli', 'Coronavirus'];
    
    return List.generate(3, (index) {
      final threatLevel = threatLevels[_random.nextInt(threatLevels.length)];
      final baseNumber = index + 1;
      
      // Determine number of pathogens based on difficulty
      int pathogenCount;
      Map<String, dynamic> rewards;
      
      switch (threatLevel) {
        case 'Facile':
          pathogenCount = 2;
          rewards = {'energie': 20, 'biomateriaux': 15, 'points': 5};
          break;
        case 'Modéré':
          pathogenCount = 3;
          rewards = {'energie': 35, 'biomateriaux': 25, 'points': 10};
          break;
        case 'Difficile':
          pathogenCount = 4;
          rewards = {'energie': 50, 'biomateriaux': 40, 'points': 15};
          break;
        default:
          pathogenCount = 2;
          rewards = {'energie': 20, 'biomateriaux': 15, 'points': 5};
      }
      
      // Generate random pathogens
      final pathogens = List.generate(pathogenCount, (_) {
        return pathogenTypes[_random.nextInt(pathogenTypes.length)];
      });
      
      return {
        'id': 'system-base-$baseNumber',
        'name': 'Base Virale ${String.fromCharCode(65 + index)}', // Alpha, Beta, Gamma
        'owner': 'Système',
        'ownerId': 'system',
        'threatLevel': threatLevel,
        'pathogens': pathogens,
        'rewards': rewards,
        'createdAt': DateTime.now().toIso8601String(),
      };
    });
  }
}
