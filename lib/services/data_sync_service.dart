import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../providers/auth_providers.dart';
import '../providers/firestore_providers.dart';
import '../providers/game_providers.dart';

/// Service for synchronizing data between Firestore and local state
class DataSyncService {
  final Ref ref;
  
  DataSyncService(this.ref);
  
  /// Initialize local state from Firestore data
  Future<void> syncUserDataFromFirestore(UserProfile profile) async {
    try {
      // Update resources with values from user profile
      final resources = ref.read(resourcesProvider);
      resources.updateEnergie(profile.currentEnergie);
      resources.updateBiomateriaux(profile.currentBiomateriaux);
      
      // Update research points
      final memoireImmunitaire = ref.read(memoireImmunitaireProvider);
      memoireImmunitaire.setResearchPoints(profile.researchPoints);
      
      // Load immune memory signatures
      for (final signature in profile.immuneMemorySignatures) {
        if (signature.isNotEmpty) {
          memoireImmunitaire.addSignatureFromName(signature);
        }
      }
    } catch (e) {
      print('Error syncing from Firestore: $e');
    }
  }
  
  /// Save local state to Firestore
  Future<void> syncUserDataToFirestore() async {
    try {
      final authState = ref.read(authStateProvider);
      final firestoreService = ref.read(firestoreServiceProvider);
      
      if (authState.value != null) {
        final userId = authState.value!.uid;
        
        final resources = ref.read(resourcesProvider);
        final memoireImmunitaire = ref.read(memoireImmunitaireProvider);
        
        // Get current user profile to preserve other fields
        final userProfileAsync = ref.read(userProfileProvider);
        
        await userProfileAsync.whenData((profile) async {
          if (profile != null) {
            // Get immune memory signatures
            final signatures = memoireImmunitaire.signatures
                .map((sig) => sig.pathogenName)
                .where((name) => name.isNotEmpty)
                .toList();
            
            // Update user profile with current values
            final updateData = {
              'currentEnergie': resources.currentEnergie,
              'currentBiomateriaux': resources.currentBiomateriaux,
              'researchPoints': memoireImmunitaire.researchPoints,
              'immuneMemorySignatures': signatures,
              'victories': profile.victories,
              'lastLogin': DateTime.now().toIso8601String(),
            };
            
            await firestoreService.updateUserProfile(userId, updateData);
          }
        });
      }
    } catch (e) {
      print('Error syncing to Firestore: $e');
    }
  }
  
  /// Force a full sync cycle (from Firestore to local and back)
  Future<void> performFullSync() async {
    try {
      // Get current user
      final authState = ref.read(authStateProvider);
      if (authState.value == null) {
        return;
      }
      
      // Get current user profile
      final userProfileAsync = ref.read(userProfileProvider);
      await userProfileAsync.whenData((profile) async {
        if (profile != null) {
          // First sync from Firestore to local
          await syncUserDataFromFirestore(profile);
          
          // Then sync from local back to Firestore
          await syncUserDataToFirestore();
        }
      });
    } catch (e) {
      print('Error performing full sync: $e');
    }
  }
}

final dataSyncServiceProvider = Provider<DataSyncService>((ref) {
  return DataSyncService(ref);
});
