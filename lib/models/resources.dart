import 'package:flutter/material.dart';

/// Model for managing the player's defensive resources
class ResourcesDefensive with ChangeNotifier {
  int _currentEnergie;
  int _maxEnergie;
  int _energieRegenerationRate; // per minute
  
  int _currentBiomateriaux;
  int _maxBiomateriaux;
  int _biomateriauxRegenerationRate; // per minute
  
  DateTime _lastUpdateTime;
  
  ResourcesDefensive({
    int currentEnergie = 100,
    int maxEnergie = 100,
    int energieRegenerationRate = 5,
    int currentBiomateriaux = 50,
    int maxBiomateriaux = 100,
    int biomateriauxRegenerationRate = 3,
  }) : 
    _currentEnergie = currentEnergie,
    _maxEnergie = maxEnergie,
    _energieRegenerationRate = energieRegenerationRate,
    _currentBiomateriaux = currentBiomateriaux,
    _maxBiomateriaux = maxBiomateriaux,
    _biomateriauxRegenerationRate = biomateriauxRegenerationRate,
    _lastUpdateTime = DateTime.now();
  
  // Getters
  int get currentEnergie => _currentEnergie;
  int get maxEnergie => _maxEnergie;
  int get energieRegenerationRate => _energieRegenerationRate;
  
  int get currentBiomateriaux => _currentBiomateriaux;
  int get maxBiomateriaux => _maxBiomateriaux;
  int get biomateriauxRegenerationRate => _biomateriauxRegenerationRate;
  
  /// Updates resources based on passive regeneration
  void updateResources() {
    final now = DateTime.now();
    final elapsedMinutes = now.difference(_lastUpdateTime).inSeconds / 60;
    
    // Calculate regenerated amounts
    final energieRegenerated = (elapsedMinutes * _energieRegenerationRate).floor();
    final biomateriauxRegenerated = (elapsedMinutes * _biomateriauxRegenerationRate).floor();
    
    // Update resources capped at max values
    if (energieRegenerated > 0) {
      _currentEnergie = (_currentEnergie + energieRegenerated).clamp(0, _maxEnergie);
    }
    
    if (biomateriauxRegenerated > 0) {
      _currentBiomateriaux = (_currentBiomateriaux + biomateriauxRegenerated).clamp(0, _maxBiomateriaux);
    }
    
    _lastUpdateTime = now;
    notifyListeners();
  }
  
  /// Consumes energie for actions
  /// Returns true if successful, false if insufficient energie
  bool consumeEnergie(int amount) {
    if (_currentEnergie >= amount) {
      _currentEnergie -= amount;
      notifyListeners();
      return true;
    }
    return false;
  }
  
  /// Consumes biomateriaux for creation
  /// Returns true if successful, false if insufficient biomateriaux
  bool consumeBiomateriaux(int amount) {
    if (_currentBiomateriaux >= amount) {
      _currentBiomateriaux -= amount;
      notifyListeners();
      return true;
    }
    return false;
  }
  
  /// Increases regeneration rates from research or upgrades
  void upgradeRegenerationRates({int energieBonus = 0, int biomateriauxBonus = 0}) {
    if (energieBonus > 0) {
      _energieRegenerationRate += energieBonus;
    }
    
    if (biomateriauxBonus > 0) {
      _biomateriauxRegenerationRate += biomateriauxBonus;
    }
    
    notifyListeners();
  }
  
  /// Increases maximum capacity from research or upgrades
  void upgradeCapacity({int energieBonus = 0, int biomateriauxBonus = 0}) {
    if (energieBonus > 0) {
      _maxEnergie += energieBonus;
    }
    
    if (biomateriauxBonus > 0) {
      _maxBiomateriaux += biomateriauxBonus;
    }
    
    notifyListeners();
  }
  
  /// Converts to Map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'currentEnergie': _currentEnergie,
      'maxEnergie': _maxEnergie,
      'energieRegenerationRate': _energieRegenerationRate,
      'currentBiomateriaux': _currentBiomateriaux,
      'maxBiomateriaux': _maxBiomateriaux,
      'biomateriauxRegenerationRate': _biomateriauxRegenerationRate,
      'lastUpdateTime': _lastUpdateTime.toIso8601String(),
    };
  }
  
  /// Creates instance from Firestore data
  factory ResourcesDefensive.fromMap(Map<String, dynamic> map) {
    return ResourcesDefensive(
      currentEnergie: map['currentEnergie'] ?? 100,
      maxEnergie: map['maxEnergie'] ?? 100,
      energieRegenerationRate: map['energieRegenerationRate'] ?? 5,
      currentBiomateriaux: map['currentBiomateriaux'] ?? 50,
      maxBiomateriaux: map['maxBiomateriaux'] ?? 100,
      biomateriauxRegenerationRate: map['biomateriauxRegenerationRate'] ?? 3,
    );
  }
}
