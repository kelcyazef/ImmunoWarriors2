import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../providers/auth_providers.dart';
import '../providers/firestore_providers.dart';
import '../providers/game_providers.dart';
import 'game_state_storage.dart';

/// Service for synchronizing data between local storage, Firestore, and app state
class DataSyncService {
  final Ref ref;
  bool _initialized = false;
  bool _isSyncing = false;
  
  DataSyncService(this.ref);
  
  /// Initialize the sync service and local storage
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      await GameStateStorage.initialize();
      _initialized = true;
      print('DataSyncService initialized');
    } catch (e) {
      print('Error initializing DataSyncService: $e');
    }
  }
  
  /// Load game state from local storage to app state
  Future<void> loadFromLocalStorage() async {
    await initialize();
    
    try {
      // Get values from local storage
      final energie = GameStateStorage.getEnergie();
      final biomateriaux = GameStateStorage.getBiomateriaux();
      final researchPoints = GameStateStorage.getResearchPoints();
      final signatures = GameStateStorage.getSignatures();
      
      // Update app state with local values
      final resources = ref.read(resourcesProvider);
      resources.updateEnergie(energie);
      resources.updateBiomateriaux(biomateriaux);
      
      final memoireImmunitaire = ref.read(memoireImmunitaireProvider);
      memoireImmunitaire.setResearchPoints(researchPoints);
      
      // Load immune memory signatures
      for (final signature in signatures) {
        if (signature.isNotEmpty) {
          memoireImmunitaire.addSignatureFromName(signature);
        }
      }
      
      print('Game state loaded from local storage. Energy: $energie, Biomaterials: $biomateriaux');
    } catch (e) {
      print('Error loading from local storage: $e');
    }
  }
  
  /// Save current app state to local storage
  Future<void> saveToLocalStorage() async {
    await initialize();
    
    try {
      final resources = ref.read(resourcesProvider);
      final memoireImmunitaire = ref.read(memoireImmunitaireProvider);
      
      // Get signatures from memory
      final signatures = memoireImmunitaire.signatures
          .map((sig) => sig.pathogenName)
          .where((name) => name.isNotEmpty)
          .toList();
      
      // Save all values to local storage
      await GameStateStorage.saveGameState(
        energie: resources.currentEnergie,
        biomateriaux: resources.currentBiomateriaux,
        researchPoints: memoireImmunitaire.researchPoints,
        victories: GameStateStorage.getVictories(), // Preserve victories
        signatures: signatures,
      );
      
      print('Game state saved to local storage');
    } catch (e) {
      print('Error saving to local storage: $e');
    }
  }
  
  /// Load data from Firestore and save to local storage
  Future<void> syncFromFirestore(UserProfile profile) async {
    await initialize();
    
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
      
      // Also save to local storage
      await GameStateStorage.saveGameState(
        energie: profile.currentEnergie,
        biomateriaux: profile.currentBiomateriaux,
        researchPoints: profile.researchPoints,
        victories: profile.victories,
        signatures: profile.immuneMemorySignatures,
      );
      
      print('Game state synced from Firestore and saved locally');
    } catch (e) {
      print('Error syncing from Firestore: $e');
    }
  }
  
  /// Save local state to Firestore
  Future<void> syncToFirestore() async {
    final authState = ref.read(authStateProvider);
    final currentUser = authState.value;
    
    // Check if user is logged in
    if (currentUser == null) {
      print('Cannot sync to Firestore: User not logged in');
      return;
    }
    
    if (_isSyncing) {
      print('Sync already in progress, skipping');
      return;
    }
    
    _isSyncing = true;
    
    try {
      // First save to local storage
      await saveToLocalStorage();
      
      // Get current app state
      final resources = ref.read(resourcesProvider);
      final memoireImmunitaire = ref.read(memoireImmunitaireProvider);
      final signatures = memoireImmunitaire.signatures.map((sig) => sig.pathogenName).toList();
      final victories = GameStateStorage.getVictories(); // Use storage victories count
      
      // Prepare user data
      final userData = {
        'currentEnergie': resources.currentEnergie,
        'currentBiomateriaux': resources.currentBiomateriaux,
        'immuneMemorySignatures': signatures,
        'researchPoints': memoireImmunitaire.researchPoints,
        'victories': victories,
        'lastLogin': DateTime.now().toIso8601String(),
      };
      
      final firestoreService = ref.read(firestoreServiceProvider);
      
      // Check if user document exists
      final userProfile = await firestoreService.getUserProfileOnce(currentUser.uid);
      
      if (userProfile == null) {
        // User document doesn't exist, create a new one with complete data
        print('Creating new user document in Firestore');
        await firestoreService.createUserProfile(
          userId: currentUser.uid,
          email: currentUser.email ?? 'unknown@email.com',
        );
        // Update with the current game state
        await firestoreService.updateUserProfile(currentUser.uid, userData);
      } else {
        // User exists, just update the data
        await firestoreService.updateUserProfile(currentUser.uid, userData);
      }
      
      print('Game state synced to Firestore');
    } catch (e) {
      print('Error syncing to Firestore: $e');
    } finally {
      _isSyncing = false;
    }
  }
  
  /// Force a full sync cycle
  Future<void> performFullSync() async {
    await initialize();
    
    try {
      // First try to load from local storage
      await loadFromLocalStorage();
      
      // Then try to sync with Firestore if user is logged in
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final firestoreService = ref.read(firestoreServiceProvider);
        final profile = await firestoreService.getUserProfileOnce(user.uid);
        
        if (profile != null) {
          // Then sync from Firestore to update local data
          await syncFromFirestore(profile);
          
          // Finally, sync from local state back to Firestore
          await syncToFirestore();
          print('Full sync completed successfully');
        }
      }
    } catch (e) {
      print('Error performing full sync: $e');
    }
  }
  
  /// Save data after combat or other important events
  Future<void> saveAfterEvent() async {
    // First save locally
    await saveToLocalStorage();
    
    // Then try to sync with Firestore
    await syncToFirestore();
  }
  
  /// Delete enemy base from Firestore after defeating it
  Future<void> deleteEnemyBase(String docId) async {
    try {
      final authState = ref.read(authStateProvider);
      final currentUser = authState.value;
      
      // Check if user is logged in
      if (currentUser == null) {
        print('Cannot delete enemy base: User not logged in');
        return;
      }
      
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.deleteDocument('enemy_bases', docId);
      print('Enemy base deleted from Firestore: $docId');
    } catch (e) {
      print('Error deleting enemy base: $e');
    }
  }
}

final dataSyncServiceProvider = Provider<DataSyncService>((ref) {
  return DataSyncService(ref);
});
