import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new user profile
  Future<void> createUserProfile({
    required String userId,
    required String email,
  }) async {
    final userProfile = UserProfile(
      id: userId,
      displayName: email.split('@')[0], // Simple display name from email
      lastLogin: DateTime.now(),
    );

    await _firestore
        .collection('users')
        .doc(userId)
        .set(userProfile.toMap());
  }

  // Get user profile stream
  Stream<UserProfile?> getUserProfile(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? UserProfile.fromDocument(doc) : null);
  }

  // Update user profile
  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .update(data);
  }
}
