import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/firestore_providers.dart';
import '../services/firestore_service.dart';

/// Manages energy regeneration, consumption, and purchase
class EnergyManager extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final String userId;
  
  // Energy configuration
  static const int maxEnergy = 100;
  static const int regenerationRate = 1; // Energy per minute
  static const int energyPerAd = 20;
  static const int energyPerBiomaterial = 5; // How much energy per biomaterial
  static const int energyCostPerCombat = 10; // Energy cost to start a combat
  
  // Energy state
  int _currentEnergy = 0;
  DateTime? _lastRegenerationTime;
  Timer? _regenerationTimer;
  
  // Public getters
  int get currentEnergy => _currentEnergy;
  bool get isRegenerating => _regenerationTimer != null && _regenerationTimer!.isActive;
  bool get isEnergyFull => _currentEnergy >= maxEnergy;
  
  // Time remaining until next energy point
  Duration get timeUntilNextEnergy {
    if (isEnergyFull) return Duration.zero;
    
    final now = DateTime.now();
    if (_lastRegenerationTime == null) return Duration.zero;
    
    // Calculate regeneration interval (60 seconds / regenerationRate)
    final regenerationIntervalSeconds = 60 ~/ regenerationRate;
    final secondsElapsed = now.difference(_lastRegenerationTime!).inSeconds % regenerationIntervalSeconds;
    
    return Duration(seconds: regenerationIntervalSeconds - secondsElapsed);
  }
  
  // Time remaining until completely full energy
  Duration get timeUntilFullEnergy {
    if (isEnergyFull) return Duration.zero;
    
    final energyNeeded = maxEnergy - _currentEnergy;
    return Duration(minutes: energyNeeded ~/ regenerationRate);
  }
  
  // Constructor
  EnergyManager({
    required FirestoreService firestoreService,
    required this.userId,
    int initialEnergy = 0,
    DateTime? lastRegenerationTime,
  }) : _firestoreService = firestoreService {
    _currentEnergy = initialEnergy;
    _lastRegenerationTime = lastRegenerationTime ?? DateTime.now();
    _startRegenerationTimer();
  }
  
  // Handle nullable values safely
  int _safeInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed ?? defaultValue;
    }
    return defaultValue;
  }
  
  // Start timer to regenerate energy
  void _startRegenerationTimer() {
    if (_regenerationTimer?.isActive ?? false) {
      _regenerationTimer!.cancel();
    }
    
    // No need to regenerate if full
    if (isEnergyFull) return;
    
    // Calculate energy gained since last regeneration
    _calculatePendingEnergy();
    
    // Start timer for continuous regeneration
    _regenerationTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_currentEnergy < maxEnergy) {
        _currentEnergy += regenerationRate;
        if (_currentEnergy > maxEnergy) _currentEnergy = maxEnergy;
        _lastRegenerationTime = DateTime.now();
        _saveEnergyState();
        notifyListeners();
      } else {
        _regenerationTimer?.cancel();
      }
    });
  }
  
  // Calculate energy gained since last check
  void _calculatePendingEnergy() {
    if (_lastRegenerationTime == null) return;
    
    final now = DateTime.now();
    final minutesElapsed = now.difference(_lastRegenerationTime!).inMinutes;
    
    if (minutesElapsed > 0) {
      final energyGained = minutesElapsed * regenerationRate;
      _currentEnergy += energyGained;
      if (_currentEnergy > maxEnergy) _currentEnergy = maxEnergy;
      _lastRegenerationTime = now;
      notifyListeners();
    }
  }
  
  // Consume energy for an action (returns true if successful)
  Future<bool> consumeEnergy(int amount) async {
    _calculatePendingEnergy(); // Ensure latest energy value
    
    if (_currentEnergy < amount) return false;
    
    _currentEnergy -= amount;
    _saveEnergyState();
    
    // Restart timer if it was stopped (energy was full)
    if (!isRegenerating && !isEnergyFull) {
      _startRegenerationTimer();
    }
    
    notifyListeners();
    return true;
  }
  
  // Add energy (from ad, purchase, etc.)
  Future<void> addEnergy(int amount) async {
    _calculatePendingEnergy(); // Ensure latest energy value
    
    _currentEnergy += amount;
    if (_currentEnergy > maxEnergy) _currentEnergy = maxEnergy;
    _saveEnergyState();
    
    notifyListeners();
  }
  
  // Add energy by watching a video ad
  Future<bool> addEnergyFromAd() async {
    // Normally integrate with an actual ad SDK
    // For now, we'll simulate watching an ad
    bool adWatched = await _simulateAdWatching();
    
    if (adWatched) {
      await addEnergy(energyPerAd);
      return true;
    }
    return false;
  }
  
  // Purchase energy with biomaterials
  Future<bool> purchaseEnergyWithBiomaterials(int biomaterialsToSpend) async {
    // Get current biomaterials
    final userProfile = await _firestoreService.getUserProfileOnce(userId);
    // Get the current biomaterials from user profile
    final currentBiomaterials = userProfile != null ? _safeInt(userProfile.currentBiomateriaux) : 0;
    
    if (currentBiomaterials < biomaterialsToSpend) return false;
    
    // Calculate energy to add
    final energyToAdd = biomaterialsToSpend * energyPerBiomaterial;
    
    // Reduce biomaterials and add energy
    await _firestoreService.updateUserProfile(
      userId, 
      {
        'currentEnergie': _currentEnergy + energyToAdd > maxEnergy ? maxEnergy : _currentEnergy + energyToAdd,
        'currentBiomateriaux': currentBiomaterials - biomaterialsToSpend
      }
    );
    
    await addEnergy(energyToAdd);
    return true;
  }
  
  // Simulate watching an ad (would be replaced by actual ad SDK)
  Future<bool> _simulateAdWatching() async {
    // In a real implementation, this would show an ad and return true if completed
    await Future.delayed(const Duration(seconds: 1)); // Simulate ad loading time
    return true; // Simulating successful ad watching
  }
  
  // Save energy state to Firebase
  Future<void> _saveEnergyState() async {
    await _firestoreService.updateUserProfile(
      userId,
      {'currentEnergie': _currentEnergy},
    );
  }
  
  // Clean up timer when disposing
  @override
  void dispose() {
    _regenerationTimer?.cancel();
    super.dispose();
  }
}

// Energy manager provider
final energyManagerProvider = Provider.autoDispose.family<EnergyManager, String>((ref, userId) {
  // Get FirestoreService from provider
  final firestoreService = ref.read(firestoreServiceProvider);
  
  // Create energy manager
  final energyManager = EnergyManager(
    firestoreService: firestoreService,
    userId: userId,
  );
  
  // Handle disposal
  ref.onDispose(() {
    energyManager.dispose();
  });
  
  return energyManager;
});

// Energy value provider (for UI that only needs the value)
final energyValueProvider = Provider.autoDispose<int>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return 0;
  
  final energyManager = ref.watch(energyManagerProvider(user.uid));
  return energyManager.currentEnergy;
});

// Time until next energy provider
final timeUntilNextEnergyProvider = Provider.autoDispose<Duration>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Duration.zero;
  
  final energyManager = ref.watch(energyManagerProvider(user.uid));
  return energyManager.timeUntilNextEnergy;
});
