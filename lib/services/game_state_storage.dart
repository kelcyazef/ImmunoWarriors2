import 'package:hive_flutter/hive_flutter.dart';

/// Service for local storage of game state using Hive
class GameStateStorage {
  static const String _gameStateBoxName = 'gameState';
  
  // Keys for storing different game state elements
  static const String _energieKey = 'energie';
  static const String _biomateriauxKey = 'biomateriaux';
  static const String _researchPointsKey = 'researchPoints';
  static const String _victoriesKey = 'victories';
  static const String _signaturesKey = 'signatures';
  static const String _lastSyncKey = 'lastSync';
  
  /// Initialize Hive storage
  static Future<void> initialize() async {
    await Hive.initFlutter();
    await Hive.openBox<dynamic>(_gameStateBoxName);
  }
  
  /// Save energy value locally
  static Future<void> saveEnergie(int value) async {
    final box = Hive.box<dynamic>(_gameStateBoxName);
    await box.put(_energieKey, value);
  }
  
  /// Save biomaterials value locally
  static Future<void> saveBiomateriaux(int value) async {
    final box = Hive.box<dynamic>(_gameStateBoxName);
    await box.put(_biomateriauxKey, value);
  }
  
  /// Save research points value locally
  static Future<void> saveResearchPoints(int value) async {
    final box = Hive.box<dynamic>(_gameStateBoxName);
    await box.put(_researchPointsKey, value);
  }
  
  /// Save victories count locally
  static Future<void> saveVictories(int value) async {
    final box = Hive.box<dynamic>(_gameStateBoxName);
    await box.put(_victoriesKey, value);
  }
  
  /// Save immune memory signatures locally
  static Future<void> saveSignatures(List<String> signatures) async {
    final box = Hive.box<dynamic>(_gameStateBoxName);
    await box.put(_signaturesKey, signatures);
  }
  
  /// Save last sync timestamp
  static Future<void> saveLastSync(DateTime timestamp) async {
    final box = Hive.box<dynamic>(_gameStateBoxName);
    await box.put(_lastSyncKey, timestamp.toIso8601String());
  }
  
  /// Get energie value from local storage
  static int getEnergie({int defaultValue = 100}) {
    final box = Hive.box<dynamic>(_gameStateBoxName);
    return box.get(_energieKey, defaultValue: defaultValue);
  }
  
  /// Get biomaterials value from local storage
  static int getBiomateriaux({int defaultValue = 50}) {
    final box = Hive.box<dynamic>(_gameStateBoxName);
    return box.get(_biomateriauxKey, defaultValue: defaultValue);
  }
  
  /// Get research points from local storage
  static int getResearchPoints({int defaultValue = 0}) {
    final box = Hive.box<dynamic>(_gameStateBoxName);
    return box.get(_researchPointsKey, defaultValue: defaultValue);
  }
  
  /// Get victories count from local storage
  static int getVictories({int defaultValue = 0}) {
    final box = Hive.box<dynamic>(_gameStateBoxName);
    return box.get(_victoriesKey, defaultValue: defaultValue);
  }
  
  /// Get immune memory signatures from local storage
  static List<String> getSignatures() {
    final box = Hive.box<dynamic>(_gameStateBoxName);
    final signatures = box.get(_signaturesKey);
    if (signatures is List) {
      return signatures.cast<String>();
    }
    return [];
  }
  
  /// Get last sync timestamp
  static DateTime? getLastSync() {
    final box = Hive.box<dynamic>(_gameStateBoxName);
    final timestamp = box.get(_lastSyncKey);
    if (timestamp != null) {
      try {
        return DateTime.parse(timestamp);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
  
  /// Save complete game state locally
  static Future<void> saveGameState({
    required int energie,
    required int biomateriaux,
    required int researchPoints,
    required int victories,
    required List<String> signatures,
  }) async {
    final box = Hive.box<dynamic>(_gameStateBoxName);
    
    await box.putAll({
      _energieKey: energie,
      _biomateriauxKey: biomateriaux,
      _researchPointsKey: researchPoints,
      _victoriesKey: victories,
      _signaturesKey: signatures,
      _lastSyncKey: DateTime.now().toIso8601String(),
    });
  }
  
  /// Clear all stored game state data
  static Future<void> clearGameState() async {
    final box = Hive.box<dynamic>(_gameStateBoxName);
    await box.clear();
  }
}
